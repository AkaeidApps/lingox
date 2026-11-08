import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/controllers/tts_controller.dart';
import '../../../../core/errors/translation_exceptions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/language_model.dart';
import '../../../../data/repositories/translation_repository.dart';

class CameraTranslatorController extends GetxController {
  final TranslationRepository _repository = Get.find<TranslationRepository>();

  final Rx<LanguageModel> targetLanguage = const LanguageModel(
    code: 'es',
    name: 'Spanish',
    flagEmoji: '🇪🇸',
  ).obs;
  final RxString extractedText = ''.obs;
  final RxString translatedText = ''.obs;
  final RxBool isProcessing = false.obs;
  final RxBool hasImage = false.obs;
  final RxBool showResult = false.obs;

  void takePhoto() {
    // Phase 5: Camera integration will replace this simulation
    _simulateOCR();
  }

  void pickFromGallery() {
    // Phase 5: Gallery picker integration will replace this simulation
    _simulateOCR();
  }

  void _simulateOCR() {
    isProcessing.value = true;
    hasImage.value = true;

    Future.delayed(const Duration(seconds: 2), () {
      extractedText.value =
          'Welcome to our restaurant. Please enjoy your meal.';
      showResult.value = true;
      isProcessing.value = false;
      // Translate the extracted text using real API
      _translateExtractedText(
        'Welcome to our restaurant. Please enjoy your meal.',
      );
    });
  }

  /// Translate extracted text using the real Google Cloud Translation API
  Future<void> _translateExtractedText(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final result = await _repository.translateAndSave(
        text: text.trim(),
        targetLanguage: targetLanguage.value,
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
    }
  }

  /// Public method to translate text after OCR extraction (Phase 5 integration point)
  Future<void> translateExtractedText(String text) async {
    extractedText.value = text;
    showResult.value = true;
    await _translateExtractedText(text);
  }

  void reset() {
    extractedText.value = '';
    translatedText.value = '';
    hasImage.value = false;
    showResult.value = false;
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

class CameraTranslatorPage extends StatelessWidget {
  const CameraTranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CameraTranslatorController());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.cameraTranslator),
        centerTitle: true,
        actions: [
          if (controller.hasImage.value)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the preview proportional and let the rest of the page
            // scroll, so short screens never overflow.
            final previewHeight = (constraints.maxHeight * 0.35).clamp(
              180.0,
              320.0,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              child: Column(
                children: [
                  // Language selector
                  _buildLanguageSelector(controller),
                  const SizedBox(height: AppDimensions.paddingMD),
                  // Camera preview / Image area
                  SizedBox(
                    height: previewHeight,
                    child: _buildCameraArea(controller),
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  // Action buttons
                  _buildActionButtons(controller),
                  const SizedBox(height: AppDimensions.paddingMD),
                  // Results
                  _buildResults(controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(CameraTranslatorController controller) {
    return Obx(
      () => InkWell(
        onTap: () {
          // Phase 1: Language selection UI
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.translate,
                color: AppColors.primary,
                size: AppDimensions.iconMD,
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Text(
                  'Translate to',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                controller.targetLanguage.value.flagEmoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: AppDimensions.paddingSM),
              Flexible(
                child: Text(
                  controller.targetLanguage.value.name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontMD,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingXS),
              Icon(
                Icons.keyboard_arrow_down,
                size: AppDimensions.iconMD,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraArea(CameraTranslatorController controller) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: controller.hasImage.value
              ? AppColors.surfaceVariant
              : Colors.black87,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: controller.hasImage.value
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Simulated image preview
                  Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 60,
                            color: AppColors.textHint,
                          ),
                          SizedBox(height: AppDimensions.paddingMD),
                          Text(
                            'Image Preview',
                            style: TextStyle(
                              fontSize: AppDimensions.fontMD,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // OCR overlay
                  Positioned(
                    top: AppDimensions.paddingMD,
                    right: AppDimensions.paddingMD,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSM,
                        vertical: AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSM,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.text_fields,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Text Detected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppDimensions.fontXS,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    Text(
                      'Camera preview will appear here',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMD,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons(CameraTranslatorController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(AppStrings.takePhoto),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingMD,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMD),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: Text(AppStrings.pickFromGallery),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingMD,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(CameraTranslatorController controller) {
    return Obx(
      () => controller.isProcessing.value
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Text(
                    AppStrings.ocrExtracting,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMD,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : controller.showResult.value
          ? Column(
              children: [
                // Extracted text
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.text_fields,
                            size: AppDimensions.iconSM,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppDimensions.paddingSM),
                          Text(
                            AppStrings.extractedText,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSM,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {
                              // Phase 5: Text editing
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      TextField(
                        controller: TextEditingController(
                          text: controller.extractedText.value,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSM,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(
                            AppDimensions.paddingSM,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSM),
                // Translated text
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.targetLanguage.value.flagEmoji,
                            style: const TextStyle(fontSize: 16),
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
                            onPressed: controller.speakTranslation,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      Text(
                        controller.translatedText.value,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLG,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
