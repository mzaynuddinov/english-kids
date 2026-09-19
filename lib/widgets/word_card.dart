import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';

/// Compact dark word card: badges, IPA glass box, 3 accordions, learned toggle.
class WordCardWidget extends StatefulWidget {
  final Word word;
  final bool learned;
  final bool saved;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;
  final String voiceGender;

  const WordCardWidget({
    super.key,
    required this.word,
    required this.learned,
    required this.saved,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
    this.voiceGender = 'female',
  });

  @override
  State<WordCardWidget> createState() => _WordCardWidgetState();
}

typedef WordCard = WordCardWidget;

class _WordCardWidgetState extends State<WordCardWidget> with SingleTickerProviderStateMixin {
  bool exampleOpen = false;
  bool synOpen = false;
  bool originOpen = false;
  late final AnimationController play;

  Word get word => widget.word;

  @override
  void initState() {
    super.initState();
    play = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void dispose() {
    play.dispose();
    super.dispose();
  }

  Future<void> _speakExample() async {
    play
      ..reset()
      ..forward();
    await widget.onSpeak(word.example.isEmpty ? word.english : word.example);
  }

  @override
  Widget build(BuildContext context) {
    final voiceBadge = widget.voiceGender == 'male' ? 'Male Voice' : 'Female Voice';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: slate950,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cyan600.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _badge(
                          word.topic.isEmpty ? 'Greetings' : word.topic,
                          background: Colors.blue.shade900.withValues(alpha: 0.4),
                          foreground: const Color(0xFFBFDBFE),
                        ),
                        if (word.posLabel.isNotEmpty)
                          _badge(
                            word.posLabel,
                            background: slate800,
                            foreground: const Color(0xFFE2E8F0),
                          ),
                        if (word.cefr.isNotEmpty)
                          _badge(word.cefr, background: cyan700, foreground: Colors.white),
                        if (widget.learned)
                          _badge(
                            'Омӯхта шуд',
                            background: const Color(0xFF10B981).withValues(alpha: 0.2),
                            foreground: const Color(0xFF6EE7B7),
                            icon: Icons.check_rounded,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: widget.saved ? 'Аз захира хориҷ' : 'Барои баъд',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onSave(word),
                    icon: Icon(
                      widget.saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: widget.saved ? emerald500 : cyan500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                word.displayEnglish,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.05,
                ),
              ),
              Text(
                word.pronunciation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                  height: 1.2,
                ),
              ),
              Text(
                word.tajik,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade200,
                  height: 1.2,
                ),
              ),
              if (word.ipaLabel.isNotEmpty || word.phoneticLabel.isNotEmpty || word.stress.isNotEmpty) ...[
                const SizedBox(height: 10),
                _phoneticBox(),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.tonalIcon(
                  onPressed: () => widget.onSpeak(word.english),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Гӯш кардан'),
                ),
              ),
              const SizedBox(height: 4),
              _accordion(
                title: 'Ҷумлаи мисол',
                open: exampleOpen,
                onTap: () => setState(() => exampleOpen = !exampleOpen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.example.isEmpty ? word.displayEnglish : word.example,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    if (word.exampleTajik.isNotEmpty)
                      Text(word.exampleTajik, style: TextStyle(color: Colors.grey.shade300)),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: play,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: play.isAnimating || play.value > 0 && play.value < 1 ? play.value : 0,
                            color: emerald500,
                            backgroundColor: slate800,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _speakExample,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: cyan600),
                            ),
                            icon: const Icon(Icons.volume_up_rounded, size: 18),
                            label: const Text('Гӯш кардани ҷумла'),
                          ),
                        ),
                        _badge(voiceBadge, background: indigo600.withValues(alpha: 0.35), foreground: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              _accordion(
                title: 'Синонимҳо ва Антонимҳо',
                open: synOpen,
                onTap: () => setState(() => synOpen = !synOpen),
                child: word.synonyms.isEmpty && word.antonyms.isEmpty
                    ? Text('Ҳоло синоним ё антоним нест.', style: TextStyle(color: Colors.grey.shade300))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (word.synonyms.isNotEmpty)
                            Text(
                              'Синонимҳо: ${word.synonyms.join(', ')}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          if (word.antonyms.isNotEmpty)
                            Text('Антонимҳо: ${word.antonyms.join(', ')}', style: TextStyle(color: Colors.grey.shade200)),
                        ],
                      ),
              ),
              _accordion(
                title: 'Решаи калима',
                open: originOpen,
                onTap: () => setState(() => originOpen = !originOpen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (word.posLabel.isNotEmpty)
                      Text(word.posLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    Text(
                      word.origin.isNotEmpty
                          ? word.origin
                          : (word.grammarNote.isNotEmpty ? word.grammarNote : 'Решаи калима дар луғати кӯдакона.'),
                      style: TextStyle(color: Colors.grey.shade200),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: widget.learned ? () {} : () => widget.onLearn(word),
                        icon: Icon(widget.learned ? Icons.check_circle_rounded : Icons.check_rounded),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emerald600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        label: const Text('Омӯхта шуд'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onRemind(word),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: slate700),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.alarm_rounded),
                      label: const Text('Ёдрас'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, {required Color background, required Color foreground, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _phoneticBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          if (word.ipaLabel.isNotEmpty) _phoneticItem('IPA', word.ipaLabel),
          if (word.phoneticLabel.isNotEmpty) _phoneticItem('Phonetic', word.phoneticLabel),
          if (word.stress.isNotEmpty) _phoneticItem('Stress', word.stress),
        ],
      ),
    );
  }

  Widget _phoneticItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w800)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _accordion({
    required String title,
    required bool open,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.expand_more_rounded, color: cyan500),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
          crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}
