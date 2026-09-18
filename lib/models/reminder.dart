class WordReminder {
  final String id;
  final String wordId;
  final String english;
  final String tajik;
  final String pronunciation;
  final int intervalMs;
  final int repeatTotal;
  final int completed;
  final int nextAt;
  final int createdAt;
  final bool paused;
  final bool finished;
  final List<int> notificationIds;

  const WordReminder({
    required this.id,
    required this.wordId,
    required this.english,
    required this.tajik,
    required this.pronunciation,
    required this.intervalMs,
    required this.repeatTotal,
    this.completed = 0,
    required this.nextAt,
    required this.createdAt,
    this.paused = false,
    this.finished = false,
    this.notificationIds = const [],
  });

  String get intervalLabel {
    if (intervalMs < 60000) return '${intervalMs ~/ 1000} сония';
    if (intervalMs < 3600000) return '${intervalMs ~/ 60000} дақиқа';
    return '${intervalMs ~/ 3600000} соат';
  }

  WordReminder copyWith({
    int? completed,
    int? nextAt,
    bool? paused,
    bool? finished,
    List<int>? notificationIds,
  }) {
    return WordReminder(
      id: id,
      wordId: wordId,
      english: english,
      tajik: tajik,
      pronunciation: pronunciation,
      intervalMs: intervalMs,
      repeatTotal: repeatTotal,
      completed: completed ?? this.completed,
      nextAt: nextAt ?? this.nextAt,
      createdAt: createdAt,
      paused: paused ?? this.paused,
      finished: finished ?? this.finished,
      notificationIds: notificationIds ?? this.notificationIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wordId': wordId,
        'english': english,
        'tajik': tajik,
        'pronunciation': pronunciation,
        'intervalMs': intervalMs,
        'repeatTotal': repeatTotal,
        'completed': completed,
        'nextAt': nextAt,
        'createdAt': createdAt,
        'paused': paused,
        'finished': finished,
        'notificationIds': notificationIds,
      };

  static WordReminder? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    try {
      return WordReminder(
        id: '${raw['id'] ?? ''}',
        wordId: '${raw['wordId'] ?? ''}',
        english: '${raw['english'] ?? ''}',
        tajik: '${raw['tajik'] ?? ''}',
        pronunciation: '${raw['pronunciation'] ?? ''}',
        intervalMs: raw['intervalMs'] is num ? (raw['intervalMs'] as num).toInt() : 60000,
        repeatTotal: raw['repeatTotal'] is num ? (raw['repeatTotal'] as num).toInt() : 1,
        completed: raw['completed'] is num ? (raw['completed'] as num).toInt() : 0,
        nextAt: raw['nextAt'] is num ? (raw['nextAt'] as num).toInt() : 0,
        createdAt: raw['createdAt'] is num ? (raw['createdAt'] as num).toInt() : 0,
        paused: raw['paused'] == true,
        finished: raw['finished'] == true,
        notificationIds: (raw['notificationIds'] as List?)
                ?.whereType<num>()
                .map((e) => e.toInt())
                .toList() ??
            const [],
      );
    } catch (_) {
      return null;
    }
  }
}

class ReminderPlan {
  final Duration interval;
  final int repeats;
  const ReminderPlan({required this.interval, required this.repeats});
}
