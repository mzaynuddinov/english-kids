import 'package:english_kids/models/word.dart';
import 'package:english_kids/pages/quiz_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Word> sample() => const [
        Word(english: 'hello', pronunciation: 'ҳэллоу', tajik: 'салом', week: 1, topic: 'Greetings'),
        Word(english: 'cat', pronunciation: 'кэт', tajik: 'гурба', week: 4, topic: 'Animals'),
        Word(english: 'dog', pronunciation: 'дог', tajik: 'саг', week: 4, topic: 'Animals'),
        Word(english: 'red', pronunciation: 'ред', tajik: 'сурх', week: 2, topic: 'Colors'),
        Word(english: 'blue', pronunciation: 'блу', tajik: 'кабуд', week: 2, topic: 'Colors'),
        Word(english: 'water', pronunciation: 'уотер', tajik: 'об', week: 5, topic: 'Food'),
      ];

  test('builds up to 5 unique questions without duplicate answers', () {
    final quiz = buildQuiz(sample(), count: 5, seed: 3);
    expect(quiz.length, 5);
    final prompts = quiz.map((q) => q.word.english).toSet();
    expect(prompts.length, 5);
    for (final question in quiz) {
      expect(question.options.toSet().length, question.options.length);
      expect(question.options.contains(question.correct), isTrue);
      expect(question.options.length, lessThanOrEqualTo(4));
      expect(question.options.length, greaterThanOrEqualTo(1));
    }
  });

  test('does not crash with tiny or empty vocabulary', () {
    expect(buildQuiz(const []), isEmpty);
    final one = buildQuiz(sample().take(1).toList(), count: 5);
    expect(one.length, 1);
    expect(one.first.options, ['салом']);
  });
}
