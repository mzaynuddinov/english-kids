import 'word.dart';

bool alphabetComplete(Set<String> letters) => letters.length >= 26;

bool weekComplete(int week, List<Word> words, Set<String> learned) {
  final list = words.where((w) => w.week == week).toList();
  if (list.isEmpty) return false;
  return list.every((w) => w.isMarked(learned));
}

bool weekUnlocked(int week, Set<String> letters, List<Word> words, Set<String> learned) {
  if (!alphabetComplete(letters)) return false;
  for (var w = 1; w < week; w++) {
    if (!weekComplete(w, words, learned)) return false;
  }
  return true;
}

bool grammarUnlocked(List<Word> words, Set<String> learned, Set<String> letters) {
  return alphabetComplete(letters) && weekComplete(5, words, learned);
}

String lockReason(int week) {
  if (week <= 1) return 'Аввал алифборо ба анҷом расонед.';
  return 'Аввал Ҳафтаи ${week - 1}-ро ба анҷом расонед.';
}
