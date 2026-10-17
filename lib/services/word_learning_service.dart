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
    if (migrated) await _persist();
    notifyListeners();
  }

  Future<void> setFlag(
    String wordId, {
    bool? learned,
    bool? saved,
  }) async {
    final id = studentId;
    if (id == null || wordId.isEmpty) return;
    byId = Lexicon.withFlag(byId, wordId, learned: learned, saved: saved);
    await _persist();
    notifyListeners();
  }

  Future<WordLearning> record(
    String wordId,
    OralMark mark, {
    DateTime? at,
  }) async {
    final id = studentId;
    final when = (at ?? DateTime.now()).millisecondsSinceEpoch;
    if (id == null || wordId.isEmpty) return const WordLearning();
    byId = Lexicon.record(byId, wordId, mark, at: when);
    await _persist();
    await _mirrorProgress(wordId, mark);
    notifyListeners();
    return of(wordId);
  }

  Future<void> clear(String studentId) async {
    await PreferencesService.instance.saveRaw(wordLearningKey(studentId), jsonEncode(Lexicon.encode({})));
    await PreferencesService.instance.saveSet('learned_$studentId', {});
    await PreferencesService.instance.saveSet('saved_$studentId', {});
    if (this.studentId == studentId) {
      byId = {};
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final id = studentId;
    if (id == null) return;
    await PreferencesService.instance.saveRaw(
      wordLearningKey(id),
      jsonEncode(Lexicon.encode(byId)),
    );
    await PreferencesService.instance.saveSet('learned_$id', learnedIds());
    await PreferencesService.instance.saveSet('saved_$id', savedIds());
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
    studentId = null;
    byId = {};
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    studentId = null;
    byId = {};
  }
}
