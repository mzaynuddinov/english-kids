import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final bool learned;
  final bool saved;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;

  const WordCard({
    super.key,
    required this.word,
    required this.learned,
    required this.saved,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSpeak(word.english),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cyan600.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          word.topic,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: cyan600,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (learned) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, color: emerald500, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  word.displayEnglish,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  word.pronunciation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  word.tajik,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => onSpeak(word.english),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Гӯш кардан'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => onSave(word),
                        icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: saved ? emerald600.withValues(alpha: 0.18) : null,
                          foregroundColor: saved ? emerald700 : null,
                        ),
                        label: Text(saved ? 'Захира шуд' : 'Барои баъд'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onLearn(word),
                        icon: Icon(learned ? Icons.check_circle_rounded : Icons.school_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: learned ? emerald600 : teal600,
                          foregroundColor: Colors.white,
                        ),
                        label: Text(learned ? 'Омӯхта шуд' : 'Омӯхтам'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Ёдраси калима',
                      child: OutlinedButton(
                        onPressed: () => onRemind(word),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          side: const BorderSide(color: cyan600),
                          foregroundColor: cyan700,
                        ),
                        child: const Icon(Icons.alarm_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
