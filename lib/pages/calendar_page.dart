import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/activity.dart';
import '../services/progress_service.dart';
import '../theme.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final snap = ProgressService.instance.snapshot;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday + 6) % 7));
    const names = ['Дш', 'Сш', 'Чш', 'Пш', 'Ҷм', 'Шб', 'Яш'];
    final today = snap.days[ProgressService.todayKey()] ?? const DailyActivity();
    return Scaffold(
      appBar: AppBar(title: const Text('Тақвими омӯзиш')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text('Ҳафтаи ҷорӣ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _DayDot(
                      label: names[i],
                      date: monday.add(Duration(days: i)),
                      done: (snap.days[ProgressService.todayKey(monday.add(Duration(days: i)))] ??
                              const DailyActivity())
                          .total >
                          0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortDate(DateTime.now().millisecondsSinceEpoch),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text('Калимаҳои кушода: ${today.opened}'),
                    Text('Гӯш карда шуд: ${today.listened}'),
                    Text('Омӯхта шуд: ${today.learned}'),
                    Text('Санҷишҳо: ${today.tests}'),
                    Text('Ёдрасҳо: ${today.reminders}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool done;
  const _DayDot({required this.label, required this.date, required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 6),
        CircleAvatar(
          radius: 16,
          backgroundColor: done ? emerald600 : cyan600.withValues(alpha: 0.12),
          child: Text(
            done ? '✓' : '·',
            style: TextStyle(color: done ? Colors.white : cyan700, fontWeight: FontWeight.w900),
          ),
        ),
        Text('${date.day}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
