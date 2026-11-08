import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../errors/tts_exceptions.dart';
import 'api_config.dart';

/// Text-to-speech engine backed by the Gemini API.
///
/// Gemini TTS uses the same free API key as Gemini translation, so spoken
/// translations keep working without a Cloud Text-to-Speech billing account.
/// The API returns base64 audio (usually WAV, sometimes raw PCM). Raw PCM is
/// wrapped in a WAV header before it is saved so audioplayers can play it.
class GeminiTtsService {
  final Dio _dio;
  final String? _apiKeyOverride;
  final List<String> _models;

  GeminiTtsService({Dio? dio, String? apiKey, String? model})
    : _dio = dio ?? _createDio(),
      _apiKeyOverride = apiKey,
      _models = _buildModels(model);

  factory GeminiTtsService.create() => GeminiTtsService();

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.geminiBaseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.ttsConnectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.ttsReceiveTimeout),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    );
  }

  static List<String> _buildModels(String? model) {
    final primary = (model ?? ApiConfig.geminiTtsModel).trim();
    final models = <String>[
      if (primary.isNotEmpty) primary,
      ...ApiConfig.geminiTtsFallbackModels,
    ];
    return models.toSet().toList();
  }

  /// Synthesize [text] and return the path of the generated audio file.
  ///
  /// [languageCode] is accepted for parity with the Cloud TTS service; Gemini
  /// detects the spoken language from the text itself.
  Future<String> synthesize({
    required String text,
    required String languageCode,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const TtsApiException(message: 'Text cannot be empty.');
    }
    if (trimmed.length > ApiConfig.geminiTtsMaxCharacters) {
      throw TtsApiException(
        message:
            'Text too long for TTS '
            '(max ${ApiConfig.geminiTtsMaxCharacters} characters).',
        code: 'TTS_INPUT_TOO_LONG',
      );
    }

    final apiKey = await _requireApiKey();
    DioException? lastError;

    for (final model in _models) {
      try {
        final response = await _dio.post(
          '/models/$model:generateContent',
          queryParameters: {'key': apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': trimmed},
                ],
              },
            ],
            'generationConfig': {
              'responseModalities': ['AUDIO'],
              'speechConfig': {
                'voiceConfig': {
                  'prebuiltVoiceConfig': {
                    'voiceName': ApiConfig.geminiTtsVoice,
                  },
                },
              },
            },
          },
        );

        return await _saveAudio(response.data);
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        final hasFallback = model != _models.last;
        // Retry only when the model itself is unavailable or overloaded.
        if (hasFallback && (status == 404 || status == 503)) {
          continue;
        }
        throw _handleDioError(e);
      }
    }

    throw _handleDioError(
      lastError ??
          DioException(
            requestOptions: RequestOptions(path: '/models'),
            message: 'No Gemini TTS model could be reached.',
          ),
    );
  }

  Future<String> _requireApiKey() async {
    if (_apiKeyOverride != null) {
      final override = _apiKeyOverride.trim();
      if (override.isEmpty) {
        throw const TtsApiKeyException(
          message:
              'Gemini API key is not configured. Add a free Gemini key in '
              'Settings > API Configuration.',
        );
      }
      return override;
    }

    await ApiConfig.initialize();
    final apiKey = ApiConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw const TtsApiKeyException(
        message:
            'Gemini API key is not configured. Add a free Gemini key in '
            'Settings > API Configuration.',
      );
    }
    return apiKey;
  }

  Future<String> _saveAudio(dynamic data) async {
    final audio = _extractAudio(data);
    final isWav =
        audio.mimeType.toLowerCase().contains('wav') ||
        (audio.bytes.length >= 4 &&
            ascii.decode(audio.bytes.sublist(0, 4), allowInvalid: true) ==
                'RIFF');

    final bytes = isWav
        ? audio.bytes
        : _wrapPcmAsWav(
            audio.bytes,
            sampleRate: _sampleRateFromMime(audio.mimeType),
          );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'tts_${DateTime.now().microsecondsSinceEpoch}.wav';
    final filePath = '${tempDir.path}/$fileName';
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }

  ({Uint8List bytes, String mimeType}) _extractAudio(dynamic data) {
    if (data is Map) {
      final candidates = data['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final candidate = candidates.first;
        if (candidate is Map) {
          final content = candidate['content'];
          if (content is Map && content['parts'] is List) {
            for (final part in content['parts'] as List) {
              if (part is Map && part['inlineData'] is Map) {
                final inline = part['inlineData'] as Map;
                final encoded = inline['data'];
                if (encoded is String && encoded.isNotEmpty) {
                  return (
                    bytes: base64Decode(encoded),
                    mimeType: inline['mimeType']?.toString() ?? 'audio/wav',
                  );
                }
              }
            }
          }

          final finishReason = candidate['finishReason']?.toString();
          if (finishReason != null &&
              finishReason != 'STOP' &&
              finishReason != 'FINISH_REASON_UNSPECIFIED') {
            throw TtsApiException(
              message: 'Gemini could not generate speech ($finishReason).',
            );
          }
        }
      }

      final feedback = data['promptFeedback'];
      if (feedback is Map && feedback['blockReason'] != null) {
        throw TtsApiException(
          message: 'Gemini blocked the speech request '
              '(${feedback['blockReason']}).',
        );
      }
    }

    throw const TtsApiException(
      message: 'Gemini TTS returned no audio. Try a shorter text.',
    );
  }

  int _sampleRateFromMime(String mimeType) {
    final match = RegExp(r'rate=(\d+)').firstMatch(mimeType.toLowerCase());
    if (match == null) return ApiConfig.ttsSamplingRate;
    return int.tryParse(match.group(1)!) ?? ApiConfig.ttsSamplingRate;
  }

  /// Adds a standard 44-byte WAV header to raw 16-bit mono PCM audio.
  Uint8List _wrapPcmAsWav(
    Uint8List pcm, {
    int sampleRate = 24000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final blockAlign = channels * bitsPerSample ~/ 8;
    final byteRate = sampleRate * blockAlign;
    final builder = BytesBuilder(copy: false);

    void writeString(String value) => builder.add(ascii.encode(value));

    void writeUint16(int value) {
      final data = ByteData(2)..setUint16(0, value, Endian.little);
      builder.add(data.buffer.asUint8List());
    }

    void writeUint32(int value) {
      final data = ByteData(4)..setUint32(0, value, Endian.little);
      builder.add(data.buffer.asUint8List());
    }

    writeString('RIFF');
    writeUint32(36 + pcm.length);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1); // PCM
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(blockAlign);
    writeUint16(bitsPerSample);
    writeString('data');
    writeUint32(pcm.length);
    builder.add(pcm);

    return builder.toBytes();
  }

  Never _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        throw const TtsTimeoutException();
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        throw const TtsNetworkException();
      case DioExceptionType.badResponse:
        _handleErrorResponse(e.response);
      case DioExceptionType.cancel:
        throw const TtsApiException(message: 'TTS request cancelled.');
      case DioExceptionType.badCertificate:
        throw const TtsApiException(message: 'SSL certificate error.');
    }
  }

  Never _handleErrorResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Gemini TTS request failed.';
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      message = error['message']?.toString() ?? message;
    }

    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('api key') &&
        (statusCode == 400 || statusCode == 401 || statusCode == 403)) {
      throw TtsApiKeyException(message: message);
    }

    switch (statusCode) {
      case 400:
        throw TtsApiException(message: message, statusCode: statusCode);
      case 401:
        throw const TtsApiKeyException();
      case 403:
        if (lowerMessage.contains('quota')) {
          throw const TtsQuotaExceededException();
        }
        throw TtsApiKeyException(message: message);
      case 404:
        throw const TtsApiException(message: 'Gemini TTS model not found.');
      case 429:
        throw const TtsQuotaExceededException();
      case 500:
      case 503:
        throw const TtsApiException(
          message: 'Gemini TTS service temporarily unavailable.',
        );
      default:
        throw TtsApiException(message: message, statusCode: statusCode);
    }
  }
}
