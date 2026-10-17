import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/word.dart';
import '../models/word_learning.dart';
import '../services/student_service.dart';
import '../services/word_learning_service.dart';
import '../theme.dart';

String formatLearningStamp(int? at) {
  if (at == null || at <= 0) return 'ҳанӯз нест';
  final date = DateTime.fromMillisecondsSinceEpoch(at);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
}

String oralMarkLabel(OralMark mark) {
  switch (mark) {
    case OralMark.correct:
      return 'Дуруст';
    case OralMark.incorrect:
      return 'Нодуруст';
    case OralMark.unknown:
      return 'Надонист';
  }
}

Future<void> showWordHistory(BuildContext context, Word word) {
  final service = WordLearningService.instance;
  final current = StudentService.instance.currentStudentId;
  final record = service.studentId == current ? service.of(word.id) : const WordLearning();
  return showLearningHistory(
    context,
    title: word.displayEnglish,
    subtitle: word.tajik,
    record: record,
  );
}

Future<void> showLearningHistory(
  BuildContext context, {
  required String title,
  required String subtitle,
  required WordLearning record,
}) {
  final students = StudentService.instance;
  Student? student;
  final current = students.currentStudentId;
  for (final item in students.students) {
    if (item.id == current) student = item;
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          shrinkWrap: true,
          children: [
            Text(
              student?.name ?? 'Талаба',
              style: const TextStyle(fontWeight: FontWeight.w800, color: teal700),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _line('Омӯхта шуд', record.learned ? 'ҳа' : 'не'),
            _line('Барои баъд', record.saved ? 'ҳа' : 'не'),
            _line('Санҷида шудааст', record.quizzed ? 'ҳа' : 'не'),
            _line('Пурсишҳо', '${record.asked}'),
            _line('Ҷавобҳои дуруст', '${record.correct}'),
            _line('Ҷавобҳои нодуруст', '${record.incorrect}'),
            _line('Надонист', '${record.unknown}'),
            _line('Такрорҳо', '${record.repetitions}'),
            _line('Охирин пурсиш', formatLearningStamp(record.lastQuizAt)),
            _line('Охирин ҷавоби дуруст', formatLearningStamp(record.lastCorrectAt)),
            const SizedBox(height: 12),
            const Text('Таърихи пурсиш', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (record.history.isEmpty)
              const Text('Барои ин талаба ҳанӯз пурсиш сабт нашудааст.')
            else
              for (final attempt in record.history.reversed.take(12))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    attempt.mark == OralMark.correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: attempt.mark == OralMark.correct ? emerald600 : Colors.orange.shade800,
                  ),
                  title: Text(oralMarkLabel(attempt.mark), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(formatLearningStamp(attempt.at)),
                ),
          ],
        ),
      );
    },
  );
}

Widget _line(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}
