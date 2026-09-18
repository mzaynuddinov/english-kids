import 'package:flutter/material.dart';

import '../models/alphabet.dart';
import '../theme.dart';
import 'letter_page.dart';

class AlphabetPage extends StatelessWidget {
  final Set<String> learnedLetters;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(AlphabetLetter letter) onLearnLetter;

  const AlphabetPage({
    super.key,
    required this.learnedLetters,
    required this.onSpeak,
    required this.onLearnLetter,
  });

  @override
  Widget build(BuildContext context) {
    final done = alphabetLetters.where((l) => learnedLetters.contains(l.letter)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Алифбо')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              '$done / 26 ҳарф',
              style: const TextStyle(fontWeight: FontWeight.w800, color: cyan700),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: done / 26,
                minHeight: 10,
                color: emerald500,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alphabetLetters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, i) {
                final letter = alphabetLetters[i];
                final learned = learnedLetters.contains(letter.letter);
                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LetterPage(
                          letter: letter,
                          learned: learned,
                          onSpeak: onSpeak,
                          onLearn: onLearnLetter,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: learned
                            ? emerald500.withValues(alpha: 0.7)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              letter.letter,
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1),
                            ),
                            const Spacer(),
                            Text(letter.emoji, style: const TextStyle(fontSize: 22)),
                            if (learned)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.check_circle_rounded, color: emerald600, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(letter.ipa, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).hintColor)),
                        const Spacer(),
                        Text(letter.word, style: const TextStyle(fontWeight: FontWeight.w900)),
                        Text(letter.tajik, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
