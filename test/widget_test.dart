import 'dart:io';

import 'package:english_kids/app.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/reminder_service.dart';
import 'package:english_kids/services/student_service.dart';
import 'package:english_kids/services/vocabulary_service.dart';
import 'package:english_kids/services/word_learning_service.dart';
import 'package:english_kids/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ReminderService.suppressTimersForTests = true;
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
    VocabularyService.debugLoader = () async {
      final raw = File('data/vocabulary.json').readAsStringSync();
      return VocabularyService.parseRaw(raw);
    };
  });

  tearDown(() {
    VocabularyService.debugReset();
    ReminderService.instance.cancelAllTimers();
    ReminderService.suppressTimersForTests = false;
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
  });

  test('reminder service can be cancelled', () {
    ReminderService.instance.cancelAllTimers();
    expect(ReminderService.suppressTimersForTests, isTrue);
  });

  test('students are added only by name and stay separate', () async {
    await StudentService.instance.init();
    expect(StudentService.instance.students, isEmpty);
    expect(StudentService.instance.currentStudentId, isNull);

    final nasim = await StudentService.instance.addStudent('Насим');
    final usmon = await StudentService.instance.addStudent('Усмон');
    expect(nasim.id, isNot(usmon.id));
    expect(StudentService.instance.students.map((s) => s.name), ['Насим', 'Усмон']);
    expect(StudentService.instance.currentStudentId, nasim.id);
    expect(
      StudentService.instance.learnedKey(nasim.id),
      isNot(StudentService.instance.learnedKey(usmon.id)),
    );

    await PreferencesService.instance.saveSet(
      StudentService.instance.learnedKey(nasim.id),
      {'word-1'},
    );
    await PreferencesService.instance.saveSet(
      StudentService.instance.learnedKey(usmon.id),
      {'word-2'},
    );

    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.students.map((s) => s.name), ['Насим', 'Усмон']);
    expect(
      StudentService.instance.students.any((s) => s.name == 'Талабаи асосӣ'),
      isFalse,
    );

    final restored = StudentService.instance.students.firstWhere((s) => s.name == 'Насим');
    expect(restored.id, nasim.id);
    expect(
      await PreferencesService.instance.loadSet(StudentService.instance.learnedKey(nasim.id)),
      {'word-1'},
    );
    expect(
      await PreferencesService.instance.loadSet(StudentService.instance.learnedKey(usmon.id)),
      {'word-2'},
    );

    await StudentService.instance.renameStudent(nasim.id, 'Насими нав');
    expect(StudentService.instance.studentById(nasim.id)?.name, 'Насими нав');
    expect(
      await PreferencesService.instance.loadSet(StudentService.instance.learnedKey(nasim.id)),
      {'word-1'},
    );

    await StudentService.instance.deleteStudent(nasim.id);
    await StudentService.instance.deleteStudent(usmon.id);
    expect(StudentService.instance.students, isEmpty);
    expect(StudentService.instance.currentStudentId, isNull);
  });

  testWidgets('first frame shows the app name on a light screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EnglishKidsApp());
    await tester.pump();

    expect(find.text(appName), findsWidgets);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(appName), findsWidgets);
    expect(find.text('Мушкилоти муваққатӣ ба вуҷуд омад.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(seconds: 20)));
}
