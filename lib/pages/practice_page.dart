import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/word.dart';
import '../widgets/empty_state.dart';
import '../widgets/word_card.dart';

class PracticePage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
  final Map<String, int> misses;
  final Map<String, int> hits;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;

  const PracticePage({
    super.key,
    required this.words,
    required this.learned,
    required this.saved,
    required this.misses,
    required this.hits,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final hard = [...words]..sort((a, b) => (misses[b.id] ?? 0).compareTo(misses[a.id] ?? 0));
    final list = hard.where((w) => (misses[w.id] ?? 0) > 0).take(20).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Боз такрор кардан лозим')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (list.isEmpty)
              const EmptyState(
                icon: Icons.replay_rounded,
                title: 'Ҳоло калимаи душвор нест',
                text: 'Пас аз санҷиш калимаҳое, ки хато шудаанд, дар ин ҷо меоянд.',
              ),
            for (final word in list) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  masteryLabel(hits[word.id] ?? 0, misses[word.id] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              WordCard(
                key: ValueKey('practice-${word.id}'),
                word: word,
                learned: word.isMarked(learned),
                saved: word.isMarked(saved),
                onSpeak: onSpeak,
                onSave: onSave,
                onLearn: onLearn,
                onRemind: onRemind,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
