import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../models/word.dart';
import '../services/preferences_service.dart';
import '../services/progress_service.dart';
import '../services/reminder_service.dart';
import '../theme.dart';
import 'about_page.dart';
import 'calendar_page.dart';
import 'guide_page.dart';
import 'parent_hub_page.dart';
import 'parent_stats_page.dart';
import 'pin_gate.dart';

class SettingsPage extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final Future<String?> Function() onTestVoice;
  final List<Word> words;
  final Set<String> learned;
  final Future<void> Function() onResetProgress;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onTestVoice,
    required this.words,
    required this.learned,
    required this.onResetProgress,
  });

  bool get slow => settings.speechRate < 0.38;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Танзимот')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _section(
              icon: Icons.palette_rounded,
              title: 'Намуди барнома',
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark')),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('Auto')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) =>
                    onChanged(settings.copyWith(themeMode: value.first)),
              ),
            ),
            _section(
              icon: Icons.text_fields_rounded,
              title: 'Андозаи матн',
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('A',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Expanded(
                        child: Slider(
                          min: 0.85,
                          max: 1.25,
                          divisions: 8,
                          value: settings.textScale,
                          label: '${(settings.textScale * 100).round()}%',
                          onChanged: (value) =>
                              onChanged(settings.copyWith(textScale: value)),
                        ),
                      ),
                      const Text('A',
                          style: TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Text(
                      '${(settings.textScale * 100).round()}% — пешнамоиши андоза'),
                ],
              ),
            ),
            _section(
              icon: Icons.record_voice_over_rounded,
              title: 'Овози талаффуз',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'female',
                          icon: Icon(Icons.female),
                          label: Text('Зан')),
                      ButtonSegment(
                          value: 'male',
                          icon: Icon(Icons.male),
                          label: Text('Мард')),
                    ],
                    selected: {settings.voiceGender},
                    onSelectionChanged: (value) =>
                        onChanged(settings.copyWith(voiceGender: value.first)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Суръати овоз',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Одатӣ 1.0x')),
                      ButtonSegment(value: true, label: Text('Суст 0.75x')),
                    ],
                    selected: {slow},
                    onSelectionChanged: (value) => onChanged(settings.copyWith(
                        speechRate: value.first ? 0.32 : 0.45)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final message = await onTestVoice();
                      if (!context.mounted || message == null) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(message)));
                    },
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Санҷиши овоз'),
                  ),
                ],
              ),
            ),
            _section(
              icon: Icons.notifications_outlined,
              title: 'Огоҳиҳо',
              child: const Text(
                'Ёдрасҳо огоҳии Android ва TTS-ро истифода мебаранд. Агар телефони шумо огоҳӣ ё овози пасзаминаро маҳдуд кунад, барнома кушода мемонад ва экрани сиёҳ намедиҳад.',
              ),
            ),
            _section(
              icon: Icons.lock_rounded,
              title: 'Амният',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      final ok =
                          await unlockParent(context, title: 'Қисми волидон');
                      if (!ok || !context.mounted) return;
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentHubPage(
                              words: words, learned: learned, saved: const {}),
                        ),
                      );
                    },
                    child: const Text('Қисми волидон'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () async {
                      final ok =
                          await unlockParent(context, title: 'Омори омӯзиш');
                      if (!ok || !context.mounted) return;
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ParentStatsPage(
                                words: words, learned: learned)),
                      );
                    },
                    child: const Text('Омори омӯзиш'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CalendarPage()));
                    },
                    child: const Text('Тақвими омӯзиш'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _reset(context),
                    child: const Text('Сброси пешрафт'),
                  ),
                ],
              ),
            ),
            _section(
              icon: Icons.help_outline_rounded,
              title: 'Кӯмак',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const GuidePage()),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Дастурамал'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                    icon: const Icon(Icons.info_outline_rounded),
                    label: const Text('Дар бораи барнома'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context) async {
    final pinOk = await unlockParent(context, title: 'Сброси пешрафт');
    if (!pinOk || !context.mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сброси пешрафт'),
        content: const Text(
            'Ҳамаи пешрафт, натиҷаҳо ва захираҳои шумо пок мешаванд.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Бекор кардан')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Сброс кардан')),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final again = await unlockParent(context, title: 'Тасдиқи ниҳоӣ');
    if (!again || !context.mounted) return;
    final resetSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Танзимотро ҳам пок кунем?'),
        content: const Text(
            'Мавзӯъ, андозаи матн ва овоз ба ҳолати аввала бармегардад. PIN нигоҳ дошта мешавад.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Не')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ҳа')),
        ],
      ),
    );
    try {
      await PreferencesService.instance.saveSet('learned', {});
      await PreferencesService.instance.saveSet('saved', {});
      await ProgressService.instance.resetLearning();
      await ReminderService.instance.initialize();
      await onResetProgress();
      if (resetSettings == true) {
        onChanged(const AppSettings());
      }
    } catch (error) {
      debugPrint('Reset failed: $error');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Пешрафт пок шуд.')));
  }

  Widget _section(
      {required IconData icon, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: cyan600),
                  const SizedBox(width: 9),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
