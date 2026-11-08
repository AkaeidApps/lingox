import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:lingox/data/repositories/translation_repository.dart';
import 'package:lingox/features/translator/presentation/pages/translate_page.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<TranslationRepository>(TranslationRepository());
  });

  tearDown(Get.reset);

  testWidgets('language picker filters languages as the user searches', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: TranslatePage()));
    await tester.pump();

    await tester.tap(find.text('Target Language'));
    await tester.pumpAndSettle();

    expect(find.text('French'), findsOneWidget);
    expect(find.text('German'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'fr');
    await tester.pump();

    expect(find.text('French'), findsOneWidget);
    expect(find.text('German'), findsNothing);
    expect(find.text('No languages found'), findsNothing);

    await tester.enterText(find.byType(TextField).last, 'zzz');
    await tester.pump();

    expect(find.text('French'), findsNothing);
    expect(find.text('No languages found'), findsOneWidget);
  });
}
