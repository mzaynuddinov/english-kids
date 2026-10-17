import 'package:english_kids/models/progress_rules.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/pages/week_page.dart';
import 'package:english_kids/pages/words_page.dart';
import 'package:english_kids/services/pin_service.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/student_service.dart';
import 'package:english_kids/services/word_learning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const apple = Word(
    english: 'apple',
    pronunciation: 'a',
    tajik: 'себ',
    week: 1,
    topic: 'Fruit',
  );
  const ball = Word(
    english: 'ball',
    pronunciation: 'b',
    tajik: 'тӯб',
    week: 2,
    topic: 'Toys',
  );
  final letters = {for (var i = 0; i < 26; i++) String.fromCharCode(65 + i)};

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
    PinService.instance.debugReset();
  });

  test('each student unlocks the next week only from their own saved words', () async {
    await StudentService.instance.init();
    final nasim = await StudentService.instance.addStudent('Насим');
    final hadisa = await StudentService.instance.addStudent('Ҳадиса');
    final words = [apple, ball];
    expect(weekUnlocked(1, {}, words, {}), isFalse);
    expect(weekUnlocked(1, letters, words, {}), isTrue);
    expect(weekUnlocked(2, letters, words, {}), isFalse);

    await PreferencesService.instance.saveSet(
      StudentService.instance.learnedKey(nasim.id),
      {apple.id},
    );

    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    final nasimLearned = await PreferencesService.instance.loadSet(
      StudentService.instance.learnedKey(nasim.id),
    );
    final hadisaLearned = await PreferencesService.instance.loadSet(
      StudentService.instance.learnedKey(hadisa.id),
    );
    expect(weekUnlocked(2, letters, words, nasimLearned), isTrue);
    expect(weekUnlocked(2, letters, words, hadisaLearned), isFalse);
    expect(weekUnlocked(1, {}, words, nasimLearned), isFalse);
  });

  testWidgets('Богзашт removes the learned mark on the same card', (tester) async {
    var learned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WeekPage(
          week: 1,
          title: 'Ҳафтаи 1',
          words: const [apple],
          learned: const {},
          saved: const {},
          onSpeak: (_) async {},
          onSave: (_) async {},
          onLearn: (_) async {
            learned = !learned;
          },
          onRemind: (_) async {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Омӯхта шуд'), findsOneWidget);

    await tester.tap(find.text('Омӯхта шуд'));
    await tester.pump();
    await tester.pump();
    expect(learned, isTrue);
    expect(find.text('Бозгашт'), findsOneWidget);

    await tester.tap(find.text('Бозгашт'));
    await tester.pump();
    await tester.pump();
    expect(learned, isFalse);
    expect(find.text('Омӯхта шуд'), findsOneWidget);
    expect(find.text('Бозгашт'), findsNothing);
  });

  testWidgets('a locked week cannot be opened from the word list', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WordsPage(
          words: const [apple, ball],
          learned: const {},
          saved: const {},
          weekOpen: (week) => week == 1,
          onSpeak: (_) async {},
          onSave: (_) async {},
          onLearn: (word) async {
            opened = true;
          },
          onRemind: (_) async {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('🔒 Ҳафтаи 2'), findsOneWidget);
    await tester.tap(find.text('🔒 Ҳафтаи 2'));
    await tester.pump();
    expect(opened, isFalse);
    expect(find.text('Ҳафтаи 2'), findsNothing);
    expect(find.text('apple'), findsNothing);
  });
}
