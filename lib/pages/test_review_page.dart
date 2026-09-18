import 'package:flutter/material.dart';

import '../models/test_models.dart';
import '../theme.dart';

class TestReviewPage extends StatelessWidget {
  final TestSession session;

  const TestReviewPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Баррасӣ')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: session.questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final q = session.questions[i];
            final answer = session.answers.where((a) => a.questionId == q.id);
            final given = answer.isEmpty ? '—' : answer.first.given;
            final ok = answer.isNotEmpty && answer.first.correct;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${q.prompt}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ok ? '✓ Дуруст' : '✗ Нодуруст',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ok ? emerald700 : const Color(0xFFDC2626),
                      ),
                    ),
                    Text('Шумо: $given'),
                    Text('Дуруст: ${q.expected}', style: const TextStyle(fontWeight: FontWeight.w800)),
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
