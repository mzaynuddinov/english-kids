import 'package:flutter_test/flutter_test.dart';
import 'package:english_kids/main.dart';

void main() {
  testWidgets('English Kids starts', (tester) async {
    await tester.pumpWidget(const EnglishKidsApp());
    await tester.pump();
    expect(find.text('🌟 English Kids'), findsOneWidget);
  });
}
