import 'package:flutter/material.dart';

import '../models/test_models.dart';
import '../services/test_engine.dart';
import '../theme.dart';
import 'test_review_page.dart';

class TestResultPage extends StatelessWidget {
  final TestSession session;
  final VoidCallback onRetry;

  const TestResultPage({
    super.key,
    required this.session,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final result = resultFrom(session);
    return Scaffold(
      appBar: AppBar(title: const Text('Натиҷа')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              '🎉 Санҷиш анҷом ёфт!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${session.kindLabel}: ${result.correct} / ${result.total}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, color: cyan700),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Дуруст', '${result.correct}', emerald700),
                    _row('Нодуруст', '${result.incorrect}', const Color(0xFFDC2626)),
                    _row('Дақиқӣ', '${result.accuracy}%', teal700),
                  ],
                ),
              ),
            ),
            if (result.review.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Боз такрор кун', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in result.review)
                    Chip(label: Text(item)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (session.kind == TestKind.alphabet)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in session.questions)
                    _letterChip(q, session.answers.any((a) => a.questionId == q.id && a.correct)),
                ],
              ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => TestReviewPage(session: session)),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Баррасӣ'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Аз нав санҷидан'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _letterChip(TestQuestion q, bool ok) {
    return Chip(
      avatar: Icon(
        ok ? Icons.check_rounded : Icons.close_rounded,
        size: 16,
        color: ok ? emerald700 : const Color(0xFFDC2626),
      ),
      label: Text('${q.letter ?? q.expected} ${ok ? "✓" : "✗"}'),
    );
  }
}
