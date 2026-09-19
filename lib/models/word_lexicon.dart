// Child-safe lexicon helpers. Never emit the string "null".

class WordFormation {
  final String prefix;
  final String root;
  final String suffix;
  final String note;

  const WordFormation({
    this.prefix = '',
    this.root = '',
    this.suffix = '',
    this.note = '',
  });

  bool get isEmpty =>
      prefix.isEmpty && root.isEmpty && suffix.isEmpty && note.isEmpty;

  bool get hasParts =>
      prefix.isNotEmpty || root.isNotEmpty || suffix.isNotEmpty;

  Map<String, String> toJson() => {
        'prefix': prefix,
        'root': root,
        'suffix': suffix,
        'note': note,
      };

  static WordFormation? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final prefix = '${raw['prefix'] ?? ''}'.trim();
    final root = '${raw['root'] ?? ''}'.trim();
    final suffix = '${raw['suffix'] ?? ''}'.trim();
    final note = '${raw['note'] ?? raw['explanation'] ?? ''}'.trim();
    final value =
        WordFormation(prefix: prefix, root: root, suffix: suffix, note: note);
    return value.isEmpty ? null : value;
  }
}

const _bannedLexemes = {'null', 'undefined', 'n/a', 'none', 'nil', 'nan'};

List<String> cleanLexemeList(dynamic raw) {
  if (raw == null) return const [];
  final parts = <String>[];
  if (raw is List) {
    for (final item in raw) {
      if (item == null) continue;
      parts.add('$item');
    }
  } else {
    final text = '$raw'.trim();
    if (text.isEmpty) return const [];
    if (_bannedLexemes.contains(text.toLowerCase())) return const [];
    parts.addAll(text.split(RegExp(r'[,;/|]')));
  }
  final out = <String>[];
  final seen = <String>{};
  for (final part in parts) {
    final value = part.trim();
    if (value.isEmpty) continue;
    final key = value.toLowerCase();
    if (_bannedLexemes.contains(key)) continue;
    if (!seen.add(key)) continue;
    out.add(value);
  }
  return out;
}

const synonymMap = <String, List<String>>{
  'hello': ['Hi', 'Hey'],
  'hi': ['Hello', 'Hey'],
  'goodbye': ['Bye', 'See you'],
  'bye': ['Goodbye', 'See you'],
  'see you': ['Bye', 'Goodbye'],
  'yes': ['OK'],
  'ok': ['Yes'],
  'happy': ['Glad', 'Fine'],
  'sad': ['Unhappy'],
  'fine': ['Good', 'Great'],
  'great': ['Good', 'Fine'],
  'good': ['Nice', 'Kind'],
  'nice': ['Kind', 'Good'],
  'kind': ['Nice', 'Good'],
  'big': ['Large'],
  'small': ['Little'],
  'fast': ['Quick'],
  'new': ['Fresh'],
  'old': ['Aged'],
  'start': ['Begin'],
  'begin': ['Start'],
  'finish': ['End'],
  'end': ['Finish'],
  'like': ['Love'],
  'love': ['Like'],
  'help': ['Aid'],
  'friend': ['Pal'],
  'mom': ['Mother'],
  'mother': ['Mom'],
  'dad': ['Father'],
  'father': ['Dad'],
  'home': ['House'],
  'house': ['Home'],
  'look': ['See'],
  'see': ['Look'],
  'speak': ['Talk', 'Tell'],
  'tell': ['Say', 'Speak'],
  'listen': ['Hear'],
  'make': ['Build'],
  'build': ['Make'],
  'gift': ['Present'],
  'near': ['Close'],
  'inside': ['In'],
  'outside': ['Out'],
  'always': ['Forever'],
  'want': ['Need'],
  'need': ['Want'],
};

const antonymMap = <String, List<String>>{
  'hello': ['Goodbye'],
  'hi': ['Goodbye'],
  'goodbye': ['Hello'],
  'bye': ['Hello'],
  'yes': ['No'],
  'no': ['Yes'],
  'happy': ['Sad'],
  'sad': ['Happy'],
  'good': ['Bad'],
  'bad': ['Good'],
  'big': ['Small'],
  'small': ['Big'],
  'fast': ['Slow'],
  'slow': ['Fast'],
  'new': ['Old'],
  'old': ['New'],
  'open': ['Close'],
  'close': ['Open'],
  'start': ['Finish'],
  'finish': ['Start'],
  'begin': ['End'],
  'end': ['Begin'],
  'up': ['Down'],
  'down': ['Up'],
  'left': ['Right'],
  'right': ['Left'],
  'in': ['Out'],
  'out': ['In'],
  'inside': ['Outside'],
  'outside': ['Inside'],
  'near': ['Far'],
  'far': ['Near'],
  'early': ['Late'],
  'late': ['Early'],
  'clean': ['Dirty'],
  'dirty': ['Clean'],
  'quiet': ['Loud'],
  'loud': ['Quiet'],
  'dark': ['Light'],
  'light': ['Dark'],
  'day': ['Night'],
  'night': ['Day'],
  'boy': ['Girl'],
  'girl': ['Boy'],
  'hot': ['Cold'],
  'cold': ['Hot'],
  'warm': ['Cool'],
  'cool': ['Warm'],
  'many': ['Few'],
  'few': ['Many'],
  'more': ['Less'],
  'less': ['More'],
  'first': ['Last'],
  'last': ['First'],
  'come': ['Go'],
  'go': ['Come'],
  'sit': ['Stand'],
  'stand': ['Sit'],
  'win': ['Lose'],
  'lose': ['Win'],
  'give': ['Take'],
  'take': ['Give'],
  'remember': ['Forget'],
  'forget': ['Remember'],
  'always': ['Never'],
  'never': ['Always'],
  'with': ['Without'],
  'without': ['With'],
  'can': ['Cannot'],
  'cannot': ['Can'],
  'yummy': ['Yucky'],
  'yucky': ['Yummy'],
  'together': ['Alone'],
  'alone': ['Together'],
};

const formationMap = <String, WordFormation>{
  'teacher': WordFormation(
      root: 'teach',
      suffix: '-er',
      note: 'teach + -er → шахсе, ки меомӯзонад.'),
  'player': WordFormation(
      root: 'play',
      suffix: '-er',
      note: 'play + -er → шахсе, ки бозӣ мекунад.'),
  'singer': WordFormation(
      root: 'sing', suffix: '-er', note: 'sing + -er → шахсе, ки месарояд.'),
  'worker': WordFormation(
      root: 'work', suffix: '-er', note: 'work + -er → шахсе, ки кор мекунад.'),
  'helper': WordFormation(
      root: 'help', suffix: '-er', note: 'help + -er → шахсе, ки ёрӣ медиҳад.'),
  'driver': WordFormation(
      root: 'drive',
      suffix: '-er',
      note: 'drive + -er → шахсе, ки мошин меронад.'),
  'farmer': WordFormation(
      root: 'farm',
      suffix: '-er',
      note: 'farm + -er → шахсе, ки дар ферма кор мекунад.'),
  'shopkeeper': WordFormation(
      prefix: 'shop',
      root: 'keep',
      suffix: '-er',
      note: 'shop + keep + -er → фурӯшандаи дӯкон.'),
  'firefighter': WordFormation(
      prefix: 'fire',
      root: 'fight',
      suffix: '-er',
      note: 'fire + fight + -er → оташнишон.'),
  'homework': WordFormation(
      prefix: 'home', root: 'work', note: 'home + work → вазифаи хонагӣ.'),
  'classroom': WordFormation(
      prefix: 'class', root: 'room', note: 'class + room → синфхона.'),
  'football': WordFormation(
      prefix: 'foot', root: 'ball', note: 'foot + ball → футбол.'),
  'birthday': WordFormation(
      prefix: 'birth', root: 'day', note: 'birth + day → рӯзи таваллуд.'),
  'goodbye': WordFormation(
      prefix: 'good', root: 'bye', note: 'good + bye → хайру хуш.'),
  'cannot': WordFormation(
      prefix: 'can', root: 'not', note: 'can + not → наметавонам.'),
  'without':
      WordFormation(prefix: 'with', root: 'out', note: 'with + out → бе.'),
};

List<String> lexiconSynonyms(String english) =>
    List<String>.from(synonymMap[english.trim().toLowerCase()] ?? const []);

List<String> lexiconAntonyms(String english) =>
    List<String>.from(antonymMap[english.trim().toLowerCase()] ?? const []);

WordFormation lexiconFormation(String english) =>
    formationMap[english.trim().toLowerCase()] ?? const WordFormation();
