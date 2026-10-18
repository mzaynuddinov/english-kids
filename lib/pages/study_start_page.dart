import 'package:flutter/material.dart';

import '../models/alphabet.dart';
import '../models/days.dart';
import '../models/progress_rules.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import '../services/student_service.dart';
import '../services/word_learning_service.dart';
import 'alphabet_page.dart';
import 'catalog_quiz_page.dart';
import 'oral_quiz_page.dart';
import 'week_page.dart';

class StudyStartPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
  final Set<String> letters;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;
  final Future<void> Function(AlphabetLetter letter) onLearnLetter;

  const StudyStartPage({
    super.key,
    required this.words,
    required this.learned,
    required this.saved,
    required this.letters,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
    required this.onLearnLetter,
  });

  String get _studentName {
    final id = StudentService.instance.currentStudentId;
    for (final student in StudentService.instance.students) {
      if (student.id == id) return student.name;
    }
    return 'Талаба интихоб нашудааст';
  }

  List<Word> _topic(String topic) => words.where((word) => word.topic == topic).toList();

  Set<String> get _activeLetters {
    final learning = WordLearningService.instance;
    final fromProgress = ProgressService.instance.snapshot.letters;
    if (learning.studentId == null) return {...fromProgress, ...letters};
    return {
      ...fromProgress,
      for (final id in learning.learnedIds())
        if (id.startsWith('letter:') && id.length > 7) id.substring(7),
    };
  }

  Set<String> get _activeLearned {
    final learning = WordLearningService.instance;
    if (learning.studentId == null) return learned;
    return learning.learnedIds();
  }

  Set<String> get _activeSaved {
    final learning = WordLearningService.instance;
    if (learning.studentId == null) return saved;
    return learning.savedIds();
  }

  bool _open(int week) => weekUnlocked(week, _activeLetters, words, _activeLearned);

  List<Word> _openTopic(String topic) => _topic(topic).where((word) => _open(word.week)).toList();

  String _topicLock(String topic) {
    if (!alphabetComplete(_activeLetters)) return lockReason(1);
    final list = _topic(topic);
    if (list.isEmpty) return lockReason(1);
    for (final word in list) {
      if (!_open(word.week)) return lockReason(word.week);
    }
    return lockReason(1);
  }

  void _blocked(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ProgressService.instance,
        WordLearningService.instance,
        StudentService.instance,
      ]),
      builder: (context, _) => _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оғози омӯзиш')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(_studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Аввал алифбо. Ҳафтаи навбатӣ танҳо пас аз анҷоми ҳафтаи пеш кушода мешавад. Натиҷа барои талабаи ҷорӣ сабт мешавад.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _tile(context, 'Алифбои англисӣ', 'English Alphabet · 26 ҳарф', () {
            Navigator.push<void>(context, MaterialPageRoute(builder: (_) => AlphabetPage(onSpeak: onSpeak, onLearnLetter: onLearnLetter)));
          }),
          _tile(context, 'Пурсиши алифбо', 'Ҳарфи калон ва хурд: A a', () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => CatalogQuizPage(
                  title: 'Пурсиши алифбо',
                  onSpeak: onSpeak,
                  prompts: [
                    for (final letter in alphabetLetters)
                      QuizPrompt(
                        id: letterLearningId(letter.letter),
                        title: '${letter.letter} ${letter.letter.toLowerCase()}',
                        answer: '${letter.word} · ${letter.tajik}',
                        speak: letter.letter,
                      ),
                  ],
                ),
              ),
            );
          }),
          _tile(
            context,
            'Рақамҳо',
            'Numbers · ${_topic('Numbers').length}',
            () => _openWords(context, 'Рақамҳо', _openTopic('Numbers')),
            onQuiz: () => _openQuiz(context, 'Пурсиши рақамҳо', _openTopic('Numbers')),
            locked: _openTopic('Numbers').isEmpty,
            lockText: _topicLock('Numbers'),
          ),
          _tile(
            context,
            'Рӯзҳои ҳафта',
            'Days of the Week · 7',
            () {
              if (!alphabetComplete(_activeLetters)) {
                _blocked(context, lockReason(1));
                return;
              }
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => CatalogQuizPage(title: 'Рӯзҳои ҳафта', prompts: dayPrompts(), onSpeak: onSpeak),
                ),
              );
            },
            locked: !alphabetComplete(_activeLetters),
            lockText: lockReason(1),
          ),
          _tile(
            context,
            'Рангҳо',
            'Colors · ${_topic('Colors').length}',
            () => _openWords(context, 'Рангҳо', _openTopic('Colors')),
            onQuiz: () => _openQuiz(context, 'Пурсиши рангҳо', _openTopic('Colors')),
            locked: _openTopic('Colors').isEmpty,
            lockText: _topicLock('Colors'),
          ),
          _tile(
            context,
            'Калимаҳои ибтидоӣ',
            'Basics · ${_topic('Basics').length}',
            () => _openWords(context, 'Калимаҳои ибтидоӣ', _openTopic('Basics')),
            onQuiz: () => _openQuiz(context, 'Пурсиши калимаҳои ибтидоӣ', _openTopic('Basics')),
            locked: _openTopic('Basics').isEmpty,
            lockText: _topicLock('Basics'),
          ),
          _tile(
            context,
            'Тамоми луғати кушода',
            'Танҳо ҳафтаҳои кушода',
            () => _openQuiz(context, 'Пурсиши луғат', words.where((word) => _open(word.week)).toList()),
            locked: !words.any((word) => _open(word.week)),
            lockText: lockReason(1),
          ),
          const SizedBox(height: 8),
          const Text('Ҳафтаҳои мавҷуда', style: TextStyle(fontWeight: FontWeight.w900)),
          for (var week = 1; week <= weekCount; week++)
            _tile(
              context,
              'Ҳафтаи $week',
              weekTitles[week] ?? '',
              () => _openWeek(context, week),
              onQuiz: () => _openQuiz(
                context,
                'Пурсиши ҳафтаи $week',
                words.where((word) => word.week == week).toList(),
              ),
              locked: !_open(week),
              lockText: lockReason(week),
            ),
          const SizedBox(height: 12),
          const Text(
            'Моҳҳои сол ҳамчун мавзӯи алоҳида дар луғат нестанд. Курси 12-моҳа сохта нашуд, то мундариҷаи тайёрнашуда илова нашавад.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _openQuiz(BuildContext context, String title, List<Word> list) {
    if (list.isEmpty || list.any((word) => !_open(word.week))) {
      _blocked(context, list.isEmpty ? lockReason(1) : lockReason(list.first.week));
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => OralQuizPage(words: list, onSpeak: onSpeak, title: title)),
    );
  }

  void _openWords(BuildContext context, String title, List<Word> list) {
    if (list.isEmpty || list.any((word) => !_open(word.week))) {
      _blocked(context, lockReason(1));
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WeekPage(
          week: list.first.week,
          title: title,
          words: list,
          learned: _activeLearned,
          saved: _activeSaved,
          onSpeak: onSpeak,
          onSave: onSave,
          onLearn: onLearn,
          onRemind: onRemind,
        ),
      ),
    );
  }

  void _openWeek(BuildContext context, int week) {
    if (!_open(week)) {
      _blocked(context, lockReason(week));
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WeekPage(
          week: week,
          title: weekTitles[week] ?? 'Ҳафтаи $week',
          words: words.where((word) => word.week == week).toList(),
          learned: _activeLearned,
          saved: _activeSaved,
          onSpeak: onSpeak,
          onSave: onSave,
          onLearn: onLearn,
          onRemind: onRemind,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap, {
    VoidCallback? onQuiz,
    bool locked = false,
    String? lockText,
  }) {
    return Card(
      child: ListTile(
        title: Text(locked ? '🔒 $title' : title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(locked ? (lockText ?? subtitle) : subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onQuiz != null)
              IconButton(
                tooltip: 'Пурсиш',
                onPressed: locked
                    ? () => _blocked(context, lockText ?? lockReason(1))
                    : onQuiz,
                icon: const Icon(Icons.record_voice_over_rounded),
              ),
            Icon(locked ? Icons.lock_rounded : Icons.chevron_right_rounded),
          ],
        ),
        onTap: locked ? () => _blocked(context, lockText ?? lockReason(1)) : onTap,
      ),
    );
  }
}
