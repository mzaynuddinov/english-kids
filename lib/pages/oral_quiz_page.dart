import 'package:flutter/material.dart';

import '../models/word.dart';
import '../models/word_learning.dart';
import '../services/student_service.dart';
import '../services/word_learning_service.dart';
import '../theme.dart';

class OralQuizPage extends StatefulWidget {
  final List<Word> words;
  final Future<void> Function(String text) onSpeak;

  const OralQuizPage({
    super.key,
    required this.words,
    required this.onSpeak,
  });

  @override
  State<OralQuizPage> createState() => _OralQuizPageState();
}

class _OralQuizPageState extends State<OralQuizPage> {
  OralScope scope = OralScope.all;
  List<Word> queue = const [];
  int index = 0;
  bool running = false;
  bool reveal = false;
  bool finished = false;
  int sessionCorrect = 0;
  int sessionIncorrect = 0;
  int sessionUnknown = 0;
  bool saving = false;

  String get _studentName {
    final id = StudentService.instance.currentStudentId;
    for (final student in StudentService.instance.students) {
      if (student.id == id) return student.name;
    }
    return 'Талаба';
  }

  Map<String, WordLearning> get _state => WordLearningService.instance.byId;

  void _start() {
    final selected = Lexicon.select(scope, widget.words, _state, DateTime.now());
    setState(() {
      queue = selected;
      index = 0;
      running = selected.isNotEmpty;
      finished = selected.isEmpty;
      reveal = false;
      sessionCorrect = 0;
      sessionIncorrect = 0;
      sessionUnknown = 0;
    });
  }

  Future<void> _mark(OralMark mark) async {
    if (saving || index >= queue.length) return;
    final word = queue[index];
    setState(() => saving = true);
    try {
      await WordLearningService.instance.record(word.id, mark);
    } catch (error, stack) {
      debugPrint('Oral quiz save failed: $error\n$stack');
    }
    if (!mounted) return;
    setState(() {
      saving = false;
      reveal = false;
      if (mark == OralMark.correct) sessionCorrect += 1;
      if (mark == OralMark.incorrect) sessionIncorrect += 1;
      if (mark == OralMark.unknown) sessionUnknown += 1;
      index += 1;
      if (index >= queue.length) {
        running = false;
        finished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пурсиши луғат'),
      ),
      body: SafeArea(
        child: running ? _session() : (finished ? _report(emptyQueue: queue.isEmpty) : _setup()),
      ),
    );
  }

  Widget _setup() {
    final now = DateTime.now();
    final summary = Lexicon.summary(widget.words, _state);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          _studentName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Аз талаба шифоҳӣ пурсед ва ҷавобро худатон сабт кунед. Натиҷа танҳо барои ҳамин талаба мемонад.',
          style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _count('Ҳама', '${summary.total}'),
            _count('Омӯхта', '${summary.learned}'),
            _count('Наомӯхта', '${summary.unlearned}'),
            _count('Барои баъд', '${summary.saved}'),
            _count('Нодуруст', '${summary.wrong}'),
            _count('Насанҷида', '${summary.untested}'),
          ],
        ),
        const SizedBox(height: 16),
        _scopeTile(OralScope.all, 'Ҳамаи калимаҳо', Lexicon.select(OralScope.all, widget.words, _state, now).length),
        _scopeTile(OralScope.unlearned, 'Ҳанӯз омӯхтанашуда', Lexicon.select(OralScope.unlearned, widget.words, _state, now).length),
        _scopeTile(OralScope.learned, 'Омӯхташуда', Lexicon.select(OralScope.learned, widget.words, _state, now).length),
        _scopeTile(OralScope.saved, 'Барои баъд монда', Lexicon.select(OralScope.saved, widget.words, _state, now).length),
        _scopeTile(OralScope.wrong, 'Қаблан нодуруст', Lexicon.select(OralScope.wrong, widget.words, _state, now).length),
        _scopeTile(OralScope.notToday, 'Имрӯз санҷиданашуда', Lexicon.select(OralScope.notToday, widget.words, _state, now).length),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.words.isEmpty ? null : _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Пурсишро оғоз кун'),
        ),
      ],
    );
  }

  Widget _scopeTile(OralScope value, String title, int count) {
    final selected = scope == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: selected ? cyan600 : null,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.w900)),
      onTap: () => setState(() => scope = value),
    );
  }

  Widget _session() {
    final word = queue[index];
    final record = WordLearningService.instance.of(word.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$_studentName · ${index + 1} / ${queue.length}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: queue.isEmpty ? 0 : index / queue.length,
            color: cyan600,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 18),
          Text(
            word.displayEnglish,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
          ),
          if (word.pronunciation.trim().isNotEmpty)
            Text(
              word.pronunciation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => widget.onSpeak(word.english),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Гӯш кардан'),
          ),
          const SizedBox(height: 8),
          if (!reveal)
            OutlinedButton(
              onPressed: () => setState(() => reveal = true),
              child: const Text('Ҷавобро нишон диҳ'),
            )
          else
            Text(
              word.tajik,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: teal700),
            ),
          const SizedBox(height: 8),
          Text(
            record.quizzed
                ? 'Қаблан: ${record.correct} дуруст, ${record.incorrect + record.unknown} нодуруст'
                : 'Ин калима ҳанӯз барои ин талаба санҷида нашудааст',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          FilledButton(
            onPressed: saving ? null : () => _mark(OralMark.correct),
            style: FilledButton.styleFrom(backgroundColor: emerald600, minimumSize: const Size.fromHeight(48)),
            child: const Text('Дуруст'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: saving ? null : () => _mark(OralMark.incorrect),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800, minimumSize: const Size.fromHeight(48)),
            child: const Text('Нодуруст'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: saving ? null : () => _mark(OralMark.unknown),
            style: FilledButton.styleFrom(backgroundColor: slate700, minimumSize: const Size.fromHeight(48)),
            child: const Text('Надонист · барои баъд'),
          ),
          TextButton(
            onPressed: saving
                ? null
                : () => setState(() {
                      running = false;
                      finished = true;
                    }),
            child: const Text('Хотима ва ҳисобот'),
          ),
        ],
      ),
    );
  }

  Widget _report({required bool emptyQueue}) {
    final asked = sessionCorrect + sessionIncorrect + sessionUnknown;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          emptyQueue ? 'Дар ин рӯйхат калима нест' : 'Ҳисоботи пурсиш',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(_studentName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 16),
        _count('Сабт шуд', '$asked'),
        _count('Дуруст', '$sessionCorrect'),
        _count('Нодуруст', '$sessionIncorrect'),
        _count('Надонист', '$sessionUnknown'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() {
            finished = false;
            running = false;
          }),
          child: const Text('Бозгашт ба интихоб'),
        ),
      ],
    );
  }

  Widget _count(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}
