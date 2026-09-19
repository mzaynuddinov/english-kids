import 'package:english_kids/models/word.dart';
import 'package:english_kids/models/word_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final words = [
    const Word(
        english: 'hello',
        pronunciation: 'ҳэллоу',
        tajik: 'салом',
        week: 1,
        topic: 'Greetings'),
    const Word(
        english: 'help',
        pronunciation: 'ҳелп',
        tajik: 'ёрӣ',
        week: 3,
        topic: 'Verbs'),
    const Word(
        english: 'yellow',
        pronunciation: 'йеллоу',
        tajik: 'зард',
        week: 2,
        topic: 'Colors'),
    const Word(
        english: 'teacher',
        pronunciation: 'тичер',
        tajik: 'муаллим',
        week: 6,
        topic: 'School'),
  ];

  test('exact english ranks above startsWith and contains', () {
    final hits = searchWords(words, 'hello');
    expect(hits, isNotEmpty);
    expect(hits.first.word.english, 'hello');
    expect(hits.first.score, 1000);
  });

  test('tajik exact match is ranked', () {
    final hits = searchWords(words, 'салом');
    expect(hits.first.word.english, 'hello');
    expect(hits.first.field, 'tj');
  });

  test('pronunciation is searchable', () {
    final hits = searchWords(words, 'тичер');
    expect(hits.first.word.english, 'teacher');
  });

  test('empty query returns nothing', () {
    expect(searchWords(words, '   '), isEmpty);
  });
}
