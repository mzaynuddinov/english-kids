import 'dart:async';

import 'package:english_kids/models/word.dart';
import 'package:english_kids/services/pin_service.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/student_service.dart';
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
  });

  tearDown(() {
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
  });

  test('PIN stays valid after the process restarts', () async {
    expect(await PinService.instance.hasPin(), isFalse);
    expect(await PinService.instance.setPin('2468'), isTrue);
    final salt = await PreferencesService.instance.loadRaw('parent_pin_salt');

    PreferencesService.instance.debugReset();

    expect(await PinService.instance.hasPin(), isTrue);
    expect(await PinService.instance.verify('2468'), isTrue);
    expect(await PinService.instance.verify('0000'), isFalse);
    expect(await PreferencesService.instance.loadRaw('parent_pin_salt'), salt);
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

    await tester.tap(find.byTooltip('Гӯш кардан'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
