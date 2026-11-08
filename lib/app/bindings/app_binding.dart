import 'package:get/get.dart';

import '../../core/controllers/tts_controller.dart';
import '../../core/network/translation_service.dart';
import '../../core/network/translation_service_router.dart';
import '../../core/services/text_to_speech_service.dart';
import '../../data/repositories/translation_repository.dart';

/// GetX binding for dependency injection of API services and repositories.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Translation service router (Google when configured, Gemini otherwise)
    Get.lazyPut<TranslationService>(
      () => TranslationServiceRouter(),
      fenix: true,
    );

    // Text-to-Speech Service
    Get.lazyPut<TextToSpeechService>(
      () => TextToSpeechService.create(),
      fenix: true,
    );

    // Text-to-Speech Controller
    Get.lazyPut<TtsController>(() => TtsController(), fenix: true);

    // Repository
    Get.lazyPut<TranslationRepository>(
      () => TranslationRepository(apiService: Get.find<TranslationService>()),
      fenix: true,
    );
  }
}
