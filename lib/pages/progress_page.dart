import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/student.dart';
import '../models/word.dart';
import '../models/word_learning.dart';
import '../services/progress_service.dart';
import '../services/student_service.dart';
import '../services/word_learning_service.dart';
import '../theme.dart';
import 'certificate_page.dart';

class ProgressPage extends StatelessWidget {
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
  final ProgressSnapshot snapshot;
  final VoidCallback onPractice;
  final VoidCallback onHistory;
  final VoidCallback onCalendar;

  const ProgressPage({
    super.key,
    required this.words,
    required this.learned,
    required this.saved,
    required this.snapshot,
    required this.onPractice,
    required this.onHistory,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final service = WordLearningService.instance;
    final sameStudent = service.studentId != null &&
        service.studentId == StudentService.instance.currentStudentId;
    final summary = sameStudent ? Lexicon.summary(words, service.byId) : null;
    final learnedCount = summary?.learned ?? learned.length;
    final savedCount = summary?.saved ?? saved.length;
    final earned = sameStudent
        ? Lexicon.certificateEarned(words, service.byId)
        : words.isNotEmpty && learned.length >= words.length && words.length >= 500;
    String? studentName;
    final currentId = StudentService.instance.currentStudentId;
    for (final student in StudentService.instance.students) {
      if (student.id == currentId) studentName = student.name;
    }
    final pct = words.isEmpty ? 0.0 : learnedCount / words.length;
    final practice = snapshot.misses.values.where((v) => v > 0).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Text(
          'Пешрафт',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 13,
                          color: emerald500,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(pct * 100).round()}%',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                          ),
                          const Text('пешрафт'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  studentName == null
                      ? '$learnedCount аз ${words.length} калима омӯхта шуд'
                      : '$studentName: $learnedCount аз ${words.length} калима омӯхта шуд',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                if (earned) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final student = await StudentService.instance.getCurrentStudent();
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificatePage(
                            student: student ?? Student(id: 'default', name: 'Талаба'),
                            wordCount: words.length,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Гирифтани сертификат'),
                  ),
                ],
                if (snapshot.streak > 0) ...[
                  const SizedBox(height: 8),
                  Text('🔥 ${snapshot.streak} рӯз пай дар пай', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Омӯхта', '$learnedCount'),
            _chip('Наомӯхта', '${summary?.unlearned ?? (words.length - learnedCount)}'),
            _chip('Барои баъд', '$savedCount'),
            _chip('Насанҷида', '${summary?.untested ?? words.length}'),
            _chip('Алифбо', '${snapshot.letters.length} / 26'),
            _chip('Гӯш', '${snapshot.listens}'),
            _chip('Санҷиш', '${snapshot.history.length}'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPractice,
                icon: const Icon(Icons.replay_rounded),
                label: Text('Боз такрор ($practice)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Натиҷаҳо'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onCalendar,
          icon: const Icon(Icons.calendar_month_rounded),
          label: const Text('Тақвими омӯзиш'),
        ),
        const SizedBox(height: 18),
        const Text('Мукофотҳо', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final item in achievementCatalog)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                item.icon,
                color: snapshot.achievements.contains(item.id) ? emerald600 : slate700,
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(item.text),
              trailing: snapshot.achievements.contains(item.id)
                  ? const Text('✓', style: TextStyle(color: emerald600, fontWeight: FontWeight.w900, fontSize: 18))
                  : const Text('○'),
            ),
          ),
        const SizedBox(height: 10),
        ...List.generate(weekCount, (i) {
          final week = i + 1;
          final list = words.where((w) => w.week == week).toList();
          final done = list.where((w) => w.isMarked(learned)).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: teal600.withValues(alpha: 0.16),
                child: Text(
                  '$week',
                  style: const TextStyle(color: teal700, fontWeight: FontWeight.w900),
                ),
              ),
              title: Text(
                'Ҳафтаи $week',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${weekTitles[week]} • $done аз ${list.length}'),
              trailing: SizedBox(
                width: 70,
                child: LinearProgressIndicator(
                  value: list.isEmpty ? 0 : done / list.length,
                  color: emerald500,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
