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

  test('parses map records', () {
    final word = Word.tryParse({
      'english': 'cat',
      'pronunciation': 'кэт',
      'tajik': 'гурба',
      'week': 4,
      'topic': 'Animals',
    });
    expect(word?.english, 'cat');
    expect(word?.week, 4);
  });

  test('bundled vocabulary.json is valid and complete', () {
    final file = File('data/vocabulary.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());
    final words = (decoded as List).map(Word.tryParse).whereType<Word>().toList();
    expect(words.length, 150);
    expect(words.every((w) => w.isValid), isTrue);
    expect(words.where((w) => w.week == 1).length, 25);
    expect(words.where((w) => w.week == 2).length, 25);
    expect(words.where((w) => w.week == 3).length, 30);
    expect(words.where((w) => w.week == 4).length, 30);
    expect(words.where((w) => w.week == 5).length, 40);
  });
}
