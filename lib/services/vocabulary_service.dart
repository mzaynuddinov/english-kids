import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/word.dart';

class VocabularyLoadResult {
  final List<Word> words;
  final String? error;

  const VocabularyLoadResult({required this.words, this.error});

  bool get ok => error == null && words.isNotEmpty;
}

class VocabularyService {
  /// Test hook so widget tests do not depend on fake-async asset I/O.
  @visibleForTesting
  static Future<VocabularyLoadResult> Function()? debugLoader;

  static Future<VocabularyLoadResult> load() {
    final override = debugLoader;
    if (override != null) return override();
    return loadFromBundle();
  }

  static Future<VocabularyLoadResult> loadFromBundle() async {
    try {
      final raw = await rootBundle
          .loadString('data/vocabulary.json')
          .timeout(const Duration(seconds: 8));
      return parseRaw(raw);
    } catch (error, stack) {
      debugPrint('Vocabulary load failed: $error\n$stack');
      return const VocabularyLoadResult(
        words: [],
        error: 'Калимаҳо бор нашуданд.',
      );
    }
  }

  static VocabularyLoadResult parseRaw(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const VocabularyLoadResult(
          words: [],
          error: 'Калимаҳо бор нашуданд.',
        );
      }
      final words = <Word>[];
      final seen = <String>{};
      for (final item in decoded) {
        final word = Word.tryParse(item);
        if (word == null) continue;
        final key = word.id;
        if (!seen.add(key)) continue;
        words.add(word);
      }
      if (words.isEmpty) {
        return const VocabularyLoadResult(
          words: [],
          error: 'Калимаҳо бор нашуданд.',
        );
      }
      return VocabularyLoadResult(words: words);
    } catch (error, stack) {
      debugPrint('Vocabulary parse failed: $error\n$stack');
      return const VocabularyLoadResult(
        words: [],
        error: 'Калимаҳо бор нашуданд.',
      );
    }
  }

  @visibleForTesting
  static void debugReset() {
    debugLoader = null;
  }
}
