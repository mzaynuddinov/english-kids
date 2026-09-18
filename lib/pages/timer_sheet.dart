import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../models/word.dart';
import '../theme.dart';

class TimerSheet extends StatefulWidget {
  final Word word;
  const TimerSheet({super.key, required this.word});

  @override
  State<TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<TimerSheet> {
  Duration? interval;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [teal600, cyan600]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.alarm_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interval == null ? 'Кай такрор кунем?' : 'Чанд маротиба?',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        widget.word.displayEnglish,
                        style: const TextStyle(color: cyan600, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (interval == null) ...[
              Row(
                children: [
                  Expanded(child: _time(const Duration(seconds: 30), '30 сония')),
                  const SizedBox(width: 8),
                  Expanded(child: _time(const Duration(minutes: 1), '1 дақиқа')),
                  const SizedBox(width: 8),
                  Expanded(child: _time(const Duration(minutes: 5), '5 дақ.')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _time(const Duration(minutes: 15), '15 дақ.')),
                  const SizedBox(width: 8),
                  Expanded(child: _time(const Duration(minutes: 30), '30 дақ.')),
                  const SizedBox(width: 8),
                  Expanded(child: _time(const Duration(hours: 1), '1 соат')),
                ],
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 2, 3, 5, 10]
                    .map(
                      (n) => OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          ReminderPlan(interval: interval!, repeats: n),
                        ),
                        child: Text('$n'),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Огоҳӣ ҳамеша нишон дода мешавад. Хониши овоз дар пасзамина ба дастгоҳ вобаста аст.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _time(Duration delay, String label) {
    return OutlinedButton(
      onPressed: () => setState(() => interval = delay),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Text(label, textAlign: TextAlign.center, maxLines: 2),
    );
  }
}
