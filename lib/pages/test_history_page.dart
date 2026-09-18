import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/test_models.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';

class TestHistoryPage extends StatelessWidget {
  final List<TestResult> results;

  const TestHistoryPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Натиҷаҳои санҷиш')),
      body: SafeArea(
        child: results.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.history_rounded,
                  title: 'Ҳоло натиҷа нест',
                  text: 'Санҷишро анҷом диҳед — натиҷа дар ин ҷо мемонад.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = results[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: teal600.withValues(alpha: 0.16),
                        child: Text(
                          '${r.accuracy}',
                          style: const TextStyle(color: teal700, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                      title: Text(r.kindLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text('${shortDate(r.createdAt)} • ${r.correct} / ${r.total} • ${r.accuracy}%'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
