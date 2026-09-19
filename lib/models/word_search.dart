import 'word.dart';

class WordSearchHit {
  final Word word;
  final int score;
  final String field;

  const WordSearchHit({
    required this.word,
    required this.score,
    required this.field,
  });
}

/// Rank: exact EN/TJ → startsWith → contains → pronunciation.
List<WordSearchHit> searchWords(Iterable<Word> words, String query,
    {int limit = 40}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];

  final hits = <WordSearchHit>[];
  for (final word in words) {
    final english = word.english.toLowerCase();
    final tajik = word.tajik.toLowerCase();
    final pronunciation = word.pronunciation.toLowerCase();
    int score = 0;
    var field = '';
    if (english == needle) {
      score = 1000;
      field = 'en';
    } else if (tajik == needle) {
      score = 900;
      field = 'tj';
    } else if (pronunciation == needle) {
      score = 800;
      field = 'ipa';
    } else if (english.startsWith(needle)) {
      score = 700;
      field = 'en';
    } else if (tajik.startsWith(needle)) {
      score = 600;
      field = 'tj';
    } else if (pronunciation.startsWith(needle)) {
      score = 500;
      field = 'ipa';
    } else if (english.contains(needle)) {
      score = 400;
      field = 'en';
    } else if (tajik.contains(needle)) {
      score = 300;
      field = 'tj';
    } else if (pronunciation.contains(needle)) {
      score = 200;
      field = 'ipa';
    }
    if (score == 0) continue;
    hits.add(WordSearchHit(word: word, score: score, field: field));
  }

  hits.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byLength = a.word.english.length.compareTo(b.word.english.length);
    if (byLength != 0) return byLength;
    return a.word.english.toLowerCase().compareTo(b.word.english.toLowerCase());
  });
  if (hits.length <= limit) return hits;
  return hits.sublist(0, limit);
}
