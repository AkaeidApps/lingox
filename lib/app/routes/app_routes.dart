import 'package:get/get.dart';

// Import all pages for route registration
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/translator/presentation/pages/translate_page.dart';
import '../../features/voice_translator/presentation/pages/voice_translator_page.dart';
import '../../features/conversation/presentation/pages/conversation_page.dart';
import '../../features/camera_translator/presentation/pages/camera_translator_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class Routes {
  Routes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String translate = '/translate';
  static const String voiceTranslator = '/voice-translator';
  static const String conversation = '/conversation';
  static const String cameraTranslator = '/camera-translator';
  static const String history = '/history';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
}

class AppPages {
  AppPages._();

  static const initialRoute = Routes.splash;

  static final List<GetPage> routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(name: Routes.onboarding, page: () => const OnboardingPage()),
    GetPage(name: Routes.home, page: () => const HomePage()),
    GetPage(name: Routes.translate, page: () => const TranslatePage()),
    GetPage(
      name: Routes.voiceTranslator,
      page: () => const VoiceTranslatorPage(),
    ),
    GetPage(name: Routes.conversation, page: () => const ConversationPage()),
    GetPage(
      name: Routes.cameraTranslator,
      page: () => const CameraTranslatorPage(),
    ),
    GetPage(name: Routes.history, page: () => const HistoryPage()),
    GetPage(name: Routes.favorites, page: () => const FavoritesPage()),
    GetPage(name: Routes.settings, page: () => const SettingsPage()),
  ];
}
