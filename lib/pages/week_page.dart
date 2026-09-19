import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/word_card.dart';

class WeekPage extends StatefulWidget {
  final int week;
  final String title;
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;

  const WeekPage({
    super.key,
    required this.week,
    required this.title,
    required this.words,
    required this.learned,
    required this.saved,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
  });

  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  late Set<String> learned;
  late Set<String> saved;

  @override
  void initState() {
    super.initState();
    learned = {...widget.learned};
    saved = {...widget.saved};
  }

  Future<void> _save(Word word) async {
    await widget.onSave(word);
    if (!mounted) return;
    setState(() {
      if (word.isMarked(saved)) {
        saved.remove(word.id);
        saved.remove(word.english);
      } else {
        saved.add(word.id);
      }
    });
  }

  Future<void> _learn(Word word) async {
    await widget.onLearn(word);
    if (!mounted) return;
    setState(() => learned.add(word.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ҳафтаи ${widget.week}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [slate900, Color(0xFF134E4A)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: teal600.withValues(alpha: 0.55)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.words.length} калима • гӯш кунед, омӯзед ва барои баъд захира кунед',
                    style: const TextStyle(color: Color(0xFF99F6E4), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.words.isEmpty)
              const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Калима нест',
                text: 'Барои ин ҳафта калима ёфт нашуд.',
              ),
            for (var day = 1; day <= 5; day++) ...[
              if (widget.words.any((w) => w.day == day)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 6),
                  child: Text(
                    'Рӯзи $day • ${widget.words.where((w) => w.day == day).length} калима',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: cyan700),
                  ),
                ),
                ...widget.words.where((w) => w.day == day).map(
                      (word) => WordCard(
                        key: ValueKey(word.id),
                        word: word,
                        learned: word.isMarked(learned),
                        saved: word.isMarked(saved),
                        onSpeak: widget.onSpeak,
                        onSave: _save,
                        onLearn: _learn,
                        onRemind: widget.onRemind,
                      ),
                    ),
              ],
            ],
            ...widget.words.where((w) => w.day < 1 || w.day > 5).map(
                  (word) => WordCard(
                    key: ValueKey(word.id),
                    word: word,
                    learned: word.isMarked(learned),
                    saved: word.isMarked(saved),
                    onSpeak: widget.onSpeak,
                    onSave: _save,
                    onLearn: _learn,
                    onRemind: widget.onRemind,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
