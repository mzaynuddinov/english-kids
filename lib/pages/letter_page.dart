import 'package:flutter/material.dart';

import '../models/alphabet.dart';
import '../theme.dart';

class LetterPage extends StatefulWidget {
  final AlphabetLetter letter;
  final bool learned;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(AlphabetLetter letter) onLearn;

  const LetterPage({
    super.key,
    required this.letter,
    required this.learned,
    required this.onSpeak,
    required this.onLearn,
  });

  @override
  State<LetterPage> createState() => _LetterPageState();
}

class _LetterPageState extends State<LetterPage> {
  late bool learned;

  @override
  void initState() {
    super.initState();
    learned = widget.learned;
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;
    return Scaffold(
      appBar: AppBar(title: Text('Ҳарфи ${letter.letter}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [slate950, Color(0xFF134E4A)]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cyan600.withValues(alpha: 0.55)),
              ),
              child: Column(
                children: [
                  Text(letter.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 6),
                  Text(
                    letter.letter,
                    style: const TextStyle(color: Colors.white, fontSize: 88, fontWeight: FontWeight.w900, height: 1),
                  ),
                  Text(letter.ipa, style: const TextStyle(color: Color(0xFF99F6E4), fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 10),
                  Text(
                    letter.word,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  Text(letter.wordIpa, style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(letter.tajik, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: FilledButton.tonalIcon(
                onPressed: () => widget.onSpeak(letter.letter),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Овози ҳарф'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => widget.onSpeak(letter.word),
                icon: const Icon(Icons.record_voice_over_rounded),
                label: Text('Овози ${letter.word}'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: learned
                    ? () {}
                    : () async {
                        await widget.onLearn(letter);
                        if (mounted) setState(() => learned = true);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: learned ? emerald600 : teal600,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(learned ? Icons.check_circle_rounded : Icons.check_rounded),
                label: Text(learned ? 'Омӯхта шуд' : 'Омӯхтам'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
