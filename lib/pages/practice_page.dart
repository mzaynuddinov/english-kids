import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';

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
    final snap = ProgressService.instance.snapshot;
    final hard = [...words]..sort((a, b) => (misses[b.id] ?? 0).compareTo(misses[a.id] ?? 0));
    final list = hard.where((w) => (misses[w.id] ?? 0) > 0).take(20).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Калимаҳое, ки боз такрор кардан лозим аст')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              'Бонки хатогиҳо — калимаҳое, ки хато шудаанд.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              const EmptyState(
                icon: Icons.replay_rounded,
                title: 'Ҳоло калимаи душвор нест',
                text: 'Пас аз санҷиш калимаҳое, ки хато шудаанд, дар ин ҷо меоянд.',
              ),
            for (final word in list)
              _MistakeCard(
                word: word,
                misses: misses[word.id] ?? 0,
                mastery: masteryLabel(hits[word.id] ?? 0, misses[word.id] ?? 0),
                lastAt: snap.wordStats[word.id]?.lastMistakeAt ?? 0,
                saved: word.isMarked(saved),
                onSpeak: onSpeak,
                onSave: () => onSave(word),
                onRemind: () => onRemind(word),
                onRepeat: () async {
                  await onSpeak(word.english);
                  if (!word.isMarked(learned)) await onLearn(word);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final Word word;
  final int misses;
  final String mastery;
  final int lastAt;
  final bool saved;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function() onSave;
  final Future<void> Function() onRemind;
  final Future<void> Function() onRepeat;

  const _MistakeCard({
    required this.word,
    required this.misses,
    required this.mastery,
    required this.lastAt,
    required this.saved,
    required this.onSpeak,
    required this.onSave,
    required this.onRemind,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(word.displayEnglish, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.1))),
                  IconButton(tooltip: saved ? 'Аз захира хориҷ' : 'Барои баъд', onPressed: onSave, icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, color: cyan700)),
                  IconButton(tooltip: 'Ёдрас', onPressed: onRemind, icon: const Icon(Icons.alarm_rounded, color: cyan700)),
                ],
              ),
              Text(word.tajik, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(mastery, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cyan700)),
              const SizedBox(height: 4),
              Text('Хато: $misses маротиба', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              if (lastAt > 0) Text('Охирин санҷиш: ${shortDate(lastAt)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.tonalIcon(
                        onPressed: () => onSpeak(word.english),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('🔊 Гӯш кардан'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: onRepeat,
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('📚 Такрор кардан'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
