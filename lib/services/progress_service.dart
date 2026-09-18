import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/reminder.dart';
import '../models/test_models.dart';
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
    );
  }
}

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();
  static const _key = 'learning_state_v2';

  ProgressSnapshot snapshot = const ProgressSnapshot();

  Future<ProgressSnapshot> load() async {
    try {
      final raw = await PreferencesService.instance.loadRaw(_key);
      if (raw == null || raw.isEmpty) {
        snapshot = const ProgressSnapshot();
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
    return snapshot;
  }

  Future<void> save(ProgressSnapshot next) async {
    snapshot = next;
    try {
      await PreferencesService.instance.saveRaw(_key, jsonEncode(next.toJson()));
    } catch (error, stack) {
      debugPrint('Progress save failed: $error\n$stack');
    }
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

  Set<String> computeAchievements(ProgressSnapshot state, {int learned = 0}) {
    final next = {...state.achievements};
    if (learned >= 10) next.add('first_10');
    if (state.streak >= 3) next.add('streak_3');
    if (learned >= 50) next.add('words_50');
    if (learned >= 100) next.add('words_100');
    if (state.letters.length >= 26) next.add('alphabet');
    if (state.listens >= 10) next.add('listen_10');
    if (state.dailyDone) next.add('daily');
    return next;
  }
}
