import 'dart:io';

import 'package:english_kids/app.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/vocabulary_service.dart';
import 'package:english_kids/theme.dart';
import 'package:english_kids/widgets/error_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(const EnglishKidsApp());
  await tester.pump(); // first frame + post-frame load
  await tester.pump(); // apply vocabulary setState
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find.textContaining('Нақшаи омӯзиш').evaluate().isNotEmpty) return;
    if (find.text('Калимаҳо бор нашуданд.').evaluate().isNotEmpty) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();
    VocabularyService.debugLoader = () async {
      final raw = File('data/vocabulary.json').readAsStringSync();
      return VocabularyService.parseRaw(raw);
    };
  });

  tearDown(VocabularyService.debugReset);

  testWidgets('first frame shows the Tajik app name, not a black screen', (tester) async {
    await tester.pumpWidget(const EnglishKidsApp());
    await tester.pump();

    expect(find.text(appName), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('home shell renders after vocabulary load', (tester) async {
    await pumpApp(tester);

    expect(find.text(appName), findsWidgets);
    expect(find.textContaining('Нақшаи омӯзиш'), findsOneWidget);
    expect(find.textContaining('Мушкилоти имрӯз'), findsOneWidget);
    expect(find.text('Алифбо'), findsOneWidget);
    expect(find.textContaining('Калимаи имрӯз'), findsOneWidget);
  });

  testWidgets('drawer contains required destinations', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Асосӣ'), findsWidgets);
    expect(find.text('Алифбо'), findsWidgets);
    expect(find.text('Калимаҳо'), findsWidgets);
    expect(find.text('Санҷиш'), findsOneWidget);
    expect(find.text('Ёдраскуниҳо'), findsOneWidget);
    expect(find.text('Барои баъд'), findsWidgets);
    expect(find.text('Пешрафт'), findsWidgets);
    expect(find.text('Танзимот'), findsWidgets);
    expect(find.text('Таҳиягар'), findsOneWidget);
    expect(find.text('Дар бораи барнома'), findsOneWidget);
  });

  testWidgets('fallback screen is child-friendly', (tester) async {
    await tester.pumpWidget(const ErrorFallback());
    expect(find.text(appName), findsOneWidget);
    expect(find.text('Мушкилоти муваққатӣ ба вуҷуд омад.'), findsOneWidget);
    expect(find.text('Дубора кӯшиш кунед'), findsOneWidget);
  });
}
