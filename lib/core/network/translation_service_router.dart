import '../errors/translation_exceptions.dart';
import 'api_config.dart';
import 'gemini_translate_service.dart';
import 'google_translate_service.dart';
import 'translation_service.dart';

/// Which translation engine will handle the next request.
enum TranslationProvider { google, gemini }

/// Routes translation requests to a configured engine.
///
/// Priority:
/// 1. Google Cloud Translation when a Google key is configured.
/// 2. Gemini when only a Gemini key is configured.
///
/// Gemini has a free tier and does not require a billing account, which makes
/// it a practical fallback when Cloud Translation cannot be enabled.
class TranslationServiceRouter implements TranslationService {
  final GoogleTranslateService _google;
  final GeminiTranslateService _gemini;

  TranslationServiceRouter({
    GoogleTranslateService? google,
    GeminiTranslateService? gemini,
  }) : _google = google ?? GoogleTranslateService.create(),
       _gemini = gemini ?? GeminiTranslateService.create();

  /// The engine that will be used for the next request.
  ///
  /// Returns `null` when no key is configured.
  TranslationProvider? get activeProvider {
    if (ApiConfig.hasApiKey) return TranslationProvider.google;
    if (ApiConfig.hasGeminiApiKey) return TranslationProvider.gemini;
    return null;
  }

  Future<TranslationService> _resolve() async {
    await ApiConfig.initialize();

    if (ApiConfig.hasApiKey) return _google;
    if (ApiConfig.hasGeminiApiKey) return _gemini;

    throw const ApiKeyException(
      message:
          'No translation API key is configured. Add a free Gemini key in '
          'Settings > API Configuration.',
    );
  }

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final service = await _resolve();
    return service.translate(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );
  }

  @override
  Future<String> detectLanguage(String text) async {
    final service = await _resolve();
    return service.detectLanguage(text);
  }

  @override
  Future<List<Map<String, String>>> getSupportedLanguages() async {
    final service = await _resolve();
    return service.getSupportedLanguages();
  }

  @override
  Future<bool> hasInternetConnection() async {
    final service = await _resolve();
    return service.hasInternetConnection();
  }
}
