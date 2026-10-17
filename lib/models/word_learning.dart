import 'word.dart';

/// Oral quiz mark recorded by the parent. The child is not asked to type.
enum OralMark { correct, incorrect, unknown }

enum OralScope { all, unlearned, learned, saved, wrong, notToday }

String wordLearningKey(String studentId) => 'word_learning_v1_$studentId';

class OralAttempt {
  final int at;
  final OralMark mark;

  const OralAttempt({required this.at, required this.mark});

  Map<String, dynamic> toJson() => {'at': at, 'mark': mark.name};

  static OralAttempt? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final at = raw['at'];
    final name = '${raw['mark'] ?? ''}';
    OralMark? mark;
    for (final value in OralMark.values) {
      if (value.name == name) mark = value;
    }
    if (mark == null || at is! num) return null;
    return OralAttempt(at: at.toInt(), mark: mark);
  }
}

class WordLearning {
  final bool learned;
  final bool saved;
  final int correct;
  final int incorrect;
  final int unknown;
  final int repetitions;
  final int? lastQuizAt;
  final int? lastCorrectAt;
  final List<OralAttempt> history;

  const WordLearning({
    this.learned = false,
    this.saved = false,
    this.correct = 0,
    this.incorrect = 0,
    this.unknown = 0,
    this.repetitions = 0,
    this.lastQuizAt,
    this.lastCorrectAt,
    this.history = const [],
  });

  bool get quizzed => lastQuizAt != null && lastQuizAt! > 0;

  bool get previouslyWrong => incorrect > 0 || unknown > 0;

  int get asked => correct + incorrect + unknown;

  bool get hasState =>
      learned || saved || quizzed || history.isNotEmpty || asked > 0;

  WordLearning copyWith({
    bool? learned,
    bool? saved,
    int? correct,
    int? incorrect,
    int? unknown,
    int? repetitions,
    int? lastQuizAt,
    int? lastCorrectAt,
    List<OralAttempt>? history,
  }) {
    return WordLearning(
      learned: learned ?? this.learned,
      saved: saved ?? this.saved,
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      unknown: unknown ?? this.unknown,
      repetitions: repetitions ?? this.repetitions,
      lastQuizAt: lastQuizAt ?? this.lastQuizAt,
      lastCorrectAt: lastCorrectAt ?? this.lastCorrectAt,
      history: history ?? this.history,
    );
  }

  WordLearning apply({
    bool? learned,
    bool? saved,
    OralMark? mark,
    int? at,
    int historyLimit = 40,
  }) {
    var next = this;
    if (learned != null) next = next.copyWith(learned: learned);
    if (saved != null) next = next.copyWith(saved: saved);
    if (mark != null) {
      final when = at ?? 0;
      final history = [...next.history, OralAttempt(at: when, mark: mark)];
      final trimmed = history.length > historyLimit
          ? history.sublist(history.length - historyLimit)
          : history;
      next = next.copyWith(
        correct: next.correct + (mark == OralMark.correct ? 1 : 0),
        incorrect: next.incorrect + (mark == OralMark.incorrect ? 1 : 0),
        unknown: next.unknown + (mark == OralMark.unknown ? 1 : 0),
        repetitions: next.repetitions + 1,
        lastQuizAt: when,
        lastCorrectAt: mark == OralMark.correct ? when : next.lastCorrectAt,
        saved: mark == OralMark.unknown ? true : next.saved,
        history: trimmed,
      );
    }
    return next;
  }

  Map<String, dynamic> toJson() => {
        'learned': learned,
        'saved': saved,
        'correct': correct,
        'incorrect': incorrect,
        'unknown': unknown,
        'repetitions': repetitions,
        'lastQuizAt': lastQuizAt,
        'lastCorrectAt': lastCorrectAt,
        'history': history.map((e) => e.toJson()).toList(),
      };

  static WordLearning fromJson(Map<String, dynamic> json) {
    int n(String key) => json[key] is num ? (json[key] as num).toInt() : 0;
    int? stamp(String key) {
      final value = json[key];
      if (value is! num || value <= 0) return null;
      return value.toInt();
    }

    return WordLearning(
      learned: json['learned'] == true,
      saved: json['saved'] == true,
      correct: n('correct'),
      incorrect: n('incorrect'),
      unknown: n('unknown'),
      repetitions: n('repetitions'),
      lastQuizAt: stamp('lastQuizAt'),
      lastCorrectAt: stamp('lastCorrectAt'),
      history: (json['history'] as List? ?? [])
          .map(OralAttempt.tryParse)
          .whereType<OralAttempt>()
          .toList(),
    );
  }
}

class LexiconSummary {
  final int total;
  final int learned;
  final int unlearned;
  final int saved;
  final int wrong;
  final int untested;

  const LexiconSummary({
    required this.total,
    required this.learned,
    required this.unlearned,
    required this.saved,
    required this.wrong,
    required this.untested,
  });

  double get learnedFraction => total == 0 ? 0 : learned / total;
}

class Lexicon {
  static WordLearning of(Map<String, WordLearning> state, String wordId) =>
      state[wordId] ?? const WordLearning();

  static Map<String, WordLearning> record(
    Map<String, WordLearning> state,
    String wordId,
    OralMark mark, {
    required int at,
  }) {
    if (wordId.isEmpty) return state;
    return {
      ...state,
      wordId: of(state, wordId).apply(mark: mark, at: at),
    };
  }

  static Map<String, WordLearning> withFlag(
    Map<String, WordLearning> state,
    String wordId, {
    bool? learned,
    bool? saved,
  }) {
    if (wordId.isEmpty) return state;
    final next = of(state, wordId).apply(learned: learned, saved: saved);
    if (!next.hasState) {
      final copy = {...state}..remove(wordId);
      return copy;
    }
    return {...state, wordId: next};
  }

  static bool _sameDay(int? at, DateTime now) {
    if (at == null || at <= 0) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(at);
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool matches(OralScope scope, WordLearning record, DateTime now) {
    switch (scope) {
      case OralScope.all:
        return true;
      case OralScope.unlearned:
        return !record.learned;
      case OralScope.learned:
        return record.learned;
      case OralScope.saved:
        return record.saved;
      case OralScope.wrong:
        return record.previouslyWrong;
      case OralScope.notToday:
        return !_sameDay(record.lastQuizAt, now);
    }
  }

  static List<Word> select(
    OralScope scope,
    List<Word> words,
    Map<String, WordLearning> state,
    DateTime now,
  ) {
    return [
      for (final word in words)
        if (word.id.isNotEmpty && matches(scope, of(state, word.id), now)) word,
    ];
  }

  static LexiconSummary summary(List<Word> words, Map<String, WordLearning> state) {
    var learned = 0;
    var saved = 0;
    var wrong = 0;
    var untested = 0;
    final seen = <String>{};
    for (final word in words) {
      if (!seen.add(word.id)) continue;
      final record = of(state, word.id);
      if (record.learned) learned += 1;
      if (record.saved) saved += 1;
      if (record.previouslyWrong) wrong += 1;
      if (!record.quizzed) untested += 1;
    }
    return LexiconSummary(
      total: seen.length,
      learned: learned,
      unlearned: seen.length - learned,
      saved: saved,
      wrong: wrong,
      untested: untested,
    );
  }

  /// Certificate requires every vocabulary id to be learned for this student.
  /// A shared English name is not enough, and another student's map is ignored.
  static bool certificateEarned(List<Word> words, Map<String, WordLearning> state) {
    if (words.length != 500) return false;
    final seen = <String>{};
    for (final word in words) {
      if (word.id.isEmpty || !seen.add(word.id)) return false;
      if (!of(state, word.id).learned) return false;
    }
    return seen.length == 500;
  }

  /// Copies legacy learned/saved keys into per-word records.
  /// A bare English name is used only when exactly one word has that name.
  static Map<String, WordLearning> migrate({
    required List<Word> words,
    required Set<String> learnedKeys,
    required Set<String> savedKeys,
    Map<String, WordLearning>? existing,
  }) {
    final byId = <String, Word>{};
    final nameCount = <String, int>{};
    for (final word in words) {
      if (word.id.isEmpty) continue;
      byId[word.id] = word;
      final name = word.english.trim().toLowerCase();
      nameCount[name] = (nameCount[name] ?? 0) + 1;
    }
    final uniqueName = <String, String>{};
    for (final word in byId.values) {
      final name = word.english.trim().toLowerCase();
      if (nameCount[name] == 1) uniqueName[name] = word.id;
    }

    String? resolve(String key) {
      if (byId.containsKey(key)) return key;
      return uniqueName[key.trim().toLowerCase()];
    }

    final next = {...?existing};
    void applyKeys(Set<String> keys, {required bool learned, required bool saved}) {
      for (final key in keys) {
        final id = resolve(key);
        if (id == null) continue;
        next[id] = of(next, id).apply(
          learned: learned ? true : null,
          saved: saved ? true : null,
        );
      }
    }

    applyKeys(learnedKeys, learned: true, saved: false);
    applyKeys(savedKeys, learned: false, saved: true);
    next.removeWhere((_, record) => !record.hasState);
    return next;
  }

  static Map<String, dynamic> encode(Map<String, WordLearning> state) => {
        'words': {
          for (final entry in state.entries)
            if (entry.key.isNotEmpty && entry.value.hasState)
              entry.key: entry.value.toJson(),
        },
      };

  static Map<String, WordLearning> decode(dynamic raw) {
    if (raw is! Map) return {};
    final words = raw['words'];
    if (words is! Map) return {};
    return {
      for (final entry in words.entries)
        if (entry.value is Map) '${entry.key}': WordLearning.fromJson(Map<String, dynamic>.from(entry.value as Map)),
    };
  }
}
