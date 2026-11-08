import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/controllers/tts_controller.dart';
import '../../../../core/errors/translation_exceptions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/waveform_animation.dart';
import '../../../../data/models/language_model.dart';
import '../../../../data/repositories/translation_repository.dart';

class VoiceTranslatorController extends GetxController {
  final TranslationRepository _repository = Get.find<TranslationRepository>();

  final RxBool isListening = false.obs;
  final RxString transcribedText = ''.obs;
  final RxString translatedText = ''.obs;
  final Rx<LanguageModel> sourceLanguage = const LanguageModel(
    code: 'en',
    name: 'English',
    flagEmoji: '🇬🇧',
  ).obs;
  final Rx<LanguageModel> targetLanguage = const LanguageModel(
    code: 'es',
    name: 'Spanish',
    flagEmoji: '🇪🇸',
  ).obs;
  final RxBool isLoading = false.obs;
  final RxString status = AppStrings.tapToSpeak.obs;

  void toggleListening() {
    if (isListening.value) {
      stopListening();
    } else {
      startListening();
    }
  }

  void startListening() {
    isListening.value = true;
    status.value = AppStrings.listening;
    transcribedText.value = '';
    translatedText.value = '';

    // Phase 4: Real speech-to-text integration will replace this simulation
    // For now, simulate listening to demonstrate the translation workflow
    Future.delayed(const Duration(seconds: 3), () {
      if (isListening.value) {
        transcribedText.value = 'Hello, how are you today?';
        stopListening();
        // Translate the transcribed text using real API
        _translateTranscription('Hello, how are you today?');
      }
    });
  }

  void stopListening() {
    isListening.value = false;
    status.value = AppStrings.tapToSpeak;
  }

  /// Translate the transcribed text using the real Google Cloud Translation API
  Future<void> _translateTranscription(String text) async {
    if (text.trim().isEmpty) return;

    isLoading.value = true;
    try {
      final result = await _repository.translateAndSave(
        text: text.trim(),
        targetLanguage: targetLanguage.value,
        sourceLanguage: sourceLanguage.value.code != 'auto'
            ? sourceLanguage.value
            : null,
      );
      translatedText.value = result.translatedText;
    } on TranslationException catch (e) {
      translatedText.value = 'Error: ${e.message}';
      Get.snackbar(
        'Translation Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } catch (e) {
      translatedText.value = 'Translation failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Public method to translate text (used when Phase 4 speech-to-text provides real input)
  Future<void> translateTranscription(String text) async {
    await _translateTranscription(text);
  }

  void speakTranslation() {
    if (translatedText.value.isEmpty) return;
    final ttsController = Get.find<TtsController>();
    ttsController.speak(
      text: translatedText.value,
      languageCode: targetLanguage.value.code,
    );
  }
}

class VoiceTranslatorPage extends StatelessWidget {
  const VoiceTranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VoiceTranslatorController());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.voiceTranslator),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final microphoneHeight = (constraints.maxHeight * 0.42).clamp(
              240.0,
              360.0,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              child: Column(
                children: [
                  // Language selectors
                  _buildLanguageSelectors(controller),
                  const SizedBox(height: AppDimensions.paddingLG),
                  // Microphone area
                  SizedBox(
                    height: microphoneHeight,
                    child: _buildMicrophoneArea(controller),
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),
                  // Transcription area
                  _buildResultArea(controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageSelectors(VoiceTranslatorController controller) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _VoiceLanguageCard(
              language: controller.sourceLanguage.value,
              label: AppStrings.sourceLanguage,
              onTap: () {
                // Phase 1: Language selection UI
              },
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMD),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.swap_horiz, color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppDimensions.paddingMD),
        Expanded(
          child: Obx(
            () => _VoiceLanguageCard(
              language: controller.targetLanguage.value,
              label: AppStrings.targetLanguage,
              onTap: () {
                // Phase 1: Language selection UI
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicrophoneArea(VoiceTranslatorController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Waveform
          Obx(
            () => WaveformAnimation(
              isPlaying: controller.isListening.value,
              color: AppColors.primary,
              barCount: 25,
              maxHeight: 50,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          // Microphone button
          Obx(
            () => GestureDetector(
              onTap: controller.toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: controller.isListening.value ? 120 : 100,
                height: controller.isListening.value ? 120 : 100,
                decoration: BoxDecoration(
                  gradient: controller.isListening.value
                      ? AppColors.accentGradient
                      : AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (controller.isListening.value
                                  ? AppColors.accent
                                  : AppColors.primary)
                              .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  controller.isListening.value ? Icons.mic : Icons.mic_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          // Status text
          Obx(
            () => Text(
              controller.status.value,
              style: TextStyle(
                fontSize: AppDimensions.fontLG,
                color: controller.isListening.value
                    ? AppColors.accent
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea(VoiceTranslatorController controller) {
    return Column(
      children: [
        // Transcription
        Obx(
          () => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      controller.sourceLanguage.value.flagEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Text(
                      AppStrings.transcription,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingSM),
                if (controller.transcribedText.value.isNotEmpty)
                  Text(
                    controller.transcribedText.value,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontLG,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  )
                else
                  Text(
                    AppStrings.noTranscription,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMD,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMD),
        // Translation
        Obx(
          () => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      controller.targetLanguage.value.flagEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Text(
                      controller.targetLanguage.value.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        color: AppColors.primary,
                        size: AppDimensions.iconMD,
                      ),
                      onPressed: controller.translatedText.value.isNotEmpty
                          ? controller.speakTranslation
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingSM),
                if (controller.translatedText.value.isNotEmpty)
                  Text(
                    controller.translatedText.value,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontLG,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  )
                else
                  Text(
                    'Translation will appear here',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMD,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceLanguageCard extends StatelessWidget {
  final LanguageModel language;
  final String label;
  final VoidCallback onTap;

  const _VoiceLanguageCard({
    required this.language,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 130;
          final padding = compact
              ? AppDimensions.paddingSM
              : AppDimensions.paddingMD;

          return Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSM,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        language.flagEmoji,
                        style: TextStyle(fontSize: compact ? 18 : 20),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Expanded(
                      child: Text(
                        language.name,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontMD,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: compact
                          ? AppDimensions.iconSM
                          : AppDimensions.iconMD,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
