import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/controllers/tts_controller.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/translation_model.dart';
import '../../../../data/repositories/translation_repository.dart';

class FavoritesController extends GetxController {
  final TranslationRepository _repository = Get.find<TranslationRepository>();

  final RxString searchQuery = ''.obs;
  final RxList<TranslationModel> favorites = <TranslationModel>[].obs;
  final RxBool isLoading = true.obs;

  List<TranslationModel> get filteredFavorites {
    if (searchQuery.value.isEmpty) return favorites;
    final query = searchQuery.value.toLowerCase();
    return favorites.where((item) {
      return item.sourceText.toLowerCase().contains(query) ||
          item.translatedText.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    isLoading.value = true;
    try {
      final data = await _repository.getFavorites();
      favorites.value = data;
    } catch (e) {
      favorites.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFavorite(TranslationModel translation) async {
    try {
      await _repository.removeFromFavorites(translation.id ?? '');
      await _loadFavorites();
      Get.snackbar(
        'Success',
        'Removed from favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Failed to remove from favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void copyTranslation(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Success',
      AppStrings.translationCopied,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  void speakText(String text, String languageCode) {
    if (text.isEmpty) return;
    final ttsController = Get.find<TtsController>();
    ttsController.speak(text: text, languageCode: languageCode);
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FavoritesController());

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.favorites), centerTitle: true),
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
                  hintText: AppStrings.searchFavorites,
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
            // Favorites list
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
                return controller.filteredFavorites.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoritesList(controller);
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
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 40,
              color: AppColors.accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            AppStrings.noFavorites,
            style: const TextStyle(
              fontSize: AppDimensions.fontLG,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            AppStrings.addSomeFavorites,
            style: const TextStyle(
              fontSize: AppDimensions.fontSM,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(FavoritesController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      itemCount: controller.filteredFavorites.length,
      itemBuilder: (context, index) {
        final translation = controller.filteredFavorites[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          child: Dismissible(
            key: Key(translation.id ?? 'fav_$index'),
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
              controller.removeFavorite(translation);
            },
            child: AppCard(
              margin: EdgeInsets.zero,
              onTap: () {
                // Navigate to translation detail
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language pair
                  Wrap(
                    spacing: AppDimensions.paddingXS,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: AppDimensions.iconSM,
                        color: AppColors.accent,
                      ),
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
                        icon: Icon(
                          Icons.volume_up,
                          color: AppColors.primary,
                          size: AppDimensions.iconSM,
                        ),
                        onPressed: () {
                          controller.speakText(
                            translation.translatedText,
                            translation.targetLanguage.code,
                          );
                        },
                      ),
                      const SizedBox(width: AppDimensions.paddingSM),
                      IconButton(
                        icon: Icon(
                          Icons.copy_outlined,
                          color: AppColors.textSecondary,
                          size: AppDimensions.iconSM,
                        ),
                        onPressed: () {
                          controller.copyTranslation(
                            translation.translatedText,
                          );
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
}
