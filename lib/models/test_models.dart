import 'activity.dart';

enum TestKind { alphabet, vocabulary, daily }

enum QuestionKind { listenType, tajikType, englishChoice, listenChoice, match, sentenceChoice }

class TestQuestion {
  final String id;
  final QuestionKind kind;
  final String prompt;
  final String speakText;
  final String expected;
  final List<String> options;
  final String? hint;
  final String? emoji;
  final String? wordId;
  final String? letter;

  const TestQuestion({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.speakText,
    required this.expected,
    this.options = const [],
    this.hint,
    this.emoji,
    this.wordId,
    this.letter,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'prompt': prompt,
        'speakText': speakText,
        'expected': expected,
        'options': options,
        'hint': hint,
        'emoji': emoji,
        'wordId': wordId,
        'letter': letter,
      };

  static TestQuestion fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: '${json['id'] ?? ''}',
      kind: QuestionKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => QuestionKind.englishChoice,
      ),
      prompt: '${json['prompt'] ?? ''}',
      speakText: '${json['speakText'] ?? ''}',
      expected: '${json['expected'] ?? ''}',
      options: (json['options'] as List?)?.map((e) => '$e').toList() ?? const [],
      hint: json['hint'] as String?,
      emoji: json['emoji'] as String?,
      wordId: json['wordId'] as String?,
      letter: json['letter'] as String?,
    );
  }
}

class AnswerRecord {
  final String questionId;
  final String given;
  final bool correct;
  final int timestamp;

  const AnswerRecord({
    required this.questionId,
    required this.given,
    required this.correct,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'given': given,
        'correct': correct,
        'timestamp': timestamp,
      };

  static AnswerRecord fromJson(Map<String, dynamic> json) {
    return AnswerRecord(
      questionId: '${json['questionId'] ?? ''}',
      given: '${json['given'] ?? ''}',
      correct: json['correct'] == true,
      timestamp: json['timestamp'] is num ? (json['timestamp'] as num).toInt() : 0,
    );
  }
}

class TestSession {
  final String id;
  final TestKind kind;
  final List<TestQuestion> questions;
  final List<AnswerRecord> answers;
  final int index;
  final int createdAt;
  final bool completed;

  const TestSession({
    required this.id,
    required this.kind,
    required this.questions,
    this.answers = const [],
    this.index = 0,
    required this.createdAt,
    this.completed = false,
  });

  int get total => questions.length;
  int get correctCount => answers.where((a) => a.correct).length;
  int get batch => (index ~/ 5) + 1;
  int get batches => (total + 4) ~/ 5;
  String get kindLabel {
    switch (kind) {
      case TestKind.alphabet:
        return 'Алифбо';
      case TestKind.vocabulary:
        return 'Калимаҳо';
      case TestKind.daily:
        return 'Мушкилоти имрӯз';
    }
  }
  bool get isLockedCurrent {
    if (index >= questions.length) return true;
    final id = questions[index].id;
    return answers.any((a) => a.questionId == id);
  }

  TestSession copyWith({
    List<AnswerRecord>? answers,
    int? index,
    bool? completed,
  }) {
    return TestSession(
      id: id,
      kind: kind,
      questions: questions,
      answers: answers ?? this.answers,
      index: index ?? this.index,
      createdAt: createdAt,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': answers.map((a) => a.toJson()).toList(),
        'index': index,
        'createdAt': createdAt,
        'completed': completed,
      };

  static TestSession fromJson(Map<String, dynamic> json) {
    return TestSession(
      id: '${json['id'] ?? ''}',
      kind: TestKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => TestKind.daily,
      ),
      questions: (json['questions'] as List? ?? [])
          .whereType<Map>()
          .map((e) => TestQuestion.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      answers: (json['answers'] as List? ?? [])
          .whereType<Map>()
          .map((e) => AnswerRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      index: json['index'] is num ? (json['index'] as num).toInt() : 0,
      createdAt: json['createdAt'] is num ? (json['createdAt'] as num).toInt() : 0,
      completed: json['completed'] == true,
    );
  }
}

class TestResult {
  final String id;
  final TestKind kind;
  final int createdAt;
  final int total;
  final int correct;
  final List<String> review;
  final List<ReviewLine> items;

  const TestResult({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.total,
    required this.correct,
    this.review = const [],
    this.items = const [],
  });

  int get incorrect => total - correct;
  int get accuracy => total == 0 ? 0 : ((correct / total) * 100).round();

  String get kindLabel {
    switch (kind) {
      case TestKind.alphabet:
        return 'Алифбо';
      case TestKind.vocabulary:
        return 'Калимаҳо';
      case TestKind.daily:
        return 'Мушкилоти имрӯз';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'createdAt': createdAt,
        'total': total,
        'correct': correct,
        'review': review,
        'items': items.map((e) => e.toJson()).toList(),
      };

  static TestResult fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: '${json['id'] ?? ''}',
      kind: TestKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => TestKind.daily,
      ),
      createdAt: json['createdAt'] is num ? (json['createdAt'] as num).toInt() : 0,
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
      correct: json['correct'] is num ? (json['correct'] as num).toInt() : 0,
      review: (json['review'] as List?)?.map((e) => '$e').toList() ?? const [],
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ReviewLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

String normalizeAnswer(String raw) {
  var value = raw.trim().toLowerCase();
  value = value.replaceAll(RegExp(r'''[.,!?;:'"«»]'''), '');
  value = value.replaceAll(RegExp(r'\s+'), ' ');
  return value;
}

bool answersMatch(String expected, String given) {
  return normalizeAnswer(expected) == normalizeAnswer(given);
}
