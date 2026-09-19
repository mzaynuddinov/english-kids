import 'package:english_kids/models/test_models.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/services/test_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Word> sample() => const [
        Word(english: 'hello', pronunciation: 'ҳэллоу', tajik: 'салом', week: 1, topic: 'Greetings'),
        Word(english: 'cat', pronunciation: 'кэт', tajik: 'гурба', week: 4, topic: 'Animals'),
        Word(english: 'dog', pronunciation: 'дог', tajik: 'саг', week: 4, topic: 'Animals'),
        Word(english: 'red', pronunciation: 'ред', tajik: 'сурх', week: 2, topic: 'Colors'),
        Word(english: 'blue', pronunciation: 'блу', tajik: 'кабуд', week: 2, topic: 'Colors'),
        Word(english: 'water', pronunciation: 'уотер', tajik: 'об', week: 5, topic: 'Food'),
        Word(english: 'apple', pronunciation: 'эпл', tajik: 'себ', week: 5, topic: 'Fruit'),
        Word(english: 'orange', pronunciation: 'оренҷ', tajik: 'норанҷӣ', week: 2, topic: 'Colors'),
        Word(english: 'orange', pronunciation: 'оренҷ', tajik: 'апельсин', week: 5, topic: 'Fruit'),
      ];

  test('alphabet session shuffles A–Z once per seed', () {
    final session = buildAlphabetSession(seed: 7);
    expect(session.questions.length, 26);
    expect(session.questions.map((q) => q.expected).toSet().length, 26);
    expect(session.questions.map((q) => q.expected).toSet(), containsAll(['A', 'Z', 'M']));
    expect(session.kind, TestKind.alphabet);
    final again = buildAlphabetSession(seed: 7);
    expect(again.questions.map((q) => q.expected).toList(), session.questions.map((q) => q.expected).toList());
    final other = buildAlphabetSession(seed: 99);
    expect(other.questions.map((q) => q.expected).join(), isNot(session.questions.map((q) => q.expected).join()));
  });

  test('answersMatch ignores case and extra spaces', () {
    expect(answersMatch('Apple', ' apple '), isTrue);
    expect(answersMatch('Apple', 'banana'), isFalse);
  });

  test('submitAnswer locks the question and does not regenerate', () {
    var session = buildAlphabetSession(seed: 1);
    final first = session.questions.first;
    final firstId = first.id;
    session = submitAnswer(session, first.expected);
    expect(session.answers.length, 1);
    expect(session.answers.first.correct, isTrue);
    expect(session.index, 1);
    final again = submitAnswer(session.copyWith(index: 0), 'B');
    expect(again.answers.where((a) => a.questionId == firstId).length, 1);
    expect(session.questions[1].id, isNot(firstId));
  });

  test('vocabulary session uses only learned words', () {
    final words = sample();
    final learned = {words[0].id, words[1].id, words[2].id};
    final session = buildVocabularySession(
      words: words,
      plan: TestBlueprint(learned: learned, seed: 4),
      count: 25,
    );
    expect(session.questions, isNotEmpty);
    expect(session.questions.length, lessThanOrEqualTo(3));
    expect(session.questions.every((q) => q.wordId != null && learned.contains(q.wordId)), isTrue);
  });

  test('vocabulary session is empty without learned words', () {
    final session = buildVocabularySession(
      words: sample(),
      plan: const TestBlueprint(seed: 2),
    );
    expect(session.questions, isEmpty);
  });

  test('daily session uses a large pool shown in batches of 5', () {
    final words = sample();
    final learned = {for (final w in words) w.id};
    final session = buildDailySession(
      words: words,
      plan: TestBlueprint(learned: learned, seed: 11),
    );
    expect(session.questions.length, greaterThan(10));
    expect(session.questions.length, lessThanOrEqualTo(30));
    expect(session.batches, greaterThanOrEqualTo(4));
    expect(session.questions.map((q) => q.id).toSet().length, session.questions.length);
  });

  test('resultFrom counts accuracy and review list', () {
    var session = buildAlphabetSession(seed: 2);
    final first = session.questions.first.expected;
    final second = session.questions[1].expected;
    session = submitAnswer(session, first);
    session = submitAnswer(session, 'zzz');
    final result = resultFrom(session);
    expect(result.correct, 1);
    expect(result.review, contains(second));
    expect(result.items.length, 26);
    expect(result.items.first.correct, isTrue);
    expect(result.items[1].correct, isFalse);
  });

  test('weighted picker returns unique learned words and can prefer mistakes', () {
    final words = sample().take(4).toList();
    final picked = pickLearnedWeighted(
      learned: words,
      misses: {words[0].id: 6},
      count: 4,
      seed: 3,
    );
    expect(picked.map((w) => w.id).toSet().length, picked.length);
    expect(picked.length, 4);
    expect(picked.map((w) => w.id).toSet(), {for (final w in words) w.id});
  });
}
