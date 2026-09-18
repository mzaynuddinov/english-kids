import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/reminder.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';

class RemindersPage extends StatefulWidget {
  final Future<void> Function(WordReminder reminder) onPause;
  final Future<void> Function(WordReminder reminder) onResume;
  final Future<void> Function(WordReminder reminder) onDelete;
  final Future<void> Function(String text) onSpeak;

  const RemindersPage({
    super.key,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
    required this.onSpeak,
  });

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<WordReminder> get reminders => ProgressService.instance.snapshot.reminders;

  @override
  Widget build(BuildContext context) {
    final active = reminders.where((r) => !r.finished).toList();
    final done = reminders.where((r) => r.finished).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Ёдраскуниҳо')),
      body: SafeArea(
        child: active.isEmpty && done.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.alarm_rounded,
                  title: 'Ёдрас нест',
                  text: 'Аз корти калима тугмаи ⏰ Ёдрас-ро пахш кунед.',
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  for (final r in active) _card(context, r),
                  if (done.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Анҷомёфта', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (final r in done) _card(context, r),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _card(BuildContext context, WordReminder r) {
    final status = r.finished
        ? '✓ Анҷом ёфт'
        : r.paused
            ? 'Таваққуф'
            : 'Ҳар ${r.intervalLabel}';
    final title = r.english.isEmpty
        ? r.english
        : r.english[0].toUpperCase() + r.english.substring(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm_rounded, color: cyan600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            Text(r.tajik, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('$status  •  ${r.completed} / ${r.repeatTotal}'),
            if (!r.finished && !r.paused) Text('Навбат: ${clockOf(r.nextAt)}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                IconButton(
                  tooltip: 'Гӯш кардан',
                  onPressed: () => widget.onSpeak(r.english),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
                if (!r.finished && !r.paused)
                  IconButton(
                    tooltip: 'Таваққуф',
                    onPressed: () async {
                      await widget.onPause(r);
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.pause_circle_rounded),
                  ),
                if (!r.finished && r.paused)
                  IconButton(
                    tooltip: 'Давом',
                    onPressed: () async {
                      await widget.onResume(r);
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.play_circle_rounded),
                  ),
                IconButton(
                  tooltip: 'Нест кардан',
                  onPressed: () async {
                    await widget.onDelete(r);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
