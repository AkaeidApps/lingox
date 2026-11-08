import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingox/data/repositories/translation_repository.dart';
import 'package:lingox/features/camera_translator/presentation/pages/camera_translator_page.dart';
import 'package:lingox/features/conversation/presentation/pages/conversation_page.dart';
import 'package:lingox/features/favorites/presentation/pages/favorites_page.dart';
import 'package:lingox/features/history/presentation/pages/history_page.dart';
import 'package:lingox/features/home/presentation/pages/home_page.dart';
import 'package:lingox/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lingox/features/settings/presentation/pages/settings_page.dart';
import 'package:lingox/features/translator/presentation/pages/translate_page.dart';
import 'package:lingox/features/voice_translator/presentation/pages/voice_translator_page.dart';

/// Common phone and tablet sizes used to guard against RenderFlex overflows.
const _sizes = <String, Size>{
  'small phone': Size(320, 480),
  'phone': Size(360, 640),
  'large phone': Size(412, 915),
  'small landscape': Size(640, 360),
  'tablet': Size(1024, 1366),
};

const _pages = <String, Widget Function()>{
  'home': HomePage.new,
  'translate': TranslatePage.new,
  'camera': CameraTranslatorPage.new,
  'voice': VoiceTranslatorPage.new,
  'conversation': ConversationPage.new,
  'settings': SettingsPage.new,
  'onboarding': OnboardingPage.new,
  'history': HistoryPage.new,
  'favorites': FavoritesPage.new,
};

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put<TranslationRepository>(TranslationRepository());
  });

  tearDown(Get.reset);

  for (final pageEntry in _pages.entries) {
    for (final sizeEntry in _sizes.entries) {
      testWidgets('${pageEntry.key} has no overflow on ${sizeEntry.key}', (
        tester,
      ) async {
        tester.view.physicalSize = sizeEntry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(GetMaterialApp(home: pageEntry.value()));
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Bengali can be selected as a target language', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: TranslatePage()));
    await tester.pump();

    await tester.tap(find.text('Target Language'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'bangla');
    await tester.pump();

    expect(find.text('Bengali'), findsOneWidget);
  });
}
