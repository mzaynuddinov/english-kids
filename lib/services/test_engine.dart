import '../models/alphabet.dart';
import '../models/test_models.dart';
import '../models/word.dart';

class TestBlueprint {
  final Set<String> learned;
  final Set<String> saved;
  final Map<String, int> misses;
  final int seed;

  const TestBlueprint({
    this.learned = const {},
    this.saved = const {},
    this.misses = const {},
    this.seed = 1,
  });
}

int _mix(int a, int b) => (a * 1103515245 + b + 12345) & 0x7fffffff;

List<T> _shuffled<T>(List<T> input, int seed) {
  final list = [...input];
  var s = seed == 0 ? 1 : seed;
  for (var i = list.length - 1; i > 0; i--) {
    s = _mix(s, i);
    final j = s % (i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}

List<String> _choices(String correct, List<String> pool, int seed, {int count = 4}) {
  final others = pool.where((p) => p != correct).toList();
  final picked = _shuffled(others, seed).take(count - 1).toList();
  return _shuffled([correct, ...picked], seed + 9);
}

TestQuestion _listenType(Word word, int i) {
  return TestQuestion(
    id: 'lt-$i-${word.id}',
    kind: QuestionKind.listenType,
    prompt: 'Гӯш кун ва калимаро нависед',
    speakText: word.english,
    expected: word.english,
    hint: word.tajik,
    wordId: word.id,
  );
}

TestQuestion _tajikType(Word word, int i) {
  return TestQuestion(
    id: 'tt-$i-${word.id}',
    kind: QuestionKind.tajikType,
    prompt: 'Ба англисӣ нависед',
    speakText: word.english,
    expected: word.english,
    hint: word.tajik,
    wordId: word.id,
  );
}

TestQuestion _englishChoice(Word word, List<String> meanings, int i, int seed) {
  return TestQuestion(
    id: 'ec-$i-${word.id}',
    kind: QuestionKind.englishChoice,
    prompt: 'Маънои тоҷикиро интихоб кунед',
    speakText: word.english,
    expected: word.tajik,
    options: _choices(word.tajik, meanings, seed + i),
    wordId: word.id,
  );
}

TestQuestion _listenChoice(Word word, List<String> english, int i, int seed) {
  return TestQuestion(
    id: 'lc-$i-${word.id}',
    kind: QuestionKind.listenChoice,
    prompt: 'Гӯш кун ва калимаи дурустро интихоб кунед',
    speakText: word.english,
    expected: word.displayEnglish,
    options: _choices(word.displayEnglish, english, seed + i),
    wordId: word.id,
  );
}

List<Word> _unique(List<Word> words) {
  final seen = <String>{};
  return [for (final w in words) if (seen.add(w.id)) w];
}

TestSession buildAlphabetSession({int seed = 1}) {
  final letters = alphabetLetters;
  final questions = [
    for (var i = 0; i < letters.length; i++)
      TestQuestion(
        id: 'az-$i-${letters[i].letter}',
        kind: QuestionKind.listenType,
        prompt: 'Ҳарфро гӯш кунед ва нависед',
        speakText: letters[i].letter,
        expected: letters[i].letter,
        emoji: letters[i].emoji,
        letter: letters[i].letter,
        hint: '${letters[i].word} — ${letters[i].tajik}',
      ),
  ];
  return TestSession(
    id: 'alpha-$seed-${DateTime.now().millisecondsSinceEpoch}',
    kind: TestKind.alphabet,
    questions: questions,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

TestSession buildVocabularySession({
  required List<Word> words,
  required TestBlueprint plan,
  int count = 24,
}) {
  final pool = _unique(words);
  if (pool.isEmpty) {
    return TestSession(
      id: 'empty',
      kind: TestKind.vocabulary,
      questions: const [],
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
  final meanings = pool.map((w) => w.tajik).toSet().toList()..sort();
  final english = pool.map((w) => w.displayEnglish).toSet().toList()..sort();
  final hard = [...pool]..sort((a, b) => (plan.misses[b.id] ?? 0).compareTo(plan.misses[a.id] ?? 0));
  final saved = pool.where((w) => w.isMarked(plan.saved)).toList();
  final learned = pool.where((w) => w.isMarked(plan.learned)).toList();
  final fresh = pool.where((w) => !w.isMarked(plan.learned)).toList();
  final buckets = [
    ..._shuffled(fresh, plan.seed),
    ..._shuffled(hard.take(8).toList(), plan.seed + 1),
    ..._shuffled(saved, plan.seed + 2),
    ..._shuffled(learned, plan.seed + 3),
    ..._shuffled(pool, plan.seed + 4),
  ];
  final picked = _unique(buckets).take(count.clamp(1, pool.length)).toList();
  final questions = <TestQuestion>[];
  for (var i = 0; i < picked.length; i++) {
    final word = picked[i];
    switch (i % 4) {
      case 0:
        questions.add(_listenType(word, i));
      case 1:
        questions.add(_tajikType(word, i));
      case 2:
        questions.add(_englishChoice(word, meanings, i, plan.seed));
      default:
        questions.add(_listenChoice(word, english, i, plan.seed));
    }
  }
  return TestSession(
    id: 'vocab-${plan.seed}-${DateTime.now().millisecondsSinceEpoch}',
    kind: TestKind.vocabulary,
    questions: questions,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

TestSession buildDailySession({
  required List<Word> words,
  required TestBlueprint plan,
  int count = 30,
}) {
  final vocab = buildVocabularySession(words: words, plan: plan, count: 20);
  final letters = _shuffled(alphabetLetters, plan.seed).take(10).toList();
  final alpha = [
    for (var i = 0; i < letters.length; i++)
      TestQuestion(
        id: 'd-az-$i-${letters[i].letter}',
        kind: QuestionKind.listenType,
        prompt: 'Ҳарфро гӯш кунед ва нависед',
        speakText: letters[i].letter,
        expected: letters[i].letter,
        emoji: letters[i].emoji,
        letter: letters[i].letter,
        hint: letters[i].word,
      ),
  ];
  final mixed = _shuffled([...vocab.questions, ...alpha], plan.seed + 11).take(count).toList();
  return TestSession(
    id: 'daily-${plan.seed}-${DateTime.now().millisecondsSinceEpoch}',
    kind: TestKind.daily,
    questions: mixed,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

TestSession submitAnswer(TestSession session, String given) {
  if (session.completed || session.index >= session.questions.length) return session;
  final question = session.questions[session.index];
  if (session.answers.any((a) => a.questionId == question.id)) return session;
  final correct = answersMatch(question.expected, given);
  final answers = [
    ...session.answers,
    AnswerRecord(
      questionId: question.id,
      given: given,
      correct: correct,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  ];
  final nextIndex = session.index + 1;
  return session.copyWith(
    answers: answers,
    index: nextIndex >= session.questions.length ? session.index : nextIndex,
    completed: nextIndex >= session.questions.length,
  );
}

TestResult resultFrom(TestSession session) {
  final review = <String>[];
  for (final answer in session.answers.where((a) => !a.correct)) {
    final q = session.questions.where((item) => item.id == answer.questionId);
    if (q.isEmpty) continue;
    review.add(q.first.expected);
  }
  return TestResult(
    id: session.id,
    kind: session.kind,
    createdAt: session.createdAt,
    total: session.questions.length,
    correct: session.correctCount,
    review: review.toSet().toList(),
  );
}
