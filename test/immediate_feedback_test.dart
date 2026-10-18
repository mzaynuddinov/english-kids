import 'dart:async';

import 'package:english_kids/models/days.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/services/pin_service.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/reminder_service.dart';
import 'package:english_kids/services/student_service.dart';
import 'package:english_kids/services/word_learning_service.dart';
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

  test('an empty name is rejected without creating a student', () async {
    await StudentService.instance.init();
    final watch = Stopwatch()..start();
    final failed = StudentService.instance.addStudent('   ');
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(200));
    await expectLater(failed, throwsArgumentError);
    expect(StudentService.instance.students, isEmpty);
  });

  test('rename and student switch are visible before storage and roll back on failure', () async {
    await StudentService.instance.init();
    final first = await StudentService.instance.addStudent('Насим');
    final second = await StudentService.instance.addStudent('Ҳадиса');
    expect(StudentService.instance.currentStudentId, first.id);

    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    final renamed = StudentService.instance.renameStudent(first.id, 'Нилуфар');
    expect(StudentService.instance.studentById(first.id)?.name, 'Нилуфар');
    expect(StudentService.instance.studentById(first.id)?.id, first.id);
    final switched = StudentService.instance.setCurrentStudent(second.id);
    expect(StudentService.instance.currentStudentId, second.id);
    gate.complete();
    await renamed;
    await switched;
    expect(StudentService.instance.currentStudentId, second.id);
    expect(StudentService.instance.studentById(first.id)?.name, 'Нилуфар');

    PreferencesService.instance.debugBeforeWrite = null;
    PreferencesService.instance.debugFailWrites = true;
    final failedRename = StudentService.instance.renameStudent(first.id, 'Дигар');
    expect(StudentService.instance.studentById(first.id)?.name, 'Дигар');
    await expectLater(failedRename, throwsStateError);
    expect(StudentService.instance.studentById(first.id)?.name, 'Нилуфар');

    final failedSwitch = StudentService.instance.setCurrentStudent(first.id);
    expect(StudentService.instance.currentStudentId, first.id);
    await expectLater(failedSwitch, throwsStateError);
    expect(StudentService.instance.currentStudentId, second.id);
  });

  test('one student learned flag does not change another student', () async {
    await StudentService.instance.init();
    final first = await StudentService.instance.addStudent('Насим');
    final second = await StudentService.instance.addStudent('Ҳадиса');
    await WordLearningService.instance.openStudent(
      studentId: first.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    expect(await WordLearningService.instance.setFlag(apple.id, learned: true), isTrue);
    await WordLearningService.instance.openStudent(
      studentId: second.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    expect(WordLearningService.instance.studentId, second.id);
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
    await WordLearningService.instance.openStudent(
      studentId: first.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
  });

  test('alphabet progress is visible before storage, and a newer letter wins', () async {
    await StudentService.instance.init();
    final student = await StudentService.instance.addStudent('Насим');
    final key = StudentService.instance.progressKey(student.id);
    await ProgressService.instance.load(key: key);
    await WordLearningService.instance.openStudent(
      studentId: student.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    final letterId = letterLearningId('A');
    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    final withA = ProgressService.instance.snapshot.copyWith(letters: {'A'});
    final watch = Stopwatch()..start();
    final progressWrite = ProgressService.instance.save(withA);
    final flagWrite = WordLearningService.instance.setFlag(letterId, learned: true);
    watch.stop();
    expect(ProgressService.instance.snapshot.letters, contains('A'));
    expect(WordLearningService.instance.of(letterId).learned, isTrue);
    expect(watch.elapsedMilliseconds, lessThan(200));
    var finished = false;
    progressWrite.whenComplete(() => finished = true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(finished, isFalse);
    gate.complete();
    expect(await progressWrite, isTrue);
    expect(await flagWrite, isTrue);

    final older = ProgressService.instance.save(
      ProgressService.instance.snapshot.copyWith(letters: <String>{'A'}),
    );
    final newer = ProgressService.instance.save(
      ProgressService.instance.snapshot.copyWith(letters: <String>{'B'}),
    );
    expect(ProgressService.instance.snapshot.letters, <String>{'B'});
    await older;
    await newer;
    ProgressService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await ProgressService.instance.load(key: key);
    expect(ProgressService.instance.snapshot.letters, <String>{'B'});

    PreferencesService.instance.debugFailWrites = true;
    final failed = ProgressService.instance.save(
      ProgressService.instance.snapshot.copyWith(letters: <String>{}),
    );
    expect(ProgressService.instance.snapshot.letters, isEmpty);
    expect(await failed, isFalse);
    expect(ProgressService.instance.snapshot.letters, contains('B'));
  });

  test('a warm PIN check does not read storage again', () async {
    expect(await PinService.instance.setPin('1234'), isTrue);
    final reads = PreferencesService.instance.prefsReads;
    final watch = Stopwatch()..start();
    final ok = await PinService.instance.verify('1234');
    final wrong = await PinService.instance.verify('0000');
    final short = await PinService.instance.verify('12');
    watch.stop();
    expect(ok, isTrue);
    expect(wrong, isFalse);
    expect(short, isFalse);
    expect(PreferencesService.instance.prefsReads, reads);
    expect(watch.elapsedMilliseconds, lessThan(200));
  });
}
