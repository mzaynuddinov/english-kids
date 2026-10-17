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

  test('adding a student persists and keeps progress separate', () async {
    await StudentService.instance.init();
    final created = await StudentService.instance.addStudent('Али');
    expect(StudentService.instance.students.map((s) => s.name), contains('Али'));
    expect(
      StudentService.instance.learnedKey(created.id),
      isNot(StudentService.instance.learnedKey('default')),
    );

    await PreferencesService.instance.saveSet(
      StudentService.instance.learnedKey('default'),
      {'word-1'},
    );
    await PreferencesService.instance.saveSet(
      StudentService.instance.learnedKey(created.id),
      {'word-2'},
    );

    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    expect(
      StudentService.instance.students.map((s) => s.name),
      containsAll(['Талабаи асосӣ', 'Али']),
    );

    final ali = StudentService.instance.students.firstWhere((s) => s.name == 'Али');
    final def = await PreferencesService.instance.loadSet(
      StudentService.instance.learnedKey('default'),
    );
    final aliLearned = await PreferencesService.instance.loadSet(
      StudentService.instance.learnedKey(ali.id),
    );
    expect(def, {'word-1'});
    expect(aliLearned, {'word-2'});

    await StudentService.instance.renameStudent(ali.id, 'Алишер');
    expect(StudentService.instance.students.any((s) => s.name == 'Алишер'), isTrue);

    await StudentService.instance.setCurrentStudent(ali.id);
    expect(StudentService.instance.currentStudentId, ali.id);

    final beforeDelete = StudentService.instance.students.length;
    await StudentService.instance.deleteStudent(ali.id);
    expect(StudentService.instance.students.length, beforeDelete - 1);
    expect(StudentService.instance.students.any((s) => s.id == ali.id), isFalse);
    expect(StudentService.instance.students, isNotEmpty);
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
