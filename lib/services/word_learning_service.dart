import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/word.dart';
import '../models/word_learning.dart';
import 'preferences_service.dart';
import 'progress_service.dart';
import 'vocabulary_service.dart';

/// Per-student learning state for the shared 500-word list.
/// The vocabulary itself is not copied; only `studentId + wordId` records are.
/// Each student's map stays in memory after the first successful read so a
/// later switch does not read storage again.
class WordLearningService extends ChangeNotifier {
  WordLearningService._();
  static final WordLearningService instance = WordLearningService._();

  String? studentId;
  Map<String, WordLearning> byId = {};
  final Map<String, Map<String, WordLearning>> _byStudent = {};
  final Map<String, Map<String, WordLearning>> _durableByStudent = {};
  final Map<String, int> _latestGen = {};
  final Map<String, Future<void>> _inflight = {};
  int _gen = 0;
  int _activeGen = 0;
  Future<void> _lock = Future<void>.value();

  @visibleForTesting
  Future<void> Function()? debugBeforeOpen;

  @visibleForTesting
  int diskReads = 0;

  WordLearning of(String wordId) => Lexicon.of(byId, wordId);

  Set<String> learnedIds() => {
        for (final entry in byId.entries)
          if (entry.value.learned) entry.key,
      };

  Set<String> savedIds() => {
        for (final entry in byId.entries)
          if (entry.value.saved) entry.key,
      };

  bool cached(String id) => _byStudent.containsKey(id);

  /// Shows a student whose map is already in memory. Does not touch storage.
  bool activate(String id) {
    if (!_byStudent.containsKey(id)) return false;
    _activeGen++;
    _show(id);
    return true;
  }

  Future<void> preload({
    required String studentId,
    required List<Word> vocab,
    required Set<String> legacyLearned,
    required Set<String> legacySaved,
  }) {
    if (_byStudent.containsKey(studentId)) return Future<void>.value();
    return _ensureLoaded(
      studentId: studentId,
      vocab: vocab,
      legacyLearned: legacyLearned,
      legacySaved: legacySaved,
    );
  }

  Future<void> openStudent({
    required String studentId,
    required List<Word> vocab,
    required Set<String> legacyLearned,
    required Set<String> legacySaved,
  }) async {
    if (_byStudent.containsKey(studentId)) {
      _activeGen++;
      _show(studentId);
      return;
    }
    final token = ++_activeGen;
    await _ensureLoaded(
      studentId: studentId,
      vocab: vocab,
      legacyLearned: legacyLearned,
      legacySaved: legacySaved,
    );
    if (token != _activeGen) return;
    if (_byStudent.containsKey(studentId)) _show(studentId);
  }

  Future<void> _ensureLoaded({
    required String studentId,
    required List<Word> vocab,
    required Set<String> legacyLearned,
    required Set<String> legacySaved,
  }) {
    final pending = _inflight[studentId];
    if (pending != null) return pending;
    final created = _readStore(
      studentId: studentId,
      vocab: vocab,
      legacyLearned: legacyLearned,
      legacySaved: legacySaved,
    );
    _inflight[studentId] = created;
    return created.whenComplete(() {
      if (identical(_inflight[studentId], created)) _inflight.remove(studentId);
    });
  }

  Future<void> _readStore({
    required String studentId,
    required List<Word> vocab,
    required Set<String> legacyLearned,
    required Set<String> legacySaved,
  }) async {
    final raw = await PreferencesService.instance.loadRaw(wordLearningKey(studentId));
    diskReads++;
    final hook = debugBeforeOpen;
    if (hook != null) await hook();
    if (_latestGen.containsKey(studentId)) return;
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
        if (_byStudent.containsKey(studentId)) return;
        loaded = Lexicon.migrate(
          words: vocab,
          learnedKeys: legacyLearned,
          savedKeys: legacySaved,
        );
        migrated = true;
      }
    }
    if (_latestGen.containsKey(studentId)) return;
    _byStudent[studentId] = loaded;
    _durableByStudent[studentId] = loaded;
    if (migrated) {
      final gen = ++_gen;
      _latestGen[studentId] = gen;
      await _enqueue(gen, studentId, loaded);
    }
  }

  void _show(String id) {
    final map = _byStudent[id];
    if (map == null) return;
    studentId = id;
    byId = map;
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
    _latestGen[id] = gen;
    byId = next;
    _byStudent[id] = next;
    notifyListeners();
    return _enqueue(gen, id, next);
  }

  Future<bool> _enqueue(int gen, String id, Map<String, WordLearning> snapshot) {
    final done = Completer<bool>();
    _lock = _lock.then((_) async {
      try {
        if (_latestGen[id] != gen) {
          if (!done.isCompleted) done.complete(true);
          return;
        }
        final saved = await _writeStudent(id, snapshot);
        if (_latestGen[id] != gen) {
          if (!done.isCompleted) done.complete(true);
          return;
        }
        if (!saved) {
          final durable = _durableByStudent[id] ?? <String, WordLearning>{};
          _byStudent[id] = durable;
          if (studentId == id) {
            byId = durable;
            notifyListeners();
          }
          if (!done.isCompleted) done.complete(false);
          return;
        }
        _durableByStudent[id] = snapshot;
        _syncCertificate(id, snapshot);
        if (!done.isCompleted) done.complete(true);
      } catch (error, stack) {
        debugPrint('Word learning save failed: $error\n$stack');
        if (_latestGen[id] == gen) {
          final durable = _durableByStudent[id] ?? <String, WordLearning>{};
          _byStudent[id] = durable;
          if (studentId == id) {
            byId = durable;
            notifyListeners();
          }
        }
        if (!done.isCompleted) done.complete(false);
      }
    });
    return done.future;
  }

  void _syncCertificate(String id, Map<String, WordLearning> snapshot) {
    if (studentId != id) return;
    if (!ProgressService.instance.key.endsWith('_$id')) return;
    if (ProgressService.instance.displayOnly) return;
    final vocab = VocabularyService.cachedWords;
    if (vocab == null) return;
    final earned = Lexicon.certificateEarned(vocab, snapshot);
    unawaited(ProgressService.instance.syncCertificate(earned: earned));
  }

  Future<void> clear(String studentId) async {
    _gen++;
    _latestGen[studentId] = _gen;
    final empty = <String, WordLearning>{};
    _byStudent[studentId] = empty;
    _durableByStudent[studentId] = empty;
    await PreferencesService.instance.saveRaw(wordLearningKey(studentId), jsonEncode(Lexicon.encode(empty)));
    await PreferencesService.instance.saveSet('learned_$studentId', {});
    await PreferencesService.instance.saveSet('saved_$studentId', {});
    if (this.studentId == studentId) {
      byId = empty;
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
    _byStudent.remove(id);
    _durableByStudent.remove(id);
    _latestGen.remove(id);
    _activeGen++;
    if (studentId != id) return;
    _gen++;
    studentId = null;
    byId = {};
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _gen++;
    _activeGen++;
    _lock = Future<void>.value();
    studentId = null;
    byId = {};
    _byStudent.clear();
    _durableByStudent.clear();
    _latestGen.clear();
    _inflight.clear();
    debugBeforeOpen = null;
    diskReads = 0;
  }
}
