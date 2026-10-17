import 'package:flutter/material.dart';

import '../models/grammar.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import 'grammar_lesson_page.dart';

class GrammarPage extends StatelessWidget {
  final Future<void> Function(String text) onSpeak;

  const GrammarPage({
    super.key,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final snap = ProgressService.instance.snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Грамматикаи асосӣ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              'Грамматика пас аз алифбо ва Ҳафтаи 5 кушода мешавад.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            for (final lesson in grammarLessons)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: snap.grammar.contains(lesson.id)
                        ? emerald600
                        : cyan600.withValues(alpha: 0.16),
                    child: Icon(
                      snap.grammar.contains(lesson.id) ? Icons.check_rounded : Icons.menu_book_rounded,
                      color: snap.grammar.contains(lesson.id) ? Colors.white : cyan700,
                    ),
                  ),
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(lesson.tajik),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GrammarLessonPage(lesson: lesson, onSpeak: onSpeak),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
