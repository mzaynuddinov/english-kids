import 'dart:async';

import 'package:english_kids/models/alphabet.dart';
import 'package:english_kids/models/days.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/pages/alphabet_page.dart';
import 'package:english_kids/pages/students_page.dart';
import 'package:english_kids/services/pin_service.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/reminder_service.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReminderService.suppressTimersForTests = true;
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
    ProgressService.instance.debugReset();
    PinService.instance.debugReset();
  });

  tearDown(() {
    PreferencesService.instance.debugBeforeWrite = null;
    PreferencesService.instance.debugFailWrites = false;
  });

  test('a learned flag is visible before storage finishes and rolls back on failure', () async {
    await StudentService.instance.init();
    final student = await StudentService.instance.addStudent('Насим');
    await WordLearningService.instance.openStudent(
      studentId: student.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    final watch = Stopwatch()..start();
    final pending = WordLearningService.instance.setFlag(apple.id, learned: true);
    watch.stop();
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
    expect(watch.elapsedMilliseconds, lessThan(200));
    var finished = false;
    pending.whenComplete(() => finished = true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(finished, isFalse, reason: 'the save is still waiting on storage');
    gate.complete();
    expect(await pending, isTrue);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);

    PreferencesService.instance.debugBeforeWrite = null;
    PreferencesService.instance.debugFailWrites = true;
    final failed = WordLearningService.instance.setFlag(apple.id, learned: false);
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
    expect(await failed, isFalse);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
  });

  test('an older write cannot replace a newer learned tap', () async {
    await StudentService.instance.init();
    final student = await StudentService.instance.addStudent('Насим');
    await WordLearningService.instance.openStudent(
      studentId: student.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    final first = WordLearningService.instance.setFlag(apple.id, learned: true);
    final second = WordLearningService.instance.setFlag(apple.id, learned: false);
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
    await first;
    await second;
    WordLearningService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await WordLearningService.instance.openStudent(
      studentId: student.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
  });

  test('a student appears before storage finishes, is not duplicated, and is removed if saving fails', () async {
    await StudentService.instance.init();
    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    final watch = Stopwatch()..start();
    final first = StudentService.instance.addStudent('Насим');
    final second = StudentService.instance.addStudent('Насим');
    watch.stop();
    expect(StudentService.instance.students.map((student) => student.name), ['Насим']);
    expect(watch.elapsedMilliseconds, lessThan(200));
    var finished = false;
    first.whenComplete(() => finished = true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(finished, isFalse);
    gate.complete();
    final savedFirst = await first;
    final savedSecond = await second;
    expect(savedFirst.id, savedSecond.id);
    expect(StudentService.instance.students, hasLength(1));

    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.students.single.name, 'Насим');

    PreferencesService.instance.debugFailWrites = true;
    final failed = StudentService.instance.addStudent('Ҳадиса');
    expect(StudentService.instance.students.map((student) => student.name), ['Насим', 'Ҳадиса']);
    await expectLater(failed, throwsStateError);
    expect(StudentService.instance.students.map((student) => student.name), ['Насим']);
  });

  testWidgets('the student list and the alphabet button update before storage finishes', (tester) async {
    await StudentService.instance.init();
    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    final added = StudentService.instance.addStudent('Насим');
    await tester.pumpWidget(const MaterialApp(home: StudentsPage()));
    for (var i = 0; i < 8; i++) {
      await tester.pump();
      if (find.text('Насим').evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    expect(find.text('Насим'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(StudentService.instance.students.single.name, 'Насим');
    gate.complete();
    await added;

    final studentId = StudentService.instance.currentStudentId!;
    await WordLearningService.instance.openStudent(
      studentId: studentId,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    final letterGate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => letterGate.future;
    final host = GlobalKey<_AlphabetFeedbackHostState>();
    await tester.pumpWidget(MaterialApp(home: _AlphabetFeedbackHost(key: host)));
    await tester.pump();
    expect(find.text('Омӯхтам'), findsOneWidget);

    final learning = host.currentState!.markFirstLetter();
    await tester.pump();
    expect(find.text('Омӯхта шуд'), findsOneWidget);
    expect(find.textContaining('Офарин'), findsOneWidget);
    expect(ProgressService.instance.snapshot.letters, contains('A'));

    letterGate.complete();
    await learning;
    await tester.pump();
    expect(find.text('Омӯхта шуд'), findsOneWidget);
    expect(StudentService.instance.students, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _AlphabetFeedbackHost extends StatefulWidget {
  const _AlphabetFeedbackHost({super.key});

  @override
  State<_AlphabetFeedbackHost> createState() => _AlphabetFeedbackHostState();
}

class _AlphabetFeedbackHostState extends State<_AlphabetFeedbackHost> {
  Future<void> markFirstLetter() async {
    final letter = alphabetLetters.first;
    final progress = ProgressService.instance;
    final learning = WordLearningService.instance;
    final before = progress.snapshot;
    final id = letterLearningId(letter.letter);
    final next = progress.withActivity(before.copyWith(letters: {...before.letters, letter.letter}));
    final progressWrite = progress.save(next);
    final flagWrite = learning.setFlag(id, learned: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('🎉 Офарин! Ҳарфи ${letter.letter} омӯхта шуд.')));
    final flagOk = await flagWrite;
    final progressOk = await progressWrite;
    if ((!flagOk || !progressOk) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ҳарфи ${letter.letter} захира нашуд. Боз кӯшиш кунед.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlphabetPage(
      onSpeak: (_) async {},
      onLearnLetter: (_) async {},
    );
  }
}


