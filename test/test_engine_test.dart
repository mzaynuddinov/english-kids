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

  test('alphabet session is sequential A to Z', () {
    final session = buildAlphabetSession(seed: 7);
    expect(session.questions.length, 26);
    expect(session.questions.first.expected, 'A');
    expect(session.questions.last.expected, 'Z');
    expect(session.kind, TestKind.alphabet);
  });

  test('answersMatch ignores case and extra spaces', () {
    expect(answersMatch('Apple', ' apple '), isTrue);
    expect(answersMatch('Apple', 'banana'), isFalse);
  });

  test('submitAnswer locks the question and does not regenerate', () {
    var session = buildAlphabetSession(seed: 1);
    final firstId = session.questions.first.id;
    session = submitAnswer(session, 'A');
    expect(session.answers.length, 1);
    expect(session.answers.first.correct, isTrue);
    expect(session.index, 1);
    final again = submitAnswer(session.copyWith(index: 0), 'B');
    expect(again.answers.where((a) => a.questionId == firstId).length, 1);
    expect(session.questions[1].id, 'az-1-B');
  });

  test('daily session uses a large pool shown in batches of 5', () {
    final session = buildDailySession(
      words: sample(),
      plan: const TestBlueprint(seed: 11),
    );
    expect(session.questions.length, greaterThan(10));
    expect(session.questions.length, lessThanOrEqualTo(30));
    expect(session.batches, greaterThanOrEqualTo(4));
    expect(session.questions.map((q) => q.id).toSet().length, session.questions.length);
  });

  test('resultFrom counts accuracy and review list', () {
    var session = buildAlphabetSession(seed: 2);
    session = submitAnswer(session, 'A');
    session = submitAnswer(session, 'zzz');
    final result = resultFrom(session);
    expect(result.correct, 1);
    expect(result.review, contains('B'));
  });
}
