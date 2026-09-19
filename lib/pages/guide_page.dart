import 'package:flutter/material.dart';

import '../theme.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дастурамал')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [
            Text(
              'Чӣ тавр Англисиро Омӯз-ро истифода баред',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
                'Ҳама фаслҳоро пахш кунед. Кӯдак ҳамеша қадами навбатиро мебинад.'),
            SizedBox(height: 12),
            _GuideTile(
              icon: Icons.abc_rounded,
              title: 'Алифбо',
              body:
                  'Аз ҳарфи A оғоз кунед ва то Z кашед. Рахи A–Z ҳарфи ҷориро нишон медиҳад ва худ ба он меравад. Тугмаҳои 🔊 Ҳарф ва 🔊 Калима ҷудоанд. Вақте 26/26 мешавад, 🎉 Алифбо пурра омӯхта шуд!',
            ),
            _GuideTile(
              icon: Icons.menu_book_rounded,
              title: 'Ҳафтаҳо ва қулф',
              body:
                  'Аввал алифбо, баъд Ҳафтаи 1, баъд Ҳафтаи 2. Ҳафтаи қулфшуда кушода намешавад. Калимаҳоро гӯш кунед, «Омӯхта шуд»-ро пахш кунед ва барои баъд захира кунед.',
            ),
            _GuideTile(
              icon: Icons.style_rounded,
              title: 'Корти калима',
              body:
                  'Корт IPA, ҷумлаи мисол, синоним/антоним ва сохти калимаро нишон медиҳад — танҳо агар маълумот бошад. Ҳеҷ гоҳ «null» намебинад. Тугмаҳо: Гӯш кардан, Омӯхта шуд, Ёдрас.',
            ),
            _GuideTile(
              icon: Icons.search_rounded,
              title: 'Ҷустуҷӯ',
              body:
                  'Нишонаи ҷустуҷӯ пеш аз Танзимот аст. Шумо метавонед калимаҳои англисӣ ё тоҷикиро ҷӯед. Танҳо калимаҳои омӯхташуда корти пурраро мекушоянд. Калимаи қулфшуда бо 🔒 мемонад — ҷустуҷӯ қулфи ҳафтаро намешиканад.',
            ),
            _GuideTile(
              icon: Icons.quiz_rounded,
              title: 'Санҷишҳо',
              body:
                  'Санҷиши калимаҳо танҳо аз калимаҳои омӯхта сохта мешавад. Агар камтар аз 25 калима бошад, аввал бештар омӯзед. Ҷавоби додашуда дигар иваз намешавад.',
            ),
            _GuideTile(
              icon: Icons.alarm_rounded,
              title: 'Ёдрас ва огоҳӣ',
              body:
                  'Аз корт «Ёдрас»-ро пахш кунед. Огоҳӣ дар вақти муайян меояд ва TTS калимаро мехонад. Агар телефони шумо TTS-и пасзаминаро маҳдуд кунад, огоҳӣ ҳамоно мемонад.',
            ),
            _GuideTile(
              icon: Icons.lock_rounded,
              title: 'PIN-и волидон',
              body:
                  'PIN бояд аниқ 4 рақам бошад. Худи PIN захира намешавад — танҳо хеш. Бо он қисми волидон, омор ва пок кардани пешрафт кушода мешавад.',
            ),
            _GuideTile(
              icon: Icons.brightness_6_rounded,
              title: 'Намуд ва овоз',
              body:
                  'Light / Dark / Auto ва андозаи матн дар Танзимот. Овоз: зан ё мард, одатӣ ё суст. Агар овози мардона набошад, барнома паём медиҳад ва намеафтад.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _GuideTile(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ExpansionTile(
          leading: Icon(icon, color: cyan700),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(body, style: const TextStyle(height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
