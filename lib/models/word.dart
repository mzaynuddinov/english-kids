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
  final String partOfSpeech;
  final String cefr;
  final List<String> synonyms;
  final List<String> antonyms;
  final String grammarNote;

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
    this.partOfSpeech = '',
    this.cefr = '',
    this.synonyms = const [],
    this.antonyms = const [],
    this.grammarNote = '',
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

  static List<String> _list(dynamic raw) {
    if (raw is List) {
      return [
        for (final item in raw)
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ];
    }
    final text = '$raw'.trim();
    if (text.isEmpty) return const [];
    return [
      for (final part in text.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static Word? tryParse(dynamic raw) {
    try {
      if (raw is List && raw.length >= 5) {
        final week = raw[3] is num ? (raw[3] as num).toInt() : int.tryParse('${raw[3]}') ?? 0;
        final topic = '${raw[4]}'.trim();
        final pos = inferPartOfSpeech(topic);
        final word = Word(
          english: '${raw[0]}'.trim(),
          pronunciation: '${raw[1]}'.trim(),
          tajik: '${raw[2]}'.trim(),
          week: week,
          topic: topic,
          partOfSpeech: pos,
          cefr: inferCefr(week),
          grammarNote: inferGrammarNote(pos),
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
        final topic = '${raw['topic'] ?? raw['category'] ?? ''}'.trim();
        final posRaw = '${raw['partOfSpeech'] ?? raw['pos'] ?? ''}'.trim();
        final pos = posRaw.isEmpty ? inferPartOfSpeech(topic) : posRaw;
        final cefrRaw = '${raw['cefr'] ?? raw['level'] ?? ''}'.trim();
        final noteRaw = '${raw['grammarNote'] ?? raw['grammar_note'] ?? ''}'.trim();
        final word = Word(
          english: '${raw['english'] ?? raw['en'] ?? ''}'.trim(),
          pronunciation: '${raw['pronunciation'] ?? raw['ipa'] ?? ''}'.trim(),
          tajik: '${raw['tajik'] ?? raw['tj'] ?? raw['meaning'] ?? ''}'.trim(),
          week: week,
          topic: topic,
          day: day < 1 ? 1 : day,
          difficulty: difficulty < 1 ? 1 : difficulty,
          example: '${raw['example'] ?? ''}'.trim(),
          exampleTajik: '${raw['example_tajik'] ?? raw['exampleTajik'] ?? ''}'.trim(),
          partOfSpeech: pos,
          cefr: cefrRaw.isEmpty ? inferCefr(week) : cefrRaw,
          synonyms: _list(raw['synonyms']),
          antonyms: _list(raw['antonyms']),
          grammarNote: noteRaw.isEmpty ? inferGrammarNote(pos) : noteRaw,
        );
        return word.isValid ? word : null;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

String inferCefr(int week) => week <= 5 ? 'A1' : 'A2';

String inferPartOfSpeech(String topic) {
  switch (topic) {
    case 'Greetings':
      return 'phrase';
    case 'Feelings':
    case 'Colors':
    case 'Adjectives':
      return 'adjective';
    case 'Basics':
      return 'pronoun';
    case 'Numbers':
      return 'number';
    case 'Questions':
      return 'question';
    case 'Connectors':
      return 'conjunction';
    case 'Grammar':
      return 'grammar';
    case 'Verbs':
    case 'Play':
      return 'verb';
    default:
      return 'noun';
  }
}

String inferGrammarNote(String pos) {
  switch (pos) {
    case 'noun':
      return 'Ин ном аст — шахс, ҷой ё чиз.';
    case 'verb':
      return 'Ин феъл аст — кор ё ҳаракат.';
    case 'adjective':
      return 'Ин сифат аст — чӣ гуна будан.';
    case 'phrase':
      return 'Ин ибораи тайёр аст.';
    case 'pronoun':
      return 'Ин ҷонишин аст.';
    case 'number':
      return 'Ин рақам аст.';
    case 'question':
      return 'Ин калимаи савол аст.';
    case 'conjunction':
      return 'Ин пайвандак аст.';
    case 'grammar':
      return 'Ин калимаи грамматикӣ аст.';
    default:
      return '';
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
