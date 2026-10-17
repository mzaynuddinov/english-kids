import 'dart:io';

import 'package:english_kids/models/word.dart';
import 'package:english_kids/models/word_learning.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/vocabulary_service.dart';
import 'package:english_kids/services/word_learning_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Word> words;
  late Word apple;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();
    WordLearningService.instance.debugReset();
    words = VocabularyService.parseRaw(File('data/vocabulary.json').readAsStringSync()).words;
    apple = words.firstWhere((word) => word.english.toLowerCase() == 'apple');
  });

  test('every student can be asked the full 500-word vocabulary', () {
    expect(words, hasLength(500));
    expect(words.map((word) => word.id).toSet(), hasLength(500));
    final now = DateTime(2026, 10, 17, 9);
    const ali = <String, WordLearning>{};
    const madina = <String, WordLearning>{};
    expect(Lexicon.select(OralScope.all, words, ali, now), hasLength(500));
    expect(Lexicon.select(OralScope.all, words, madina, now), hasLength(500));
    expect(Lexicon.select(OralScope.unlearned, words, ali, now), hasLength(500));
    expect(Lexicon.select(OralScope.notToday, words, madina, now), hasLength(500));
  });

  test('word state, mistakes, saved list and history stay on one student', () {
    final now = DateTime(2026, 10, 17, 9, 15);
    var ali = <String, WordLearning>{};
    var madina = <String, WordLearning>{};
    var yusuf = <String, WordLearning>{};

    ali = Lexicon.record(ali, apple.id, OralMark.incorrect, at: now.millisecondsSinceEpoch);
    ali = Lexicon.record(ali, apple.id, OralMark.unknown, at: now.millisecondsSinceEpoch + 1000);
    ali = Lexicon.withFlag(ali, apple.id, learned: false, saved: true);
    madina = Lexicon.record(madina, apple.id, OralMark.correct, at: now.millisecondsSinceEpoch + 2000);

    final aliApple = Lexicon.of(ali, apple.id);
    expect(aliApple.incorrect, 1);
    expect(aliApple.unknown, 1);
    expect(aliApple.correct, 0);
    expect(aliApple.saved, isTrue);
    expect(aliApple.learned, isFalse);
    expect(aliApple.history, hasLength(2));
    expect(aliApple.lastQuizAt, now.millisecondsSinceEpoch + 1000);
    expect(aliApple.previouslyWrong, isTrue);
    expect(aliApple.repetitions, 2);

    expect(Lexicon.of(madina, apple.id).correct, 1);
    expect(Lexicon.of(madina, apple.id).incorrect, 0);
    expect(Lexicon.of(madina, apple.id).saved, isFalse);
    expect(Lexicon.of(madina, apple.id).lastCorrectAt, now.millisecondsSinceEpoch + 2000);
    expect(Lexicon.of(yusuf, apple.id).quizzed, isFalse);
    expect(Lexicon.of(yusuf, apple.id).asked, 0);

    expect(Lexicon.select(OralScope.saved, words, ali, now).map((word) => word.id), [apple.id]);
    expect(Lexicon.select(OralScope.saved, words, madina, now), isEmpty);
    expect(Lexicon.select(OralScope.wrong, words, ali, now).map((word) => word.id), [apple.id]);
    expect(Lexicon.select(OralScope.wrong, words, madina, now), isEmpty);
    expect(Lexicon.select(OralScope.notToday, words, ali, now), hasLength(499));
    expect(Lexicon.select(OralScope.notToday, words, yusuf, now), hasLength(500));

    final summary = Lexicon.summary(words, ali);
    expect(summary.total, 500);
    expect(summary.learned, 0);
    expect(summary.unlearned, 500);
    expect(summary.saved, 1);
    expect(summary.wrong, 1);
    expect(summary.untested, 499);
  });

  test('a learned mark and the certificate belong only to that student', () {
    final oranges = words.where((word) => word.english.toLowerCase() == 'orange').toList();
    expect(oranges.length, greaterThan(1));

    final byName = Lexicon.migrate(words: words, learnedKeys: {'orange'}, savedKeys: {});
    for (final orange in oranges) {
      expect(Lexicon.of(byName, orange.id).learned, isFalse, reason: 'a shared name is not a word id');
    }

    var ali = Lexicon.migrate(words: words, learnedKeys: {apple.id, oranges.first.id}, savedKeys: {});
    final madina = Lexicon.migrate(words: words, learnedKeys: <String>{}, savedKeys: {});
    expect(Lexicon.of(ali, apple.id).learned, isTrue);
    expect(Lexicon.of(ali, oranges.first.id).learned, isTrue);
    expect(Lexicon.of(ali, oranges.last.id).learned, isFalse);
    expect(Lexicon.of(madina, apple.id).learned, isFalse);

    expect(Lexicon.certificateEarned(words, ali), isFalse);
    for (final word in words) {
      ali = Lexicon.withFlag(ali, word.id, learned: true);
    }
    expect(Lexicon.summary(words, ali).learned, 500);
    expect(Lexicon.summary(words, ali).learnedFraction, 1);
    expect(Lexicon.certificateEarned(words, ali), isTrue);
    expect(Lexicon.certificateEarned(words, madina), isFalse);
    expect(Lexicon.select(OralScope.learned, words, ali, DateTime(2026, 10, 17)), hasLength(500));
    expect(Lexicon.select(OralScope.learned, words, madina, DateTime(2026, 10, 17)), isEmpty);
  });

  test('saved answers remain after the service memory is cleared', () async {
    final when = DateTime(2026, 10, 17, 18, 45);
    await WordLearningService.instance.openStudent(
      studentId: 'ali',
      vocab: words,
      legacyLearned: {apple.id},
      legacySaved: {},
    );
    await WordLearningService.instance.record(apple.id, OralMark.incorrect, at: when);
    await WordLearningService.instance.record(
      apple.id,
      OralMark.unknown,
      at: when.add(const Duration(minutes: 5)),
    );

    expect(await PreferencesService.instance.loadSet('learned_ali'), contains(apple.id));
    expect(await PreferencesService.instance.loadSet('saved_ali'), contains(apple.id));

    WordLearningService.instance.debugReset();
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();

    await WordLearningService.instance.openStudent(
      studentId: 'ali',
      vocab: words,
      legacyLearned: {},
      legacySaved: {},
    );
    final restored = WordLearningService.instance.of(apple.id);
    expect(restored.learned, isTrue);
    expect(restored.saved, isTrue);
    expect(restored.incorrect, 1);
    expect(restored.unknown, 1);
    expect(restored.history, hasLength(2));
    expect(restored.lastQuizAt, when.add(const Duration(minutes: 5)).millisecondsSinceEpoch);

    await WordLearningService.instance.openStudent(
      studentId: 'madina',
      vocab: words,
      legacyLearned: {},
      legacySaved: {},
    );
    expect(WordLearningService.instance.of(apple.id).quizzed, isFalse);
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
    expect(WordLearningService.instance.learnedIds(), isEmpty);
    expect(await PreferencesService.instance.loadSet('learned_ali'), contains(apple.id));
  });
}
