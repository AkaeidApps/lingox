/// Base exception class for all TTS-related errors.
abstract class TtsException implements Exception {
  final String message;
  final String? code;

  const TtsException({required this.message, this.code});

  @override
  String toString() => 'TtsException[$code]: $message';
}

/// API key missing or invalid for TTS
class TtsApiKeyException extends TtsException {
  const TtsApiKeyException({
    super.message = 'TTS API key is not configured. Please set your Google Cloud Text-to-Speech API key.',
  }) : super(code: 'TTS_API_KEY_MISSING');
}

/// Network connectivity error during TTS request
class TtsNetworkException extends TtsException {
  const TtsNetworkException({
    super.message = 'No internet connection. Check your network settings.',
  }) : super(code: 'TTS_NETWORK_ERROR');
}

/// TTS API timeout error
class TtsTimeoutException extends TtsException {
  const TtsTimeoutException({
    super.message = 'TTS request timed out. Please try again.',
  }) : super(code: 'TTS_TIMEOUT');
}

/// Unsupported language for TTS
class TtsUnsupportedLanguageException extends TtsException {
  final String languageCode;
  const TtsUnsupportedLanguageException(this.languageCode, {String? message})
    : super(
        message:
            message ??
            'Language "$languageCode" is not supported for text-to-speech.',
        code: 'TTS_UNSUPPORTED_LANGUAGE',
      );
}

/// No voice found for the given language
class TtsVoiceNotFoundException extends TtsException {
  final String languageCode;
  const TtsVoiceNotFoundException(this.languageCode, {String? message})
    : super(
        message: message ?? 'No voice found for language "$languageCode".',
        code: 'TTS_VOICE_NOT_FOUND',
      );
}

/// Audio playback error
class TtsPlaybackException extends TtsException {
  const TtsPlaybackException({
    super.message = 'Failed to play audio. Please try again.',
  }) : super(code: 'TTS_PLAYBACK_ERROR');
}

/// Generic TTS API error
class TtsApiException extends TtsException {
  final int? statusCode;
  const TtsApiException({required super.message, this.statusCode, String? code})
    : super(code: code ?? 'TTS_API_ERROR');
}

/// TTS quota exceeded
class TtsQuotaExceededException extends TtsException {
  const TtsQuotaExceededException({
    super.message = 'TTS API quota exceeded. Please try again later.',
  }) : super(code: 'TTS_QUOTA_EXCEEDED');
}
