import 'package:flutter/material.dart';

import '../models/grammar.dart';
import '../services/progress_service.dart';
import '../theme.dart';

class GrammarLessonPage extends StatefulWidget {
  final GrammarLesson lesson;
  final Future<void> Function(String text) onSpeak;

  const GrammarLessonPage({super.key, required this.lesson, required this.onSpeak});

  @override
  State<GrammarLessonPage> createState() => _GrammarLessonPageState();
}

class _GrammarLessonPageState extends State<GrammarLessonPage> {
  String? chosen;
  bool done = false;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final quiz = lesson.quiz.first;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(lesson.tajik, style: const TextStyle(color: cyan700, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(lesson.explain, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            for (final ex in lesson.examples)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(ex.english, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(ex.tajik),
                  trailing: IconButton(
                    tooltip: 'Гӯш кардан',
                    onPressed: () => widget.onSpeak(ex.english),
                    icon: const Icon(Icons.volume_up_rounded, color: cyan600),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text('Машқи хурд', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(quiz.prompt, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final option in quiz.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: chosen != null
                      ? null
                      : () async {
                          setState(() {
                            chosen = option;
                            done = option == quiz.expected;
                          });
                          if (option == quiz.expected) {
                            final snap = ProgressService.instance.snapshot;
                            await ProgressService.instance.save(
                              snap.copyWith(grammar: {...snap.grammar, lesson.id}),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: chosen == option
                        ? (option == quiz.expected ? emerald700 : const Color(0xFFDC2626))
                        : null,
                  ),
                  child: Text(option),
                ),
              ),
            if (chosen != null)
              Text(
                done ? '✓ Дуруст' : '✗ Нодуруст. Дуруст: ${quiz.expected}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: done ? emerald700 : const Color(0xFFDC2626),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
