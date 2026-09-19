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
  });

  test('bundled vocabulary.json is 500 unique valid words', () {
    final file = File('data/vocabulary.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());
    final words = (decoded as List).map(Word.tryParse).whereType<Word>().toList();
    expect(words.length, 500);
    expect(words.map((w) => w.id).toSet().length, 500);
    expect(words.where((w) => w.english.toLowerCase() == 'orange').length, 2);
    expect(words.every((w) => w.isValid), isTrue);
    for (var week = 1; week <= 10; week++) {
      expect(words.where((w) => w.week == week).length, 50, reason: 'week $week');
    }
  });
}
