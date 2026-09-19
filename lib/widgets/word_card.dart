import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme.dart';

/// Universal word card: theme-aware, hides empty sections, never shows "null".
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

class _WordCardWidgetState extends State<WordCardWidget> {
  bool exampleOpen = false;
  bool synOpen = false;
  bool formOpen = false;

  Word get word => widget.word;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onCard = scheme.onSurface;
    final muted = scheme.onSurface.withValues(alpha: 0.68);
    final voiceBadge =
        widget.voiceGender == 'male' ? 'Male Voice' : 'Female Voice';
    final synonyms = [
      for (final item in word.synonyms)
        if (item.trim().isNotEmpty && item.trim().toLowerCase() != 'null')
          item.trim()
    ];
    final antonyms = [
      for (final item in word.antonyms)
        if (item.trim().isNotEmpty && item.trim().toLowerCase() != 'null')
          item.trim()
    ];
    final showPhonetic = word.ipaLabel.isNotEmpty ||
        word.phoneticLabel.isNotEmpty ||
        word.stress.isNotEmpty;
    final showPairs = synonyms.isNotEmpty || antonyms.isNotEmpty;
    final showFormation = !word.formation.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? slate950 : scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: scheme.primary.withValues(alpha: dark ? 0.35 : 0.22)),
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
                          background: scheme.primary.withValues(alpha: 0.16),
                          foreground: scheme.primary,
                        ),
                        if (word.posLabel.isNotEmpty)
                          _badge(
                            word.posLabel,
                            background: scheme.surfaceContainerHighest,
                            foreground: onCard,
                          ),
                        if (word.cefr.isNotEmpty)
                          _badge(word.cefr,
                              background: cyan700, foreground: Colors.white),
                        if (widget.learned)
                          _badge(
                            'Омӯхта шуд',
                            background:
                                const Color(0xFF10B981).withValues(alpha: 0.2),
                            foreground:
                                dark ? const Color(0xFF6EE7B7) : emerald700,
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
                      widget.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: widget.saved ? emerald500 : scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                word.displayEnglish,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: onCard,
                  height: 1.05,
                ),
              ),
              if (word.pronunciation.trim().isNotEmpty)
                Text(
                  word.pronunciation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: muted, height: 1.2),
                ),
              Text(
                word.tajik,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: onCard,
                  height: 1.2,
                ),
              ),
              if (showPhonetic) ...[
                const SizedBox(height: 10),
                _phoneticBox(scheme, onCard, muted),
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
                title: 'Мисол дар ҷумла',
                open: exampleOpen,
                color: onCard,
                onTap: () => setState(() => exampleOpen = !exampleOpen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.example.isEmpty ? word.displayEnglish : word.example,
                      style:
                          TextStyle(color: onCard, fontWeight: FontWeight.w800),
                    ),
                    if (word.exampleTajik.isNotEmpty)
                      Text(word.exampleTajik, style: TextStyle(color: muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onSpeak(word.example.isEmpty
                                ? word.english
                                : word.example),
                            icon: const Icon(Icons.volume_up_rounded, size: 18),
                            label: const Text('Гӯш кардани ҷумла'),
                          ),
                        ),
                        _badge(
                          voiceBadge,
                          background: indigo600.withValues(alpha: 0.28),
                          foreground: dark ? Colors.white : indigo700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showPairs)
                _accordion(
                  title: 'Синонимҳо ва Антонимҳо',
                  open: synOpen,
                  color: onCard,
                  onTap: () => setState(() => synOpen = !synOpen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (synonyms.isNotEmpty) ...[
                        Text('Синонимҳо',
                            style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in synonyms)
                              _badge(
                                item,
                                background:
                                    scheme.primary.withValues(alpha: 0.14),
                                foreground: scheme.primary,
                              ),
                          ],
                        ),
                      ],
                      if (synonyms.isNotEmpty && antonyms.isNotEmpty)
                        const SizedBox(height: 10),
                      if (antonyms.isNotEmpty) ...[
                        Text('Антонимҳо',
                            style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in antonyms)
                              _badge(
                                item,
                                background:
                                    scheme.error.withValues(alpha: 0.12),
                                foreground: scheme.error,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              if (showFormation)
                _accordion(
                  title: 'Сохти калима',
                  open: formOpen,
                  color: onCard,
                  onTap: () => setState(() => formOpen = !formOpen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (word.formation.hasParts)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (word.formation.prefix.isNotEmpty)
                              _badge(word.formation.prefix,
                                  background: scheme.secondaryContainer,
                                  foreground: scheme.onSecondaryContainer),
                            if (word.formation.root.isNotEmpty)
                              _badge(word.formation.root,
                                  background: scheme.primaryContainer,
                                  foreground: scheme.onPrimaryContainer),
                            if (word.formation.suffix.isNotEmpty)
                              _badge(word.formation.suffix,
                                  background: scheme.tertiaryContainer,
                                  foreground: scheme.onTertiaryContainer),
                          ],
                        ),
                      if (word.formation.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(word.formation.note,
                            style: TextStyle(
                                color: onCard, fontWeight: FontWeight.w700)),
                      ],
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
                        onPressed:
                            widget.learned ? () {} : () => widget.onLearn(word),
                        icon: Icon(widget.learned
                            ? Icons.check_circle_rounded
                            : Icons.check_rounded),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emerald600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
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
                        foregroundColor: onCard,
                        side: BorderSide(color: scheme.outline),
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

  Widget _badge(String text,
      {required Color background, required Color foreground, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
                color: foreground, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _phoneticBox(ColorScheme scheme, Color onCard, Color muted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          if (word.ipaLabel.isNotEmpty)
            _phoneticItem('IPA', word.ipaLabel, onCard, muted),
          if (word.phoneticLabel.isNotEmpty)
            _phoneticItem('Phonetic', word.phoneticLabel, onCard, muted),
          if (word.stress.isNotEmpty)
            _phoneticItem('Stress', word.stress, onCard, muted),
        ],
      ),
    );
  }

  Widget _phoneticItem(String label, String value, Color onCard, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: muted, fontSize: 10, fontWeight: FontWeight.w800)),
        Text(value,
            style: TextStyle(color: onCard, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _accordion({
    required String title,
    required bool open,
    required Color color,
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
                  child: Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.expand_more_rounded,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild:
              Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
          crossFadeState:
              open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}
