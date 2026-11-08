import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/waveform_animation.dart';
import '../../../../data/models/translation_model.dart';
import '../../../../data/repositories/translation_repository.dart';
import '../../../translator/presentation/pages/translate_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomeController extends GetxController {
  final TranslationRepository _repository = Get.find<TranslationRepository>();
  final RxInt bottomNavIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxList<TranslationModel> recentTranslations = <TranslationModel>[].obs;
  final RxBool isLoadingHistory = true.obs;

  void setBottomNavIndex(int index) {
    bottomNavIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('[Home] Home screen opened');
    _loadRecentTranslations();
  }

  Future<void> _loadRecentTranslations() async {
    isLoadingHistory.value = true;
    try {
      final history = await _repository.getHistory();
      recentTranslations.value = history.take(5).toList();
    } catch (e) {
      recentTranslations.clear();
    } finally {
      isLoadingHistory.value = false;
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.bottomNavIndex.value,
          children: const [
            _HomeContent(),
            TranslatePlaceholder(),
            HistoryPlaceholder(),
            FavoritesPlaceholder(),
            SettingsPlaceholder(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => _BottomNavigation(
          currentIndex: controller.bottomNavIndex.value,
          onTap: controller.setBottomNavIndex,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader()),
          // Search language field
          SliverToBoxAdapter(child: _buildSearchField()),
          // Language selector cards
          SliverToBoxAdapter(child: _buildLanguageCards()),
          // Translate Now button
          SliverToBoxAdapter(child: _buildTranslateButton()),
          // Voice Translator card
          SliverToBoxAdapter(child: _buildVoiceCard()),
          // Quick access features
          SliverToBoxAdapter(child: _buildQuickAccess()),
          // Recent translations
          SliverToBoxAdapter(child: _buildRecentTranslations()),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppDimensions.paddingXL),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLG,
        AppDimensions.paddingMD,
        AppDimensions.paddingLG,
        AppDimensions.paddingSM,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarMD,
            height: AppDimensions.avatarMD,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: const Center(
              child: Text(
                'LX',
                style: TextStyle(
                  fontSize: AppDimensions.fontLG,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppStrings.appTagline,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingSM,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: AppStrings.searchLanguage,
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
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
      ),
    );
  }

  Widget _buildLanguageCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        final outerPadding = compact
            ? AppDimensions.paddingMD
            : AppDimensions.paddingLG;
        final gap = compact ? AppDimensions.paddingSM : AppDimensions.paddingMD;
        final swapSize = compact ? 36.0 : 40.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: outerPadding,
            vertical: AppDimensions.paddingSM,
          ),
          child: Row(
            children: [
              Expanded(
                child: _HomeLanguageCard(
                  flag: '🇬🇧',
                  name: 'English',
                  label: AppStrings.sourceLanguage,
                  compact: compact,
                ),
              ),
              SizedBox(width: gap),
              // Swap button
              Container(
                width: swapSize,
                height: swapSize,
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
                child: Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: compact ? 18 : AppDimensions.iconMD,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _HomeLanguageCard(
                  flag: '🇪🇸',
                  name: 'Spanish',
                  label: AppStrings.targetLanguage,
                  compact: compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTranslateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingSM,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Get.toNamed(Routes.translate),
          icon: const Icon(Icons.translate),
          label: Text(AppStrings.translateNow),
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
    );
  }

  Widget _buildVoiceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingSM,
      ),
      child: AppCard(
        onTap: () => Get.toNamed(Routes.voiceTranslator),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.voiceGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white),
                ),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.voiceTranslator,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLG,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Tap to start voice translation',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            WaveformAnimation(
              isPlaying: true,
              color: AppColors.primary,
              barCount: 30,
              maxHeight: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLG,
        AppDimensions.paddingMD,
        AppDimensions.paddingLG,
        AppDimensions.paddingSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.quickAccess,
            style: const TextStyle(
              fontSize: AppDimensions.fontLG,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            children: [
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.chat_bubble_outline,
                  label: AppStrings.conversation,
                  gradient: AppColors.primaryGradient,
                  onTap: () => Get.toNamed(Routes.conversation),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.camera_alt_outlined,
                  label: AppStrings.cameraTranslator,
                  gradient: AppColors.accentGradient,
                  onTap: () => Get.toNamed(Routes.cameraTranslator),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTranslations() {
    final controller = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLG,
        AppDimensions.paddingMD,
        AppDimensions.paddingLG,
        AppDimensions.paddingSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  AppStrings.recentTranslations,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppDimensions.fontLG,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.history),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSM,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          Obx(() {
            if (controller.isLoadingHistory.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingMD),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              );
            }

            if (controller.recentTranslations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.noRecentTranslations,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontMD,
                          color: AppColors.textHint,
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
                ),
              );
            }

            return Column(
              children: controller.recentTranslations
                  .take(3)
                  .map(
                    (translation) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.paddingSM,
                      ),
                      child: AppCard(
                        onTap: () => Get.toNamed(Routes.translate),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppDimensions.paddingXS,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  translation.sourceLanguage.flagEmoji,
                                  style: const TextStyle(fontSize: 18),
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
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                                Text(
                                  translation.targetLanguage.flagEmoji,
                                  style: const TextStyle(fontSize: 18),
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
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _HomeLanguageCard extends StatelessWidget {
  final String flag;
  final String name;
  final String label;
  final bool compact;

  const _HomeLanguageCard({
    required this.flag,
    required this.name,
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Get.toNamed(Routes.translate),
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        compact ? AppDimensions.paddingSM : AppDimensions.cardPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  flag,
                  maxLines: 1,
                  style: TextStyle(fontSize: compact ? 18 : 20),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSM),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact
                        ? AppDimensions.fontSM
                        : AppDimensions.fontMD,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? AppDimensions.fontXS : AppDimensions.fontSM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(icon, color: Colors.white, size: AppDimensions.iconLG),
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppDimensions.fontSM,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavigation({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: const TextStyle(
          fontSize: AppDimensions.fontXS,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: AppDimensions.fontXS),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate_outlined),
            activeIcon: Icon(Icons.translate),
            label: AppStrings.translate,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: AppStrings.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: AppStrings.favorites,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}

// Placeholder widgets for bottom nav tabs
class TranslatePlaceholder extends StatelessWidget {
  const TranslatePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const TranslatePage();
  }
}

class HistoryPlaceholder extends StatelessWidget {
  const HistoryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoryPage();
  }
}

class FavoritesPlaceholder extends StatelessWidget {
  const FavoritesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const FavoritesPage();
  }
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}
