import 'package:flutter/material.dart';

import '../models/test_models.dart';
import '../services/test_engine.dart';
import '../theme.dart';

class TestRunnerPage extends StatefulWidget {
  final TestSession session;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(TestSession session) onChanged;
  final Future<void> Function(TestSession session) onFinished;

  const TestRunnerPage({
    super.key,
    required this.session,
    required this.onSpeak,
    required this.onChanged,
    required this.onFinished,
  });

  @override
  State<TestRunnerPage> createState() => _TestRunnerPageState();
}

class _TestRunnerPageState extends State<TestRunnerPage> {
  late TestSession session;
  final controller = TextEditingController();
  AnswerRecord? lastAnswer;
  TestQuestion? lastQuestion;
  bool feedback = false;
  bool busy = false;
  String? spokenId;

  @override
  void initState() {
    super.initState();
    session = widget.session;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSpeak());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  TestQuestion? get current {
    if (session.questions.isEmpty) return null;
    if (feedback) return lastQuestion;
    if (session.index >= session.questions.length) return session.questions.last;
    return session.questions[session.index];
  }

  void _maybeSpeak() {
    final q = current;
    if (q == null || feedback) return;
    if (q.kind == QuestionKind.listenType || q.kind == QuestionKind.listenChoice) {
      if (spokenId == q.id) return;
      spokenId = q.id;
      widget.onSpeak(q.speakText);
    }
  }

  Future<void> _submit(String given) async {
    if (busy || feedback || session.completed) return;
    final question = current;
    if (question == null) return;
    if (session.answers.any((a) => a.questionId == question.id)) return;
    final typed = given.trim();
    if (typed.isEmpty &&
        (question.kind == QuestionKind.listenType || question.kind == QuestionKind.tajikType)) {
      return;
    }
    setState(() => busy = true);
    final next = submitAnswer(session, typed);
    if (next.answers.isEmpty) {
      setState(() => busy = false);
      return;
    }
    setState(() {
      lastQuestion = question;
      lastAnswer = next.answers.last;
      session = next;
      feedback = true;
      busy = false;
      controller.clear();
    });
    await widget.onChanged(next);
  }

  Future<void> _continue() async {
    if (!feedback) return;
    if (session.completed) {
      await widget.onFinished(session);
      return;
    }
    setState(() {
      feedback = false;
      lastAnswer = null;
      lastQuestion = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSpeak());
  }

  @override
  Widget build(BuildContext context) {
    final q = current;
    final total = session.total;
    final number = feedback
        ? session.answers.length
        : (session.index + 1).clamp(1, total == 0 ? 1 : total);
    final batch = ((number - 1) ~/ 5) + 1;
    final batches = (total + 4) ~/ 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.kindLabel),
      ),
      body: SafeArea(
        child: q == null
            ? const Center(child: Text('Савол нест'))
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: total == 0 ? 0 : number / total,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(99),
                      color: cyan600,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Саволи $number / $total  •  Қисми $batch / $batches',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: cyan700),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          _promptCard(q),
                          const SizedBox(height: 12),
                          if (!feedback) ..._inputs(q),
                          if (feedback && lastAnswer != null) _feedback(q, lastAnswer!),
                        ],
                      ),
                    ),
                    if (feedback)
                      FilledButton.icon(
                        onPressed: _continue,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(session.completed ? 'Натиҷа' : 'Саволи нав'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _promptCard(TestQuestion q) {
    final listen = q.kind == QuestionKind.listenType || q.kind == QuestionKind.listenChoice;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (q.emoji != null) Text(q.emoji!, style: const TextStyle(fontSize: 40)),
            Text(q.prompt, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (!listen && q.kind == QuestionKind.tajikType)
              Text(q.hint ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            if (!listen && q.kind == QuestionKind.englishChoice)
              Text(q.speakText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            if (listen) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.tonalIcon(
                  onPressed: () => widget.onSpeak(q.speakText),
                  icon: const Icon(Icons.headphones_rounded),
                  label: const Text('🎧 Гӯш кун'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _inputs(TestQuestion q) {
    if (q.kind == QuestionKind.listenType || q.kind == QuestionKind.tajikType) {
      return [
        TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Ҷавоби худро нависед',
            border: OutlineInputBorder(),
          ),
          onSubmitted: _submit,
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => _submit(controller.text),
          child: const Text('Ҷавоб'),
        ),
      ];
    }
    return [
      for (final option in q.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => _submit(option),
            child: Text(option, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
    ];
  }

  Widget _feedback(TestQuestion q, AnswerRecord answer) {
    final ok = answer.correct;
    return Card(
      color: ok ? emerald600.withValues(alpha: 0.12) : const Color(0xFFDC2626).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ok ? '✓ Дуруст' : '✗ Нодуруст',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: ok ? emerald700 : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 6),
            Text('Шумо: ${answer.given}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Дуруст: ${q.expected}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
