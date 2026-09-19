import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/reminder.dart';
import '../models/test_models.dart';
import '../models/word.dart';
import 'preferences_service.dart';

class ProgressSnapshot {
  final Set<String> letters;
  final Map<String, int> misses;
  final Map<String, int> hits;
  final int listens;
  final String? lastDay;
  final int streak;
  final Set<String> achievements;
  final List<TestResult> history;
  final TestSession? active;
  final List<WordReminder> reminders;
  final bool dailyDone;
  final int alphabetIndex;
  final Set<String> grammar;
  final List<MistakeRecord> mistakes;
  final Map<String, DailyActivity> days;
  final Map<String, WordActivity> wordStats;
  final int reminderDone;

  const ProgressSnapshot({
    this.letters = const {},
    this.misses = const {},
    this.hits = const {},
    this.listens = 0,
    this.lastDay,
    this.streak = 0,
    this.achievements = const {},
    this.history = const [],
    this.active,
    this.reminders = const [],
    this.dailyDone = false,
    this.alphabetIndex = 0,
    this.grammar = const {},
    this.mistakes = const [],
    this.days = const {},
    this.wordStats = const {},
    this.reminderDone = 0,
  });

  ProgressSnapshot copyWith({
    Set<String>? letters,
    Map<String, int>? misses,
    Map<String, int>? hits,
    int? listens,
    String? lastDay,
    int? streak,
    Set<String>? achievements,
    List<TestResult>? history,
    TestSession? active,
    bool clearActive = false,
    List<WordReminder>? reminders,
    bool? dailyDone,
    int? alphabetIndex,
    Set<String>? grammar,
    List<MistakeRecord>? mistakes,
    Map<String, DailyActivity>? days,
    Map<String, WordActivity>? wordStats,
    int? reminderDone,
  }) {
    return ProgressSnapshot(
      letters: letters ?? this.letters,
      misses: misses ?? this.misses,
      hits: hits ?? this.hits,
      listens: listens ?? this.listens,
      lastDay: lastDay ?? this.lastDay,
      streak: streak ?? this.streak,
      achievements: achievements ?? this.achievements,
      history: history ?? this.history,
      active: clearActive ? null : (active ?? this.active),
      reminders: reminders ?? this.reminders,
      dailyDone: dailyDone ?? this.dailyDone,
      alphabetIndex: alphabetIndex ?? this.alphabetIndex,
      grammar: grammar ?? this.grammar,
      mistakes: mistakes ?? this.mistakes,
      days: days ?? this.days,
      wordStats: wordStats ?? this.wordStats,
      reminderDone: reminderDone ?? this.reminderDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'letters': letters.toList(),
        'misses': misses,
        'hits': hits,
        'listens': listens,
        'lastDay': lastDay,
        'streak': streak,
        'achievements': achievements.toList(),
        'history': history.map((h) => h.toJson()).toList(),
        'active': active?.toJson(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'dailyDone': dailyDone,
        'alphabetIndex': alphabetIndex,
        'grammar': grammar.toList(),
        'mistakes': mistakes.map((m) => m.toJson()).toList(),
        'days': {for (final e in days.entries) e.key: e.value.toJson()},
        'wordStats': {for (final e in wordStats.entries) e.key: e.value.toJson()},
        'reminderDone': reminderDone,
      };

  static ProgressSnapshot fromJson(Map<String, dynamic> json) {
    TestSession? active;
    final rawActive = json['active'];
    if (rawActive is Map) {
      try {
        active = TestSession.fromJson(Map<String, dynamic>.from(rawActive));
      } catch (_) {
        active = null;
      }
    }
    final rawDays = json['days'] as Map? ?? {};
    final rawStats = json['wordStats'] as Map? ?? {};
    return ProgressSnapshot(
      letters: {...?((json['letters'] as List?)?.map((e) => '$e'))},
      misses: {
        for (final e in (json['misses'] as Map? ?? {}).entries)
          '${e.key}': e.value is num ? (e.value as num).toInt() : 0,
      },
      hits: {
        for (final e in (json['hits'] as Map? ?? {}).entries)
          '${e.key}': e.value is num ? (e.value as num).toInt() : 0,
      },
      listens: json['listens'] is num ? (json['listens'] as num).toInt() : 0,
      lastDay: json['lastDay'] as String?,
      streak: json['streak'] is num ? (json['streak'] as num).toInt() : 0,
      achievements: {...?((json['achievements'] as List?)?.map((e) => '$e'))},
      history: (json['history'] as List? ?? [])
          .whereType<Map>()
          .map((e) => TestResult.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      active: active,
      reminders: (json['reminders'] as List? ?? [])
          .map(WordReminder.tryParse)
          .whereType<WordReminder>()
          .toList(),
      dailyDone: json['dailyDone'] == true,
      alphabetIndex: json['alphabetIndex'] is num ? (json['alphabetIndex'] as num).toInt() : 0,
      grammar: {...?((json['grammar'] as List?)?.map((e) => '$e'))},
      mistakes: (json['mistakes'] as List? ?? []).map(MistakeRecord.tryParse).whereType<MistakeRecord>().toList(),
      days: {
        for (final e in rawDays.entries)
          if (e.value is Map) '${e.key}': DailyActivity.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
      wordStats: {
        for (final e in rawStats.entries)
          if (e.value is Map) '${e.key}': WordActivity.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
      reminderDone: json['reminderDone'] is num ? (json['reminderDone'] as num).toInt() : 0,
    );
  }
}

class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final ProgressService instance = ProgressService._();
  static const _key = 'learning_state_v2';

  ProgressSnapshot snapshot = const ProgressSnapshot();

  Future<ProgressSnapshot> load() async {
    try {
      final raw = await PreferencesService.instance.loadRaw(_key);
      if (raw == null || raw.isEmpty) {
        snapshot = const ProgressSnapshot();
        notifyListeners();
        return snapshot;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        snapshot = ProgressSnapshot.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (error, stack) {
      debugPrint('Progress load failed: $error\n$stack');
      snapshot = const ProgressSnapshot();
    }
    notifyListeners();
    return snapshot;
  }

  Future<void> save(ProgressSnapshot next) async {
    snapshot = next;
    notifyListeners();
    try {
      await PreferencesService.instance.saveRaw(_key, jsonEncode(next.toJson()));
    } catch (error, stack) {
      debugPrint('Progress save failed: $error\n$stack');
    }
  }

  Future<void> resetLearning() async {
    await save(const ProgressSnapshot());
  }

  @visibleForTesting
  void debugReset() {
    snapshot = const ProgressSnapshot();
  }

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  ProgressSnapshot withActivity(ProgressSnapshot current) {
    final today = todayKey();
    if (current.lastDay == today) {
      return current.copyWith(streak: current.streak == 0 ? 1 : current.streak);
    }
    final yesterday = todayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (current.lastDay == yesterday) {
      return current.copyWith(lastDay: today, streak: current.streak + 1);
    }
    return current.copyWith(lastDay: today, streak: 1);
  }

  ProgressSnapshot bumpDay(
    ProgressSnapshot current, {
    int opened = 0,
    int listened = 0,
    int learned = 0,
    int tests = 0,
    int reminders = 0,
  }) {
    final key = todayKey();
    final days = {...current.days};
    final prev = days[key] ?? const DailyActivity();
    days[key] = prev.add(
      opened: opened,
      listened: listened,
      learned: learned,
      tests: tests,
      reminders: reminders,
    );
    return current.copyWith(days: days);
  }

  ProgressSnapshot bumpWord(
    ProgressSnapshot current,
    String wordId, {
    int opened = 0,
    int listened = 0,
    int mistake = 0,
    int correct = 0,
  }) {
    if (wordId.isEmpty) return current;
    final stats = {...current.wordStats};
    final prev = stats[wordId] ?? const WordActivity();
    final now = DateTime.now().millisecondsSinceEpoch;
    stats[wordId] = prev.copyWith(
      openedCount: prev.openedCount + opened,
      listenedCount: prev.listenedCount + listened,
      mistakeCount: prev.mistakeCount + mistake,
      correctCount: prev.correctCount + correct,
      lastOpenedAt: opened > 0 ? now : prev.lastOpenedAt,
      lastListenedAt: listened > 0 ? now : prev.lastListenedAt,
      lastMistakeAt: mistake > 0 ? now : prev.lastMistakeAt,
    );
    return current.copyWith(wordStats: stats);
  }

  Set<String> computeAchievements(ProgressSnapshot state, {int learned = 0}) {
    final next = {...state.achievements};
    if (learned >= 10) next.add('first_10');
    if (state.streak >= 3) next.add('streak_3');
    if (learned >= 50) next.add('words_50');
    if (learned >= 100) next.add('words_100');
    if (state.letters.length >= 26) next.add('alphabet');
    if (state.listens >= 10) next.add('listen_10');
    if (state.dailyDone) next.add('daily');
    if (state.grammar.length >= 10) next.add('grammar');
    return next;
  }
}

int learnedInWeek(int week, List<Word> words, Set<String> learned) {
  final list = words.where((w) => w.week == week).toList();
  return list.where((w) => w.isMarked(learned)).length;
}
