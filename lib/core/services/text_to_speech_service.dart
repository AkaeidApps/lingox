import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../errors/tts_exceptions.dart';
import '../network/api_config.dart';
import '../network/gemini_tts_service.dart';

/// Service for Google Cloud Text-to-Speech API.
///
/// Converts text to speech using the Google Cloud TTS REST API and plays
/// the resulting audio using audioplayers. When only a Gemini API key is
/// configured, the free Gemini TTS engine is used instead.
///
/// IMPORTANT: Never embed API keys in production code. Use a backend proxy.
class TextToSpeechService {
  final Dio _dio;
  final GeminiTtsService _geminiTts;

  TextToSpeechService({Dio? dio, GeminiTtsService? geminiTts})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(
                seconds: ApiConfig.ttsConnectTimeout,
              ),
              receiveTimeout: const Duration(
                seconds: ApiConfig.ttsReceiveTimeout,
              ),
            ),
          ),
      _geminiTts = geminiTts ?? GeminiTtsService.create();

  factory TextToSpeechService.create() {
    return TextToSpeechService();
  }

  /// Synthesize text to speech and return the audio file path.
  ///
  /// [text] - The text to synthesize
  /// [languageCode] - The language code (e.g. 'en-US', 'es-ES')
  /// [ssmlGender] - Optional voice gender ('MALE', 'FEMALE', 'NEUTRAL')
  /// Returns the path to the synthesized audio file.
  Future<String> synthesize({
    required String text,
    required String languageCode,
    String? ssmlGender,
  }) async {
    await ApiConfig.initialize();

    // Prefer Gemini when the free Gemini key is the only key available.
    // Cloud Text-to-Speech requires a billing account, Gemini does not.
    if (ApiConfig.ttsApiKey.isEmpty && ApiConfig.hasGeminiApiKey) {
      return _geminiTts.synthesize(text: text, languageCode: languageCode);
    }

    // Check API key
    final apiKey = ApiConfig.ttsApiKey;
    if (apiKey.isEmpty) {
      throw const TtsApiKeyException();
    }

    // Check text length
    if (text.length > ApiConfig.ttsMaxCharacters) {
      throw TtsApiException(
        message:
            'Text too long for TTS (max ${ApiConfig.ttsMaxCharacters} characters).',
        code: 'TTS_INPUT_TOO_LONG',
      );
    }

    // Find a suitable voice for the language
    final voiceName = await _findVoiceForLanguage(languageCode, ssmlGender);
    if (voiceName.isEmpty) {
      throw TtsVoiceNotFoundException(languageCode);
    }

    try {
      // Build the request body
      final requestBody = {
        'input': {'text': text},
        'voice': {
          'languageCode': languageCode,
          'name': voiceName,
          'ssmlGender': ?ssmlGender,
        },
        'audioConfig': {
          'audioEncoding': ApiConfig.ttsAudioEncoding,
          'sampleRateHertz': ApiConfig.ttsSamplingRate,
        },
      };

      // Make the API call
      final response = await _dio.post(
        '${ApiConfig.ttsBaseUrl}${ApiConfig.ttsSynthesizeEndpoint}',
        queryParameters: {'key': apiKey},
        data: requestBody,
        options: Options(
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        ),
      );

      if (response.statusCode != 200) {
        _handleTtsError(response);
      }

      // Extract audio content (base64 encoded)
      final data = response.data;
      if (data == null || data['audioContent'] == null) {
        throw const TtsApiException(message: 'No audio content in response.');
      }

      final audioBase64 = data['audioContent'] as String;
      final audioBytes = base64Decode(audioBase64);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(audioBytes);

      return filePath;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is TtsException) rethrow;
      throw TtsApiException(message: 'TTS synthesis failed: $e');
    }
  }

  /// List available voices for a language.
  Future<List<Map<String, dynamic>>> listVoices({String? languageCode}) async {
    final apiKey = ApiConfig.ttsApiKey;
    if (apiKey.isEmpty) {
      throw const TtsApiKeyException();
    }

    try {
      final response = await _dio.get(
        '${ApiConfig.ttsBaseUrl}${ApiConfig.ttsVoicesEndpoint}',
        queryParameters: {'key': apiKey},
      );

      if (response.statusCode != 200) {
        _handleTtsError(response);
      }

      final data = response.data;
      if (data == null || data['voices'] == null) {
        return [];
      }

      final voices = data['voices'] as List;
      final result = voices.map((v) {
        final voiceMap = v as Map<String, dynamic>;
        return {
          'name': voiceMap['name'] ?? '',
          'languageCode': voiceMap['languageCodes']?.first ?? '',
          'ssmlGender': voiceMap['ssmlGender'] ?? 'NEUTRAL',
        };
      }).toList();

      // Filter by language if specified
      if (languageCode != null && languageCode.isNotEmpty) {
        return result
            .where(
              (v) => (v['languageCode'] as String).startsWith(
                languageCode.split('-')[0],
              ),
            )
            .toList();
      }

      return result.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is TtsException) rethrow;
      throw TtsApiException(message: 'Failed to list voices: $e');
    }
  }

  /// Find a suitable voice name for the given language.
  Future<String> _findVoiceForLanguage(
    String languageCode,
    String? ssmlGender,
  ) async {
    try {
      final voices = await listVoices(languageCode: languageCode);

      // Try exact match first
      for (final voice in voices) {
        final vc = voice['languageCode'] as String;
        if (vc == languageCode) {
          if (ssmlGender == null ||
              (voice['ssmlGender'] as String?) == ssmlGender) {
            return voice['name'] as String;
          }
        }
      }

      // Try prefix match (e.g. 'en' matches 'en-US')
      final prefix = languageCode.split('-')[0];
      for (final voice in voices) {
        final vc = voice['languageCode'] as String;
        if (vc.startsWith(prefix)) {
          if (ssmlGender == null ||
              (voice['ssmlGender'] as String?) == ssmlGender) {
            return voice['name'] as String;
          }
        }
      }

      // Return any voice with matching prefix
      for (final voice in voices) {
        final vc = voice['languageCode'] as String;
        if (vc.startsWith(prefix)) {
          return voice['name'] as String;
        }
      }

      return '';
    } catch (e) {
      // If listing voices fails, return a default voice name
      // This allows the API to auto-select a voice
      return '';
    }
  }

  /// Convert language code from translation format to TTS format.
  /// E.g. 'en' -> 'en-US', 'es' -> 'es-ES', 'fr' -> 'fr-FR'
  static String toTtsLanguageCode(String languageCode) {
    if (languageCode.isEmpty || languageCode == 'auto') {
      return 'en-US';
    }

    // If already in full format (e.g. 'en-US'), return as-is
    if (languageCode.contains('-')) {
      return languageCode;
    }

    // Map common language codes to their default region
    const Map<String, String> languageMap = {
      'af': 'af-ZA',
      'sq': 'sq-AL',
      'am': 'am-ET',
      'ar': 'ar-XA',
      'hy': 'hy-AM',
      'az': 'az-AZ',
      'eu': 'eu-ES',
      'be': 'be-BY',
      'bs': 'bs-BA',
      'bg': 'bg-BG',
      'bn': 'bn-IN',
      'my': 'my-MM',
      'ca': 'ca-ES',
      'ceb': 'en-US', // No Cebuano TTS, fallback to English
      'zh': 'zh-CN',
      'hr': 'hr-HR',
      'cs': 'cs-CZ',
      'da': 'da-DK',
      'nl': 'nl-NL',
      'en': 'en-US',
      'eo': 'en-US', // No Esperanto TTS, fallback
      'et': 'et-EE',
      'fi': 'fi-FI',
      'fr': 'fr-FR',
      'gl': 'gl-ES',
      'ka': 'ka-GE',
      'de': 'de-DE',
      'el': 'el-GR',
      'gu': 'gu-IN',
      'ha': 'ha-NG',
      'haw': 'en-US', // No Hawaiian TTS, fallback
      'he': 'iw-IL',
      'hi': 'hi-IN',
      'hmn': 'en-US', // No Hmong TTS, fallback
      'hu': 'hu-HU',
      'is': 'is-IS',
      'ig': 'ig-NG',
      'id': 'id-ID',
      'ga': 'ga-IE',
      'it': 'it-IT',
      'ja': 'ja-JP',
      'jw': 'en-US', // No Javanese TTS, fallback
      'kn': 'kn-IN',
      'kk': 'kk-KZ',
      'km': 'km-KH',
      'ko': 'ko-KR',
      'ku': 'en-US', // No Kurdish TTS, fallback
      'ky': 'ky-KG',
      'lo': 'lo-LA',
      'la': 'en-US', // No Latin TTS, fallback
      'lv': 'lv-LV',
      'lt': 'lt-LT',
      'mg': 'en-US', // No Malagasy TTS, fallback
      'ms': 'ms-MY',
      'ml': 'ml-IN',
      'mt': 'mt-MT',
      'mi': 'en-US', // No Maori TTS, fallback
      'mr': 'mr-IN',
      'mn': 'mn-MN',
      'ne': 'ne-NP',
      'no': 'nb-NO',
      'ps': 'ps-AF',
      'fa': 'fa-IR',
      'pl': 'pl-PL',
      'pt': 'pt-BR',
      'pa': 'pa-IN',
      'ro': 'ro-RO',
      'ru': 'ru-RU',
      'sr': 'sr-RS',
      'st': 'en-US', // No Sesotho TTS, fallback
      'sn': 'en-US', // No Shona TTS, fallback
      'sd': 'sd-IN',
      'si': 'si-LK',
      'sk': 'sk-SK',
      'sl': 'sl-SI',
      'so': 'so-SO',
      'es': 'es-ES',
      'su': 'en-US', // No Sundanese TTS, fallback
      'sw': 'sw-KE',
      'sv': 'sv-SE',
      'tl': 'fil-PH', // Tagalog -> Filipino
      'tg': 'tg-TJ',
      'ta': 'ta-IN',
      'te': 'te-IN',
      'th': 'th-TH',
      'tr': 'tr-TR',
      'uk': 'uk-UA',
      'ur': 'ur-PK',
      'ug': 'en-US', // No Uyghur TTS, fallback
      'uz': 'uz-UZ',
      'vi': 'vi-VN',
      'cy': 'cy-GB',
      'yi': 'yi-001',
      'yo': 'yo-NG',
      'zu': 'en-US', // No Zulu TTS, fallback
    };

    return languageMap[languageCode] ?? 'en-US';
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
        _handleTtsError(e.response!);
      case DioExceptionType.cancel:
        throw const TtsApiException(message: 'TTS request cancelled.');
      case DioExceptionType.badCertificate:
        throw const TtsApiException(message: 'SSL certificate error.');
    }
  }

  Never _handleTtsError(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    // Extract error message from Google API response
    String message = 'TTS API error';
    if (data is Map && data['error'] is Map) {
      final error = data['error'];
      message = error['message'] ?? message;
      final errorcode = error['code'];
      if (errorcode == 429) {
        throw const TtsQuotaExceededException();
      }
    }

    switch (statusCode) {
      case 400:
        throw TtsApiException(message: message, statusCode: statusCode);
      case 401:
        throw const TtsApiKeyException();
      case 403:
        if (message.toLowerCase().contains('quota')) {
          throw const TtsQuotaExceededException();
        }
        throw const TtsApiKeyException();
      case 404:
        throw const TtsApiException(message: 'TTS service not found.');
      case 429:
        throw const TtsQuotaExceededException();
      case 500:
      case 503:
        throw const TtsApiException(
          message: 'TTS service temporarily unavailable.',
        );
      default:
        throw TtsApiException(message: message, statusCode: statusCode);
    }
  }
}
