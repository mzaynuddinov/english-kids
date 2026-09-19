import 'dart:convert';
import 'dart:io';

import 'package:english_kids/services/vocabulary_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parseRaw accepts the bundled 500-word list', () {
    final raw = File('data/vocabulary.json').readAsStringSync();
    final result = VocabularyService.parseRaw(raw);
    expect(result.ok, isTrue);
    expect(result.words.length, 500);
    expect(result.words.where((w) => w.english.toLowerCase() == 'orange').length, 2);
    expect(result.words.map((w) => w.id).toSet().length, 500);
    expect(result.error, isNull);
  });

  test('parseRaw rejects junk without throwing', () {
    expect(VocabularyService.parseRaw('{}').ok, isFalse);
    expect(VocabularyService.parseRaw('not-json').ok, isFalse);
    expect(VocabularyService.parseRaw('[]').ok, isFalse);
    expect(VocabularyService.parseRaw('[{"english":""}]').ok, isFalse);
  });

  test('asset bundle contains vocabulary.json', () async {
    final raw = await rootBundle.loadString('data/vocabulary.json');
    expect(jsonDecode(raw), isA<List>());
    final result = VocabularyService.parseRaw(raw);
    expect(result.words.length, 500);
    expect(result.words.map((w) => w.id).toSet().length, 500);
  });
}
