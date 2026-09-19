import 'package:flutter/material.dart';

import '../models/progress_rules.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import 'week_page.dart';

class WordsPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;
  final void Function(String message) onLocked;

  const WordsPage({
    super.key,
    required this.words,
    required this.learned,
    required this.saved,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
    required this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    final letters = ProgressService.instance.snapshot.letters;
    return Scaffold(
      appBar: AppBar(title: const Text('Калимаҳо')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            for (var week = 1; week <= weekCount; week++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WeekTile(
                  week: week,
                  words: words.where((w) => w.week == week).toList(),
                  learned: learned,
                  locked: !weekUnlocked(week, letters, words, learned),
                  onOpen: () {
                    if (!weekUnlocked(week, letters, words, learned)) {
                      onLocked(lockReason(week));
                      return;
                    }
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeekPage(
                          week: week,
                          title: weekTitles[week] ?? 'Ҳафтаи $week',
                          words: words.where((w) => w.week == week).toList(),
                          learned: learned,
                          saved: saved,
                          onSpeak: onSpeak,
                          onSave: onSave,
                          onLearn: onLearn,
                          onRemind: onRemind,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekTile extends StatelessWidget {
  final int week;
  final List<Word> words;
  final Set<String> learned;
  final bool locked;
  final VoidCallback onOpen;

  const _WeekTile({
    required this.week,
    required this.words,
    required this.learned,
    required this.locked,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final done = words.where((w) => w.isMarked(learned)).length;
    final pct = words.isEmpty ? 0.0 : done / words.length;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: locked ? [slate700, slate800] : const [teal600, cyan600]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white)
                    : Text(
                        '$week',
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locked ? '🔒 Ҳафтаи $week' : 'Ҳафтаи $week', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(weekTitles[week] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (locked)
                    Text(lockReason(week), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: pct, minHeight: 7, color: emerald500),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('$done/${words.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
