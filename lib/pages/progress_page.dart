import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';

class ProgressPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;

  const ProgressPage({
    super.key,
    required this.words,
    required this.learned,
  });

  @override
  Widget build(BuildContext context) {
    final pct = words.isEmpty ? 0.0 : learned.length / words.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Text(
          'Пешрафт',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 13,
                          color: emerald500,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(pct * 100).round()}%',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                          ),
                          const Text('пешрафт'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${learned.length} аз ${words.length} калима омӯхта шуд',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(5, (i) {
          final week = i + 1;
          final list = words.where((w) => w.week == week).toList();
          final done = list.where((w) => learned.contains(w.english)).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: teal600.withValues(alpha: 0.16),
                child: Text(
                  '$week',
                  style: const TextStyle(color: teal700, fontWeight: FontWeight.w900),
                ),
              ),
              title: Text(
                'Ҳафтаи $week',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${weekTitles[week]} • $done аз ${list.length}'),
              trailing: SizedBox(
                width: 70,
                child: LinearProgressIndicator(
                  value: list.isEmpty ? 0 : done / list.length,
                  color: emerald500,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
