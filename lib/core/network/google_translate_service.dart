import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../errors/translation_exceptions.dart';
import 'api_config.dart';
import 'translation_service.dart';

/// Service for interacting with Google Cloud Translation API (v2).
///
/// This service handles:
/// - Text translation
/// - Language detection
/// - Fetching supported languages
///
/// Requests use POST with JSON bodies, which avoids URL-length limits and
/// handles special characters (emoji, new lines, etc.) correctly.
///
/// Security: In production, all requests should go through a backend proxy
/// to avoid exposing API keys in the client app.
class GoogleTranslateService implements TranslationService {
  final Dio _dio;
  final Future<bool> Function()? connectivityCheck;
  final String? _apiKeyOverride;

  GoogleTranslateService({
    Dio? dio,
    this.connectivityCheck,
    String? apiKey,
    String? baseUrl,
  }) : _dio = dio ?? _createDio(baseUrl: baseUrl ?? ApiConfig.baseUrl),
       _apiKeyOverride = apiKey;

  factory GoogleTranslateService.create() {
    return GoogleTranslateService();
  }

  static Dio _createDio({required String baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    );
  }

  /// Check if the device has internet connectivity.
  @override
  Future<bool> hasInternetConnection() async {
    // Tests and callers can provide their own check so the plugin is not needed.
    final check = connectivityCheck;
    if (check != null) return check();

    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Resolve the API key from an injected value, the runtime setting, or the
  /// compile-time `--dart-define` value.
  Future<String> _requireApiKey() async {
    if (_apiKeyOverride != null) {
      final override = _apiKeyOverride.trim();
      if (override.isEmpty) throw const ApiKeyException();
      return override;
    }

    // Load a runtime key even when a compile-time key exists, so a key entered
    // in Settings can override it.
    await ApiConfig.initialize();

    final apiKey = ApiConfig.apiKey;
    if (apiKey.isEmpty) throw const ApiKeyException();
    return apiKey;
  }

  /// Translate text from source language to target language.
  ///
  /// [text] - The text to translate
  /// [targetLanguage] - Target language code (e.g., 'es', 'fr', 'de')
  /// [sourceLanguage] - Optional source language code. If null or 'auto',
  ///                    the API will auto-detect the language.
  ///
  /// Returns the translated text.
  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (text.trim().isEmpty) {
      throw const ApiException(message: 'Input text cannot be empty.');
    }

    if (text.length > ApiConfig.maxCharacters) {
      throw InputTooLongException(ApiConfig.maxCharacters);
    }

    final apiKey = await _requireApiKey();

    if (!await hasInternetConnection()) {
      throw const NetworkException();
    }

    try {
      final response = await _dio.post(
        '',
        queryParameters: {'key': apiKey},
        data: {
          'q': text,
          'target': targetLanguage,
          'format': 'text',
          if (sourceLanguage != null &&
              sourceLanguage.isNotEmpty &&
              sourceLanguage != 'auto')
            'source': sourceLanguage,
        },
      );

      final translations = _readPath(response.data, ['data', 'translations']);
      if (translations is List && translations.isNotEmpty) {
        final first = translations.first;
        if (first is Map && first['translatedText'] != null) {
          return first['translatedText'].toString();
        }
      }

      throw const ApiException(
        message: 'Unexpected response format from translation API.',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw ApiException(message: 'Translation failed: $e');
    }
  }

  /// Detect the language of the given text.
  ///
  /// Returns the detected language code (e.g., 'en', 'es', 'fr').
  @override
  Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) {
      throw const LanguageDetectionException(
        message: 'Cannot detect language of empty text.',
      );
    }

    final apiKey = await _requireApiKey();

    if (!await hasInternetConnection()) {
      throw const NetworkException();
    }

    try {
      final response = await _dio.post(
        ApiConfig.detectEndpoint,
        queryParameters: {'key': apiKey},
        data: {
          'q': [text],
        },
      );

      final detections = _readPath(response.data, ['data', 'detections']);
      if (detections is List && detections.isNotEmpty) {
        final firstResult = detections.first;
        if (firstResult is List && firstResult.isNotEmpty) {
          final first = firstResult.first;
          if (first is Map && first['language'] != null) {
            return first['language'].toString();
          }
        }
      }

      throw const LanguageDetectionException();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw LanguageDetectionException(message: 'Detection failed: $e');
    }
  }

  /// Fetch the list of supported languages from the API.
  ///
  /// Returns a list of maps with 'language' (code) and 'name' keys.
  @override
  Future<List<Map<String, String>>> getSupportedLanguages() async {
    final apiKey = await _requireApiKey();

    if (!await hasInternetConnection()) {
      throw const NetworkException();
    }

    try {
      final response = await _dio.get(
        ApiConfig.languagesEndpoint,
        queryParameters: {
          'key': apiKey,
          // Ask for English names so the picker shows stable labels.
          'target': 'en',
        },
      );

      final languages = _readPath(response.data, ['data', 'languages']);
      if (languages is List) {
        return languages.map((language) {
          final map = language is Map ? language : const <String, dynamic>{};
          return {
            'language': map['language']?.toString() ?? '',
            'name': map['name']?.toString() ?? '',
          };
        }).toList();
      }

      throw const ApiException(
        message: 'Unexpected response format from languages API.',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw ApiException(message: 'Failed to fetch languages: $e');
    }
  }

  dynamic _readPath(dynamic data, List<String> path) {
    dynamic current = data;
    for (final segment in path) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Convert HTTP error responses from the API into typed exceptions.
  Never _handleErrorResponse(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;

    String? message;
    String? reason;

    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        message = error['message']?.toString();
        final details = error['details'];
        if (details is List) {
          for (final detail in details) {
            if (detail is Map && detail['reason'] != null) {
              reason = detail['reason'].toString();
              break;
            }
          }
        }
        if (reason == null && error['errors'] is List) {
          final errors = error['errors'] as List;
          if (errors.isNotEmpty && errors.first is Map) {
            reason = (errors.first as Map)['reason']?.toString();
          }
        }
      }
    }

    final lowerMessage = (message ?? '').toLowerCase();
    final isApiKeyError =
        reason == 'API_KEY_INVALID' ||
        reason == 'API_KEY_SERVICE_BLOCKED' ||
        lowerMessage.contains('api key not valid') ||
        lowerMessage.contains('api key') && statusCode == 400;

    if (isApiKeyError) {
      throw ApiKeyException(
        message: message ?? 'Google Cloud Translation API key is invalid.',
      );
    }

    final isQuotaError =
        statusCode == 429 ||
        reason == 'RATE_LIMIT_EXCEEDED' ||
        lowerMessage.contains('quota') ||
        lowerMessage.contains('rate limit');

    if (isQuotaError) {
      throw QuotaExceededException(message: message ?? 'API quota exceeded.');
    }

    switch (statusCode) {
      case 400:
        if (lowerMessage.contains('target') ||
            lowerMessage.contains('source') ||
            lowerMessage.contains('language')) {
          throw UnsupportedLanguageException('', message: message);
        }
        throw ApiException(
          message: message ?? 'Invalid translation request.',
          statusCode: statusCode,
        );
      case 401:
        throw ApiKeyException(message: message ?? 'API key is not authorized.');
      case 403:
        throw ApiException(
          message:
              message ??
              'The Translation API is not enabled or access was denied.',
          statusCode: statusCode,
        );
      case 404:
        throw ApiException(
          message: 'Translation service not found',
          statusCode: statusCode,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        throw ApiException(
          message: 'Translation service is temporarily unavailable',
          statusCode: statusCode,
        );
      default:
        throw ApiException(
          message: message ?? 'Translation API request failed.',
          statusCode: statusCode,
        );
    }
  }

  /// Convert Dio errors to custom exceptions.
  TranslationException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiTimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null) {
          _handleErrorResponse(response);
        }
        return ApiException(
          message: e.message ?? 'Server error',
          statusCode: response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled');
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true ||
            e.message?.contains('Network') == true) {
          return const NetworkException();
        }
        return ApiException(message: e.message ?? 'Unknown error occurred');
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'SSL certificate error. Check your network connection.',
        );
      case DioExceptionType.transformTimeout:
        return ApiException(message: e.message ?? 'Unknown error occurred');
    }
  }
}
