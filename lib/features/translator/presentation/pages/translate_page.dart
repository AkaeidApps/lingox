import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/controllers/tts_controller.dart';
import '../../../../core/errors/translation_exceptions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/language_model.dart';
import '../../../../data/repositories/translation_repository.dart';

class TranslateController extends GetxController {
  final TranslationRepository _repository = Get.find<TranslationRepository>();

  final Rx<LanguageModel> sourceLanguage = const LanguageModel(
    code: 'auto',
    name: 'Auto-detect',
    flagEmoji: '🔍',
  ).obs;
  final Rx<LanguageModel> targetLanguage = const LanguageModel(
    code: 'es',
    name: 'Spanish',
    flagEmoji: '🇪🇸',
  ).obs;
  final RxString inputText = ''.obs;
  final RxString translatedText = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool showResult = false.obs;
  final RxBool isFavorite = false.obs;
  final RxString currentTranslationId = ''.obs;
  final RxString errorMessage = ''.obs;

  final TextEditingController textController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    textController.addListener(() {
      inputText.value = textController.text;
    });
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  void swapLanguages() {
    // Don't swap if source is auto-detect
    if (sourceLanguage.value.code == 'auto') return;

    final temp = sourceLanguage.value;
    sourceLanguage.value = targetLanguage.value;
    targetLanguage.value = temp;
  }

  void clearText() {
    textController.clear();
    inputText.value = '';
    translatedText.value = '';
    showResult.value = false;
    errorMessage.value = '';
    currentTranslationId.value = '';
    isFavorite.value = false;
  }

  Future<void> translate() async {
    errorMessage.value = '';

    if (inputText.value.trim().isEmpty) {
      Get.snackbar(
        AppStrings.error,
        AppStrings.noTextToTranslate,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    showResult.value = false;

    try {
      final result = await _repository.translateAndSave(
        text: inputText.value.trim(),
        targetLanguage: targetLanguage.value,
        sourceLanguage: sourceLanguage.value.code != 'auto'
            ? sourceLanguage.value
            : null,
      );

      translatedText.value = result.translatedText;
      showResult.value = true;
      currentTranslationId.value = result.id ?? '';

      // Check if this translation is already favorited
      try {
        isFavorite.value = await _repository.isFavorite(result.id ?? '');
      } catch (_) {
        isFavorite.value = false;
      }
    } on TranslationException catch (e) {
      errorMessage.value = e.message;
      _showErrorSnackbar(e);
    } catch (e) {
      errorMessage.value = 'Translation failed. Please try again.';
      Get.snackbar(
        AppStrings.error,
        'Translation failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(TranslationException e) {
    Color bgColor = AppColors.error;
    String title = AppStrings.error;

    if (e.code == 'NETWORK_ERROR') {
      bgColor = AppColors.warning;
      title = 'No Connection';
    } else if (e.code == 'API_KEY_MISSING') {
      bgColor = AppColors.warning;
      title = 'Configuration Required';
    } else if (e.code == 'QUOTA_EXCEEDED') {
      bgColor = AppColors.warning;
      title = 'Quota Exceeded';
    } else if (e.code == 'TIMEOUT') {
      bgColor = AppColors.warning;
      title = 'Timeout';
    }

    Get.snackbar(
      title,
      e.message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: bgColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> toggleFavorite() async {
    if (currentTranslationId.value.isEmpty) return;

    try {
      final history = await _repository.getHistory();
      final translation = history.firstWhere(
        (t) => t.id == currentTranslationId.value,
        orElse: () => throw Exception('Translation not found'),
      );

      await _repository.toggleFavorite(translation);
      isFavorite.value = !isFavorite.value;

      Get.snackbar(
        'Success',
        isFavorite.value ? 'Added to favorites' : 'Removed from favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Failed to update favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void copyTranslation() {
    if (translatedText.value.isEmpty) return;

    Clipboard.setData(ClipboardData(text: translatedText.value));
    Get.snackbar(
      'Success',
      AppStrings.translationCopied,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  void speakTranslation() {
    if (translatedText.value.isEmpty) return;

    final ttsController = Get.find<TtsController>();
    ttsController.speak(
      text: translatedText.value,
      languageCode: targetLanguage.value.code,
    );
  }

  Future<void> pasteText() async {
    try {
      final clipboard = await Clipboard.getData('text/plain');
      final text = clipboard?.text;
      if (text != null && text.isNotEmpty) {
        textController.text = text;
        inputText.value = text;
      }
    } catch (_) {
      // Ignore clipboard errors
    }
  }
}

class TranslatePage extends StatelessWidget {
  const TranslatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TranslateController());

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.translate), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On short screens (landscape, split-screen, keyboard open) the
            // fixed sections do not fit, so the whole page becomes scrollable.
            final isCompact = constraints.maxHeight < 640;
            final sections = <Widget>[
              _buildLanguageSelectors(controller),
              const SizedBox(height: AppDimensions.paddingMD),
              _buildInputCard(controller),
              const SizedBox(height: AppDimensions.paddingMD),
              _buildTranslateButton(controller),
              const SizedBox(height: AppDimensions.paddingMD),
            ];

            if (isCompact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...sections,
                    SizedBox(height: 240, child: _buildResultCard(controller)),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...sections,
                  Expanded(child: _buildResultCard(controller)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageSelectors(TranslateController controller) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _LanguageCard(
              language: controller.sourceLanguage.value,
              label: AppStrings.sourceLanguage,
              onTap: () => _showLanguageBottomSheet(
                Get.context!,
                isSource: true,
                selectedCode: controller.sourceLanguage.value.code,
                onSelected: (lang) {
                  controller.sourceLanguage.value = lang;
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMD),
        Obx(
          () => AnimatedRotation(
            turns: controller.sourceLanguage.value.code == 'auto' ? 0 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: controller.sourceLanguage.value.code != 'auto'
                    ? controller.swapLanguages
                    : null,
                disabledColor: Colors.white38,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMD),
        Expanded(
          child: Obx(
            () => _LanguageCard(
              language: controller.targetLanguage.value,
              label: AppStrings.targetLanguage,
              onTap: () => _showLanguageBottomSheet(
                Get.context!,
                isSource: false,
                selectedCode: controller.targetLanguage.value.code,
                onSelected: (lang) {
                  controller.targetLanguage.value = lang;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(TranslateController controller) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.textController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: AppStrings.enterText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppDimensions.paddingMD),
              counterText: '',
            ),
          ),
          Obx(
            () => Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppDimensions.paddingMD),
                child: Text(
                  '${controller.inputText.value.length}',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSM,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
          ),
          Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingSM,
              vertical: AppDimensions.paddingXS,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppDimensions.paddingSM,
              children: [
                TextButton.icon(
                  onPressed: controller.clearText,
                  icon: const Icon(Icons.clear, size: 18),
                  label: Text(AppStrings.clearText),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSM,
                      vertical: AppDimensions.paddingXS,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.pasteText,
                  icon: const Icon(Icons.paste, size: 18),
                  label: Text(AppStrings.pasteText),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSM,
                      vertical: AppDimensions.paddingXS,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton(TranslateController controller) {
    return Obx(
      () => SizedBox(
        height: AppDimensions.buttonHeight,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.translate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.translate, size: 20),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Text(
                      AppStrings.translateButton,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontLG,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResultCard(TranslateController controller) {
    return Obx(
      () => controller.showResult.value
          ? AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language label + actions
                  Row(
                    children: [
                      Text(
                        controller.targetLanguage.value.flagEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: AppDimensions.paddingSM),
                      Expanded(
                        child: Text(
                          controller.targetLanguage.value.name,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSM,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _ResultActionButton(
                        icon: Icons.volume_up,
                        color: AppColors.primary,
                        tooltip: AppStrings.listenTranslation,
                        onPressed: controller.speakTranslation,
                      ),
                      _ResultActionButton(
                        icon: Icons.copy_outlined,
                        color: AppColors.textSecondary,
                        tooltip: AppStrings.copyTranslation,
                        onPressed: controller.copyTranslation,
                      ),
                      _ResultActionButton(
                        icon: Icons.share_outlined,
                        color: AppColors.textSecondary,
                        tooltip: AppStrings.shareTranslation,
                        onPressed: () {
                          // Phase 1: UI only
                        },
                      ),
                      _ResultActionButton(
                        icon: controller.isFavorite.value
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: controller.isFavorite.value
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        tooltip: controller.isFavorite.value
                            ? AppStrings.removeFromFavorites
                            : AppStrings.addToFavorites,
                        onPressed: controller.toggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingSM),
                  // Translated text
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        controller.translatedText.value,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLG,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 200;
                final circleSize = compact ? 52.0 : 80.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      compact
                          ? AppDimensions.paddingSM
                          : AppDimensions.paddingXL,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.translate,
                            size: circleSize / 2,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(
                          height: compact
                              ? AppDimensions.paddingSM
                              : AppDimensions.paddingMD,
                        ),
                        Text(
                          'Translation will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact
                                ? AppDimensions.fontSM
                                : AppDimensions.fontMD,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showLanguageBottomSheet(
    BuildContext context, {
    required bool isSource,
    required String selectedCode,
    required Function(LanguageModel) onSelected,
  }) {
    Get.bottomSheet(
      _LanguagePickerSheet(
        isSource: isSource,
        selectedCode: selectedCode,
        onSelected: onSelected,
      ),
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLG),
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  final bool isSource;
  final String selectedCode;
  final Function(LanguageModel) onSelected;

  const _LanguagePickerSheet({
    required this.isSource,
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<LanguageModel> _languages;

  @override
  void initState() {
    super.initState();
    _languages = _availableLanguages(LanguagesRepository.allLanguages);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LanguageModel> _availableLanguages(List<LanguageModel> languages) {
    if (widget.isSource) return languages;
    return languages.where((lang) => lang.code != 'auto').toList();
  }

  void _search(String query) {
    setState(() {
      _languages = _availableLanguages(
        LanguagesRepository.search(query.trim()),
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLG),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height * 0.75).clamp(320.0, 600.0),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppDimensions.paddingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.searchLanguage,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textHint,
                          ),
                          onPressed: _clearSearch,
                          tooltip: AppStrings.clearText,
                        ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _search,
              ),
            ),
            // Language list
            Expanded(
              child: _languages.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.noLanguagesFound,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontMD,
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMD,
                      ),
                      itemCount: _languages.length,
                      itemBuilder: (context, index) {
                        final lang = _languages[index];
                        final isSelected = lang.code == widget.selectedCode;

                        return ListTile(
                          leading: Text(
                            lang.flagEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            lang.name,
                            style: TextStyle(
                              fontSize: AppDimensions.fontMD,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: AppDimensions.iconMD,
                                )
                              : null,
                          onTap: () {
                            widget.onSelected(lang);
                            Get.back();
                          },
                          tileColor: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSM,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ResultActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: AppDimensions.iconMD),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final LanguageModel language;
  final String label;
  final VoidCallback onTap;

  const _LanguageCard({
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
          // Very narrow cards (small phones) need tighter spacing so the
          // flag, name, and dropdown arrow always fit on one line.
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                        style: TextStyle(fontSize: compact ? 18 : 22),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Expanded(
                      child: Text(
                        language.name,
                        style: TextStyle(
                          fontSize: compact
                              ? AppDimensions.fontMD
                              : AppDimensions.fontLG,
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
