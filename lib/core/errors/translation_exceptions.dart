/// Base exception class for all translation-related errors
abstract class TranslationException implements Exception {
  final String message;
  final String? code;

  const TranslationException({required this.message, this.code});

  @override
  String toString() => 'TranslationException[$code]: $message';
}

/// Network connectivity error
class NetworkException extends TranslationException {
  const NetworkException({super.message = 'No internet connection'})
    : super(code: 'NETWORK_ERROR');
}

/// API timeout error
class ApiTimeoutException extends TranslationException {
  const ApiTimeoutException({
    super.message = 'Request timed out. Please try again.',
  }) : super(code: 'TIMEOUT');
}

/// API key missing or invalid
class ApiKeyException extends TranslationException {
  const ApiKeyException({
    super.message = 'API key is not configured. Please set your Google Cloud Translation API key.',
  }) : super(code: 'API_KEY_MISSING');
}

/// Google Cloud API quota exceeded
class QuotaExceededException extends TranslationException {
  const QuotaExceededException({
    super.message = 'API quota exceeded. Please try again later.',
  }) : super(code: 'QUOTA_EXCEEDED');
}

/// Unsupported language error
class UnsupportedLanguageException extends TranslationException {
  final String languageCode;
  const UnsupportedLanguageException(this.languageCode, {String? message})
    : super(
        message:
            message ??
            'Language "$languageCode" is not supported by the translation API.',
        code: 'UNSUPPORTED_LANGUAGE',
      );
}

/// Input text too long
class InputTooLongException extends TranslationException {
  final int maxLength;
  const InputTooLongException(this.maxLength, {String? message})
    : super(
        message:
            message ??
            'Input text exceeds the maximum length of $maxLength characters.',
        code: 'INPUT_TOO_LONG',
      );
}

/// Generic API error
class ApiException extends TranslationException {
  final int? statusCode;
  const ApiException({required super.message, this.statusCode, String? code})
    : super(code: code ?? 'API_ERROR');
}

/// Language detection failed
class LanguageDetectionException extends TranslationException {
  const LanguageDetectionException({
    super.message = 'Could not detect the source language.',
  }) : super(code: 'DETECTION_FAILED');
}
