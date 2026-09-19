import 'package:flutter/material.dart';

import '../models/word.dart';
import '../services/progress_service.dart';
import '../theme.dart';

class ParentStatsPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;

  const ParentStatsPage({super.key, required this.words, required this.learned});

  @override
  Widget build(BuildContext context) {
    final snap = ProgressService.instance.snapshot;
    final today = snap.days[ProgressService.todayKey()];
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday + 6) % 7));
    var weekLearned = 0;
    for (var i = 0; i < 7; i++) {
      weekLearned += snap.days[ProgressService.todayKey(monday.add(Duration(days: i)))]?.learned ?? 0;
    }
    final mistakes = snap.mistakes.fold<int>(0, (p, e) => p + e.count);
    final tests = snap.history;
    final totalQ = tests.fold<int>(0, (p, e) => p + e.total);
    final correctQ = tests.fold<int>(0, (p, e) => p + e.correct);
    final accuracy = totalQ == 0 ? 0 : ((correctQ / totalQ) * 100).round();
    final studyDays = snap.days.values.where((d) => d.total > 0).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Омори омӯзиш')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _card('Имрӯз', '${today?.learned ?? 0} калима'),
                _card('Ин ҳафта', '$weekLearned калима'),
                _card('Дақиқӣ', '$accuracy%'),
                _card('Пайдарпай', '${snap.streak} рӯз'),
                _card('Такрор лозим', '${snap.misses.values.where((v) => v > 0).length} калима'),
                _card('Алифбо', '${snap.letters.length} / 26'),
                _card('Грамматика', '${snap.grammar.length} / 10'),
                _card('Омӯхта', '${learned.length} / ${words.length}'),
                _card('Гӯш', '${snap.listens}'),
                _card('Хатоҳо', '$mistakes'),
                _card('Рӯзҳои омӯзиш', '$studyDays'),
                _card('Ёдрасҳо', '${snap.reminderDone}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String label, String value) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cyan700)),
            ],
          ),
        ),
      ),
    );
  }
}
