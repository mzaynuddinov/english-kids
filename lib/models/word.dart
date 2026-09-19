import 'word_lexicon.dart';

export 'word_lexicon.dart' show WordFormation, cleanLexemeList;

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
  final String ipa;
  final String phonetic;
  final String stress;
  final String origin;
  final WordFormation formation;

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
    this.ipa = '',
    this.phonetic = '',
    this.stress = '',
    this.origin = '',
    this.formation = const WordFormation(),
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

  bool isMarked(Set<String> keys) =>
      keys.contains(id) || keys.contains(english);

  String get posLabel =>
      formatPos(partOfSpeech, topic: topic, english: english);

  String get ipaLabel => ipa.isEmpty ? '' : '[$ipa]';

  String get phoneticLabel {
    if (phonetic.isNotEmpty) {
      return phonetic.startsWith('/') ? phonetic : '/$phonetic/';
    }
    if (ipa.isNotEmpty) return '/$ipa/';
    return '';
  }

  static List<String> _list(dynamic raw) => cleanLexemeList(raw);

  static Word? tryParse(dynamic raw) {
    try {
      if (raw is List && raw.length >= 5) {
        final week = raw[3] is num
            ? (raw[3] as num).toInt()
            : int.tryParse('${raw[3]}') ?? 0;
        final english = '${raw[0]}'.trim();
        final topic = '${raw[4]}'.trim();
        final pos = inferPartOfSpeech(topic, english);
        final ipa = inferIpa(english);
        final word = Word(
          english: english,
          pronunciation: '${raw[1]}'.trim(),
          tajik: '${raw[2]}'.trim(),
          week: week,
          topic: topic,
          partOfSpeech: pos,
          cefr: inferCefr(week),
          synonyms: inferSynonyms(english),
          antonyms: inferAntonyms(english),
          grammarNote: inferGrammarNote(pos),
          ipa: ipa,
          phonetic: inferPhonetic(ipa),
          stress: inferStress(english),
          origin: inferOrigin(pos, topic),
          formation: inferFormation(english),
        );
        return word.isValid ? word : null;
      }
      if (raw is Map) {
        final weekRaw = raw['week'];
        final week =
            weekRaw is num ? weekRaw.toInt() : int.tryParse('$weekRaw') ?? 0;
        final dayRaw = raw['day'];
        final day =
            dayRaw is num ? dayRaw.toInt() : int.tryParse('$dayRaw') ?? 1;
        final diffRaw = raw['difficulty'];
        final difficulty =
            diffRaw is num ? diffRaw.toInt() : int.tryParse('$diffRaw') ?? 1;
        final english = '${raw['english'] ?? raw['en'] ?? ''}'.trim();
        final topic = '${raw['topic'] ?? raw['category'] ?? ''}'.trim();
        final posRaw = '${raw['partOfSpeech'] ?? raw['pos'] ?? ''}'.trim();
        final pos = posRaw.isEmpty ? inferPartOfSpeech(topic, english) : posRaw;
        final cefrRaw = '${raw['cefr'] ?? raw['level'] ?? ''}'.trim();
        final noteRaw =
            '${raw['grammarNote'] ?? raw['grammar_note'] ?? ''}'.trim();
        final ipaRaw = '${raw['ipa'] ?? raw['ipaTranscription'] ?? ''}'.trim();
        final phoneticRaw = '${raw['phonetic'] ?? ''}'.trim();
        final stressRaw = '${raw['stress'] ?? ''}'.trim();
        final originRaw = '${raw['origin'] ?? raw['etymology'] ?? ''}'.trim();
        final ipa = ipaRaw.isEmpty
            ? inferIpa(english)
            : ipaRaw.replaceAll(RegExp(r'[\[\]/]'), '');
        final grammar = noteRaw.isEmpty ? inferGrammarNote(pos) : noteRaw;
        final synonyms = _list(raw['synonyms']);
        final antonyms = _list(raw['antonyms']);
        final formation =
            WordFormation.tryParse(raw['formation']) ?? inferFormation(english);
        final word = Word(
          english: english,
          pronunciation:
              '${raw['pronunciation'] ?? raw['transliteration'] ?? ''}'.trim(),
          tajik: '${raw['tajik'] ?? raw['tj'] ?? raw['meaning'] ?? ''}'.trim(),
          week: week,
          topic: topic,
          day: day < 1 ? 1 : day,
          difficulty: difficulty < 1 ? 1 : difficulty,
          example: '${raw['example'] ?? ''}'.trim(),
          exampleTajik:
              '${raw['example_tajik'] ?? raw['exampleTajik'] ?? ''}'.trim(),
          partOfSpeech: pos,
          cefr: cefrRaw.isEmpty ? inferCefr(week) : cefrRaw,
          synonyms: synonyms.isEmpty ? inferSynonyms(english) : synonyms,
          antonyms: antonyms.isEmpty ? inferAntonyms(english) : antonyms,
          grammarNote: grammar,
          ipa: ipa,
          phonetic: phoneticRaw.isEmpty ? inferPhonetic(ipa) : phoneticRaw,
          stress: stressRaw.isEmpty ? inferStress(english) : stressRaw,
          origin: originRaw,
          formation: formation,
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

String inferPartOfSpeech(String topic, [String english = '']) {
  switch (english.toLowerCase()) {
    case 'hello':
    case 'hi':
    case 'bye':
    case 'goodbye':
      return 'interjection';
  }
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

String formatPos(String pos, {String topic = '', String english = ''}) {
  if (english.toLowerCase() == 'hello') return 'Phrase / Interjection';
  if (pos.isEmpty) return '';
  final parts = [
    for (final part in pos.split(RegExp(r'[/,]')))
      if (part.trim().isNotEmpty)
        '${part.trim()[0].toUpperCase()}${part.trim().substring(1)}',
  ];
  if (topic == 'Greetings' &&
      !parts.any((p) => p.toLowerCase().contains('interjection'))) {
    parts.add('Interjection');
  }
  return parts.join(' / ');
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
    case 'interjection':
      return 'Ин нидо аст — салом ё ҳиссиёт.';
    case 'grammar':
      return 'Ин калимаи грамматикӣ аст.';
    default:
      return '';
  }
}

String inferIpa(String english) {
  const known = <String, String>{
    'hello': 'həˈləʊ',
    'hi': 'haɪ',
    'apple': 'ˈæpəl',
    'cat': 'kæt',
    'dog': 'dɒɡ',
    'water': 'ˈwɔːtə',
    'orange': 'ˈɒrɪndʒ',
    'thank you': 'θæŋk juː',
    'please': 'pliːz',
    'goodbye': 'ˌɡʊdˈbaɪ',
  };
  return known[english.trim().toLowerCase()] ?? '';
}

String inferPhonetic(String ipa) => ipa.isEmpty ? '' : '/$ipa/';

String inferStress(String english) {
  const known = <String, String>{
    'hello': 'Hel-lo',
    'apple': 'Ap-ple',
    'orange': 'Or-ange',
    'water': 'Wa-ter',
    'family': 'Fam-i-ly',
    'goodbye': 'Good-bye',
    'please': 'Please',
  };
  final raw = english.trim();
  if (raw.isEmpty) return '';
  final hit = known[raw.toLowerCase()];
  if (hit != null) return hit;
  final match = RegExp(r'^[^aeiouyAEIOUY]*[aeiouyAEIOUY]+').firstMatch(raw);
  if (match == null || match.end >= raw.length - 1) {
    return raw[0].toUpperCase() + raw.substring(1);
  }
  final head = raw.substring(0, match.end);
  final tail = raw.substring(match.end);
  return '${head[0].toUpperCase()}${head.substring(1)}-$tail';
}

String inferOrigin(String pos, String topic) {
  final grammar = inferGrammarNote(pos);
  if (grammar.isNotEmpty) return grammar;
  if (topic.isEmpty) return '';
  return '';
}

List<String> inferSynonyms(String english) => lexiconSynonyms(english);

List<String> inferAntonyms(String english) => lexiconAntonyms(english);

WordFormation inferFormation(String english) => lexiconFormation(english);

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
