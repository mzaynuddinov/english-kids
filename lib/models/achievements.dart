import 'package:flutter/material.dart';

class AchievementInfo {
  final String id;
  final String title;
  final String text;
  final IconData icon;

  const AchievementInfo({
    required this.id,
    required this.title,
    required this.text,
    required this.icon,
  });
}

const achievementCatalog = <AchievementInfo>[
  AchievementInfo(
    id: 'first_10',
    title: 'Аввалин қадам',
    text: '10 калима омӯхтед',
    icon: Icons.emoji_events_rounded,
  ),
  AchievementInfo(
    id: 'streak_3',
    title: '3 рӯз пай дар пай',
    text: 'Се рӯзи пай дар пай омӯхтед',
    icon: Icons.local_fire_department_rounded,
  ),
  AchievementInfo(
    id: 'words_50',
    title: '50 калима',
    text: '50 калима омӯхта шуд',
    icon: Icons.star_rounded,
  ),
  AchievementInfo(
    id: 'words_100',
    title: '100 калима',
    text: '100 калима омӯхта шуд',
    icon: Icons.menu_book_rounded,
  ),
  AchievementInfo(
    id: 'alphabet',
    title: 'Алифбо',
    text: 'Ҳамаи ҳарфҳо дида шуданд',
    icon: Icons.abc_rounded,
  ),
  AchievementInfo(
    id: 'listen_10',
    title: 'Гӯш кун',
    text: '10 маротиба гӯш кардед',
    icon: Icons.headphones_rounded,
  ),
  AchievementInfo(
    id: 'daily',
    title: 'Мушкилоти имрӯз',
    text: 'Як мушкилоти имрӯзро анҷом додед',
    icon: Icons.extension_rounded,
  ),
  AchievementInfo(
    id: 'grammar',
    title: 'Грамматика',
    text: '10 дарси грамматикӣ анҷом ёфт',
    icon: Icons.spellcheck_rounded,
  ),
];

String masteryLabel(int hits, int misses) {
  if (misses >= 2 && misses >= hits) return 'Боз такрор кун';
  if (hits >= 3 && misses == 0) return 'Омӯхта шуд';
  return 'Дар ҳоли омӯзиш';
}

String clockOf(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String shortDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]}';
}
