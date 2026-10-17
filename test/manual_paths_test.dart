import 'dart:io';

import 'package:english_kids/models/alphabet.dart';
import 'package:english_kids/models/days.dart';
import 'package:english_kids/models/study_stats.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/models/word_learning.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/student_service.dart';
import 'package:english_kids/services/vocabulary_service.dart';
import 'package:english_kids/services/word_learning_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Word> words;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
    words = VocabularyService.parseRaw(File('data/vocabulary.json').readAsStringSync()).words;
  });

  test('a fresh install does not invent student names', () async {
    await StudentService.instance.init();
    expect(StudentService.instance.students, isEmpty);
    await expectLater(StudentService.instance.addStudent('   '), throwsArgumentError);
    expect(StudentService.instance.students, isEmpty);
  });

  test('old unscoped progress migrates once and is not seeded again', () async {
    await PreferencesService.instance.saveSet('learned', {'legacy-word'});
    await StudentService.instance.init();
    expect(StudentService.instance.students.map((s) => s.name), ['Маълумоти пештара']);
    expect(StudentService.instance.students.single.id, 'default');
    expect(
      await PreferencesService.instance.loadSet(StudentService.instance.learnedKey('default')),
      {'legacy-word'},
    );

    await StudentService.instance.addStudent('Насим');
    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    await StudentService.instance.init();
    expect(
      StudentService.instance.students.where((s) => s.id == 'default'),
      hasLength(1),
    );
    expect(StudentService.instance.students.map((s) => s.name), contains('Насим'));
  });

  test('letters days and saved words stay on the student who was asked', () async {
    await StudentService.instance.init();
    final nasim = await StudentService.instance.addStudent('Насим');
    final usmon = await StudentService.instance.addStudent('Усмон');
    final apple = words.firstWhere((word) => word.english.toLowerCase() == 'apple');
    final numbers = words.where((word) => word.topic == 'Numbers').toList();
    expect(numbers, isNotEmpty);
    expect(words.where((word) => word.topic == 'Colors'), isNotEmpty);

    await WordLearningService.instance.openStudent(
      studentId: nasim.id,
      vocab: words,
      legacyLearned: {},
      legacySaved: {},
    );
    await WordLearningService.instance.setFlag(letterLearningId('A'), learned: true);
    await WordLearningService.instance.setFlag(letterLearningId('B'), learned: true);
    await WordLearningService.instance.setFlag(letterLearningId('C'), learned: true);
    await WordLearningService.instance.record(weekDays.first.id, OralMark.correct);
    await WordLearningService.instance.setFlag(weekDays.first.id, learned: true);
    await WordLearningService.instance.setFlag(apple.id, learned: true, saved: true);
    final missed = await WordLearningService.instance.record(apple.id, OralMark.unknown);
    expect(missed.learned, isTrue);
    expect(missed.saved, isTrue);
    expect(missed.unknown, 1);
    expect(missed.history, isNotEmpty);

    for (final letter in alphabetLetters) {
      await WordLearningService.instance.setFlag(letterLearningId(letter.letter), learned: true);
    }
    expect(Lexicon.certificateEarned(words, WordLearningService.instance.byId), isFalse);

    await WordLearningService.instance.openStudent(
      studentId: usmon.id,
      vocab: words,
      legacyLearned: {},
      legacySaved: {},
    );
    expect(WordLearningService.instance.of(letterLearningId('A')).learned, isFalse);
    expect(WordLearningService.instance.of(apple.id).saved, isFalse);
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
    expect(WordLearningService.instance.of(weekDays.first.id).quizzed, isFalse);

    var usmonState = WordLearningService.instance.byId;
    for (final word in words) {
      usmonState = Lexicon.withFlag(usmonState, word.id, learned: true);
    }
    expect(Lexicon.certificateEarned(words, usmonState), isTrue);

    WordLearningService.instance.debugReset();
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    await StudentService.instance.init();
    await StudentService.instance.renameStudent(nasim.id, 'Насимхон');
    expect(StudentService.instance.studentById(nasim.id)?.name, 'Насимхон');

    await WordLearningService.instance.openStudent(
      studentId: nasim.id,
      vocab: words,
      legacyLearned: {},
      legacySaved: {},
    );
    expect(WordLearningService.instance.of(letterLearningId('A')).learned, isTrue);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
    expect(WordLearningService.instance.of(apple.id).unknown, 1);
    expect(WordLearningService.instance.of(weekDays.first.id).learned, isTrue);
    expect(Lexicon.certificateEarned(words, WordLearningService.instance.byId), isFalse);

    final stats = ManualStudyStats.compute(
      words: words,
      state: WordLearningService.instance.byId,
      now: DateTime.now(),
    );
    expect(stats.lettersLearned, 26);
    expect(stats.daysLearned, 1);
    expect(stats.numbersTotal, numbers.length);
    expect(stats.todayUnknown, greaterThan(0));

    await WordLearningService.instance.openStudent(
      studentId: usmon.id,
      vocab: words,
      legacyLearned: {},
      legacySaved: {},
    );
    expect(WordLearningService.instance.of(letterLearningId('A')).learned, isFalse);
    expect(Lexicon.certificateEarned(words, WordLearningService.instance.byId), isFalse);
  });
}
