import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/errors/translation_exceptions.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/gemini_translate_service.dart';
import '../../../../core/network/google_translate_service.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/language_model.dart';

enum ThemeModeOption { light, dark, system }

class SettingsController extends GetxController {
  final Rx<ThemeModeOption> themeMode = ThemeModeOption.light.obs;
  final Rx<LanguageModel> defaultSourceLanguage = const LanguageModel(
    code: 'auto',
    name: 'Auto-detect',
    flagEmoji: '🔍',
  ).obs;
  final Rx<LanguageModel> defaultTargetLanguage = const LanguageModel(
    code: 'es',
    name: 'Spanish',
    flagEmoji: '🇪🇸',
  ).obs;
  final RxDouble speechSpeed = 1.0.obs;
  final RxDouble speechPitch = 1.0.obs;

  final RxBool isApiKeyConfigured = ApiConfig.hasApiKey.obs;
  final RxBool isCheckingApiKey = false.obs;
  final TextEditingController apiKeyController = TextEditingController();

  final RxBool isGeminiKeyConfigured = ApiConfig.hasGeminiApiKey.obs;
  final RxBool isCheckingGeminiKey = false.obs;
  final TextEditingController geminiKeyController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    apiKeyController.text = ApiConfig.apiKey;
    geminiKeyController.text = ApiConfig.geminiApiKey;
  }

  @override
  void onClose() {
    apiKeyController.dispose();
    geminiKeyController.dispose();
    super.onClose();
  }

  void setThemeMode(ThemeModeOption mode) {
    themeMode.value = mode;
  }

  /// Save the API key and make one real translation request to verify it.
  Future<void> saveAndTestApiKey() async {
    final key = apiKeyController.text.trim();

    if (key.isEmpty) {
      Get.snackbar(
        'API Key Required',
        'Paste your Google Cloud Translation API key first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    await ApiConfig.saveApiKey(key);
    isApiKeyConfigured.value = ApiConfig.hasApiKey;
    isCheckingApiKey.value = true;

    try {
      final translated = await GoogleTranslateService(apiKey: key)
          .translate(text: 'Hello', sourceLanguage: 'en', targetLanguage: 'es');

      Get.snackbar(
        'API Connected',
        'Google Cloud Translation works. "Hello" → "$translated"',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on TranslationException catch (e) {
      Get.snackbar(
        'API Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'API Error',
        'Could not verify the API key: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isCheckingApiKey.value = false;
    }
  }

  /// Remove the saved runtime key and fall back to the build-time key.
  Future<void> removeApiKey() async {
    await ApiConfig.clearApiKey();
    apiKeyController.clear();
    isApiKeyConfigured.value = ApiConfig.hasApiKey;
    Get.snackbar(
      'API Key Removed',
      'The saved translation API key was removed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  /// Save the Gemini key and verify it with a real translation request.
  Future<void> saveAndTestGeminiKey() async {
    final key = geminiKeyController.text.trim();

    if (key.isEmpty) {
      Get.snackbar(
        'API Key Required',
        'Paste your free Gemini API key first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    await ApiConfig.saveGeminiApiKey(key);
    isGeminiKeyConfigured.value = ApiConfig.hasGeminiApiKey;
    isCheckingGeminiKey.value = true;

    try {
      final translated = await GeminiTranslateService(apiKey: key)
          .translate(text: 'Hello', sourceLanguage: 'en', targetLanguage: 'es');

      Get.snackbar(
        'Gemini Connected',
        'Free Gemini translation works. "Hello" → "$translated"',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on TranslationException catch (e) {
      Get.snackbar(
        'Gemini Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'Gemini Error',
        'Could not verify the Gemini key: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isCheckingGeminiKey.value = false;
    }
  }

  /// Remove the saved Gemini key.
  Future<void> removeGeminiKey() async {
    await ApiConfig.clearGeminiApiKey();
    geminiKeyController.clear();
    isGeminiKeyConfigured.value = ApiConfig.hasGeminiApiKey;
    Get.snackbar(
      'Gemini Key Removed',
      'The saved Gemini API key was removed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  void clearCache() {
    Get.snackbar(
      'Success',
      AppStrings.cacheCleared,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settings), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          children: [
            // Appearance section
            _buildSectionTitle(AppStrings.appearance),
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingMD,
              ),
              child: Obx(
                () => RadioGroup<ThemeModeOption>(
                  groupValue: controller.themeMode.value,
                  onChanged: (value) {
                    if (value != null) controller.setThemeMode(value);
                  },
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.light_mode_outlined,
                        title: AppStrings.lightTheme,
                        subtitle: 'Bright and clean interface',
                        trailing: Radio<ThemeModeOption>(
                          value: ThemeModeOption.light,
                          activeColor: AppColors.primary,
                        ),
                      ),
                      Divider(height: 1, color: AppColors.divider),
                      _buildSettingsTile(
                        icon: Icons.dark_mode_outlined,
                        title: AppStrings.darkTheme,
                        subtitle: 'Easy on the eyes',
                        trailing: Radio<ThemeModeOption>(
                          value: ThemeModeOption.dark,
                          activeColor: AppColors.primary,
                        ),
                      ),
                      Divider(height: 1, color: AppColors.divider),
                      _buildSettingsTile(
                        icon: Icons.brightness_auto_outlined,
                        title: AppStrings.systemTheme,
                        subtitle: 'Follow system settings',
                        trailing: Radio<ThemeModeOption>(
                          value: ThemeModeOption.system,
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Languages section
            _buildSectionTitle(AppStrings.languages),
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingMD,
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.language_outlined,
                    title: AppStrings.defaultSourceLanguage,
                    trailing: Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.defaultSourceLanguage.value.flagEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: AppDimensions.paddingXS),
                          Text(
                            controller.defaultSourceLanguage.value.name,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSM,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                    onTap: () {
                      // Phase 1: Language selection UI
                    },
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildSettingsTile(
                    icon: Icons.flag_outlined,
                    title: AppStrings.defaultTargetLanguage,
                    trailing: Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.defaultTargetLanguage.value.flagEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: AppDimensions.paddingXS),
                          Text(
                            controller.defaultTargetLanguage.value.name,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSM,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                    onTap: () {
                      // Phase 1: Language selection UI
                    },
                  ),
                ],
              ),
            ),

            // API configuration section
            _buildSectionTitle('API Configuration'),
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingMD,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSM,
                            ),
                          ),
                          child: const Icon(
                            Icons.key_outlined,
                            color: AppColors.primary,
                            size: AppDimensions.iconMD,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingSM),
                        const Expanded(
                          child: Text(
                            'Google Cloud Translation',
                            style: TextStyle(
                              fontSize: AppDimensions.fontMD,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingSM,
                              vertical: AppDimensions.paddingXS,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (controller.isApiKeyConfigured.value
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSM,
                              ),
                            ),
                            child: Text(
                              controller.isApiKeyConfigured.value
                                  ? 'Configured'
                                  : 'Not configured',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSM,
                                fontWeight: FontWeight.w600,
                                color: controller.isApiKeyConfigured.value
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    const Text(
                      'Paste an API key from a Google Cloud project with the '
                      'Cloud Translation API enabled.',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSM,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    TextField(
                      controller: controller.apiKeyController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'AIza...',
                        prefixIcon: const Icon(
                          Icons.vpn_key_outlined,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    Obx(
                      () => _buildApiButtons(
                        isTesting: controller.isCheckingApiKey.value,
                        onSaveAndTest: controller.saveAndTestApiKey,
                        onRemove: controller.removeApiKey,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSM),
                    const Text(
                      'Enable the API at console.cloud.google.com/apis/library/'
                      'translate.googleapis.com',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSM,
                        color: AppColors.textHint,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gemini fallback (free tier, no billing account required)
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingMD,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSM,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_outlined,
                            color: AppColors.primary,
                            size: AppDimensions.iconMD,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingSM),
                        const Expanded(
                          child: Text(
                            'Gemini (free tier)',
                            style: TextStyle(
                              fontSize: AppDimensions.fontMD,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingSM,
                              vertical: AppDimensions.paddingXS,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (controller.isGeminiKeyConfigured.value
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSM,
                              ),
                            ),
                            child: Text(
                              controller.isGeminiKeyConfigured.value
                                  ? 'Configured'
                                  : 'Not configured',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSM,
                                fontWeight: FontWeight.w600,
                                color: controller.isGeminiKeyConfigured.value
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    const Text(
                      'Free alternative to Cloud Translation \u2014 no billing '
                      'account required. Used automatically when no Google '
                      'Cloud key is configured.',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSM,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    TextField(
                      controller: controller.geminiKeyController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'AIza...',
                        prefixIcon: const Icon(
                          Icons.vpn_key_outlined,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    Obx(
                      () => _buildApiButtons(
                        isTesting: controller.isCheckingGeminiKey.value,
                        onSaveAndTest: controller.saveAndTestGeminiKey,
                        onRemove: controller.removeGeminiKey,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSM),
                    const Text(
                      'Get a free key at aistudio.google.com/apikey',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSM,
                        color: AppColors.textHint,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Speech settings section
            _buildSectionTitle(AppStrings.speechSettings),
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingMD,
              ),
              child: Column(
                children: [
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSM,
                        vertical: AppDimensions.paddingMD,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.speechSpeed,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontMD,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${controller.speechSpeed.value.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontMD,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: controller.speechSpeed.value,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              controller.speechSpeed.value = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSM,
                        vertical: AppDimensions.paddingMD,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.speechPitch,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontMD,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${controller.speechPitch.value.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontMD,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: controller.speechPitch.value,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              controller.speechPitch.value = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data management section
            _buildSectionTitle(AppStrings.dataManagement),
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingMD,
              ),
              child: _buildSettingsTile(
                icon: Icons.cached_outlined,
                title: AppStrings.clearCache,
                subtitle: 'Clear temporary translation data',
                onTap: controller.clearCache,
              ),
            ),

            // Privacy section
            _buildSectionTitle(AppStrings.privacy),
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingMD,
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildSettingsTile(
                    icon: Icons.gavel_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // About section
            _buildSectionTitle(AppStrings.appInfo),
            AppCard(
              margin: const EdgeInsets.only(
                left: AppDimensions.cardMargin,
                right: AppDimensions.cardMargin,
                bottom: AppDimensions.paddingXL,
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: AppStrings.version,
                    trailing: const Text(
                      '1.0.0',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMD,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildSettingsTile(
                    icon: Icons.code_outlined,
                    title: AppStrings.developer,
                    trailing: const Text(
                      'LingoX Team',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMD,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildSettingsTile(
                    icon: Icons.description_outlined,
                    title: AppStrings.license,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiButtons({
    required bool isTesting,
    required VoidCallback onSaveAndTest,
    required VoidCallback onRemove,
  }) {
    final testButton = FilledButton.icon(
      onPressed: isTesting ? null : onSaveAndTest,
      icon: isTesting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.check_circle_outline),
      label: Text(isTesting ? 'Testing...' : 'Save & Test'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD),
      ),
    );

    final removeButton = OutlinedButton(
      onPressed: onRemove,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingMD,
        ),
      ),
      child: const Text('Remove'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Stack the buttons on narrow phones so the labels cannot overflow.
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              testButton,
              const SizedBox(height: AppDimensions.paddingSM),
              removeButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: testButton),
            const SizedBox(width: AppDimensions.paddingSM),
            removeButton,
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingSM,
        AppDimensions.paddingLG,
        AppDimensions.paddingSM,
        AppDimensions.paddingSM,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimensions.fontSM,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        child: Icon(icon, color: AppColors.primary, size: AppDimensions.iconMD),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimensions.fontMD,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppDimensions.fontSM,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            size: AppDimensions.iconMD,
            color: AppColors.textHint,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingXS,
      ),
    );
  }
}
