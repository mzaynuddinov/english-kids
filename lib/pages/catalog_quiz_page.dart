import 'package:flutter/material.dart';

import '../models/days.dart';
import '../models/word_learning.dart';
import '../services/progress_service.dart';
import '../services/student_service.dart';
import '../services/word_learning_service.dart';
import '../theme.dart';
import '../widgets/word_history_sheet.dart';

class QuizPrompt {
  final String id;
  final String title;
  final String answer;
  final String speak;

  const QuizPrompt({
    required this.id,
    required this.title,
    required this.answer,
    required this.speak,
  });
}

class CatalogQuizPage extends StatefulWidget {
  final String title;
  final List<QuizPrompt> prompts;
  final Future<void> Function(String text) onSpeak;

  const CatalogQuizPage({
    super.key,
    required this.title,
    required this.prompts,
    required this.onSpeak,
  });

  @override
  State<CatalogQuizPage> createState() => _CatalogQuizPageState();
}

class _CatalogQuizPageState extends State<CatalogQuizPage> {
  int index = 0;
  int _action = 0;
  bool reveal = false;
  bool finished = false;
  int correct = 0;
  int incorrect = 0;
  int unknown = 0;

  String get _studentName {
    final id = StudentService.instance.currentStudentId;
    for (final student in StudentService.instance.students) {
      if (student.id == id) return student.name;
    }
    return 'Талаба';
  }

  Future<void> _syncLetter(String id, bool learned) async {
    if (!id.startsWith('letter:')) return;
    final letter = id.substring('letter:'.length);
    final snap = ProgressService.instance.snapshot;
    final letters = {...snap.letters};
    if (learned) {
      letters.add(letter);
    } else {
      letters.remove(letter);
    }
    await ProgressService.instance.save(snap.copyWith(
      letters: letters,
      achievements: ProgressService.instance.computeAchievements(
        snap.copyWith(letters: letters),
      ),
    ));
  }

  Future<void> _mark(OralMark mark) async {
    if (index >= widget.prompts.length) return;
    if (WordLearningService.instance.studentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аввал талабаро интихоб кунед.')),
        );
      }
      return;
    }
    final item = widget.prompts[index];
    final action = ++_action;
    final at = index;
    setState(() {
      reveal = false;
      if (mark == OralMark.correct) correct += 1;
      if (mark == OralMark.incorrect) incorrect += 1;
      if (mark == OralMark.unknown) unknown += 1;
      index += 1;
      if (index >= widget.prompts.length) finished = true;
    });
    try {
      await WordLearningService.instance.record(item.id, mark);
    } catch (error, stack) {
      debugPrint('Catalog quiz save failed: $error\n$stack');
      if (!mounted || action != _action) return;
      setState(() {
        index = at;
        finished = false;
        if (mark == OralMark.correct && correct > 0) correct -= 1;
        if (mark == OralMark.incorrect && incorrect > 0) incorrect -= 1;
        if (mark == OralMark.unknown && unknown > 0) unknown -= 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Натиҷа захира нашуд. Боз кӯшиш кунед.')),
      );
    }
  }

  Future<void> _toggleLearned() async {
    if (index >= widget.prompts.length) return;
    final item = widget.prompts[index];
    final next = !WordLearningService.instance.of(item.id).learned;
    final pending = WordLearningService.instance.setFlag(item.id, learned: next);
    if (mounted) setState(() {});
    final ok = await pending;
    if (!mounted) return;
    if (!ok) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ҳолат захира нашуд.')),
      );
      return;
    }
    final letterWrite = _syncLetter(item.id, next);
    setState(() {});
    await letterWrite;
  }

  Future<void> _toggleSaved() async {
    if (index >= widget.prompts.length) return;
    final item = widget.prompts[index];
    final next = !WordLearningService.instance.of(item.id).saved;
    final pending = WordLearningService.instance.setFlag(item.id, saved: next);
    if (mounted) setState(() {});
    final ok = await pending;
    if (!mounted) return;
    setState(() {});
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рӯйхати барои баъд захира нашуд.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prompts.isEmpty || finished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(_studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(widget.prompts.isEmpty ? 'Дар ин рӯйхат чизе нест.' : 'Ҳисоботи дарс'),
            Text('Дуруст: $correct'),
            Text('Нодуруст: $incorrect'),
            Text('Надонист: $unknown'),
          ],
        ),
      );
    }
    final item = widget.prompts[index];
    final record = WordLearningService.instance.of(item.id);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$_studentName · ${index + 1} / ${widget.prompts.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
            TextButton.icon(
              onPressed: () => widget.onSpeak(item.speak),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Гӯш кардан'),
            ),
            if (!reveal)
              OutlinedButton(onPressed: () => setState(() => reveal = true), child: const Text('Ҷавобро нишон диҳ'))
            else
              Text(item.answer, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: teal700)),
            const SizedBox(height: 8),
            Text(
              'Омӯзиш: ${record.learned ? 'омӯхта шудааст' : 'ҳанӯз омӯхта нашудааст'}',
              textAlign: TextAlign.center,
            ),
            Text(
              record.quizzed ? 'Пурсиши охирин: ${oralMarkLabel(record.history.last.mark)} · ${formatLearningStamp(record.lastQuizAt)}' : 'Ҳанӯз санҷида нашудааст',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () => showLearningHistory(
                context,
                title: item.title,
                subtitle: item.answer,
                record: record,
              ),
              child: const Text('Таърихи ин талаба'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _mark(OralMark.correct),
              style: FilledButton.styleFrom(backgroundColor: emerald600, minimumSize: const Size.fromHeight(46)),
              child: const Text('Дуруст ҷавоб дод'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _mark(OralMark.incorrect),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800, minimumSize: const Size.fromHeight(46)),
              child: const Text('Нодуруст ҷавоб дод'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _mark(OralMark.unknown),
              style: FilledButton.styleFrom(backgroundColor: slate700, minimumSize: const Size.fromHeight(46)),
              child: const Text('Надонист'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _toggleSaved, child: Text(record.saved ? 'Аз «барои баъд» гирифтан' : 'Барои баъд')),
            OutlinedButton(onPressed: _toggleLearned, child: Text(record.learned ? 'Омӯхта шуд — бозгашт' : 'Омӯхта шуд')),
          ],
        ),
      ),
    );
  }
}

List<QuizPrompt> dayPrompts() => [
      for (final day in weekDays)
        QuizPrompt(id: day.id, title: day.english, answer: day.tajik, speak: day.english),
    ];
