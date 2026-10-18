import 'dart:async';
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
  final int? certificateAt;

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
    this.certificateAt,
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
    int? certificateAt,
    bool clearCertificate = false,
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
      certificateAt: clearCertificate ? null : (certificateAt ?? this.certificateAt),
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
        if (certificateAt != null) 'certificateAt': certificateAt,
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
      certificateAt: json['certificateAt'] is num ? (json['certificateAt'] as num).toInt() : null,
    );
  }
}

class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final ProgressService instance = ProgressService._();
  static const _defaultKey = 'learning_state_v2';
  String _key = _defaultKey;

  ProgressSnapshot snapshot = const ProgressSnapshot();
  ProgressSnapshot _durable = const ProgressSnapshot();
  final Map<String, ProgressSnapshot> _memory = {};
  final Map<String, ProgressSnapshot> _durableMemory = {};
  final Map<String, int> _latestGen = {};
  final Map<String, Future<void>> _loads = {};
  int _saveGen = 0;
  Future<void> _saveLock = Future<void>.value();
  bool displayOnly = false;

  String get key => _key;

  /// Shows cached progress immediately. If nothing is cached, shows a blank
  /// snapshot so the previous student is not left on screen, without writing it.
  bool showPending(String key) {
    _key = key;
    final cached = _memory[key];
    if (cached != null) {
      snapshot = cached;
      _durable = _durableMemory[key] ?? cached;
      displayOnly = false;
      notifyListeners();
      return true;
    }
    displayOnly = true;
    snapshot = const ProgressSnapshot();
    notifyListeners();
    return false;
  }

  Future<void> preload(String key) {
    if (_memory.containsKey(key)) return Future<void>.value();
    return _flight(key, publish: false);
  }

  void drop(String key) {
    _memory.remove(key);
    _durableMemory.remove(key);
    _latestGen.remove(key);
    if (_key != key) return;
    snapshot = const ProgressSnapshot();
    _durable = snapshot;
    displayOnly = false;
    notifyListeners();
  }

  Future<ProgressSnapshot> load({String? key}) async {
    if (key != null) _key = key;
    final target = _key;
    final cached = _memory[target];
    if (cached != null) {
      snapshot = cached;
      _durable = _durableMemory[target] ?? cached;
      displayOnly = false;
      notifyListeners();
      return snapshot;
    }
    await _flight(target, publish: true);
    return snapshot;
  }

  Future<void> _flight(String target, {required bool publish}) {
    final pending = _loads[target];
    if (pending != null) return pending;
    final created = _read(target, publish: publish);
    _loads[target] = created;
    return created.whenComplete(() {
      if (identical(_loads[target], created)) _loads.remove(target);
    });
  }

  Future<void> _read(String target, {required bool publish}) async {
    try {
      final raw = await PreferencesService.instance.loadRaw(target);
      if (_latestGen.containsKey(target)) {
        if (publish && _key == target) displayOnly = false;
        return;
      }
      var parsed = const ProgressSnapshot();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          parsed = ProgressSnapshot.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      if (_latestGen.containsKey(target)) return;
      _memory[target] = parsed;
      _durableMemory[target] = parsed;
      if (publish && _key == target) {
        snapshot = parsed;
        _durable = parsed;
        displayOnly = false;
        notifyListeners();
      }
    } catch (error, stack) {
      debugPrint('Progress load failed: $error\n$stack');
      if (publish && _key == target && !_memory.containsKey(target)) {
        displayOnly = false;
        notifyListeners();
      }
    }
  }

  Future<void> syncCertificate({required bool earned, int? nowMillis}) async {
    if (displayOnly) return;
    if (earned) {
      if (snapshot.certificateAt != null) return;
      await save(snapshot.copyWith(certificateAt: nowMillis ?? DateTime.now().millisecondsSinceEpoch));
      return;
    }
    if (snapshot.certificateAt == null) return;
    await save(snapshot.copyWith(clearCertificate: true));
  }

  Future<bool> save(ProgressSnapshot next) async {
    if (displayOnly) return false;
    final gen = ++_saveGen;
    final saveKey = _key;
    _latestGen[saveKey] = gen;
    snapshot = next;
    _memory[saveKey] = next;
    notifyListeners();
    return _enqueueSave(gen, saveKey, next);
  }

  Future<bool> _enqueueSave(int gen, String saveKey, ProgressSnapshot captured) {
    final done = Completer<bool>();
    _saveLock = _saveLock.then((_) async {
      try {
        if (_latestGen[saveKey] != gen) {
          if (!done.isCompleted) done.complete(true);
          return;
        }
        final ok = await PreferencesService.instance.saveRaw(saveKey, jsonEncode(captured.toJson()));
        if (_latestGen[saveKey] != gen) {
          if (!done.isCompleted) done.complete(true);
          return;
        }
        if (!ok) {
          final durable = _durableMemory[saveKey] ?? const ProgressSnapshot();
          _memory[saveKey] = durable;
          if (_key == saveKey) {
            snapshot = durable;
            _durable = durable;
            notifyListeners();
          }
          if (!done.isCompleted) done.complete(false);
          return;
        }
        _durableMemory[saveKey] = captured;
        if (_key == saveKey) _durable = captured;
        if (!done.isCompleted) done.complete(true);
      } catch (error, stack) {
        debugPrint('Progress save failed: $error\n$stack');
        if (_latestGen[saveKey] == gen) {
          final durable = _durableMemory[saveKey] ?? const ProgressSnapshot();
          _memory[saveKey] = durable;
          if (_key == saveKey) {
            snapshot = durable;
            _durable = durable;
            notifyListeners();
          }
        }
        if (!done.isCompleted) done.complete(false);
      }
    });
    return done.future;
  }

  Future<void> resetLearning() async {
    displayOnly = false;
    await save(const ProgressSnapshot());
  }

  @visibleForTesting
  void debugReset() {
    snapshot = const ProgressSnapshot();
    _durable = const ProgressSnapshot();
    _memory.clear();
    _durableMemory.clear();
    _latestGen.clear();
    _loads.clear();
    _key = _defaultKey;
    displayOnly = false;
    _saveGen++;
    _saveLock = Future<void>.value();
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
