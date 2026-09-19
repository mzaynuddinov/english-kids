import 'dart:convert';
import 'dart:io';

import 'package:english_kids/models/word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses valid list records and rejects junk', () {
    final ok = Word.tryParse(['hello', 'ҳэллоу', 'салом', 1, 'Greetings']);
    expect(ok, isNotNull);
    expect(ok!.displayEnglish, 'Hello');
    expect(ok.isValid, isTrue);
    expect(ok.partOfSpeech, 'interjection');
    expect(ok.cefr, 'A1');
    expect(ok.ipa, 'həˈləʊ');
    expect(ok.phoneticLabel, "/həˈləʊ/");
    expect(ok.ipaLabel, "[həˈləʊ]");
    expect(ok.stress, 'Hel-lo');
    expect(ok.posLabel, 'Phrase / Interjection');
    expect(ok.synonyms, ['Hi', 'Hey']);
    expect(ok.antonyms, ['Goodbye']);
    expect(ok.formation.isEmpty, isTrue);

    expect(Word.tryParse(['', 'x', 'y', 1, 't']), isNull);
    expect(Word.tryParse(['hi', 'x', 'y', 0, 't']), isNull);
    expect(Word.tryParse('nope'), isNull);
    expect(Word.tryParse(null), isNull);
  });

  test('parses map records with day and example', () {
    final word = Word.tryParse({
      'english': 'cat',
      'pronunciation': 'кэт',
      'tajik': 'гурба',
      'week': 4,
      'topic': 'Animals',
      'day': 2,
      'difficulty': 1,
      'example': 'I like my cat.',
      'example_tajik': 'Ба ман гурбаам маъқул аст.',
    });
    expect(word?.english, 'cat');
    expect(word?.week, 4);
    expect(word?.day, 2);
    expect(word?.example, 'I like my cat.');
    expect(word?.partOfSpeech, 'noun');
    expect(word?.cefr, 'A1');
    expect(word?.ipa, 'kæt');
  });

  test('bundled vocabulary.json is 500 unique valid words', () {
    final file = File('data/vocabulary.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());
    final words =
        (decoded as List).map(Word.tryParse).whereType<Word>().toList();
    expect(words.length, 500);
    expect(words.map((w) => w.id).toSet().length, 500);
    expect(words.where((w) => w.english.toLowerCase() == 'orange').length, 2);
    expect(words.every((w) => w.isValid), isTrue);
    for (var week = 1; week <= 10; week++) {
      expect(words.where((w) => w.week == week).length, 50,
          reason: 'week $week');
    }
    expect(words.every((w) => w.example.trim().isNotEmpty), isTrue);
    expect(words.every((w) => w.exampleTajik.trim().isNotEmpty), isTrue);
    expect(
        words.any((w) =>
            w.english.toLowerCase() == 'hello' &&
            w.example.startsWith('Hello!')),
        isTrue);
    expect(
        words.any((w) =>
            w.english.toLowerCase() == 'apple' &&
            w.example.toLowerCase().contains('apple')),
        isTrue);
    expect(words.every((w) => w.cefr == 'A1' || w.cefr == 'A2'), isTrue);
    expect(words.every((w) => w.partOfSpeech.isNotEmpty), isTrue);
  });

  test('null synonyms never become the string null', () {
    final word = Word.tryParse({
      'english': 'cat',
      'pronunciation': 'кэт',
      'tajik': 'гурба',
      'week': 4,
      'topic': 'Animals',
      'synonyms': null,
      'antonyms': [null, 'null', '  ', 'undefined'],
    });
    expect(word, isNotNull);
    expect(word!.synonyms, isEmpty);
    expect(word.antonyms, isEmpty);
    expect(word.synonyms.contains('null'), isFalse);
    expect(word.antonyms.contains('null'), isFalse);
  });

  test('teacher formation is teach + -er, not invented etymology', () {
    final word = Word.tryParse({
      'english': 'teacher',
      'pronunciation': 'тичер',
      'tajik': 'муаллим',
      'week': 6,
      'topic': 'School',
    });
    expect(word?.formation.root, 'teach');
    expect(word?.formation.suffix, '-er');
    expect(word?.formation.note.contains('teach'), isTrue);
  });
}
