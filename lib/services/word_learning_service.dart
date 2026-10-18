import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/word.dart';
import '../models/word_learning.dart';
import 'preferences_service.dart';
import 'progress_service.dart';

/// Per-student learning state for the shared 500-word list.
/// The vocabulary itself is not copied; only `studentId + wordId` records are.
class WordLearningService extends ChangeNotifier {
  WordLearningService._();
  static final WordLearningService instance = WordLearningService._();

  String? studentId;
  Map<String, WordLearning> byId = {};
  Map<String, WordLearning> _durable = {};
  int _gen = 0;
  Future<void> _lock = Future<void>.value();

  WordLearning of(String wordId) => Lexicon.of(byId, wordId);

  Set<String> learnedIds() => {
        for (final entry in byId.entries)
          if (entry.value.learned) entry.key,
      };

  Set<String> savedIds() => {
        for (final entry in byId.entries)
          if (entry.value.saved) entry.key,
      };

  Future<void> openStudent({
    required String studentId,
    required List<Word> vocab,
    required Set<String> legacyLearned,
    required Set<String> legacySaved,
  }) async {
    final raw = await PreferencesService.instance.loadRaw(wordLearningKey(studentId));
    _gen++;
    Map<String, WordLearning> loaded;
    var migrated = false;
    if (raw == null || raw.isEmpty) {
      loaded = Lexicon.migrate(
        words: vocab,
        learnedKeys: legacyLearned,
        savedKeys: legacySaved,
      );
      migrated = true;
    } else {
      try {
        loaded = Lexicon.decode(jsonDecode(raw));
      } catch (error, stack) {
        debugPrint('Word learning decode failed: $error\n$stack');
        loaded = Lexicon.migrate(
          words: vocab,
          learnedKeys: legacyLearned,
          savedKeys: legacySaved,
        );
        migrated = true;
      }
    }
    this.studentId = studentId;
    byId = loaded;
    _durable = loaded;
    if (migrated) {
      final saved = await _writeStudent(studentId, loaded);
      if (!saved) debugPrint('Word learning migration was kept in memory only');
      if (saved) _durable = loaded;
    }
    notifyListeners();
  }

  Future<bool> setFlag(
    String wordId, {
    bool? learned,
    bool? saved,
  }) {
    final id = studentId;
    if (id == null || wordId.isEmpty) return Future<bool>.value(false);
    return _commit(id, Lexicon.withFlag(byId, wordId, learned: learned, saved: saved));
  }

  Future<WordLearning> record(
    String wordId,
    OralMark mark, {
    DateTime? at,
  }) async {
    final id = studentId;
    final when = (at ?? DateTime.now()).millisecondsSinceEpoch;
    if (id == null || wordId.isEmpty) return const WordLearning();
    final next = Lexicon.record(byId, wordId, mark, at: when);
    final ok = await _commit(id, next);
    if (!ok) throw StateError('Натиҷа захира нашуд');
    if (of(wordId).history.any((attempt) => attempt.at == when && attempt.mark == mark)) {
      await _mirrorProgress(wordId, mark);
    }
    return of(wordId);
  }

  /// Applies the new map immediately, then writes the newest map for this student.
  /// A slower older write cannot replace a newer tap. Failure of the latest
  /// write restores the last map that actually reached storage.
  Future<bool> _commit(String id, Map<String, WordLearning> next) async {
    if (studentId != id) return false;
    final gen = ++_gen;
    byId = next;
    notifyListeners();
    return _enqueue(gen, id);
  }

  Future<bool> _enqueue(int gen, String id) {
    final done = Completer<bool>();
    _lock = _lock.then((_) async {
      try {
        if (gen != _gen || studentId != id) {
          if (!done.isCompleted) done.complete(true);
          return;
        }
        final snapshot = byId;
        final saved = await _writeStudent(id, snapshot);
        if (gen != _gen || studentId != id) {
          if (!done.isCompleted) done.complete(true);
          return;
        }
        if (!saved) {
          byId = _durable;
          notifyListeners();
          if (!done.isCompleted) done.complete(false);
          return;
        }
        _durable = snapshot;
        if (!done.isCompleted) done.complete(true);
      } catch (error, stack) {
        debugPrint('Word learning save failed: $error\n$stack');
        if (gen == _gen && studentId == id) {
          byId = _durable;
          notifyListeners();
        }
        if (!done.isCompleted) done.complete(false);
      }
    });
    return done.future;
  }

  Future<void> clear(String studentId) async {
    _gen++;
    final empty = Lexicon.encode({});
    await PreferencesService.instance.saveRaw(wordLearningKey(studentId), jsonEncode(empty));
    await PreferencesService.instance.saveSet('learned_$studentId', {});
    await PreferencesService.instance.saveSet('saved_$studentId', {});
    if (this.studentId == studentId) {
      byId = {};
      _durable = {};
      notifyListeners();
    }
  }

  Future<bool> _writeStudent(String id, Map<String, WordLearning> snapshot) async {
    final saved = await PreferencesService.instance.saveRaw(
      wordLearningKey(id),
      jsonEncode(Lexicon.encode(snapshot)),
    );
    await PreferencesService.instance.saveSet('learned_$id', {
      for (final entry in snapshot.entries)
        if (entry.value.learned) entry.key,
    });
    await PreferencesService.instance.saveSet('saved_$id', {
      for (final entry in snapshot.entries)
        if (entry.value.saved) entry.key,
    });
    return saved;
  }

  Future<void> _mirrorProgress(String wordId, OralMark mark) async {
    try {
      final current = ProgressService.instance.snapshot;
      var next = ProgressService.instance.bumpWord(
        current,
        wordId,
        correct: mark == OralMark.correct ? 1 : 0,
        mistake: mark == OralMark.correct ? 0 : 1,
      );
      final hits = {...next.hits};
      final misses = {...next.misses};
      if (mark == OralMark.correct) {
        hits[wordId] = (hits[wordId] ?? 0) + 1;
      } else {
        misses[wordId] = (misses[wordId] ?? 0) + 1;
      }
      next = next.copyWith(hits: hits, misses: misses);
      await ProgressService.instance.save(next);
    } catch (error, stack) {
      debugPrint('Word learning progress mirror failed: $error\n$stack');
    }
  }

  /// Drops the in-memory map when that student is removed. Stored data is cleared by the caller.
  void release(String id) {
    if (studentId != id) return;
    _gen++;
    studentId = null;
    byId = {};
    _durable = {};
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _gen++;
    _lock = Future<void>.value();
    studentId = null;
    byId = {};
    _durable = {};
  }
}
