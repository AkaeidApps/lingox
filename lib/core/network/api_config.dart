import 'package:shared_preferences/shared_preferences.dart';

/// API configuration for Google Cloud Translation.
///
/// IMPORTANT SECURITY NOTE:
/// Never commit Google Cloud API keys or service-account credentials to source
/// control. For development you can either:
///
/// 1. Pass the key at build time:
///    `--dart-define=GOOGLE_TRANSLATE_API_KEY=YOUR_KEY`
/// 2. Enter the key in the app (Settings > API Configuration). It is stored in
///    SharedPreferences on the device only.
///
/// For production, route requests through a backend proxy so the key never
/// ships inside the app binary. See docs/BACKEND_SETUP.md.
class ApiConfig {
  ApiConfig._();

  /// Google Cloud Translation API v2 base URL.
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://translation.googleapis.com/language/translate/v2',
  );

  /// Key supplied with `--dart-define=GOOGLE_TRANSLATE_API_KEY=...`.
  static const String compileTimeApiKey = String.fromEnvironment(
    'GOOGLE_TRANSLATE_API_KEY',
    defaultValue: '',
  );

  /// SharedPreferences key used for the key entered from the app.
  static const String apiKeyPreferenceKey = 'google_translate_api_key';

  /// Key supplied with `--dart-define=GEMINI_API_KEY=...`.
  ///
  /// Gemini API has a free tier and does not require a billing account, so it
  /// can be used as a fallback when Cloud Translation billing is unavailable.
  static const String compileTimeGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String geminiApiKeyPreferenceKey = 'gemini_api_key';

  static String? _runtimeApiKey;
  static String? _runtimeGeminiApiKey;
  static bool _isInitialized = false;

  /// The key that should be used for the next request.
  ///
  /// A key saved from the Settings page takes precedence over the compile-time
  /// key, which makes it possible to change keys without rebuilding the app.
  static String get apiKey {
    final runtimeKey = _runtimeApiKey?.trim() ?? '';
    if (runtimeKey.isNotEmpty) return runtimeKey;
    return compileTimeApiKey.trim();
  }

  static bool get hasApiKey => apiKey.isNotEmpty;

  /// Gemini API key entered in Settings or supplied with `--dart-define`.
  static String get geminiApiKey {
    final runtimeKey = _runtimeGeminiApiKey?.trim() ?? '';
    if (runtimeKey.isNotEmpty) return runtimeKey;
    return compileTimeGeminiApiKey.trim();
  }

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;

  static bool get hasAnyApiKey => hasApiKey || hasGeminiApiKey;

  /// Load keys saved from the Settings page.
  ///
  /// Safe to call more than once; the values are cached in memory.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _runtimeApiKey = prefs.getString(apiKeyPreferenceKey) ?? '';
    _runtimeGeminiApiKey = prefs.getString(geminiApiKeyPreferenceKey) ?? '';
    _isInitialized = true;
  }

  /// Persist a key entered by the user.
  static Future<void> saveApiKey(String key) async {
    final normalized = key.trim();
    _runtimeApiKey = normalized;

    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(apiKeyPreferenceKey);
    } else {
      await prefs.setString(apiKeyPreferenceKey, normalized);
    }
  }

  /// Remove the saved key, falling back to the compile-time key (if any).
  static Future<void> clearApiKey() => saveApiKey('');

  /// Persist a Gemini API key entered by the user.
  static Future<void> saveGeminiApiKey(String key) async {
    final normalized = key.trim();
    _runtimeGeminiApiKey = normalized;

    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(geminiApiKeyPreferenceKey);
    } else {
      await prefs.setString(geminiApiKeyPreferenceKey, normalized);
    }
  }

  /// Remove the saved Gemini key, falling back to the compile-time key (if any).
  static Future<void> clearGeminiApiKey() => saveGeminiApiKey('');

  // ---- Gemini Configuration ----

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );

  static const List<String> geminiFallbackModels = [
    'gemini-3.1-flash-lite',
    'gemini-3-flash-preview',
    'gemini-flash-latest',
  ];

  // Request timeout in seconds
  static const int connectTimeout = 15;
  static const int receiveTimeout = 30;

  // Maximum characters per translation request (Google Cloud limit)
  static const int maxCharacters = 5000;

  // Supported languages endpoint (relative to [baseUrl])
  static const String languagesEndpoint = '/languages';

  // Detect language endpoint (relative to [baseUrl])
  static const String detectEndpoint = '/detect';

  // ---- Text-to-Speech Configuration ----

  // Google Cloud Text-to-Speech base URL
  static const String ttsBaseUrl = 'https://texttospeech.googleapis.com/v1';

  // TTS synthesize endpoint
  static const String ttsSynthesizeEndpoint = '/text:synthesize';

  // TTS list voices endpoint
  static const String ttsVoicesEndpoint = '/voices';

  // API key for TTS (for development only).
  // In production, this should be handled by your backend proxy.
  static const String ttsApiKey = String.fromEnvironment(
    'GOOGLE_TTS_API_KEY',
    defaultValue: '',
  );

  // TTS request timeout in seconds
  static const int ttsConnectTimeout = 15;
  static const int ttsReceiveTimeout = 30;

  // Maximum characters per TTS request (Google Cloud limit: 5000 chars)
  static const int ttsMaxCharacters = 5000;

  // Default audio encoding
  static const String ttsAudioEncoding = 'MP3';

  // Default sampling rate
  static const int ttsSamplingRate = 24000;

  // ---- Gemini Text-to-Speech Configuration ----
  //
  // Gemini TTS works with the same free Gemini API key used for translation,
  // so no Cloud Text-to-Speech billing account is required.

  static const String geminiTtsModel = String.fromEnvironment(
    'GEMINI_TTS_MODEL',
    defaultValue: 'gemini-3.8-flash-tts',
  );

  static const List<String> geminiTtsFallbackModels = [
    'gemini-3.8-flash-tts',
    'gemini-3.8-flash-lite-tts',
    'gemini-3.1-flash-tts-preview',
    'gemini-2.5-flash-preview-tts',
  ];

  static const String geminiTtsVoice = String.fromEnvironment(
    'GEMINI_TTS_VOICE',
    defaultValue: 'Kore',
  );

  static const int geminiTtsMaxCharacters = 4000;
}
