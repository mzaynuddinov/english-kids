import 'package:flutter/material.dart';

import '../models/alphabet.dart';
import '../services/progress_service.dart';
import '../theme.dart';

class AlphabetPage extends StatefulWidget {
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(AlphabetLetter letter) onLearnLetter;
  final ValueChanged<int>? onIndex;

  const AlphabetPage({
    super.key,
    required this.onSpeak,
    required this.onLearnLetter,
    this.onIndex,
  });

  @override
  State<AlphabetPage> createState() => _AlphabetPageState();
}

class _AlphabetPageState extends State<AlphabetPage> with SingleTickerProviderStateMixin {
  late final PageController controller;
  late int index;
  late final AnimationController pulse;

  @override
  void initState() {
    super.initState();
    index = ProgressService.instance.snapshot.alphabetIndex.clamp(0, 25);
    controller = PageController(initialPage: index);
    pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    pulse.dispose();
    super.dispose();
  }

  void _go(int next) {
    if (next < 0 || next > 25) return;
    controller.animateToPage(next, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final letters = ProgressService.instance.snapshot.letters;
        final done = alphabetLetters.where((l) => letters.contains(l.letter)).length;
        final item = alphabetLetters[index];
        final learned = letters.contains(item.letter);
        return Scaffold(
          appBar: AppBar(title: const Text('Алифбо')),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('$done / 26 ҳарф', style: const TextStyle(fontWeight: FontWeight.w800, color: cyan700)),
                          const Spacer(),
                          if (done >= 26)
                            const Text('🎉 Алифбо пурра омӯхта шуд!', style: TextStyle(fontWeight: FontWeight.w900, color: emerald600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(value: done / 26, minHeight: 8, color: emerald500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: 26,
                    onPageChanged: (value) {
                      setState(() => index = value);
                      widget.onIndex?.call(value);
                    },
                    itemBuilder: (context, i) {
                      final pane = alphabetLetters[i];
                      return _LetterCard(letter: pane);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: index > 0
                            ? FadeTransition(
                                opacity: Tween(begin: 0.45, end: 1.0).animate(pulse),
                                child: IconButton(
                                  tooltip: 'Ҳарфи қаблӣ',
                                  onPressed: () => _go(index - 1),
                                  icon: const Icon(Icons.chevron_left_rounded, size: 32, color: cyan700),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: Text(
                          'Кашед  ←  ${item.letter}  →',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: cyan700),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: index < 25
                            ? FadeTransition(
                                opacity: Tween(begin: 0.45, end: 1.0).animate(pulse),
                                child: IconButton(
                                  tooltip: 'Ҳарфи навбатӣ',
                                  onPressed: () => _go(index + 1),
                                  icon: const Icon(Icons.chevron_right_rounded, size: 32, color: cyan700),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => widget.onSpeak(item.letter),
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('🔊 Ҳарф'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => widget.onSpeak(item.word),
                          icon: const Icon(Icons.record_voice_over_rounded),
                          label: const Text('🔊 Калима'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: learned ? () {} : () => widget.onLearnLetter(item),
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
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    itemCount: 26,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final chip = alphabetLetters[i];
                      final selected = i == index;
                      final ok = letters.contains(chip.letter);
                      return GestureDetector(
                        onTap: () => _go(i),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: selected ? teal600 : (ok ? emerald600.withValues(alpha: 0.18) : cyan600.withValues(alpha: 0.12)),
                          child: Text(
                            chip.letter,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: selected ? Colors.white : (ok ? emerald700 : cyan700),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LetterCard extends StatelessWidget {
  final AlphabetLetter letter;

  const _LetterCard({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [slate950, Color(0xFF134E4A)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cyan600.withValues(alpha: 0.55)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(letter.emoji, style: const TextStyle(fontSize: 40)),
            Text(
              letter.letter,
              style: const TextStyle(color: Colors.white, fontSize: 68, fontWeight: FontWeight.w900, height: 1),
            ),
            Text(letter.ipa, style: const TextStyle(color: Color(0xFF99F6E4), fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text(letter.word, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(letter.wordIpa, style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700)),
            Text(letter.tajik, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
