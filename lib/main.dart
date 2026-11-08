import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/app_binding.dart';
import 'app/constants/app_colors.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/constants/app_strings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Startup] LingoX bootstrapping');
  runApp(const LingoXApp());
}

class LingoXApp extends StatelessWidget {
  const LingoXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.initialRoute,
      getPages: AppPages.routes,
      initialBinding: AppBinding(),
      builder: (context, child) {
        final media = MediaQuery.of(context);

        return MediaQuery(
          // Keep very large system font sizes from breaking compact layouts,
          // while still honouring smaller accessibility settings.
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.35,
            ),
          ),
          child: ColoredBox(
            color: AppColors.background,
            child: Center(
              // Tablets and desktop windows get a readable, centred column
              // instead of stretching every row across the full width.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
