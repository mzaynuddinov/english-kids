import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';
import 'calendar_page.dart';
import 'parent_stats_page.dart';
import 'practice_page.dart';
import 'test_history_page.dart';
import '../services/progress_service.dart';

class ParentHubPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
  final Future<void> Function(String text)? onSpeak;
  final Future<void> Function(Word word)? onSave;
  final Future<void> Function(Word word)? onLearn;
  final Future<void> Function(Word word)? onRemind;

  const ParentHubPage({
    super.key,
    required this.words,
    required this.learned,
    required this.saved,
    this.onSpeak,
    this.onSave,
    this.onLearn,
    this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final snap = ProgressService.instance.snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Қисми волидон')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              'Ин қисм барои волидон аст: омор, таърих ва такрор.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _tile(context, Icons.insights_rounded, 'Омори омӯзиш', () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => ParentStatsPage(words: words, learned: learned, saved: saved),
                ),
              );
            }),
            _tile(context, Icons.history_rounded, 'Таърихи санҷишҳо', () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => TestHistoryPage(results: snap.history)),
              );
            }),
            _tile(context, Icons.calendar_month_rounded, 'Тақвими омӯзиш', () {
              Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const CalendarPage()));
            }),
            if (onSpeak != null && onSave != null && onLearn != null && onRemind != null)
              _tile(context, Icons.replay_rounded, 'Калимаҳои хато', () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PracticePage(
                      words: words,
                      learned: learned,
                      saved: saved,
                      misses: snap.misses,
                      hits: snap.hits,
                      onSpeak: onSpeak!,
                      onSave: onSave!,
                      onLearn: onLearn!,
                      onRemind: onRemind!,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: cyan600),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
