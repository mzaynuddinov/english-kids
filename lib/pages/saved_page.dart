import 'package:flutter/material.dart';

import '../models/days.dart';
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
  final String voiceGender;

  const SavedPage({
    super.key,
    required this.words,
    required this.saved,
    required this.learned,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
    this.voiceGender = 'female',
  });

  @override
  Widget build(BuildContext context) {
    final list = words.where((w) => w.isMarked(saved)).toList();
    final extras = <String>[
      for (final key in saved)
        if (key.startsWith('letter:')) 'Ҳарф ${key.substring('letter:'.length)}',
      for (final day in weekDays)
        if (saved.contains(day.id)) 'Рӯз: ${day.english} · ${day.tajik}',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Text(
          'Барои баъд',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text('${list.length} калима · ${extras.length} ҳарф ё рӯз'),
        const SizedBox(height: 16),
        if (extras.isNotEmpty) ...[
          const Text('Ҳарфҳо ва рӯзҳои барои баъд', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final item in extras)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bookmark_rounded),
                title: Text(item, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (list.isEmpty && extras.isEmpty)
          const EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'Ҳоло чизе нест',
            text:
                'Калимаҳоеро, ки дертар такрор кардан мехоҳед, бо «Барои баъд» захира кунед.',
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
            voiceGender: voiceGender,
          ),
        ),
      ],
    );
  }
}
