import 'package:flutter/material.dart';

import '../models/grammar.dart';
import '../models/progress_rules.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import 'grammar_lesson_page.dart';

class GrammarPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;
  final Future<void> Function(String text) onSpeak;

  const GrammarPage({
    super.key,
    required this.words,
    required this.learned,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final snap = ProgressService.instance.snapshot;
    final unlocked = grammarUnlocked(words, learned, snap.letters);
    return Scaffold(
      appBar: AppBar(title: const Text('Грамматикаи асосӣ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (!unlocked)
              const EmptyState(
                icon: Icons.lock_rounded,
                title: 'Қадами оянда ҳоло қулф аст',
                text: 'Аввал алифбо ва Ҳафтаи 5-ро ба анҷом расонед.',
              )
            else
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
