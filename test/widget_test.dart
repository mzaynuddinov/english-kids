import 'package:english_kids/app.dart';
import 'package:english_kids/theme.dart';
import 'package:english_kids/widgets/error_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const EnglishKidsApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first frame shows the Tajik app name, not a black screen', (tester) async {
    await tester.pumpWidget(const EnglishKidsApp());
    await tester.pump();

    expect(find.text(appName), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell renders after vocabulary load', (tester) async {
    await pumpApp(tester);

    expect(find.text(appName), findsWidgets);
    expect(find.textContaining('Нақшаи омӯзиш'), findsOneWidget);
    expect(find.text('Мушкилоти имрӯз'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer contains required destinations', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Асосӣ'), findsWidgets);
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
