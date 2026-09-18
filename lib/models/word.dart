class Word {
  final String english;
  final String pronunciation;
  final String tajik;
  final int week;
  final String topic;

  const Word({
    required this.english,
    required this.pronunciation,
    required this.tajik,
    required this.week,
    required this.topic,
  });

  bool get isValid =>
      english.trim().isNotEmpty && tajik.trim().isNotEmpty && week >= 1 && week <= 5;

  String get displayEnglish {
    final value = english.trim();
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static Word? tryParse(dynamic raw) {
    try {
      if (raw is List && raw.length >= 5) {
        final week = raw[3] is num
            ? (raw[3] as num).toInt()
            : int.tryParse('${raw[3]}') ?? 0;
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
        final week = weekRaw is num
            ? weekRaw.toInt()
            : int.tryParse('$weekRaw') ?? 0;
        final word = Word(
          english: '${raw['english'] ?? raw['en'] ?? ''}'.trim(),
          pronunciation: '${raw['pronunciation'] ?? raw['ipa'] ?? ''}'.trim(),
          tajik: '${raw['tajik'] ?? raw['tj'] ?? raw['meaning'] ?? ''}'.trim(),
          week: week,
          topic: '${raw['topic'] ?? raw['category'] ?? ''}'.trim(),
        );
        return word.isValid ? word : null;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

const weekTitles = <int, String>{
  1: 'Салом ва ҳиссиёт',
  2: 'Рақамҳо ва рангҳо',
  3: 'Оила ва бадани инсон',
  4: 'Ҳайвонот ва грамматика',
  5: 'Хӯрок, нӯшокиҳо ва феълҳо',
};
