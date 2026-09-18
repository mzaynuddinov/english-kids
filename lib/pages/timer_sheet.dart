import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';

class TimerSheet extends StatelessWidget {
  final Word word;

  const TimerSheet({super.key, required this.word});

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
                      const Text(
                        'Ёдраси калима',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        word.displayEnglish,
                        style: const TextStyle(color: cyan600, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _choice(context, const Duration(seconds: 30), '30 сония')),
                const SizedBox(width: 8),
                Expanded(child: _choice(context, const Duration(minutes: 1), '1 дақиқа')),
                const SizedBox(width: 8),
                Expanded(child: _choice(context, const Duration(minutes: 5), '5 дақ.')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _choice(context, const Duration(minutes: 15), '15 дақ.')),
                const SizedBox(width: 8),
                Expanded(child: _choice(context, const Duration(minutes: 30), '30 дақ.')),
                const SizedBox(width: 8),
                Expanded(child: _choice(context, const Duration(hours: 1), '1 соат')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Огоҳӣ нишон дода мешавад. Хониши овоз дар пасзамина ба дастгоҳ вобаста аст.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(BuildContext context, Duration delay, String label) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context, delay),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Text(label, textAlign: TextAlign.center, maxLines: 2),
    );
  }
}
