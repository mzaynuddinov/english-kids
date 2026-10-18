import 'dart:async';

import 'package:flutter/material.dart';

import '../models/alphabet.dart';
import '../models/activity.dart';
import '../models/days.dart';
import '../models/progress_rules.dart';
import '../models/reminder.dart';
import '../models/settings.dart';
import '../models/test_models.dart';
import '../models/word.dart';
import '../services/preferences_service.dart';
import '../services/student_service.dart';
import '../services/progress_service.dart';
import '../services/reminder_service.dart';
import '../services/test_engine.dart';
import '../services/tts_service.dart';
import '../services/vocabulary_service.dart';
import '../services/word_learning_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_fallback.dart';
import '../widgets/search_sheet.dart';
import '../widgets/word_card.dart';
import 'about_page.dart';
import 'alphabet_page.dart';
import 'calendar_page.dart';
import 'developer_page.dart';
import 'grammar_page.dart';
import 'pin_gate.dart';
import 'practice_page.dart';
import 'progress_page.dart';
import 'oral_quiz_page.dart';
import 'reminders_page.dart';
import 'saved_page.dart';
import 'settings_page.dart';
import 'students_page.dart';
import 'study_start_page.dart';
import 'test_history_page.dart';
import 'test_hub_page.dart';
import 'test_result_page.dart';
import 'test_runner_page.dart';
import 'timer_sheet.dart';
import 'week_page.dart';
import 'words_page.dart';

class HomeShell extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const HomeShell({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  List<Word> words = const [];
  Set<String> learned = {};
  Set<String> saved = {};
  int tab = 0;
  bool loading = true;
  String? loadError;
  bool _loadInFlight = false;
  bool _loadAgain = false;
  String? _appliedStudentId;

  @override
  void initState() {
    super.initState();
    ReminderService.instance.onForegroundFire = _showInAppReminder;
    StudentService.instance.addListener(_onStudentChanged);
    WordLearningService.instance.addListener(_onLexiconChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadData());
    });
  }

  @override
  void dispose() {
    ReminderService.instance.onForegroundFire = null;
    StudentService.instance.removeListener(_onStudentChanged);
    WordLearningService.instance.removeListener(_onLexiconChanged);
    super.dispose();
  }

  void _onStudentChanged() {
    if (!mounted) return;
    final id = StudentService.instance.currentStudentId;
    if (id == _appliedStudentId) {
      setState(() {});
      return;
    }
    _appliedStudentId = id;
    setState(() {
      learned = {};
      saved = {};
    });
    unawaited(_loadData(silent: true));
  }

  void _onLexiconChanged() {
    if (!mounted) return;
    final service = WordLearningService.instance;
    if (service.studentId == null) return;
    if (service.studentId != StudentService.instance.currentStudentId) return;
    setState(() {
      learned = service.learnedIds();
      saved = service.savedIds();
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (_loadInFlight) {
      _loadAgain = true;
      return;
    }
    _loadInFlight = true;
    if (!silent && !loading) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      await StudentService.instance.init();
      final vocab = await VocabularyService.load();
      if (!mounted) return;
      setState(() {
        words = vocab.words;
        loadError = vocab.ok ? null : (vocab.error ?? 'Калимаҳо бор нашуданд.');
      });
    } catch (error, stack) {
      debugPrint('Vocabulary load failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        loadError = 'Калимаҳо бор нашуданд.';
        loading = false;
      });
    }

    try {
      final learnedSet = await PreferencesService.instance.loadSet(StudentService.instance.learnedKey());
      final savedSet = await PreferencesService.instance.loadSet(StudentService.instance.savedKey());
      final studentId = StudentService.instance.currentStudentId;
      if (studentId != null && words.isNotEmpty) {
        await WordLearningService.instance.openStudent(
          studentId: studentId,
          vocab: words,
          legacyLearned: learnedSet,
          legacySaved: savedSet,
        );
      }
      if (!mounted) return;
      final service = WordLearningService.instance;
      setState(() {
        if (service.studentId == studentId && studentId != null && words.isNotEmpty) {
          learned = service.learnedIds();
          saved = service.savedIds();
        } else {
          learned = learnedSet;
          saved = savedSet;
        }
        _appliedStudentId = StudentService.instance.currentStudentId;
      });
    } catch (error, stack) {
      debugPrint('Progress load failed: $error\n$stack');
    }

    try {
      await ProgressService.instance.load(key: StudentService.instance.progressKey());
      ReminderService.instance
          .rearmActive(widget.settings.voiceGender, widget.settings.speechRate);
      if (mounted) setState(() {});
    } catch (error, stack) {
      debugPrint('Learning state load failed: $error\n$stack');
    } finally {
      if (mounted && loading) {
        setState(() => loading = false);
      }
      _loadInFlight = false;
      if (_loadAgain && mounted) {
        _loadAgain = false;
        await _loadData(silent: true);
      }
    }
  }

  Future<void> _speak(String text) async {
    await TtsService.instance.speak(
      text: text,
      gender: widget.settings.voiceGender,
      rate: widget.settings.speechRate,
    );
    try {
      var snap = ProgressService.instance.snapshot.copyWith(
        listens: ProgressService.instance.snapshot.listens + 1,
      );
      snap = ProgressService.instance.bumpDay(snap, listened: 1);
      final needle = text.trim().toLowerCase();
      final match = words.where((w) => w.english.toLowerCase() == needle);
      if (match.isNotEmpty) {
        snap = ProgressService.instance
            .bumpWord(snap, match.first.id, listened: 1);
      }
      snap = snap.copyWith(
        achievements: ProgressService.instance
            .computeAchievements(snap, learned: learned.length),
      );
      await ProgressService.instance.save(snap);
    } catch (_) {}
    final selection = TtsService.instance.lastSelection;
    if (!mounted || selection == null || selection.genderMatched) return;
    if (widget.settings.voiceGender == 'male' && !selection.genderMatched) {
      _feedback('Овози мардона дар дастгоҳи шумо дастрас нест.');
    }
  }

  Future<String?> _testVoice() async {
    final selection = await TtsService.instance.preview(
      gender: widget.settings.voiceGender,
      rate: widget.settings.speechRate,
    );
    if (selection == null) {
      return 'Овоз санҷида шуд. Агар нашунидед, TTS-и дастгоҳро санҷед.';
    }
    if (!selection.hasVoice) {
      return 'Дар ин дастгоҳ овози TTS ёфт нашуд.';
    }
    if (!selection.genderMatched && widget.settings.voiceGender == 'male') {
      return 'Овози мардона дар дастгоҳи шумо дастрас нест.';
    }
    if (!selection.genderMatched && widget.settings.voiceGender == 'female') {
      return 'Овози занона дастрас нест. Овози англисӣ истифода шуд.';
    }
    return 'Овоз тайёр аст.';
  }

  Future<void> _toggleSave(Word word) async {
    if (!_needStudent()) return;
    final service = WordLearningService.instance;
    final wasSaved = service.of(word.id).saved;
    final nowSaved = !wasSaved;
    final pending = service.setFlag(word.id, saved: nowSaved);
    _feedback(wasSaved
        ? '«${word.displayEnglish}» аз захираҳо хориҷ шуд'
        : '🔖 «${word.displayEnglish}» барои баъд захира шуд');
    final savedNow = await pending;
    if (!mounted) return;
    if (!savedNow) {
      _feedback('«${word.displayEnglish}» захира нашуд. Боз кӯшиш кунед.');
      return;
    }
    if (service.of(word.id).saved != nowSaved) return;
  }

  Future<void> _learn(Word word) async {
    if (!_needStudent()) return;
    final service = WordLearningService.instance;
    final wasLearned = service.studentId == null
        ? word.isMarked(learned)
        : service.of(word.id).learned;
    if (!wasLearned && !_weekOpen(word.week)) {
      _feedback(lockReason(word.week));
      return;
    }
    final nowLearned = !wasLearned;
    final message = wasLearned
        ? '«${word.displayEnglish}» ба ҳолати қаблӣ баргардонида шуд.'
        : '🎉 Офарин! «${word.displayEnglish}» омӯхта шуд.';
    if (service.studentId != null) {
      final pending = service.setFlag(word.id, learned: nowLearned);
      _feedback(message);
      final savedNow = await pending;
      if (!mounted) return;
      if (!savedNow) {
        _feedback('«${word.displayEnglish}» захира нашуд. Боз кӯшиш кунед.');
        return;
      }
      if (service.of(word.id).learned != nowLearned) return;
    } else {
      final previous = learned;
      final next = {...learned};
      if (wasLearned) {
        next.remove(word.id);
        next.remove(word.english);
      } else {
        next.add(word.id);
      }
      setState(() => learned = next);
      _feedback(message);
      final ok = await PreferencesService.instance.saveSet(StudentService.instance.learnedKey(), next);
      if (!ok) {
        if (mounted) {
          setState(() => learned = previous);
          _feedback('«${word.displayEnglish}» захира нашуд. Боз кӯшиш кунед.');
        }
        return;
      }
    }
    if (!mounted) return;
    await _noteWordActivity(word, learnedNow: nowLearned);
  }

  Future<void> _noteWordActivity(Word word, {required bool learnedNow}) async {
    final service = WordLearningService.instance;
    final learnedCount = service.studentId == null
        ? learned.length
        : words.where((item) => service.of(item.id).learned).length;
    try {
      var snap = ProgressService.instance.withActivity(ProgressService.instance.snapshot);
      snap = ProgressService.instance.bumpDay(snap, learned: learnedNow ? 1 : 0, opened: 1);
      snap = ProgressService.instance.bumpWord(snap, word.id, opened: 1);
      snap = snap.copyWith(
        achievements: ProgressService.instance.computeAchievements(snap, learned: learnedCount),
      );
      await ProgressService.instance.save(snap);
    } catch (error, stack) {
      debugPrint('Word activity was not saved: $error\n$stack');
    }
  }

  Set<String> _stageLetters() {
    return {
      ...ProgressService.instance.snapshot.letters,
      for (final id in learned)
        if (id.startsWith('letter:') && id.length > 7) id.substring(7),
    };
  }

  bool _weekOpen(int week) => weekUnlocked(week, _stageLetters(), words, learned);

  bool _studentReady() {
    final id = StudentService.instance.currentStudentId;
    return id != null &&
        StudentService.instance.students.any((student) => student.id == id) &&
        WordLearningService.instance.studentId == id;
  }

  bool _needStudent() {
    if (_studentReady()) return true;
    _feedback('Аввал талабаро илова ва интихоб кунед. Ном ба таври автоматӣ илова намешавад.');
    return false;
  }

  Future<void> _learnLetter(AlphabetLetter letter) async {
    if (!_needStudent()) return;
    final progress = ProgressService.instance;
    final learning = WordLearningService.instance;
    final before = progress.snapshot;
    final id = letterLearningId(letter.letter);
    final already = before.letters.contains(letter.letter) || learning.of(id).learned;
    final letters = {...before.letters};
    if (already) {
      letters.remove(letter.letter);
    } else {
      letters.add(letter.letter);
    }
    final next = progress.withActivity(before.copyWith(
      letters: letters,
      achievements: progress.computeAchievements(
        before.copyWith(letters: letters),
        learned: words.where((word) => word.isMarked(learned)).length,
      ),
    ));
    final progressWrite = progress.save(next);
    final flagWrite = learning.setFlag(id, learned: !already);
    if (mounted) setState(() {});
    _feedback(already
        ? 'Ҳарфи ${letter.letter} ба ҳолати қаблӣ баргардонида шуд.'
        : '🎉 Офарин! Ҳарфи ${letter.letter} омӯхта шуд.');
    final flagOk = await flagWrite;
    if (!flagOk) {
      await progress.save(before);
      if (mounted) _feedback('Ҳарфи ${letter.letter} захира нашуд. Боз кӯшиш кунед.');
      return;
    }
    if (learning.of(id).learned != !already) return;
    final progressOk = await progressWrite;
    if (!progressOk && mounted) {
      await learning.setFlag(id, learned: already);
      _feedback('Ҳарфи ${letter.letter} захира нашуд. Боз кӯшиш кунед.');
    }
  }

  Future<void> _saveAlphabetIndex(int index) async {
    try {
      await ProgressService.instance.save(
        ProgressService.instance.snapshot
            .copyWith(alphabetIndex: index.clamp(0, 25)),
      );
    } catch (_) {}
  }

  Future<void> _scheduleWord(Word word) async {
    final plan = await showModalBottomSheet<ReminderPlan>(
      context: context,
      showDragHandle: true,
      builder: (_) => TimerSheet(word: word),
    );
    if (plan == null || !mounted) return;
    final message = await ReminderService.instance.scheduleWord(
      word: word,
      delay: plan.interval,
      repeats: plan.repeats,
      gender: widget.settings.voiceGender,
      rate: widget.settings.speechRate,
    );
    if (!mounted) return;
    setState(() {});
    _feedback(message);
  }

  Future<void> _markReminderDone() async {
    try {
      var snap = ProgressService.instance.snapshot;
      snap = ProgressService.instance.bumpDay(snap, reminders: 1);
      snap = snap.copyWith(reminderDone: snap.reminderDone + 1);
      await ProgressService.instance.save(snap);
    } catch (_) {}
  }

  void _showInAppReminder(WordReminder reminder) {
    if (!mounted) return;
    unawaited(_markReminderDone());
    setState(() {});
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('🔊 Вақти такрор!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reminder.english[0].toUpperCase() +
                    reminder.english.substring(1),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              Text(reminder.pronunciation,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(reminder.tajik,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('Такрор ${reminder.completed} аз ${reminder.repeatTotal}'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Пӯшидан')),
            FilledButton(
              onPressed: () {
                unawaited(_speak(reminder.english));
                Navigator.pop(ctx);
              },
              child: const Text('Гӯш кардам'),
            ),
          ],
        );
      },
    );
  }

  void _feedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: emerald500),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _openWeek(int week) async {
    if (!_needStudent()) return;
    if (!_weekOpen(week)) {
      _feedback(lockReason(week));
      return;
    }
    final snap = ProgressService.instance.snapshot;
    unawaited(() async {
      try {
        await ProgressService.instance.save(ProgressService.instance.bumpDay(snap, opened: 1));
      } catch (_) {}
    }());
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WeekPage(
          week: week,
          title: weekTitles[week] ?? 'Ҳафтаи $week',
          words: words.where((w) => w.week == week).toList(),
          learned: learned,
          saved: saved,
          onSpeak: _speak,
          onSave: _toggleSave,
          onLearn: _learn,
          onRemind: _scheduleWord,
          voiceGender: widget.settings.voiceGender,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openSettings() {
    unawaited(_openSettingsAsync());
  }

  void _openSearch() {
    unawaited(
      openWordSearch(
        context,
        words: words,
        learned: learned,
        saved: saved,
        onSpeak: _speak,
        onSave: _toggleSave,
        onLearn: _learn,
        onRemind: _scheduleWord,
        voiceGender: widget.settings.voiceGender,
      ),
    );
  }

  Future<void> _openSettingsAsync() async {
    final ok = await unlockParent(context, title: 'Танзимот');
    if (!ok || !mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          settings: widget.settings,
          onChanged: widget.onSettingsChanged,
          onTestVoice: _testVoice,
          words: words,
          learned: learned,
          onResetProgress: () async {
            setState(() {
              learned = {};
              saved = {};
            });
          },
        ),
      ),
    );
    if (mounted) await _loadData(silent: true);
  }

  Future<void> _openHistory() async {
    final ok = await unlockParent(context, title: 'Таърихи санҷишҳо');
    if (!ok || !mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TestHistoryPage(results: ProgressService.instance.snapshot.history),
      ),
    );
  }

  Future<void> _openCalendar() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CalendarPage()),
    );
  }

  Future<void> _openGrammar() async {
    if (!grammarUnlocked(words, learned, _stageLetters())) {
      _feedback('Аввал алифбо ва Ҳафтаи 5-ро ба анҷом расонед.');
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GrammarPage(onSpeak: _speak),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _startTest(TestKind kind) async {
    if (kind == TestKind.vocabulary) {
      final n = words.where((w) => w.isMarked(learned)).length;
      if (n < 25) {
        _feedback('Барои санҷиш аввал ҳадди ақал 25 калима омӯзед.');
        return;
      }
    }
    final snap = ProgressService.instance.snapshot;
    final active = snap.active;
    TestSession? session;
    if (active != null && !active.completed && active.kind == kind) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Санҷишро идома медиҳед?'),
          content: Text(
              '${active.kindLabel}: саволи ${active.index + 1} / ${active.total}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Бекор')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'restart'),
                child: const Text('Аз нав')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, 'continue'),
                child: const Text('Идома')),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == 'continue') {
        session = active;
      } else if (choice == 'restart') {
        session = _buildSession(kind);
      } else {
        return;
      }
    } else {
      session = _buildSession(kind);
    }
    await ProgressService.instance.save(snap.copyWith(active: session));
    if (!mounted) return;
    await _openRunner(session);
  }

  Future<void> _startFresh(TestKind kind) async {
    final session = _buildSession(kind);
    await ProgressService.instance
        .save(ProgressService.instance.snapshot.copyWith(active: session));
    if (!mounted) return;
    await _openRunner(session);
  }

  Future<void> _openRunner(TestSession session) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TestRunnerPage(
          session: session,
          onSpeak: _speak,
          onChanged: (next) => ProgressService.instance.save(
            ProgressService.instance.snapshot.copyWith(active: next),
          ),
          onFinished: (done) async {
            await _completeTest(done);
            if (!mounted) return;
            Navigator.pop(context);
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => TestResultPage(
                  session: done,
                  onRetry: () {
                    Navigator.pop(context);
                    unawaited(_startFresh(done.kind));
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  TestSession _buildSession(TestKind kind) {
    final plan = TestBlueprint(
      learned: learned,
      saved: saved,
      misses: ProgressService.instance.snapshot.misses,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    switch (kind) {
      case TestKind.alphabet:
        return buildAlphabetSession(seed: plan.seed);
      case TestKind.vocabulary:
        return buildVocabularySession(words: words, plan: plan);
      case TestKind.daily:
        return buildDailySession(words: words, plan: plan);
    }
  }

  Future<void> _completeTest(TestSession session) async {
    final result = resultFrom(session);
    var snap = ProgressService.instance.snapshot;
    final misses = {...snap.misses};
    final hits = {...snap.hits};
    final letters = {...snap.letters};
    final mistakes = [...snap.mistakes];
    for (final answer in session.answers) {
      TestQuestion? q;
      for (final item in session.questions) {
        if (item.id == answer.questionId) {
          q = item;
          break;
        }
      }
      if (q == null) continue;
      if (q.wordId != null) {
        if (answer.correct) {
          hits[q.wordId!] = (hits[q.wordId!] ?? 0) + 1;
          snap = ProgressService.instance.bumpWord(snap, q.wordId!, correct: 1);
        } else {
          misses[q.wordId!] = (misses[q.wordId!] ?? 0) + 1;
          snap = ProgressService.instance.bumpWord(snap, q.wordId!, mistake: 1);
          mistakes.add(
            MistakeRecord(
              wordId: q.wordId!,
              english: q.speakText,
              kind: session.kind.name,
              given: answer.given,
              expected: q.expected,
              timestamp: answer.timestamp,
              count: misses[q.wordId!] ?? 1,
            ),
          );
        }
      }
      if (q.letter != null && answer.correct) {
        letters.add(q.letter!);
      }
    }
    snap = snap.copyWith(
      misses: misses,
      hits: hits,
      letters: letters,
      mistakes: mistakes.take(200).toList(),
      history: [result, ...snap.history].take(40).toList(),
      clearActive: true,
      dailyDone: session.kind == TestKind.daily ? true : snap.dailyDone,
    );
    snap = ProgressService.instance.bumpDay(snap, tests: 1);
    snap = ProgressService.instance.withActivity(snap);
    snap = snap.copyWith(
      achievements: ProgressService.instance
          .computeAchievements(snap, learned: learned.length),
    );
    await ProgressService.instance.save(snap);
    if (mounted) setState(() {});
  }

  Word? get _wordOfDay {
    final open = words.where((word) => _weekOpen(word.week)).toList();
    if (open.isEmpty) return null;
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year)).inDays;
    return open[day % open.length];
  }

  Future<void> _continueLearning() async {
    final snap = ProgressService.instance.snapshot;
    if (!alphabetComplete(snap.letters)) {
      await _openAlphabet();
      return;
    }
    for (var week = 1; week <= weekCount; week++) {
      if (!weekComplete(week, words, learned) &&
          weekUnlocked(week, snap.letters, words, learned)) {
        await _openWeek(week);
        return;
      }
    }
    if (grammarUnlocked(words, learned, snap.letters)) {
      await _openGrammar();
      return;
    }
    _feedback('🎉 Ҳама чиз омӯхта шуд!');
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildScaffold(context);
    } catch (error, stack) {
      debugPrint('HomeShell build failed: $error\n$stack');
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: ErrorFallback(
          onRetry: () {
            if (mounted) setState(() {});
          },
        ),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    final snap = ProgressService.instance.snapshot;
    final Widget page;
    if (tab == 1) {
      page = SavedPage(
        words: words,
        saved: saved,
        learned: learned,
        onSpeak: _speak,
        onSave: _toggleSave,
        onLearn: _learn,
        onRemind: _scheduleWord,
        voiceGender: widget.settings.voiceGender,
      );
    } else if (tab == 2) {
      page = ProgressPage(
        words: words,
        learned: learned,
        saved: saved,
        snapshot: snap,
        onPractice: _openPractice,
        onHistory: () => unawaited(_openHistory()),
        onCalendar: () => unawaited(_openCalendar()),
      );
    } else {
      page = _home();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: const Row(
          children: [
            AppLogo(size: 40),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                appName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSearch,
            tooltip: 'Ҷустуҷӯ',
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Танзимот',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      drawer: _drawer(),
      body: SafeArea(
        top: false,
        child: page,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Асосӣ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Барои баъд',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Пешрафт',
          ),
        ],
      ),
    );
  }

  void _openPractice() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PracticePage(
          words: words,
          learned: learned,
          saved: saved,
          misses: ProgressService.instance.snapshot.misses,
          hits: ProgressService.instance.snapshot.hits,
          onSpeak: _speak,
          onSave: _toggleSave,
          onLearn: _learn,
          onRemind: _scheduleWord,
        ),
      ),
    );
  }

  Widget _home() {
    if (loading && words.isEmpty) {
      return const Center(
        key: ValueKey('home-loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 96),
            SizedBox(height: 18),
            Text(appName,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: cyan600),
          ],
        ),
      );
    }
    if (loadError != null && words.isEmpty) {
      return Padding(
        key: const ValueKey('home-error'),
        padding: const EdgeInsets.all(16),
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Калимаҳо бор нашуданд.',
          text:
              'Луғатро аз нав бор кунед. Барнома бе луғат ҳам кушода мемонад.',
          actionLabel: 'Дубора кӯшиш кунед',
          onAction: _loadData,
        ),
      );
    }

    final vocabLearned = words.where((word) => word.isMarked(learned)).length;
    final progress = words.isEmpty ? 0.0 : vocabLearned / words.length;
    final snap = ProgressService.instance.snapshot;
    final wotd = _wordOfDay;
    final active = snap.active;

    return CustomScrollView(
      key: const ValueKey('home'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              children: [
                _hero(progress, snap.streak, vocabLearned),
                const SizedBox(height: 12),
                _studentBar(),
                const SizedBox(height: 12),
                _studyCard(),
                const SizedBox(height: 12),
                _oralQuizCard(),
                if (active != null && !active.completed) ...[
                  const SizedBox(height: 12),
                  _continueCard(active),
                ],
                const SizedBox(height: 12),
                if (wotd != null) ...[
                  _wordOfDayCard(wotd),
                  const SizedBox(height: 12),
                ],
                _dailyChallenge(snap),
                const SizedBox(height: 12),
                _alphabetCard(_stageLetters().length),
                const SizedBox(height: 12),
                _grammarCard(snap),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _stat(Icons.menu_book_rounded, '${words.length}',
                            'Калима')),
                    const SizedBox(width: 9),
                    Expanded(
                        child: _stat(Icons.check_circle_rounded,
                            '$vocabLearned', 'Омӯхта')),
                    const SizedBox(width: 9),
                    Expanded(
                        child: _stat(Icons.local_fire_department_rounded,
                            '${snap.streak}', 'Рӯз')),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Нақшаи омӯзиш',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                          color: cyan600, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.builder(
            itemCount: weekCount,
            itemBuilder: (_, i) {
              final week = i + 1;
              final list = words.where((w) => w.week == week).toList();
              final done = list.where((w) => w.isMarked(learned)).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _weekCard(
                  week,
                  weekTitles[week] ?? '',
                  list.length,
                  done,
                  !_weekOpen(week),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openStudents() async {
    final ok = await unlockParent(context, title: 'Талабагон');
    if (!ok || !mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const StudentsPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openStudy() async {
    if (!_needStudent()) {
      await _openStudents();
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => StudyStartPage(
          words: words,
          learned: learned,
          saved: saved,
          letters: _stageLetters(),
          onSpeak: _speak,
          onSave: _toggleSave,
          onLearn: _learn,
          onRemind: _scheduleWord,
          onLearnLetter: _learnLetter,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openOralQuiz() async {
    if (!_needStudent()) return;
    final open = words.where((word) => _weekOpen(word.week)).toList();
    if (open.isEmpty) {
      _feedback(lockReason(1));
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OralQuizPage(words: open, onSpeak: _speak),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _studentBar() {
    final students = StudentService.instance.students;
    final current = StudentService.instance.currentStudentId;
    if (students.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.person_add_alt_1_rounded, color: teal600),
          title: const Text('Талаба нест', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: const Text('Номро худатон ворид кунед. Ягон ном ба таври автоматӣ илова намешавад.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => unawaited(_openStudents()),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Талабаи ҷорӣ', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            TextButton(
              onPressed: () => unawaited(_openStudents()),
              child: const Text('+ Илова кардани талаба'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final student in students)
              ChoiceChip(
                label: Text(student.name),
                selected: student.id == current,
                onSelected: (_) => unawaited(StudentService.instance.setCurrentStudent(student.id)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _studyCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(_openStudy()),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.school_rounded, color: teal600),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Оғози омӯзиш', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(
                      'Аввал алифбо, баъд ҳафтаҳо бо навбат',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cyan600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _oralQuizCard() {
    final name = () {
      final id = StudentService.instance.currentStudentId;
      for (final student in StudentService.instance.students) {
        if (student.id == id) return student.name;
      }
      return 'талаба';
    }();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(_openOralQuiz()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [teal600, cyan600]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.record_voice_over_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Пурсиши луғат',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      'Ҳамаи ${words.length} калимаро аз $name шифоҳӣ пурсед',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: cyan600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(double progress, int streak, int vocabLearned) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [slate950, slate800, Color(0xFF064E3B)]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cyan600.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              AppLogo(size: 76),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Хуш омадед!',
                      style: TextStyle(
                          color: Color(0xFF99F6E4),
                          fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Имрӯз як қадами нав ба сӯи English!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: slate700,
              color: emerald500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$vocabLearned аз ${words.length} калима',
                style: const TextStyle(color: Color(0xFFCBD5E1)),
              ),
              Text(
                streak > 0
                    ? '🔥 $streak рӯз пай дар пай'
                    : '${(progress * 100).round()}%',
                style: const TextStyle(
                    color: Color(0xFF6EE7B7), fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => unawaited(_continueLearning()),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(continueLabel(
                  ProgressService.instance.snapshot.letters, words, learned)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueCard(TestSession active) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_rounded, color: teal600),
        title: const Text('Идомаи санҷиш',
            style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle:
            Text('${active.kindLabel} • ${active.index + 1} / ${active.total}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _startTest(active.kind),
      ),
    );
  }

  Widget _wordOfDayCard(Word word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🌟 Калимаи имрӯз',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        WordCard(
          word: word,
          learned: word.isMarked(learned),
          saved: word.isMarked(saved),
          onSpeak: _speak,
          onSave: _toggleSave,
          onLearn: _learn,
          onRemind: _scheduleWord,
          voiceGender: widget.settings.voiceGender,
        ),
      ],
    );
  }

  Widget _dailyChallenge(ProgressSnapshot snap) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (words.isEmpty) {
            _feedback('Аввал луғатро бор кунед.');
            return;
          }
          unawaited(_startTest(TestKind.daily));
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                indigo600.withValues(alpha: 0.16),
                cyan600.withValues(alpha: 0.12),
              ],
            ),
          ),
          child: Row(
            children: [
              const _QuizBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 Мушкилоти имрӯз',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                      snap.dailyDone
                          ? 'Имрӯз анҷом ёфт!'
                          : 'Тақрибан 30 савол — якто-якто',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: cyan600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alphabetCard(int done) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openAlphabet,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [teal600, cyan600]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.abc_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Алифбо',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                          value: done / 26, minHeight: 7, color: emerald500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('$done / 26',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grammarCard(ProgressSnapshot snap) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(_openGrammar()),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [indigo600, blue600]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Грамматикаи асосӣ',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(
                      grammarUnlocked(words, learned, _stageLetters())
                          ? '${snap.grammar.length} / 10 дарс'
                          : '🔒 Пас аз алифбо ва Ҳафтаи 5',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: cyan600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cyan600),
          const SizedBox(height: 5),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _weekCard(int week, String title, int total, int done, bool locked) {
    final pct = total == 0 ? 0.0 : done / total;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        if (locked) {
          _feedback(lockReason(week));
          return;
        }
        unawaited(_openWeek(week));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: !locked && pct == 1
                ? emerald500.withValues(alpha: 0.65)
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: locked
                        ? [slate700, slate800]
                        : const [teal600, cyan600]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white)
                    : Text(
                        '$week',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locked ? '🔒 Ҳафтаи $week' : 'Ҳафтаи $week',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (locked)
                    Text(lockReason(week),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700))
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                          value: pct, minHeight: 7, color: emerald500),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text('$done/$total',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const Icon(Icons.chevron_right_rounded, color: cyan600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAlphabet() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AlphabetPage(
          onSpeak: _speak,
          onLearnLetter: _learnLetter,
          onIndex: (index) => unawaited(_saveAlphabetIndex(index)),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _drawer() {
    return Drawer(
      width: 320,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [slate950, Color(0xFF064E3B), Color(0xFF083344)]),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: cyan600.withValues(alpha: 0.65)),
              ),
              child: const Row(
                children: [
                  AppLogo(size: 64),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Омӯз, бозӣ кун ва пеш рав!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            _item(Icons.home_rounded, 'Асосӣ', () {
              Navigator.pop(context);
              setState(() => tab = 0);
            }),
            _item(Icons.school_rounded, 'Оғози омӯзиш', () {
              Navigator.pop(context);
              unawaited(_openStudy());
            }),
            _item(Icons.people_rounded, 'Талабагон / Фарзандон', () {
              Navigator.pop(context);
              unawaited(_openStudents());
            }),
            _item(Icons.abc_rounded, 'Алифбо', () {
              Navigator.pop(context);
              unawaited(_openAlphabet());
            }),
            _item(Icons.record_voice_over_rounded, 'Пурсиши луғат', () {
              Navigator.pop(context);
              unawaited(_openOralQuiz());
            }),
            _item(Icons.menu_book_rounded, 'Калимаҳо', () {
              Navigator.pop(context);
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => WordsPage(
                    words: words,
                    learned: learned,
                    saved: saved,
                    weekOpen: _weekOpen,
                    onSpeak: _speak,
                    onSave: _toggleSave,
                    onLearn: _learn,
                    onRemind: _scheduleWord,
                    voiceGender: widget.settings.voiceGender,
                  ),
                ),
              );
            }),
            _item(Icons.spellcheck_rounded, 'Грамматикаи асосӣ', () {
              Navigator.pop(context);
              unawaited(_openGrammar());
            }),
            _item(Icons.extension_rounded, 'Санҷиш', () {
              Navigator.pop(context);
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => TestHubPage(
                    onStart: _startTest,
                    onHistory: () => unawaited(_openHistory()),
                  ),
                ),
              );
            }),
            _item(Icons.alarm_rounded, 'Ёдраскуниҳо', () {
              Navigator.pop(context);
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => RemindersPage(
                    onPause: (r) async {
                      await ReminderService.instance.pause(r.id);
                      if (mounted) setState(() {});
                    },
                    onResume: (r) async {
                      await ReminderService.instance.resume(
                        r.id,
                        widget.settings.voiceGender,
                        widget.settings.speechRate,
                      );
                      if (mounted) setState(() {});
                    },
                    onDelete: (r) async {
                      await ReminderService.instance.delete(r.id);
                      if (mounted) setState(() {});
                    },
                    onSpeak: _speak,
                  ),
                ),
              );
            }),
            _item(Icons.calendar_month_rounded, 'Тақвими омӯзиш', () {
              Navigator.pop(context);
              unawaited(_openCalendar());
            }),
            _item(Icons.bookmark_rounded, 'Барои баъд', () {
              Navigator.pop(context);
              setState(() => tab = 1);
            }),
            _item(Icons.insights_rounded, 'Пешрафт', () {
              Navigator.pop(context);
              setState(() => tab = 2);
            }),
            _item(Icons.history_rounded, 'Таърихи санҷишҳо', () {
              Navigator.pop(context);
              unawaited(_openHistory());
            }),
            const Divider(indent: 20, endIndent: 20),
            _item(Icons.settings_rounded, 'Танзимот', () {
              Navigator.pop(context);
              _openSettings();
            }),
            _item(Icons.person_outline_rounded, 'Таҳиягар', () {
              Navigator.pop(context);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const DeveloperPage()),
              );
            }),
            _item(Icons.info_outline_rounded, 'Дар бораи барнома', () {
              Navigator.pop(context);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            }),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                '© Majnun Zaynuddinov',
                style: TextStyle(color: slate700, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      leading: Icon(icon, color: cyan600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}

class _QuizBadge extends StatelessWidget {
  const _QuizBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [indigo600, blue600]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.extension_rounded, color: Colors.white),
    );
  }
}
