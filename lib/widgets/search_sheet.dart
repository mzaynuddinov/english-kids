import 'package:flutter/material.dart';

import '../models/word.dart';
import '../models/word_search.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import 'word_card.dart';

Future<void> openWordSearch(
  BuildContext context, {
  required List<Word> words,
  required Set<String> learned,
  required Set<String> saved,
  required Future<void> Function(String text) onSpeak,
  required Future<void> Function(Word word) onSave,
  required Future<void> Function(Word word) onLearn,
  required Future<void> Function(Word word) onRemind,
  String voiceGender = 'female',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return _SearchSheet(
        words: words,
        learned: learned,
        saved: saved,
        onSpeak: onSpeak,
        onSave: onSave,
        onLearn: onLearn,
        onRemind: onRemind,
        voiceGender: voiceGender,
      );
    },
  );
}

class _SearchSheet extends StatefulWidget {
  final List<Word> words;
  final Set<String> learned;
  final Set<String> saved;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(Word word) onSave;
  final Future<void> Function(Word word) onLearn;
  final Future<void> Function(Word word) onRemind;
  final String voiceGender;

  const _SearchSheet({
    required this.words,
    required this.learned,
    required this.saved,
    required this.onSpeak,
    required this.onSave,
    required this.onLearn,
    required this.onRemind,
    required this.voiceGender,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final controller = TextEditingController();
  List<String> recent = const [];
  List<WordSearchHit> hits = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final values = await PreferencesService.instance.loadSet('recent_searches');
    if (!mounted) return;
    setState(() => recent = values.toList().reversed.take(8).toList());
  }

  Future<void> _remember(String query) async {
    final next = {...recent.reversed, query.trim()}.toList();
    if (next.length > 12) next.removeRange(0, next.length - 12);
    await PreferencesService.instance.saveSet('recent_searches', next.toSet());
    if (mounted) setState(() => recent = next.reversed.take(8).toList());
  }

  void _query(String value) {
    setState(() => hits = searchWords(widget.words, value));
  }

  Future<void> _openLearned(Word word) async {
    await _remember(
        controller.text.trim().isEmpty ? word.english : controller.text.trim());
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            WordCardWidget(
              word: word,
              learned: true,
              saved: word.isMarked(widget.saved),
              onSpeak: widget.onSpeak,
              onSave: widget.onSave,
              onLearn: widget.onLearn,
              onRemind: widget.onRemind,
              voiceGender: widget.voiceGender,
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (context, scroll) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cyan600.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Ҷустуҷӯ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                  'Калимаҳои омӯхташударо кушоед. Қулфшудаҳо танҳо нишон дода мешаванд.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _query,
                onSubmitted: (value) {
                  _query(value);
                  if (value.trim().isNotEmpty) {
                    _remember(value);
                  }
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Hello / салом',
                  border: OutlineInputBorder(),
                ),
              ),
              if (controller.text.trim().isEmpty && recent.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Ҷустуҷӯҳои охирин',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in recent)
                      ActionChip(
                        label: Text(item),
                        onPressed: () {
                          controller.text = item;
                          _query(item);
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (controller.text.trim().isEmpty)
                const Text('Калима, тарҷума ё талаффузро нависед.')
              else if (hits.isEmpty)
                const Text('Ҳеҷ калима ёфт нашуд.')
              else
                for (final hit in hits)
                  _SearchTile(
                    hit: hit,
                    learned: hit.word.isMarked(widget.learned),
                    onOpen: () => _openLearned(hit.word),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchTile extends StatelessWidget {
  final WordSearchHit hit;
  final bool learned;
  final VoidCallback onOpen;

  const _SearchTile(
      {required this.hit, required this.learned, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(learned ? Icons.menu_book_rounded : Icons.lock_rounded,
            color: learned ? teal600 : cyan700),
        title: Text(hit.word.displayEnglish,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${hit.word.tajik} • Ҳафтаи ${hit.word.week}'),
        trailing: learned
            ? const Icon(Icons.chevron_right_rounded)
            : const Text('🔒', style: TextStyle(fontSize: 18)),
        onTap: learned
            ? onOpen
            : () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                          '🔒 Аввал ин калимаро дар Ҳафтаи ${hit.word.week} омӯзед.'),
                    ),
                  );
              },
      ),
    );
  }
}
