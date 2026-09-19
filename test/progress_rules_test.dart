import 'package:english_kids/models/progress_rules.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/services/pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final words = [
    for (var i = 0; i < 3; i++)
      Word(english: 'w$i', pronunciation: 'p', tajik: 't$i', week: 1, topic: 'A'),
    for (var i = 0; i < 3; i++)
      Word(english: 'x$i', pronunciation: 'p', tajik: 'u$i', week: 2, topic: 'B'),
  ];

  test('weeks stay locked until alphabet and previous week are learned', () {
    expect(weekUnlocked(1, {}, words, {}), isFalse);
    expect(lockReason(1), 'Аввал алифборо ба анҷом расонед.');
    final letters = {for (var i = 0; i < 26; i++) String.fromCharCode(65 + i)};
    expect(alphabetComplete(letters), isTrue);
    expect(weekUnlocked(1, letters, words, {}), isTrue);
    expect(weekUnlocked(2, letters, words, {}), isFalse);
    expect(lockReason(2), 'Аввал Ҳафтаи 1-ро ба анҷом расонед.');
    final week1 = {for (final w in words.where((w) => w.week == 1)) w.id};
    expect(weekUnlocked(2, letters, words, week1), isTrue);
    expect(grammarUnlocked(words, week1, letters), isFalse);
  });

  test('PIN digest is stable and not the raw pin', () {
    final service = PinService.instance;
    expect(service.validFormat('1234'), isTrue);
    expect(service.validFormat('12'), isFalse);
    expect(service.validFormat('abcdef'), isFalse);
    final hash = service.digest('1234', 'salt');
    expect(hash, isNot('1234'));
    expect(hash, service.digest('1234', 'salt'));
    expect(hash, isNot(service.digest('1235', 'salt')));
  });
}
