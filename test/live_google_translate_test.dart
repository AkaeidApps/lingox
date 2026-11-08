import 'package:flutter_test/flutter_test.dart';
import 'package:lingox/core/network/google_translate_service.dart';

/// Live smoke test against Google Cloud Translation API.
///
/// It is skipped unless a real key is supplied:
///
/// ```bash
/// flutter test test/live_google_translate_test.dart \
///   --dart-define=GOOGLE_TRANSLATE_API_KEY=YOUR_KEY
/// ```
void main() {
  const apiKey = String.fromEnvironment('GOOGLE_TRANSLATE_API_KEY');

  test(
    'translates Hello from English to Spanish using the live API',
    () async {
      final service = GoogleTranslateService(
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
        ? 'Set --dart-define=GOOGLE_TRANSLATE_API_KEY=... to run the live test.'
        : false,
  );
}
