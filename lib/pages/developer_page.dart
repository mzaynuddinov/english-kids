import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Could not open $url: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Таҳиягар')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          children: [
            Center(
              child: Container(
                width: 124,
                height: 124,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [teal600, cyan600, blue600]),
                  boxShadow: [
                    BoxShadow(color: cyan600.withValues(alpha: 0.25), blurRadius: 24),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/developer.png'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Majnun Zaynuddinov',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Таҳиягар ва созандаи барнома',
                style: TextStyle(color: cyan600, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 22),
            _contact(Icons.phone_rounded, 'Телефон', '+992 98 537 36 35', 'tel:+992985373635'),
            _contact(Icons.email_rounded, 'Почта', 'mzaynuddinov@gmail.com', 'mailto:mzaynuddinov@gmail.com'),
            _contact(Icons.send_rounded, 'Telegram', '@mzaynuddinov', 'https://t.me/mzaynuddinov'),
            _contact(Icons.camera_alt_outlined, 'Instagram', '@mzaynuddinov', 'https://instagram.com/mzaynuddinov'),
            _contact(Icons.public_rounded, 'Facebook', 'majnun.zaynuddinov', 'https://facebook.com/majnun.zaynuddinov'),
            _contact(Icons.play_circle_outline, 'YouTube', '@mzaynuddinov', 'https://youtube.com/@mzaynuddinov'),
          ],
        ),
      ),
    );
  }

  Widget _contact(IconData icon, String label, String value, String url) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: () => _open(url),
        leading: Icon(icon, color: cyan600),
        title: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      ),
    );
  }
}
