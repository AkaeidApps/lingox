import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final RxInt currentPage = 0.obs;
  final PageController pageController = PageController();

  void nextPage() {
    if (currentPage.value < 2) {
      currentPage.value++;
      pageController.animateToPage(
        currentPage.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      skipToHome();
    }
  }

  void skipToHome() {
    Get.offAllNamed(Routes.home);
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: TextButton(
                  onPressed: controller.skipToHome,
                  child: Text(
                    AppStrings.skip,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppDimensions.fontMD,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 1),
            // Page view
            Expanded(
              flex: 4,
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                children: const [
                  _OnboardingSlide(
                    icon: Icons.translate,
                    title: AppStrings.onboardingTranslate,
                    description: AppStrings.onboardingTranslateDesc,
                    gradient: AppColors.primaryGradient,
                  ),
                  _OnboardingSlide(
                    icon: Icons.mic,
                    title: AppStrings.onboardingVoice,
                    description: AppStrings.onboardingVoiceDesc,
                    gradient: AppColors.voiceGradient,
                  ),
                  _OnboardingSlide(
                    icon: Icons.camera_alt,
                    title: AppStrings.onboardingCamera,
                    description: AppStrings.onboardingCameraDesc,
                    gradient: AppColors.accentGradient,
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingLG,
              ),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: controller.currentPage.value == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Spacer(flex: 1),
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingMD,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                    ),
                    child: Text(
                      controller.currentPage.value < 2
                          ? AppStrings.next
                          : AppStrings.getStarted,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontLG,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMD),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconBoxSize = (constraints.maxHeight * 0.32).clamp(104.0, 160.0);
        final iconSize = iconBoxSize * 0.5;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingXL,
            vertical: AppDimensions.paddingMD,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: iconSize, color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXL2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontMD,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
