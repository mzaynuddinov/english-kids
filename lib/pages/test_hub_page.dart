import 'package:flutter/material.dart';

import '../models/test_models.dart';
import '../services/progress_service.dart';
import '../theme.dart';

class TestHubPage extends StatelessWidget {
  final Future<void> Function(TestKind kind) onStart;
  final VoidCallback onHistory;

  const TestHubPage({
    super.key,
    required this.onStart,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final active = ProgressService.instance.snapshot.active;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Санҷиш'),
        actions: [
          IconButton(
            tooltip: 'Натиҷаҳои санҷиш',
            onPressed: onHistory,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (active != null && !active.completed)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_rounded, color: teal600),
                  title: const Text('Санҷишро идома медиҳед?', style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('${active.kindLabel} • саволи ${active.index + 1} / ${active.total}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onStart(active.kind),
                ),
              ),
            const SizedBox(height: 10),
            _tile(
              icon: Icons.abc_rounded,
              title: 'Санҷиши Алифбо',
              text: 'Ҳарфҳо омехта, як ҳарф дар як вақт',
              onTap: () => onStart(TestKind.alphabet),
            ),
            _tile(
              icon: Icons.menu_book_rounded,
              title: 'Санҷиши калимаҳо',
              text: 'Танҳо калимаҳои омӯхта — то 25 савол',
              onTap: () => onStart(TestKind.vocabulary),
            ),
            _tile(
              icon: Icons.extension_rounded,
              title: 'Мушкилоти имрӯз',
              text: 'Тақрибан 30 савол, якто-якто',
              onTap: () => onStart(TestKind.daily),
            ),
            const SizedBox(height: 8),
            Text(
              'Ҳар савол як бор ҷавоб дода мешавад. Ба қафо баргашта ҷавобро иваз карда наметавонед.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({required IconData icon, required String title, required String text, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [indigo600, blue600]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(text),
          trailing: const Icon(Icons.chevron_right_rounded, color: cyan600),
        ),
      ),
    );
  }
}
