class DailyActivity {
  final int opened;
  final int listened;
  final int learned;
  final int tests;
  final int reminders;

  const DailyActivity({
    this.opened = 0,
    this.listened = 0,
    this.learned = 0,
    this.tests = 0,
    this.reminders = 0,
  });

  int get total => opened + listened + learned + tests + reminders;

  DailyActivity add({
    int opened = 0,
    int listened = 0,
    int learned = 0,
    int tests = 0,
    int reminders = 0,
  }) {
    return DailyActivity(
      opened: this.opened + opened,
      listened: this.listened + listened,
      learned: this.learned + learned,
      tests: this.tests + tests,
      reminders: this.reminders + reminders,
    );
  }

  Map<String, dynamic> toJson() => {
        'opened': opened,
        'listened': listened,
        'learned': learned,
        'tests': tests,
        'reminders': reminders,
      };

  static DailyActivity fromJson(Map<String, dynamic> json) {
    int n(String key) => json[key] is num ? (json[key] as num).toInt() : 0;
    return DailyActivity(
      opened: n('opened'),
      listened: n('listened'),
      learned: n('learned'),
      tests: n('tests'),
      reminders: n('reminders'),
    );
  }
}

class WordActivity {
  final int openedCount;
  final int listenedCount;
  final int mistakeCount;
  final int correctCount;
  final int lastOpenedAt;
  final int lastListenedAt;
  final int lastMistakeAt;

  const WordActivity({
    this.openedCount = 0,
    this.listenedCount = 0,
    this.mistakeCount = 0,
    this.correctCount = 0,
    this.lastOpenedAt = 0,
    this.lastListenedAt = 0,
    this.lastMistakeAt = 0,
  });

  WordActivity copyWith({
    int? openedCount,
    int? listenedCount,
    int? mistakeCount,
    int? correctCount,
    int? lastOpenedAt,
    int? lastListenedAt,
    int? lastMistakeAt,
  }) {
    return WordActivity(
      openedCount: openedCount ?? this.openedCount,
      listenedCount: listenedCount ?? this.listenedCount,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      correctCount: correctCount ?? this.correctCount,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastListenedAt: lastListenedAt ?? this.lastListenedAt,
      lastMistakeAt: lastMistakeAt ?? this.lastMistakeAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'openedCount': openedCount,
        'listenedCount': listenedCount,
        'mistakeCount': mistakeCount,
        'correctCount': correctCount,
        'lastOpenedAt': lastOpenedAt,
        'lastListenedAt': lastListenedAt,
        'lastMistakeAt': lastMistakeAt,
      };

  static WordActivity fromJson(Map<String, dynamic> json) {
    int n(String key) => json[key] is num ? (json[key] as num).toInt() : 0;
    return WordActivity(
      openedCount: n('openedCount'),
      listenedCount: n('listenedCount'),
      mistakeCount: n('mistakeCount'),
      correctCount: n('correctCount'),
      lastOpenedAt: n('lastOpenedAt'),
      lastListenedAt: n('lastListenedAt'),
      lastMistakeAt: n('lastMistakeAt'),
    );
  }
}

class MistakeRecord {
  final String wordId;
  final String english;
  final String kind;
  final String given;
  final String expected;
  final int timestamp;
  final int count;

  const MistakeRecord({
    required this.wordId,
    required this.english,
    required this.kind,
    required this.given,
    required this.expected,
    required this.timestamp,
    this.count = 1,
  });

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'english': english,
        'kind': kind,
        'given': given,
        'expected': expected,
        'timestamp': timestamp,
        'count': count,
      };

  static MistakeRecord? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    try {
      return MistakeRecord(
        wordId: '${raw['wordId'] ?? ''}',
        english: '${raw['english'] ?? ''}',
        kind: '${raw['kind'] ?? ''}',
        given: '${raw['given'] ?? ''}',
        expected: '${raw['expected'] ?? ''}',
        timestamp: raw['timestamp'] is num ? (raw['timestamp'] as num).toInt() : 0,
        count: raw['count'] is num ? (raw['count'] as num).toInt() : 1,
      );
    } catch (_) {
      return null;
    }
  }
}

class ReviewLine {
  final String prompt;
  final String given;
  final String expected;
  final bool correct;

  const ReviewLine({
    required this.prompt,
    required this.given,
    required this.expected,
    required this.correct,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'given': given,
        'expected': expected,
        'correct': correct,
      };

  static ReviewLine fromJson(Map<String, dynamic> json) {
    return ReviewLine(
      prompt: '${json['prompt'] ?? ''}',
      given: '${json['given'] ?? ''}',
      expected: '${json['expected'] ?? ''}',
      correct: json['correct'] == true,
    );
  }
}
