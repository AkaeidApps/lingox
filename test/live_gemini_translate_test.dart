import 'package:flutter_test/flutter_test.dart';
import 'package:lingox/core/network/gemini_translate_service.dart';

/// Live smoke test against the free Gemini API.
///
/// It is skipped unless a real key is supplied:
///
/// ```bash
/// flutter test test/live_gemini_translate_test.dart \
///   --dart-define=GEMINI_API_KEY=YOUR_KEY
/// ```
void main() {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  test(
    'translates Hello from English to Spanish using the live Gemini API',
    () async {
      final service = GeminiTranslateService(
        apiKey: apiKey,
        connectivityCheck: () async => true,
      );

      final translated = await service.translate(
        text: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'es',
      );

      expect(translated.toLowerCase(), contains('hola'));
    },
    skip: apiKey.isEmpty
        ? 'Set --dart-define=GEMINI_API_KEY=... to run the live test.'
        : false,
  );
}
