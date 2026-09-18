import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/app_logo.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дар бораи барнома')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: const [
            Center(child: AppLogo(size: 120)),
            SizedBox(height: 14),
            Center(
              child: Text(
                appName,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 6),
            Center(
              child: Text(
                'Омӯзиши англисӣ барои кӯдакон',
                style: TextStyle(color: cyan600, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(height: 24),
            _AboutCard(),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Offline • Барои кӯдакон • Тоҷикистон 🇹🇯',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(height: 5),
            Center(child: Text('Версия $appVersion', style: TextStyle(color: slate700))),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Чӣ кор мекунад', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: 12),
            _Feature(Icons.abc_rounded, 'Алифбои A–Z бо калима, emoji ва талаффуз.'),
            _Feature(Icons.menu_book_rounded, 'Луғати англисӣ бо маънои тоҷикӣ, офлайн.'),
            _Feature(Icons.headphones_rounded, 'Гӯш кардан ва навиштани калима.'),
            _Feature(Icons.extension_rounded, 'Санҷишҳои пайдарпай: алифбо, калимаҳо ва мушкилоти имрӯз.'),
            _Feature(Icons.alarm_rounded, 'Ёдрасҳо бо такрор, огоҳӣ ва TTS.'),
            _Feature(Icons.insights_rounded, 'Пешрафт, мукофотҳо ва рӯзҳои пай дар пай.'),
            _Feature(Icons.bookmark_rounded, 'Барои баъд ва калимаҳои душвор ҷудо нигоҳ дошта мешаванд.'),
            _Feature(Icons.dark_mode_rounded, 'Реҷаҳои Light / Dark / Auto.'),
            _Feature(Icons.devices_rounded, 'Тарҳи мутобиқ ба экранҳои гуногун.'),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cyan600),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
