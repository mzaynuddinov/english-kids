import 'days.dart';
import 'word.dart';
import 'word_learning.dart';

/// Counts for the selected student. Word totals ignore letter and day ids.
class ManualStudyStats {
  final int lettersLearned;
  final int daysLearned;
  final int daysSaved;
  final int numbersLearned;
  final int numbersTotal;
  final int colorsLearned;
  final int colorsTotal;
  final int basicsLearned;
  final int basicsTotal;
  final int correct;
  final int incorrect;
  final int unknown;
  final int? lastQuizAt;
  final int todayCorrect;
  final int todayIncorrect;
  final int todayUnknown;

  static const int letterTotal = 26;
  static const int dayTotal = 7;

  const ManualStudyStats({
    required this.lettersLearned,
    required this.daysLearned,
    required this.daysSaved,
    required this.numbersLearned,
    required this.numbersTotal,
    required this.colorsLearned,
    required this.colorsTotal,
    required this.basicsLearned,
    required this.basicsTotal,
    required this.correct,
    required this.incorrect,
    required this.unknown,
    required this.lastQuizAt,
    required this.todayCorrect,
    required this.todayIncorrect,
    required this.todayUnknown,
  });

  static ManualStudyStats compute({
    required List<Word> words,
    required Map<String, WordLearning> state,
    required DateTime now,
    Set<String> snapshotLetters = const {},
  }) {
    final seen = <String>{};
    var numbersLearned = 0;
    var numbersTotal = 0;
    var colorsLearned = 0;
    var colorsTotal = 0;
    var basicsLearned = 0;
    var basicsTotal = 0;
    for (final word in words) {
      if (word.id.isEmpty || !seen.add(word.id)) continue;
      final learned = Lexicon.of(state, word.id).learned;
      if (word.topic == 'Numbers') {
        numbersTotal += 1;
        if (learned) numbersLearned += 1;
      } else if (word.topic == 'Colors') {
        colorsTotal += 1;
        if (learned) colorsLearned += 1;
      } else if (word.topic == 'Basics') {
        basicsTotal += 1;
        if (learned) basicsLearned += 1;
      }
    }

    var lettersLearned = 0;
    for (var code = 65; code <= 90; code++) {
      final letter = String.fromCharCode(code);
      if (snapshotLetters.contains(letter) || Lexicon.of(state, letterLearningId(letter)).learned) {
        lettersLearned += 1;
      }
    }

    var daysLearned = 0;
    var daysSaved = 0;
    for (final day in weekDays) {
      final record = Lexicon.of(state, day.id);
      if (record.learned) daysLearned += 1;
      if (record.saved) daysSaved += 1;
    }

    var correct = 0;
    var incorrect = 0;
    var unknown = 0;
    var todayCorrect = 0;
    var todayIncorrect = 0;
    var todayUnknown = 0;
    int? lastQuizAt;
    for (final record in state.values) {
      correct += record.correct;
      incorrect += record.incorrect;
      unknown += record.unknown;
      final at = record.lastQuizAt;
      if (at != null && at > 0 && (lastQuizAt == null || at > lastQuizAt)) {
        lastQuizAt = at;
      }
      for (final attempt in record.history) {
        if (!_sameDay(attempt.at, now)) continue;
        if (attempt.mark == OralMark.correct) todayCorrect += 1;
        if (attempt.mark == OralMark.incorrect) todayIncorrect += 1;
        if (attempt.mark == OralMark.unknown) todayUnknown += 1;
      }
    }

    return ManualStudyStats(
      lettersLearned: lettersLearned,
      daysLearned: daysLearned,
      daysSaved: daysSaved,
      numbersLearned: numbersLearned,
      numbersTotal: numbersTotal,
      colorsLearned: colorsLearned,
      colorsTotal: colorsTotal,
      basicsLearned: basicsLearned,
      basicsTotal: basicsTotal,
      correct: correct,
      incorrect: incorrect,
      unknown: unknown,
      lastQuizAt: lastQuizAt,
      todayCorrect: todayCorrect,
      todayIncorrect: todayIncorrect,
      todayUnknown: todayUnknown,
    );
  }

  static bool _sameDay(int at, DateTime now) {
    if (at <= 0) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(at);
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
