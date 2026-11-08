import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/controllers/tts_controller.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/translation_model.dart';
import '../../../../data/repositories/translation_repository.dart';

class HistoryController extends GetxController {
  final TranslationRepository _repository = Get.find<TranslationRepository>();

  final RxString searchQuery = ''.obs;
  final RxList<TranslationModel> history = <TranslationModel>[].obs;
  final RxBool isLoading = true.obs;

  List<TranslationModel> get filteredHistory {
    if (searchQuery.value.isEmpty) return history;
    final query = searchQuery.value.toLowerCase();
    return history.where((item) {
      return item.sourceText.toLowerCase().contains(query) ||
          item.translatedText.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    isLoading.value = true;
    try {
      final data = await _repository.getHistory();
      history.value = data;
    } catch (e) {
      history.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteItem(TranslationModel translation) async {
    try {
      await _repository.deleteFromHistory(translation.id ?? '');
      await _loadHistory();
      Get.snackbar(
        'Success',
        AppStrings.historyDeleted,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Failed to delete history item',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void speakTranslation(TranslationModel translation) {
    if (translation.translatedText.isEmpty) return;
    final ttsController = Get.find<TtsController>();
    ttsController.speak(
      text: translation.translatedText,
      languageCode: translation.targetLanguage.code,
    );
  }

  void deleteAll() {
    Get.defaultDialog(
      title: AppStrings.confirmDeleteAll,
      middleText: 'This action cannot be undone.',
      textConfirm: AppStrings.delete,
      textCancel: AppStrings.cancel,
      onConfirm: () async {
        Get.back();
        try {
          await _repository.clearHistory();
          await _loadHistory();
          Get.snackbar(
            'Success',
            'All history deleted',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            AppStrings.error,
            'Failed to clear history',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      },
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryController());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.history),
        centerTitle: true,
        actions: [
          if (controller.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: controller.deleteAll,
              tooltip: AppStrings.deleteAllHistory,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingMD,
                AppDimensions.paddingSM,
                AppDimensions.paddingMD,
                AppDimensions.paddingMD,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.searchHistory,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                    vertical: AppDimensions.paddingSM,
                  ),
                ),
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
              ),
            ),
            // History list
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  );
                }
                return controller.filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(controller);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            AppStrings.noHistory,
            style: const TextStyle(
              fontSize: AppDimensions.fontLG,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            AppStrings.startTranslating,
            style: const TextStyle(
              fontSize: AppDimensions.fontSM,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(HistoryController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      itemCount: controller.filteredHistory.length,
      itemBuilder: (context, index) {
        final translation = controller.filteredHistory[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          child: Dismissible(
            key: Key(translation.id ?? 'history_$index'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppDimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              controller.deleteItem(translation);
            },
            child: AppCard(
              margin: EdgeInsets.zero,
              onTap: () {
                // Navigate to translation detail
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language pair and time
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppDimensions.paddingXS,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              translation.sourceLanguage.flagEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              translation.sourceLanguage.code.toUpperCase(),
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSM,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            Text(
                              translation.targetLanguage.flagEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              translation.targetLanguage.code.toUpperCase(),
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSM,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingSM),
                      Text(
                        _formatTime(translation.timestamp),
                        style: const TextStyle(
                          fontSize: AppDimensions.fontXS,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingSM),
                  // Source text
                  Text(
                    translation.sourceText,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMD,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.paddingXS),
                  // Translated text
                  Text(
                    translation.translatedText,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMD,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.paddingSM),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up,
                          color: AppColors.primary,
                          size: AppDimensions.iconSM,
                        ),
                        onPressed: () {
                          controller.speakTranslation(translation);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }
}
