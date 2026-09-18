import 'package:flutter/material.dart';

import '../models/word.dart';
import '../widgets/empty_state.dart';
import '../widgets/word_card.dart';

class SavedPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> saved;
  final Set<String> learned;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;

  const SavedPage({
    super.key,
    required this.words,
    required this.saved,
    required this.learned,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final list = words.where((w) => w.isMarked(saved)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Text(
          'Барои баъд',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text('${list.length} калима захира шудааст'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'Ҳоло чизе нест',
            text: 'Калимаҳоеро, ки дертар такрор кардан мехоҳед, бо «Барои баъд» захира кунед.',
          ),
        ...list.map(
          (word) => WordCard(
            key: ValueKey('saved-${word.id}'),
            word: word,
            learned: word.isMarked(learned),
            saved: true,
            onSpeak: onSpeak,
            onSave: onSave,
            onLearn: onLearn,
            onRemind: onRemind,
          ),
        ),
      ],
    );
  }
}
