import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/controllers/tts_controller.dart';
import '../../../../core/errors/translation_exceptions.dart';
import '../../../../data/models/language_model.dart';
import '../../../../data/repositories/translation_repository.dart';

class ConversationController extends GetxController {
  final TranslationRepository _repository = Get.find<TranslationRepository>();

  final Rx<LanguageModel> language1 = const LanguageModel(
    code: 'en',
    name: 'English',
    flagEmoji: '🇬🇧',
  ).obs;
  final Rx<LanguageModel> language2 = const LanguageModel(
    code: 'es',
    name: 'Spanish',
    flagEmoji: '🇪🇸',
  ).obs;
  final RxBool isListening1 = false.obs;
  final RxBool isListening2 = false.obs;
  final RxBool isTranslating = false.obs;

  final List<ConversationMessage> messages = <ConversationMessage>[].obs;

  void toggleListening(int speaker) {
    if (speaker == 1) {
      isListening1.value = !isListening1.value;
      if (!isListening1.value) isListening2.value = false;
    } else {
      isListening2.value = !isListening2.value;
      if (!isListening2.value) isListening1.value = false;
    }
  }

  void clearConversation() {
    messages.clear();
    Get.snackbar(
      'Success',
      AppStrings.conversationCleared,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  void speakMessage(String text, int speaker) {
    if (text.isEmpty) return;
    final ttsController = Get.find<TtsController>();
    final langCode = speaker == 1 ? language1.value.code : language2.value.code;
    ttsController.speak(text: text, languageCode: langCode);
  }

  void speakTranslatedMessage(String text, int speaker) {
    if (text.isEmpty) return;
    final ttsController = Get.find<TtsController>();
    // The translated text is in the other speaker's language
    final langCode = speaker == 1 ? language2.value.code : language1.value.code;
    ttsController.speak(text: text, languageCode: langCode);
  }

  /// Send a message and translate it to the other speaker's language
  Future<void> sendMessage(String text, int speaker) async {
    if (text.trim().isEmpty) return;

    isTranslating.value = true;
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String translatedText = '';

    try {
      // Translate to the other speaker's language
      final targetLang = speaker == 1 ? language2.value : language1.value;
      final sourceLang = speaker == 1 ? language1.value : language2.value;

      translatedText = await _repository.translateOnly(
        text: text.trim(),
        targetLanguage: targetLang.code,
        sourceLanguage: sourceLang.code != 'auto' ? sourceLang.code : null,
      );
    } on TranslationException catch (e) {
      translatedText = '[Error: ${e.message}]';
      Get.snackbar(
        'Translation Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } catch (e) {
      translatedText = '[Translation failed]';
    } finally {
      isTranslating.value = false;
    }

    messages.add(
      ConversationMessage(
        text: text.trim(),
        translatedText: translatedText,
        speaker: speaker,
        timestamp: timestamp,
      ),
    );
  }
}

class ConversationMessage {
  final String text;
  final String translatedText;
  final int speaker;
  final String timestamp;

  const ConversationMessage({
    required this.text,
    required this.translatedText,
    required this.speaker,
    required this.timestamp,
  });
}

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConversationController());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.conversationTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: controller.clearConversation,
            tooltip: AppStrings.clearConversation,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Landscape phones and split-screen windows do not have enough
          // vertical space for the full-size header and input areas.
          final compact = constraints.maxHeight < 480;

          return Column(
            children: [
              // Language selectors
              _buildLanguageBar(controller, compact: compact),
              // Speaker controls
              _buildSpeakerControls(controller, compact: compact),
              const Divider(height: 1),
              // Messages
              Expanded(child: _buildMessages(controller)),
              // Input area
              _buildInputArea(controller, compact: compact),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageBar(
    ConversationController controller, {
    bool compact = false,
  }) {
    final padding = compact ? AppDimensions.paddingSM : AppDimensions.paddingMD;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _ConversationLanguageCard(
                language: controller.language1.value,
                label: AppStrings.speaker1,
                onTap: () {},
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: Obx(
              () => _ConversationLanguageCard(
                language: controller.language2.value,
                label: AppStrings.speaker2,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerControls(
    ConversationController controller, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: compact ? AppDimensions.paddingXS : AppDimensions.paddingSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _SpeakerButton(
                label: AppStrings.speaker1,
                isListening: controller.isListening1.value,
                color: AppColors.primary,
                onTap: () => controller.toggleListening(1),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: Obx(
              () => _SpeakerButton(
                label: AppStrings.speaker2,
                isListening: controller.isListening2.value,
                color: AppColors.secondary,
                onTap: () => controller.toggleListening(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ConversationController controller) {
    return Obx(
      () => controller.messages.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 40,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    Text(
                      'Start a conversation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppDimensions.fontMD,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final message = controller.messages[index];
                return _ConversationBubble(message: message);
              },
            ),
    );
  }

  Widget _buildInputArea(
    ConversationController controller, {
    bool compact = false,
  }) {
    final padding = compact ? AppDimensions.paddingSM : AppDimensions.paddingMD;
    final sendSize = compact ? 40.0 : 48.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusRound,
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                  vertical: AppDimensions.paddingSM,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSM),
          Container(
            width: sendSize,
            height: sendSize,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.send,
              color: Colors.white,
              size: compact ? 18 : 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationLanguageCard extends StatelessWidget {
  final LanguageModel language;
  final String label;
  final VoidCallback onTap;

  const _ConversationLanguageCard({
    required this.language,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flagEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: AppDimensions.paddingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    language.name,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  final String label;
  final bool isListening;
  final Color color;
  final VoidCallback onTap;

  const _SpeakerButton({
    required this.label,
    required this.isListening,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingSM,
        ),
        decoration: BoxDecoration(
          color: isListening
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(
            color: isListening ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              size: AppDimensions.iconSM,
              color: isListening ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimensions.paddingSM),
            Flexible(
              child: Text(
                isListening ? 'Listening...' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppDimensions.fontSM,
                  fontWeight: isListening ? FontWeight.w600 : FontWeight.normal,
                  color: isListening ? color : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  final ConversationMessage message;

  const _ConversationBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSpeaker1 = message.speaker == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      child: Row(
        mainAxisAlignment: isSpeaker1
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (!isSpeaker1) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '2',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.fontSM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSM),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSpeaker1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  decoration: BoxDecoration(
                    color: isSpeaker1
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(
                      color: isSpeaker1
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              message.text,
                              style: TextStyle(
                                fontSize: AppDimensions.fontMD,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              size: AppDimensions.iconSM,
                              color: AppColors.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              final controller =
                                  Get.find<ConversationController>();
                              controller.speakMessage(
                                message.text,
                                message.speaker,
                              );
                            },
                          ),
                        ],
                      ),
                      if (message.translatedText.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.paddingSM),
                        Divider(color: AppColors.divider),
                        const SizedBox(height: AppDimensions.paddingSM),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                message.translatedText,
                                style: TextStyle(
                                  fontSize: AppDimensions.fontMD,
                                  color: isSpeaker1
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                size: AppDimensions.iconSM,
                                color: AppColors.primary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final controller =
                                    Get.find<ConversationController>();
                                controller.speakTranslatedMessage(
                                  message.translatedText,
                                  message.speaker,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  message.timestamp,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXS,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (isSpeaker1) ...[
            const SizedBox(width: AppDimensions.paddingSM),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '1',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.fontSM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
