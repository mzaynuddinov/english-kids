import 'dart:async';
import 'dart:convert';

import 'package:english_kids/models/word.dart';
import 'package:english_kids/models/word_learning.dart';
import 'package:english_kids/services/pin_service.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/student_service.dart';
import 'package:english_kids/services/word_learning_service.dart';
import 'package:english_kids/widgets/word_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
    PinService.instance.debugReset();
  });

  tearDown(() {
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
    PinService.instance.debugReset();
  });

  test('PIN stays valid after the process restarts', () async {
    expect(await PinService.instance.hasPin(), isFalse);
    expect(await PinService.instance.setPin('2468'), isTrue);
    final salt = await PreferencesService.instance.loadRaw('parent_pin_salt');

    PreferencesService.instance.debugReset();
    PinService.instance.debugReset();

    expect(await PinService.instance.hasPin(), isTrue);
    expect(await PinService.instance.verify('2468'), isTrue);
    expect(await PinService.instance.verify('0000'), isFalse);
    expect(await PreferencesService.instance.loadRaw('parent_pin_salt'), salt);
    expect(await PinService.instance.hasPin(), isTrue);
  });

  test('a cached PIN answers without another storage read', () async {
    expect(await PinService.instance.setPin('1357'), isTrue);
    final reads = PreferencesService.instance.prefsReads;
    final watch = Stopwatch()..start();
    expect(await PinService.instance.verify('1357'), isTrue);
    expect(await PinService.instance.verify('0000'), isFalse);
    watch.stop();
    expect(PreferencesService.instance.prefsReads, reads);
    expect(watch.elapsedMilliseconds, lessThan(200));
    expect(await PinService.instance.hasPin(), isTrue);
  });

  test('students survive restart, refresh, and a timer', () async {
    await StudentService.instance.init();
    expect(StudentService.instance.students, isEmpty);
    await StudentService.instance.addStudent('Насим');
    await StudentService.instance.addStudent('Ҳадиса');
    expect(StudentService.instance.students.map((student) => student.name), ['Насим', 'Ҳадиса']);

    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.students.map((student) => student.name), ['Насим', 'Ҳадиса']);

    await StudentService.instance.refreshFromDisk();
    await StudentService.instance.refreshFromDisk();
    expect(StudentService.instance.students, hasLength(2));

    StudentService.instance.students = [];
    await StudentService.instance.refreshFromDisk();
    expect(StudentService.instance.students.map((student) => student.name), ['Насим', 'Ҳадиса']);

    final done = Completer<void>();
    Timer(const Duration(milliseconds: 30), () async {
      await StudentService.instance.refreshFromDisk();
      done.complete();
    });
    await done.future;
    expect(StudentService.instance.students.map((student) => student.name), ['Насим', 'Ҳадиса']);
    expect(StudentService.instance.students.map((student) => student.id).toSet(), hasLength(2));
  });

  test('renaming keeps the same id after restart', () async {
    await StudentService.instance.init();
    final created = await StudentService.instance.addStudent('Насим');
    await StudentService.instance.renameStudent(created.id, 'Насимхон');
    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.studentById(created.id)?.name, 'Насимхон');
    expect(StudentService.instance.students, hasLength(1));
  });

  test('a failed save does not report the student or the learned flag as saved', () async {
    await StudentService.instance.init();
    PreferencesService.instance.debugFailWrites = true;
    await expectLater(StudentService.instance.addStudent('Насим'), throwsStateError);
    expect(StudentService.instance.students, isEmpty);

    PreferencesService.instance.debugFailWrites = false;
    final student = await StudentService.instance.addStudent('Насим');
    const word = Word(
      english: 'apple',
      pronunciation: '/ˈæpəl/',
      tajik: 'Себ',
      week: 1,
      topic: 'Fruit',
    );
    await WordLearningService.instance.openStudent(
      studentId: student.id,
      vocab: const [word],
      legacyLearned: {},
      legacySaved: {},
    );
    expect(await WordLearningService.instance.setFlag(word.id, learned: true), isTrue);
    expect(WordLearningService.instance.of(word.id).learned, isTrue);

    PreferencesService.instance.debugFailWrites = true;
    expect(await WordLearningService.instance.setFlag(word.id, learned: false), isFalse);
    expect(WordLearningService.instance.of(word.id).learned, isTrue);
    await expectLater(
      WordLearningService.instance.record(word.id, OralMark.incorrect),
      throwsStateError,
    );
    expect(WordLearningService.instance.of(word.id).incorrect, 0);
  });

  test('a newer file copy restores students and the PIN when preferences are stale', () async {
    final hash = PinService.instance.digest('2468', 'abc');
    SharedPreferences.setMockInitialValues({
      'students_list': '[]',
      '__rev': '1',
    });
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    PreferencesService.instance.debugSeedFile({
      '__rev': '4',
      'students_list': jsonEncode([
        {'id': 's1', 'name': 'Насим', 'createdAt': '2026-01-01T00:00:00.000'},
        {'id': 's2', 'name': 'Ҳадиса', 'createdAt': '2026-01-02T00:00:00.000'},
      ]),
      'parent_pin_salt': 'abc',
      'parent_pin_hash': hash,
      'current_student_id': 's1',
    });

    await StudentService.instance.init();
    expect(StudentService.instance.students.map((student) => student.name), ['Насим', 'Ҳадиса']);
    expect(StudentService.instance.currentStudentId, 's1');
    expect(await PinService.instance.hasPin(), isTrue);
    expect(await PinService.instance.verify('2468'), isTrue);
    expect(await PinService.instance.verify('0000'), isFalse);

    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.students.map((student) => student.name), ['Насим', 'Ҳадиса']);
    expect(await PinService.instance.verify('2468'), isTrue);
  });

  testWidgets('listen, history, and reminder are icons without text labels', (tester) async {
    const word = Word(
      english: 'apple',
      pronunciation: '/ˈæpəl/',
      tajik: 'Себ',
      week: 1,
      topic: 'Fruit',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              WordCard(
                word: word,
                learned: false,
                saved: false,
                onSpeak: (_) async {},
                onSave: (_) async {},
                onLearn: (_) async {},
                onRemind: (_) async {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Гӯш кардан'), findsOneWidget);
    expect(find.byTooltip('Таърихи ин талаба'), findsOneWidget);
    expect(find.byTooltip('Ёдрас'), findsOneWidget);
    expect(find.text('Гӯш кардан'), findsNothing);
    expect(find.text('Таърихи ин талаба'), findsNothing);
    expect(find.text('Ёдрас'), findsNothing);
    expect(find.text('Омӯхта шуд'), findsOneWidget);
    final actionRow = find.ancestor(
      of: find.byTooltip('Гӯш кардан'),
      matching: find.byType(Row),
    ).first;
    expect(find.descendant(of: actionRow, matching: find.byTooltip('Таърихи ин талаба')), findsOneWidget);
    expect(find.descendant(of: actionRow, matching: find.byTooltip('Ёдрас')), findsOneWidget);
    expect(find.descendant(of: actionRow, matching: find.text('Омӯхта шуд')), findsOneWidget);

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              WordCard(
                word: word,
                learned: false,
                saved: false,
                onSpeak: (_) async {},
                onSave: (_) async {},
                onLearn: (_) async {},
                onRemind: (_) async {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Гӯш кардан'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
