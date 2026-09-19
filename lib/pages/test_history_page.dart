import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/test_models.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import 'test_review_page.dart';

class TestHistoryPage extends StatelessWidget {
  final List<TestResult> results;

  const TestHistoryPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Таърихи санҷишҳо')),
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
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(builder: (_) => HistoryDetailPage(result: r)),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class HistoryDetailPage extends StatelessWidget {
  final TestResult result;
  const HistoryDetailPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final items = result.items;
    return Scaffold(
      appBar: AppBar(title: Text(result.kindLabel)),
      body: SafeArea(
        child: items.isEmpty
            ? TestReviewPage(
                session: TestSession(
                  id: result.id,
                  kind: result.kind,
                  questions: const [],
                  createdAt: result.createdAt,
                  completed: true,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${item.prompt}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            item.correct ? '✓ Дуруст' : '✗ Нодуруст',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: item.correct ? emerald700 : const Color(0xFFDC2626),
                            ),
                          ),
                          Text('Шумо: ${item.given}'),
                          Text('Дуруст: ${item.expected}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
