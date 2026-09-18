import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';

class QuizQuestion {
  final Word word;
  final List<String> options;
  final String correct;

  const QuizQuestion({
    required this.word,
    required this.options,
    required this.correct,
  });
}

List<QuizQuestion> buildQuiz(List<Word> words, {int count = 5, int seed = 0}) {
  if (words.isEmpty) return [];
  final unique = <String, Word>{};
  for (final word in words) {
    unique.putIfAbsent(word.english.toLowerCase(), () => word);
  }
  final pool = unique.values.toList();
  pool.sort((a, b) => a.english.compareTo(b.english));
  _rotate(pool, seed % (pool.length + 1));
  final selected = pool.take(count.clamp(1, pool.length)).toList();
  final meanings = words.map((w) => w.tajik).where((m) => m.isNotEmpty).toSet().toList()
    ..sort();

  return [
    for (var i = 0; i < selected.length; i++)
      _questionFor(selected[i], meanings, seed + i),
  ];
}

QuizQuestion _questionFor(Word word, List<String> meanings, int salt) {
  final distractors = meanings.where((m) => m != word.tajik).toList();
  _rotate(distractors, salt);
  final options = <String>[word.tajik, ...distractors.take(3)];
  _rotate(options, salt + 3);
  return QuizQuestion(word: word, options: options, correct: word.tajik);
}

void _rotate<T>(List<T> items, int by) {
  if (items.length < 2) return;
  final n = by % items.length;
  if (n == 0) return;
  final head = items.sublist(0, n);
  items.removeRange(0, n);
  items.addAll(head);
}

class QuizPage extends StatefulWidget {
  final List<Word> words;

  const QuizPage({super.key, required this.words});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final List<QuizQuestion> questions;
  int index = 0;
  int score = 0;
  String? chosen;

  @override
  void initState() {
    super.initState();
    questions = buildQuiz(
      widget.words,
      count: 5,
      seed: DateTime.now().day + DateTime.now().month * 31,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мушкилоти имрӯз')),
      body: SafeArea(
        child: questions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.extension_outlined,
                  title: 'Савол нест',
                  text: 'Луғат холӣ аст. Баъдтар кӯшиш кунед.',
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: (index + 1) / questions.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(99),
                      color: cyan600,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Саволи ${index + 1} аз ${questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: cyan700),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            const Icon(Icons.translate_rounded, size: 42, color: teal600),
                            const SizedBox(height: 10),
                            Text(
                              questions[index].word.displayEnglish,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              questions[index].word.pronunciation,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...questions[index].options.map((choice) {
                      final selected = chosen == choice;
                      final correct = choice == questions[index].correct;
                      Color? color;
                      if (chosen != null && selected && correct) color = emerald600;
                      if (chosen != null && selected && !correct) color = const Color(0xFFDC2626);
                      if (chosen != null && !selected && correct) color = emerald600;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: chosen != null ? null : () => _answer(choice),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            side: BorderSide(color: color ?? Theme.of(context).dividerColor),
                            foregroundColor: color,
                          ),
                          child: Text(
                            choice,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    if (chosen != null)
                      FilledButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(index == questions.length - 1 ? 'Натиҷа' : 'Саволи нав'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  void _answer(String choice) {
    setState(() {
      chosen = choice;
      if (choice == questions[index].correct) score++;
    });
  }

  void _next() {
    if (index >= questions.length - 1) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Офарин! 🎉'),
          content: Text('Натиҷа: $score / ${questions.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Тамом'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      index++;
      chosen = null;
    });
  }
}
