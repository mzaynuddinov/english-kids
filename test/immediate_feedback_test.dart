import 'dart:async';

import 'package:english_kids/models/settings.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/pages/alphabet_page.dart';
import 'package:english_kids/pages/home_shell.dart';
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

  testWidgets('adding a student updates the list and the notice before storage finishes', (tester) async {
    await StudentService.instance.init();
    await tester.pumpWidget(const MaterialApp(home: StudentsPage()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Насим');
    await tester.tap(find.widgetWithText(FilledButton, 'Захира кардан'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Насим'), findsWidgets);
    expect(find.text('«Насим» илова шуд'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(StudentService.instance.students.single.name, 'Насим');

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Насим'), findsWidgets);
    expect(StudentService.instance.students, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('the alphabet learned button and notice update before storage finishes', (tester) async {
    tester.view.physicalSize = const Size(1200, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await StudentService.instance.init();
    await StudentService.instance.addStudent('Насим');
    await tester.pumpWidget(MaterialApp(
      home: HomeShell(settings: const AppSettings(), onSettingsChanged: (_) {}),
    ));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final homeReady = find.byKey(const ValueKey('home')).evaluate().isNotEmpty;
      final studentReady = WordLearningService.instance.studentId != null &&
          WordLearningService.instance.studentId == StudentService.instance.currentStudentId;
      if (homeReady && studentReady) break;
    }
    expect(find.byKey(const ValueKey('home')), findsOneWidget);
    expect(WordLearningService.instance.studentId, isNotNull);

    final alphabet = find.descendant(
      of: find.byKey(const ValueKey('home')),
      matching: find.text('Алифбо'),
    );
    expect(alphabet, findsOneWidget);
    await tester.tap(alphabet);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlphabetPage), findsOneWidget);
    expect(find.text('Омӯхтам'), findsOneWidget);

    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    await tester.tap(find.text('Омӯхтам'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Омӯхта шуд'), findsOneWidget);
    expect(find.textContaining('Офарин'), findsOneWidget);
    expect(ProgressService.instance.snapshot.letters, contains('A'));
    expect(find.text('Омӯхтам'), findsNothing);

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Омӯхта шуд'), findsOneWidget);

    PreferencesService.instance.debugBeforeWrite = null;
    final backGate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => backGate.future;
    await tester.tap(find.text('Омӯхта шуд'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Омӯхтам'), findsOneWidget);
    expect(find.textContaining('ба ҳолати қаблӣ'), findsOneWidget);
    expect(ProgressService.instance.snapshot.letters.contains('A'), isFalse);
    backGate.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 1)));
}
