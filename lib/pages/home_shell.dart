import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../models/word.dart';
import '../services/preferences_service.dart';
import '../services/reminder_service.dart';
import '../services/tts_service.dart';
import '../services/vocabulary_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_state.dart';
import 'about_page.dart';
import 'developer_page.dart';
import 'progress_page.dart';
import 'quiz_page.dart';
import 'saved_page.dart';
import 'settings_page.dart';
import 'timer_sheet.dart';
import 'week_page.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && !loading) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      final vocab = await VocabularyService.load();
      if (!mounted) return;
      setState(() {
        words = vocab.words;
        loadError = vocab.ok ? null : (vocab.error ?? 'Калимаҳо бор нашуданд.');
        loading = false;
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
      final learnedSet = await PreferencesService.instance
          .loadSet('learned')
          .timeout(const Duration(seconds: 4), onTimeout: () => <String>{});
      final savedSet = await PreferencesService.instance
          .loadSet('saved')
          .timeout(const Duration(seconds: 4), onTimeout: () => <String>{});
      if (!mounted) return;
      setState(() {
        learned = learnedSet;
        saved = savedSet;
      });
    } catch (error, stack) {
      debugPrint('Progress load failed: $error\n$stack');
    }
  }

  Future<void> _speak(String text) async {
    await TtsService.instance.speak(
      text: text,
      gender: widget.settings.voiceGender,
      rate: widget.settings.speechRate,
    );
    final selection = TtsService.instance.lastSelection;
    if (!mounted || selection == null || selection.genderMatched) return;
    if (widget.settings.voiceGender == 'male' && !selection.genderMatched) {
      _feedback('Овози мардона дар ин дастгоҳ ёфт нашуд. Овози англисӣ истифода шуд.');
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
      return 'Овози мардона дастрас нест. Овози англисӣ истифода шуд.';
    }
    if (!selection.genderMatched && widget.settings.voiceGender == 'female') {
      return 'Овози занона дастрас нест. Овози англисӣ истифода шуд.';
    }
    return 'Овоз тайёр аст.';
  }

  Future<void> _toggleSave(Word word) async {
    final next = {...saved};
    final added = !word.isMarked(next);
    if (added) {
      next.add(word.id);
      next.remove(word.english);
    } else {
      next.remove(word.id);
      next.remove(word.english);
    }
    await PreferencesService.instance.saveSet('saved', next);
    if (!mounted) return;
    setState(() => saved = next);
    _feedback(added ? '«${word.displayEnglish}» барои баъд захира шуд ✓' : '«${word.displayEnglish}» аз захираҳо хориҷ шуд');
  }

  Future<void> _learn(Word word) async {
    final next = {...learned, word.id}..remove(word.english);
    await PreferencesService.instance.saveSet('learned', next);
    if (!mounted) return;
    setState(() => learned = next);
    _feedback('Офарин! «${word.displayEnglish}» омӯхта шуд 🎉');
  }

  Future<void> _scheduleWord(Word word) async {
    final delay = await showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
      builder: (_) => TimerSheet(word: word),
    );
    if (delay == null || !mounted) return;
    final message = await ReminderService.instance.scheduleWord(
      word: word,
      delay: delay,
      gender: widget.settings.voiceGender,
      rate: widget.settings.speechRate,
    );
    if (!mounted) return;
    _feedback(message);
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
        ),
      ),
    );
    if (mounted) await _loadData(silent: true);
  }

  void _openSettings() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          settings: widget.settings,
          onChanged: widget.onSettingsChanged,
          onTestVoice: _testVoice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      SavedPage(
        words: words,
        saved: saved,
        learned: learned,
        onSpeak: _speak,
        onSave: _toggleSave,
        onLearn: _learn,
        onRemind: _scheduleWord,
      ),
      ProgressPage(words: words, learned: learned),
    ];

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
            onPressed: _openSettings,
            tooltip: 'Танзимот',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      drawer: _drawer(),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: pages[tab],
        ),
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

  Widget _home() {
    if (loading && words.isEmpty) {
      return const Center(
        key: ValueKey('home-loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 96),
            SizedBox(height: 18),
            Text(appName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
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
          text: 'Луғатро аз нав бор кунед. Барнома бе луғат ҳам кушода мемонад.',
          actionLabel: 'Дубора кӯшиш кунед',
          onAction: _loadData,
        ),
      );
    }

    final progress = words.isEmpty ? 0.0 : learned.length / words.length;
    final next = words.firstWhere(
      (w) => !w.isMarked(learned),
      orElse: () => words.first,
    );

    return CustomScrollView(
      key: const ValueKey('home'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              children: [
                _hero(progress, next),
                const SizedBox(height: 14),
                _dailyChallenge(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _stat(Icons.menu_book_rounded, '${words.length}', 'Калима')),
                    const SizedBox(width: 9),
                    Expanded(child: _stat(Icons.check_circle_rounded, '${learned.length}', 'Омӯхта')),
                    const SizedBox(width: 9),
                    Expanded(child: _stat(Icons.bookmark_rounded, '${saved.length}', 'Барои баъд')),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Нақшаи омӯзиш',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(color: cyan600, fontWeight: FontWeight.w900),
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
            itemCount: 5,
            itemBuilder: (_, i) {
              final week = i + 1;
              final list = words.where((w) => w.week == week).toList();
              final done = list.where((w) => w.isMarked(learned)).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _weekCard(week, weekTitles[week] ?? '', list.length, done),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hero(double progress, Word next) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [slate950, slate800, Color(0xFF064E3B)]),
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
                      style: TextStyle(color: Color(0xFF99F6E4), fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Имрӯз як қадами нав ба сӯи English!',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
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
                '${learned.length} аз ${words.length} калима',
                style: const TextStyle(color: Color(0xFFCBD5E1)),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openWeek(next.week),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Идома: ${next.displayEnglish}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyChallenge() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (words.isEmpty) {
            _feedback('Аввал луғатро бор кунед.');
            return;
          }
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => QuizPage(words: words)),
          );
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
          child: const Row(
            children: [
              _QuizBadge(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Мушкилоти имрӯз', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    SizedBox(height: 3),
                    Text('5 саволи кӯтоҳ — ҷавоб деҳ ва хол гир!', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _stat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cyan600),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _weekCard(int week, String title, int total, int done) {
    final pct = total == 0 ? 0.0 : done / total;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openWeek(week),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: pct == 1
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
                gradient: const LinearGradient(colors: [teal600, cyan600]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$week',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ҳафтаи $week', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: pct, minHeight: 7, color: emerald500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text('$done/$total', style: const TextStyle(fontWeight: FontWeight.w900)),
                const Icon(Icons.chevron_right_rounded, color: cyan600),
              ],
            ),
          ],
        ),
      ),
    );
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
                gradient: const LinearGradient(colors: [slate950, Color(0xFF064E3B), Color(0xFF083344)]),
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
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            _item(Icons.home_rounded, 'Асосӣ', () {
              Navigator.pop(context);
              setState(() => tab = 0);
            }),
            _item(Icons.bookmark_rounded, 'Барои баъд', () {
              Navigator.pop(context);
              setState(() => tab = 1);
            }),
            _item(Icons.insights_rounded, 'Пешрафт', () {
              Navigator.pop(context);
              setState(() => tab = 2);
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
