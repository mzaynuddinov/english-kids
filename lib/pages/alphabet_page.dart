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
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: controller,
                        itemCount: 26,
                        onPageChanged: (value) {
                          setState(() => index = value);
                          widget.onIndex?.call(value);
                        },
                        itemBuilder: (context, i) {
                          final item = alphabetLetters[i];
                          final ok = letters.contains(item.letter);
                          return _LetterPane(
                            letter: item,
                            learned: ok,
                            onSpeak: widget.onSpeak,
                            onLearn: widget.onLearnLetter,
                          );
                        },
                      ),
                      if (index > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FadeTransition(
                            opacity: Tween(begin: 0.45, end: 0.95).animate(pulse),
                            child: IconButton(
                              tooltip: 'Ҳарфи қаблӣ',
                              onPressed: () => _go(index - 1),
                              icon: const Icon(Icons.chevron_left_rounded, size: 32, color: cyan700),
                            ),
                          ),
                        ),
                      if (index < 25)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FadeTransition(
                            opacity: Tween(begin: 0.45, end: 0.95).animate(pulse),
                            child: IconButton(
                              tooltip: 'Ҳарфи навбатӣ',
                              onPressed: () => _go(index + 1),
                              icon: const Icon(Icons.chevron_right_rounded, size: 32, color: cyan700),
                            ),
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
                      final item = alphabetLetters[i];
                      final selected = i == index;
                      final ok = letters.contains(item.letter);
                      return GestureDetector(
                        onTap: () => _go(i),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: selected ? teal600 : (ok ? emerald600.withValues(alpha: 0.18) : cyan600.withValues(alpha: 0.12)),
                          child: Text(
                            item.letter,
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

class _LetterPane extends StatelessWidget {
  final AlphabetLetter letter;
  final bool learned;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(AlphabetLetter letter) onLearn;

  const _LetterPane({
    required this.letter,
    required this.learned,
    required this.onSpeak,
    required this.onLearn,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [slate950, Color(0xFF134E4A)]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cyan600.withValues(alpha: 0.55)),
          ),
          child: Column(
            children: [
              Text(letter.emoji, style: const TextStyle(fontSize: 42)),
              Text(
                letter.letter,
                style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, height: 1),
              ),
              Text(letter.ipa, style: const TextStyle(color: Color(0xFF99F6E4), fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              Text(letter.word, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              Text(letter.wordIpa, style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700)),
              Text(letter.tajik, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: FilledButton.tonalIcon(
            onPressed: () => onSpeak(letter.letter),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('🔊 Ҳарф'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () => onSpeak(letter.word),
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text('🔊 Калима'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: learned ? () {} : () => onLearn(letter),
            style: FilledButton.styleFrom(
              backgroundColor: learned ? emerald600 : teal600,
              foregroundColor: Colors.white,
            ),
            icon: Icon(learned ? Icons.check_circle_rounded : Icons.check_rounded),
            label: Text(learned ? 'Омӯхта шуд' : 'Омӯхтам'),
          ),
        ),
      ],
    );
  }
}
