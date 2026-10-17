import 'package:flutter/material.dart';

import '../models/alphabet.dart';
import '../models/days.dart';
import '../models/word.dart';
import '../services/student_service.dart';
import 'alphabet_page.dart';
import 'catalog_quiz_page.dart';
import 'oral_quiz_page.dart';
import 'week_page.dart';

class StudyStartPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оғози омӯзиш')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(_studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Мавзӯъро худатон интихоб кунед. Гузаштани мавзӯъҳои пешин шарт нест. Натиҷа танҳо барои талабаи ҷорӣ сабт мешавад.',
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
            () => _openWords(context, 'Рақамҳо', _topic('Numbers')),
            onQuiz: () => _openQuiz(context, 'Пурсиши рақамҳо', _topic('Numbers')),
          ),
          _tile(context, 'Рӯзҳои ҳафта', 'Days of the Week · 7', () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => CatalogQuizPage(title: 'Рӯзҳои ҳафта', prompts: dayPrompts(), onSpeak: onSpeak),
              ),
            );
          }),
          _tile(
            context,
            'Рангҳо',
            'Colors · ${_topic('Colors').length}',
            () => _openWords(context, 'Рангҳо', _topic('Colors')),
            onQuiz: () => _openQuiz(context, 'Пурсиши рангҳо', _topic('Colors')),
          ),
          _tile(
            context,
            'Калимаҳои ибтидоӣ',
            'Basics · ${_topic('Basics').length}',
            () => _openWords(context, 'Калимаҳои ибтидоӣ', _topic('Basics')),
            onQuiz: () => _openQuiz(context, 'Пурсиши калимаҳои ибтидоӣ', _topic('Basics')),
          ),
          _tile(context, 'Тамоми луғат', '500 калима', () {
            Navigator.push<void>(context, MaterialPageRoute(builder: (_) => OralQuizPage(words: words, onSpeak: onSpeak)));
          }),
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
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => OralQuizPage(words: list, onSpeak: onSpeak, title: title)),
    );
  }

  void _openWords(BuildContext context, String title, List<Word> list) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WeekPage(
          week: list.isEmpty ? 1 : list.first.week,
          title: title,
          words: list,
          learned: learned,
          saved: saved,
          onSpeak: onSpeak,
          onSave: onSave,
          onLearn: onLearn,
          onRemind: onRemind,
        ),
      ),
    );
  }

  void _openWeek(BuildContext context, int week) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WeekPage(
          week: week,
          title: weekTitles[week] ?? 'Ҳафтаи $week',
          words: words.where((word) => word.week == week).toList(),
          learned: learned,
          saved: saved,
          onSpeak: onSpeak,
          onSave: onSave,
          onLearn: onLearn,
          onRemind: onRemind,
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String subtitle, VoidCallback onTap, {VoidCallback? onQuiz}) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onQuiz != null)
              IconButton(
                tooltip: 'Пурсиш',
                onPressed: onQuiz,
                icon: const Icon(Icons.record_voice_over_rounded),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
