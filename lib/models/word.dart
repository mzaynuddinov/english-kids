class Word {
  final String english;
  final String pronunciation;
  final String tajik;
  final int week;
  final String topic;
  final int day;
  final int difficulty;
  final String example;
  final String exampleTajik;

  const Word({
    required this.english,
    required this.pronunciation,
    required this.tajik,
    required this.week,
    required this.topic,
    this.day = 1,
    this.difficulty = 1,
    this.example = '',
    this.exampleTajik = '',
  });

  bool get isValid =>
      english.trim().isNotEmpty &&
      tajik.trim().isNotEmpty &&
      week >= 1 &&
      week <= 10 &&
      day >= 1 &&
      day <= 7;

  String get displayEnglish {
    final value = english.trim();
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Homonyms such as color/fruit "orange" must stay distinct.
  String get id => '${english.toLowerCase()}|$week|${tajik.toLowerCase()}';

  bool isMarked(Set<String> keys) => keys.contains(id) || keys.contains(english);

  static Word? tryParse(dynamic raw) {
    try {
      if (raw is List && raw.length >= 5) {
        final week = raw[3] is num ? (raw[3] as num).toInt() : int.tryParse('${raw[3]}') ?? 0;
        final word = Word(
          english: '${raw[0]}'.trim(),
          pronunciation: '${raw[1]}'.trim(),
          tajik: '${raw[2]}'.trim(),
          week: week,
          topic: '${raw[4]}'.trim(),
        );
        return word.isValid ? word : null;
      }
      if (raw is Map) {
        final weekRaw = raw['week'];
        final week = weekRaw is num ? weekRaw.toInt() : int.tryParse('$weekRaw') ?? 0;
        final dayRaw = raw['day'];
        final day = dayRaw is num ? dayRaw.toInt() : int.tryParse('$dayRaw') ?? 1;
        final diffRaw = raw['difficulty'];
        final difficulty = diffRaw is num ? diffRaw.toInt() : int.tryParse('$diffRaw') ?? 1;
        final word = Word(
          english: '${raw['english'] ?? raw['en'] ?? ''}'.trim(),
          pronunciation: '${raw['pronunciation'] ?? raw['ipa'] ?? ''}'.trim(),
          tajik: '${raw['tajik'] ?? raw['tj'] ?? raw['meaning'] ?? ''}'.trim(),
          week: week,
          topic: '${raw['topic'] ?? raw['category'] ?? ''}'.trim(),
          day: day < 1 ? 1 : day,
          difficulty: difficulty < 1 ? 1 : difficulty,
          example: '${raw['example'] ?? ''}'.trim(),
          exampleTajik: '${raw['example_tajik'] ?? raw['exampleTajik'] ?? ''}'.trim(),
        );
        return word.isValid ? word : null;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

const weekCount = 10;

const weekTitles = <int, String>{
  1: 'Салом ва ҳиссиёт',
  2: 'Рақамҳо ва рангҳо',
  3: 'Оила ва бадани инсон',
  4: 'Ҳайвонот ва грамматика',
  5: 'Хӯрок, нӯшокиҳо ва феълҳо',
  6: 'Мактаб ва хона',
  7: 'Шаҳр ва табиат',
  8: 'Вақт ва обу ҳаво',
  9: 'Касб ва ҷомеа',
  10: 'Феълҳо ва ҷумлаҳо',
};
