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
  static Future<VocabularyLoadResult> load() async {
    try {
      final raw = await rootBundle.loadString('data/vocabulary.json');
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
        final key = word.english.toLowerCase();
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
      debugPrint('Vocabulary load failed: $error\n$stack');
      return const VocabularyLoadResult(
        words: [],
        error: 'Калимаҳо бор нашуданд.',
      );
    }
  }
}
