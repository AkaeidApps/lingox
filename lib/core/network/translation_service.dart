/// Common interface implemented by every translation engine.
abstract class TranslationService {
  /// Translate [text] into [targetLanguage].
  ///
  /// [sourceLanguage] may be null or `auto` to let the engine detect it.
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  });

  /// Detect the language code of [text].
  Future<String> detectLanguage(String text);

  /// Return supported languages as maps with `language` and `name`.
  Future<List<Map<String, String>>> getSupportedLanguages();

  /// Whether the device can reach the internet.
  Future<bool> hasInternetConnection();
}
