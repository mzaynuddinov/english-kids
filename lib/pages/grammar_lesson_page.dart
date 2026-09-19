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
  final chosen = <int, String>{};

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final allCorrect = lesson.quiz.isNotEmpty &&
        List.generate(lesson.quiz.length, (i) => chosen[i] == lesson.quiz[i].expected).every((ok) => ok);
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
            for (var i = 0; i < lesson.quiz.length; i++) ...[
              const SizedBox(height: 10),
              Text(lesson.quiz[i].prompt, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final option in lesson.quiz[i].options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: chosen[i] != null
                        ? null
                        : () async {
                            setState(() => chosen[i] = option);
                            final correctNow = option == lesson.quiz[i].expected &&
                                List.generate(lesson.quiz.length, (j) {
                                  final pick = j == i ? option : chosen[j];
                                  return pick == lesson.quiz[j].expected;
                                }).every((ok) => ok);
                            if (correctNow) {
                              final snap = ProgressService.instance.snapshot;
                              await ProgressService.instance.save(
                                snap.copyWith(grammar: {...snap.grammar, lesson.id}),
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: chosen[i] == option
                          ? (option == lesson.quiz[i].expected ? emerald700 : const Color(0xFFDC2626))
                          : null,
                    ),
                    child: Text(option),
                  ),
                ),
              if (chosen[i] != null)
                Text(
                  chosen[i] == lesson.quiz[i].expected
                      ? '✓ Дуруст'
                      : '✗ Нодуруст. Дуруст: ${lesson.quiz[i].expected}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: chosen[i] == lesson.quiz[i].expected ? emerald700 : const Color(0xFFDC2626),
                  ),
                ),
            ],
            if (allCorrect) ...[
              const SizedBox(height: 12),
              const Text('🎉 Дарс анҷом ёфт!', style: TextStyle(fontWeight: FontWeight.w900, color: emerald600)),
            ],
          ],
        ),
      ),
    );
  }
}
