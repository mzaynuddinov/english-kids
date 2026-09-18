import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final Future<String?> Function() onTestVoice;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onTestVoice,
  });

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
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('Auto'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) => onChanged(settings.copyWith(themeMode: value.first)),
              ),
            ),
            _section(
              icon: Icons.text_fields_rounded,
              title: 'Андозаи матн',
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Expanded(
                        child: Slider(
                          min: 0.85,
                          max: 1.25,
                          divisions: 8,
                          value: settings.textScale,
                          label: '${(settings.textScale * 100).round()}%',
                          onChanged: (value) => onChanged(settings.copyWith(textScale: value)),
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Text('${(settings.textScale * 100).round()}% — пешнамоиши андоза'),
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
                        label: Text('Зан'),
                      ),
                      ButtonSegment(
                        value: 'male',
                        icon: Icon(Icons.male),
                        label: Text('Мард'),
                      ),
                    ],
                    selected: {settings.voiceGender},
                    onSelectionChanged: (value) =>
                        onChanged(settings.copyWith(voiceGender: value.first)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: cyan600),
                      const SizedBox(width: 8),
                      const Text('Суръати овоз'),
                      Expanded(
                        child: Slider(
                          min: 0.25,
                          max: 0.65,
                          value: settings.speechRate,
                          onChanged: (value) => onChanged(settings.copyWith(speechRate: value)),
                        ),
                      ),
                    ],
                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
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
