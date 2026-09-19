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
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cyan600.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
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
                  IconButton(
                    tooltip: saved ? 'Аз захира хориҷ' : 'Барои баъд',
                    onPressed: () => onSave(word),
                    icon: Icon(
                      saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: saved ? emerald600 : cyan700,
                    ),
                  ),
                ],
              ),
              Text(
                word.displayEnglish,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.12),
              ),
              const SizedBox(height: 2),
              Text(
                word.pronunciation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: scheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                word.tajik,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.25),
              ),
              if (word.example.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Ҷумлаи мисол', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.6))),
                Text(word.example, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (word.exampleTajik.isNotEmpty) Text(word.exampleTajik),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => onSpeak(word.example),
                    icon: const Icon(Icons.volume_up_rounded, size: 18),
                    label: const Text('Гӯш кардани ҷумла'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.tonalIcon(
                  onPressed: () => onSpeak(word.english),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Гӯш кардан'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: learned ? () {} : () => onLearn(word),
                        icon: Icon(learned ? Icons.check_circle_rounded : Icons.check_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: learned ? emerald600 : teal600,
                          foregroundColor: Colors.white,
                        ),
                        label: Text(learned ? 'Омӯхта шуд' : 'Омӯхтам'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => onRemind(word),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: const BorderSide(color: cyan600),
                        foregroundColor: cyan700,
                      ),
                      icon: const Icon(Icons.alarm_rounded),
                      label: const Text('Ёдрас'),
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
