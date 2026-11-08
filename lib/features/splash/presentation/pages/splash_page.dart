import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_dimensions.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/network/api_config.dart';

/// Binding for the splash route.
///
/// The splash page is a `GetView`, so its controller must be registered before
/// the page is built. Keeping this in a route binding also gives GetX a clear
/// lifecycle to dispose the controller when the splash route is removed.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController());
  }
}

class SplashController extends GetxController {
  /// Keep the splash animation visible long enough to avoid a jarring flash.
  static const Duration _minimumSplashDuration = Duration(seconds: 2);

  /// Never let a startup dependency keep the app on the splash screen forever.
  static const Duration _initializationTimeout = Duration(seconds: 8);

  static const Duration _preferencesTimeout = Duration(seconds: 5);

  final RxBool isInitializing = true.obs;
  final RxnString errorMessage = RxnString();

  Timer? _navigationTimer;
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[Splash] Controller initialized');
    _initializeAndNavigate();
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('[Splash] Splash screen ready');
  }

  /// Retry after an initialization failure.
  void retryInitialization() {
    if (_isNavigating) {
      debugPrint('[Splash] Retry ignored: navigation already in progress');
      return;
    }
    debugPrint('[Splash] Retrying startup initialization');
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    isInitializing.value = true;
    errorMessage.value = null;

    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('[Splash] Starting essential initialization');
      await _initializeEssentialServices().timeout(_initializationTimeout);
      debugPrint(
        '[Splash] Essential initialization completed in '
        '${stopwatch.elapsedMilliseconds}ms',
      );

      final remaining = _minimumSplashDuration - stopwatch.elapsed;
      final delay = remaining.isNegative ? Duration.zero : remaining;
      debugPrint(
        '[Splash] Scheduling navigation to ${Routes.home} in '
        '${delay.inMilliseconds}ms',
      );

      _navigationTimer = Timer(delay, () {
        _navigationTimer = null;
        _navigateToHome();
      });
    } on TimeoutException catch (e, stackTrace) {
      _handleInitializationFailure(
        'Startup timed out while preparing the app. Please try again.',
        e,
        stackTrace,
      );
    } catch (e, stackTrace) {
      _handleInitializationFailure(
        'Could not finish starting the app. Please try again.',
        e,
        stackTrace,
      );
    }
  }

  /// Only essential, fast work belongs here. API clients, TTS, audio players
  /// and other features are registered lazily in [AppBinding] and must not
  /// block the splash screen.
  Future<void> _initializeEssentialServices() async {
    debugPrint('[Splash] Preparing local preferences');
    await SharedPreferences.getInstance().timeout(_preferencesTimeout);
    await ApiConfig.initialize().timeout(_preferencesTimeout);
    debugPrint('[Splash] Local preferences ready');
  }

  Future<void> _navigateToHome() async {
    if (_isNavigating || isClosed) {
      debugPrint(
        '[Splash] Navigation skipped (already navigating or disposed)',
      );
      return;
    }

    // Set the guard before awaiting so a delayed callback can never trigger a
    // second navigation.
    _isNavigating = true;
    debugPrint('[Splash] Navigating to ${Routes.home}');

    try {
      await Get.offAllNamed(Routes.home);
      debugPrint('[Splash] Navigation to ${Routes.home} completed');
    } catch (e, stackTrace) {
      _isNavigating = false;
      _handleInitializationFailure(
        'Could not open the home screen. Please try again.',
        e,
        stackTrace,
      );
    }
  }

  void _handleInitializationFailure(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[Splash] Startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    _navigationTimer?.cancel();
    _navigationTimer = null;

    if (isClosed) return;

    isInitializing.value = false;
    errorMessage.value = message;
  }

  @override
  void onClose() {
    debugPrint('[Splash] Controller disposing');
    _navigationTimer?.cancel();
    _navigationTimer = null;
    super.onClose();
  }
}

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: AppDimensions.splashLogoSize,
                height: AppDimensions.splashLogoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'LX',
                    style: TextStyle(
                      fontSize: AppDimensions.fontXL3,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = AppColors.primaryGradient.createShader(
                          const Rect.fromLTWH(0, 0, 60, 60),
                        ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              Text(
                AppStrings.splashTitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontXL2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXS),
              Text(
                AppStrings.splashSubtitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontMD,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              Obx(() {
                final error = controller.errorMessage.value;

                if (error == null) {
                  return const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: AppDimensions.paddingMD),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppDimensions.fontMD,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),
                      ElevatedButton.icon(
                        onPressed: controller.retryInitialization,
                        icon: const Icon(Icons.refresh),
                        label: const Text(AppStrings.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingXL,
                            vertical: AppDimensions.paddingMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMD,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
