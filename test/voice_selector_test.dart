import 'package:english_kids/services/voice_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefers English locale, then requested gender metadata', () {
    final voices = normalizeVoices([
      {'name': 'fr-voice', 'locale': 'fr-FR', 'gender': 'male'},
      {'name': 'en-female', 'locale': 'en-US', 'gender': 'female'},
      {'name': 'en-male', 'locale': 'en-GB', 'gender': 'male'},
    ]);

    final male = selectEnglishVoice(voices: voices, gender: 'male');
    expect(male.voice?['name'], 'en-male');
    expect(male.genderMatched, isTrue);
    expect(male.englishMatched, isTrue);

    final female = selectEnglishVoice(voices: voices, gender: 'female');
    expect(female.voice?['name'], 'en-female');
    expect(female.genderMatched, isTrue);
  });

  test('falls back to any English voice without crashing', () {
    final voices = normalizeVoices([
      {'name': 'Google en-us', 'locale': 'en-US'},
      {'name': 'Google ru-ru', 'locale': 'ru-RU'},
    ]);
    final selected = selectEnglishVoice(voices: voices, gender: 'male');
    expect(selected.voice?['locale'], 'en-US');
    expect(selected.genderMatched, isFalse);
    expect(selected.englishMatched, isTrue);
  });

  test('empty voice list is safe', () {
    final selected = selectEnglishVoice(voices: const [], gender: 'female');
    expect(selected.voice, isNull);
    expect(selected.hasVoice, isFalse);
  });
}
