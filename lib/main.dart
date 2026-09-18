import 'dart:convert';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

const emerald500 = Color(0xFF10B981);
const emerald600 = Color(0xFF059669);
const teal500 = Color(0xFF14B8A6);
const cyan500 = Color(0xFF06B6D4);
const sky500 = Color(0xFF0EA5E9);
const blue500 = Color(0xFF3B82F6);
const indigo600 = Color(0xFF4F46E5);
const slate700 = Color(0xFF334155);
const slate800 = Color(0xFF1E293B);
const slate900 = Color(0xFF0F172A);
const slate950 = Color(0xFF020617);

const appName = 'Англисиро Омӯз';
const _developerPhotoBase64 = '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';
final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifications();
  await AndroidAlarmManager.initialize();
  runApp(const EnglishKidsApp());
}

Future<void> _initNotifications() async {
  const settings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
  await notifications.initialize(settings, onDidReceiveNotificationResponse: (response) async {
    final raw = response.payload;
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final tts = FlutterTts();
    await _configureTts(tts, '${data['gender'] ?? 'female'}', (data['rate'] as num?)?.toDouble() ?? .42);
    await tts.speak('${data['word'] ?? 'Hello'}');
  });
  await notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
}

Future<void> _configureTts(FlutterTts tts, String gender, double rate) async {
  await tts.stop();
  await tts.setLanguage('en-US');
  await tts.setSpeechRate(rate);
  final voices = await tts.getVoices;
  if (voices is! List) return;
  final candidates = <Map<String, String>>[];
  for (final item in voices) {
    if (item is! Map) continue;
    final name = '${item['name'] ?? ''}';
    final locale = '${item['locale'] ?? ''}';
    if (name.isNotEmpty && locale.toLowerCase().startsWith('en')) candidates.add({'name': name, 'locale': locale});
  }
  Map<String, String>? selected;
  for (final voice in candidates) {
    final name = voice['name']!.toLowerCase();
    final male = name.contains('male') || name.contains('man') || name.contains('daniel') || name.contains('alex') || name.contains('aaron');
    final female = name.contains('female') || name.contains('woman') || name.contains('samantha') || name.contains('ava') || name.contains('zira');
    if ((gender == 'male' && male) || (gender == 'female' && female)) { selected = voice; break; }
  }
  selected ??= candidates.isEmpty ? null : candidates.first;
  if (selected != null) await tts.setVoice(selected);
}

@pragma('vm:entry-point')
Future<void> scheduledWordAlarm(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final word = '${params['word'] ?? ''}';
  final tajik = '${params['tajik'] ?? ''}';
  final gender = '${params['gender'] ?? 'female'}';
  final rate = (params['rate'] as num?)?.toDouble() ?? .42;
  if (word.isEmpty) return;
  final tts = FlutterTts();
  await _configureTts(tts, gender, rate);
  await tts.speak(word);
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  const details = AndroidNotificationDetails('word_review', 'Такрори калимаҳо', channelDescription: 'Ёдраскуниҳои калимаҳои англисӣ', importance: Importance.high, priority: Priority.high);
  await local.show(id, 'Вақти такрори калима 📚', '$word — $tajik', const NotificationDetails(android: details), payload: jsonEncode({'word': word, 'gender': gender, 'rate': rate}));
}

class Word {
  final String english, pronunciation, tajik, topic;
  final int week;
  const Word(this.english, this.pronunciation, this.tajik, this.week, this.topic);
  factory Word.fromList(List<dynamic> x) => Word(
    x[0] as String, x[1] as String, x[2] as String, x[3] as int, x[4] as String);
}

class AppSettings {
  final ThemeMode themeMode;
  final double textScale, speechRate;
  final String voiceGender;
  const AppSettings({
    this.themeMode = ThemeMode.system, this.textScale = 1,
    this.voiceGender = 'female', this.speechRate = .42,
  });
}

class EnglishKidsApp extends StatefulWidget {
  const EnglishKidsApp({super.key});
  @override State<EnglishKidsApp> createState() => _EnglishKidsAppState();
}

class _EnglishKidsAppState extends State<EnglishKidsApp> {
  AppSettings settings = const AppSettings();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => settings = AppSettings(
      themeMode: ThemeMode.values[p.getInt('themeMode') ?? 0],
      textScale: p.getDouble('textScale') ?? 1,
      voiceGender: p.getString('voiceGender') ?? 'female',
      speechRate: p.getDouble('speechRate') ?? .42,
    ));
  }

  Future<void> _save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('themeMode', s.themeMode.index);
    await p.setDouble('textScale', s.textScale);
    await p.setString('voiceGender', s.voiceGender);
    await p.setDouble('speechRate', s.speechRate);
    setState(() => settings = s);
  }

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: dark ? slate950 : const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(seedColor: dark ? cyan500 : emerald500, brightness: b),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? slate900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72, elevation: 0,
        backgroundColor: dark ? slate950 : Colors.white,
        indicatorColor: dark ? cyan500.withValues(alpha: .18) : emerald500.withValues(alpha: .14),
      ),
    );
  }

  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Англисиро Омӯз',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    themeMode: settings.themeMode,
    builder: (_, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.textScale)),
      child: child!,
    ),
    home: HomeShell(settings: settings, onSettingsChanged: _save),
  );
}

class HomeShell extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  const HomeShell({super.key, required this.settings, required this.onSettingsChanged});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  List<Word> words = [];
  Set<String> learned = {}, saved = {};
  int tab = 0;
  final FlutterTts tts = FlutterTts();

  static const weekNames = {
    1: 'Салом ва ҳиссиёт', 2: 'Рақамҳо ва рангҳо',
    3: 'Оила ва бадани инсон', 4: 'Ҳайвонот ва грамматика',
    5: 'Хӯрок, нӯшокиҳо ва феълҳо',
  };

  @override void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('data/vocabulary.json');
    final p = await SharedPreferences.getInstance();
    final data = (jsonDecode(raw) as List).map((e) => Word.fromList(e)).toList();
    setState(() {
      words = data;
      learned = p.getStringList('learned')?.toSet() ?? {};
      saved = p.getStringList('saved')?.toSet() ?? {};
    });
  }

  Future<void> _speak(String text) async {
    await _configureTts(tts, widget.settings.voiceGender, widget.settings.speechRate);
    await tts.speak(text);
  }

  Future<void> _toggleSave(Word w) async {
    final p = await SharedPreferences.getInstance();
    final next = {...saved};
    final added = next.add(w.english);
    if (!added) next.remove(w.english);
    await p.setStringList('saved', next.toList());
    setState(() => saved = next);
    _feedback(added ? '«${w.english}» барои баъд захира шуд ✓' : '«${w.english}» аз захираҳо хориҷ шуд');
  }

  void _feedback(String message) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle_rounded, color: emerald500), const SizedBox(width: 8), Expanded(child: Text(message))])));
  }

  Future<void> _learn(Word w) async {
    final p = await SharedPreferences.getInstance();
    final next = {...learned, w.english};
    await p.setStringList('learned', next.toList());
    setState(() => learned = next);
    _feedback('Офарин! «${w.english}» омӯхта шуд 🎉');
  }

  Future<void> _scheduleWord(Word w) async {
    final delay = await showModalBottomSheet<Duration>(context: context, showDragHandle: true, builder: (_) => TimerSheet(word: w));
    if (delay == null) return;
    final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483000);
    try {
      final ok = await AndroidAlarmManager.oneShotAt(DateTime.now().add(delay), id, scheduledWordAlarm, exact: true, allowWhileIdle: true, wakeup: true, rescheduleOnReboot: true, params: {'word': w.english, 'tajik': w.tajik, 'gender': widget.settings.voiceGender, 'rate': widget.settings.speechRate});
      _feedback(ok ? 'Ёдрас гузошта шуд ⏰' : 'Ёдрас гузошта нашуд. Иҷозаи Alarm/Notification-ро фаъол кунед.');
    } catch (_) {
      _feedback('Барои ёдрас иҷозаи Alarm/Notification лозим аст.');
    }
  }

  Future<void> _week(int week) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => WeekPage(
      week: week, title: weekNames[week]!,
      words: words.where((w) => w.week == week).toList(),
      learned: learned, saved: saved, speak: _speak,
      onSave: _toggleSave, onLearn: _learn, onTimer: _scheduleWord,
    )));
    _loadData();
  }

  void _settings() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => SettingsPage(settings: widget.settings, onChanged: widget.onSettingsChanged, speak: _speak),
  ));

  @override Widget build(BuildContext context) {
    final pages = [
      _home(),
      SavedPage(words: words, saved: saved, learned: learned, speak: _speak, onSave: _toggleSave, onLearn: _learn, onTimer: _scheduleWord),
      ProgressPage(words: words, learned: learned),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(children: [
          AppLogo(size: 40), SizedBox(width: 10),
          Text('Англисиро Омӯз', style: TextStyle(fontWeight: FontWeight.w900)),
        ]),
        actions: [
          IconButton(onPressed: _settings, tooltip: 'Танзимот', icon: const Icon(Icons.settings_outlined)),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _drawer(),
      body: SafeArea(top: false, bottom: true, child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280), child: pages[tab],
      )),
      bottomNavigationBar: SafeArea(
        top: false, bottom: true,
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Асосӣ'),
            NavigationDestination(icon: Icon(Icons.bookmark_outline_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: 'Захираҳо'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Пешрафт'),
          ],
        ),
      ),
    );
  }

  Widget _home() {
    if (words.isEmpty) return const Center(child: CircularProgressIndicator());
    final progress = learned.length / words.length;
    final next = words.firstWhere((w) => !learned.contains(w.english), orElse: () => words.first);
    return CustomScrollView(
      key: const ValueKey('home'),
      slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(children: [
            _hero(progress, next),
            const SizedBox(height: 14),
            _dailyChallenge(),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _stat(Icons.menu_book_rounded, words.length.toString(), 'Калима')),
              const SizedBox(width: 9),
              Expanded(child: _stat(Icons.check_circle_rounded, learned.length.toString(), 'Омӯхта')),
              const SizedBox(width: 9),
              Expanded(child: _stat(Icons.bookmark_rounded, saved.length.toString(), 'Барои баъд')),
            ]),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Нақшаи омӯзиш', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text((progress * 100).round().toString() + '%', style: const TextStyle(color: cyan500, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 10),
          ]),
        )),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.builder(
            itemCount: 5,
            itemBuilder: (_, i) {
              final week = i + 1;
              final list = words.where((w) => w.week == week).toList();
              final done = list.where((w) => learned.contains(w.english)).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _weekCard(week, weekNames[week]!, list.length, done),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hero(double progress, Word next) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [slate950, slate800, Color(0xFF064E3B)]),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: cyan500.withValues(alpha: .55)),
      boxShadow: [BoxShadow(color: cyan500.withValues(alpha: .13), blurRadius: 28)],
    ),
    child: Column(children: [
      Row(children: [
        const AppLogo(size: 76), const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Хуш омадед! 👋', style: TextStyle(color: Color(0xFF99F6E4), fontWeight: FontWeight.w800)),
          SizedBox(height: 5),
          Text('Имрӯз як қадами нав ба сӯи English!', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
        ])),
      ]),
      const SizedBox(height: 18),
      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(
        minHeight: 10, value: progress, backgroundColor: slate700, color: emerald500,
      )),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(learned.length.toString() + ' аз ' + words.length.toString() + ' калима', style: const TextStyle(color: Color(0xFFCBD5E1))),
        Text((progress * 100).round().toString() + '%', style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: () => _week(next.week),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text('Идома: ' + next.english),
      )),
    ]),
  );

  Widget _dailyChallenge() => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () { if (words.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(words: words.take(20).toList()))); },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [indigo600.withValues(alpha: .10), cyan500.withValues(alpha: .10)])),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [indigo600, blue500]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.extension_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Мушкилоти имрӯз', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            SizedBox(height: 3),
            Text('5 саволи кӯтоҳ — ҷавоб деҳ ва хол гир!', style: TextStyle(fontWeight: FontWeight.w600)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: cyan500),
        ]),
      ),
    ),
  );

  Widget _stat(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .35)),
    ),
    child: Column(children: [
      Icon(icon, color: cyan500), const SizedBox(height: 5),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]),
  );

  Widget _weekCard(int week, String title, int total, int done) {
    final pct = total == 0 ? 0.0 : done / total;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _week(week),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: pct == 1 ? emerald500.withValues(alpha: .65) : Theme.of(context).dividerColor.withValues(alpha: .3)),
        ),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [teal500, cyan500]), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(week.toString(), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ҳафтаи ' + week.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct, minHeight: 7, color: emerald500)),
          ])),
          const SizedBox(width: 10),
          Column(children: [
            Text(done.toString() + '/' + total.toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
            const Icon(Icons.chevron_right_rounded, color: cyan500),
          ]),
        ]),
      ),
    );
  }

  Widget _drawer() => Drawer(
    width: 320,
    child: SafeArea(child: Column(children: [
      Container(
        margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [slate950, Color(0xFF064E3B), Color(0xFF083344)]),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: cyan500.withValues(alpha: .65)),
        ),
        child: Row(children: [
          const AppLogo(size: 68), const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Омӯз, бозӣ кун ва пеш рав!', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          ])),
        ]),
      ),
      _drawerItem(Icons.home_rounded, 'Асосӣ', () { Navigator.pop(context); setState(() => tab = 0); }),
      _drawerItem(Icons.bookmark_rounded, 'Калимаҳоро барои баъд', () { Navigator.pop(context); setState(() => tab = 1); }),
      _drawerItem(Icons.insights_rounded, 'Пешрафти ман', () { Navigator.pop(context); setState(() => tab = 2); }),
      const Divider(indent: 20, endIndent: 20),
      _drawerItem(Icons.settings_rounded, 'Танзимот', () { Navigator.pop(context); _settings(); }),
      _drawerItem(Icons.person_outline_rounded, 'Таҳиягар', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperPage())); }),
      _drawerItem(Icons.info_outline_rounded, 'Дар бораи барнома', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())); }),
      const Spacer(),
      const Padding(padding: EdgeInsets.all(18), child: Text('© Majnun Zaynuddinov', style: TextStyle(color: slate700, fontWeight: FontWeight.w700))),
    ])),
  );

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 22),
    leading: Icon(icon, color: cyan500), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onTap: onTap,
  );
}

class WeekPage extends StatelessWidget {
  final int week; final String title; final List<Word> words;
  final Set<String> learned, saved;
  final Future<void> Function(String) speak;
  final Future<void> Function(Word) onSave, onLearn, onTimer;
  const WeekPage({super.key, required this.week, required this.title, required this.words, required this.learned, required this.saved, required this.speak, required this.onSave, required this.onLearn, required this.onTimer});

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Ҳафтаи ' + week.toString())),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [slate900, Color(0xFF134E4A)]),
            borderRadius: BorderRadius.circular(24), border: Border.all(color: teal500.withValues(alpha: .5)),
          ),
          child: Row(children: [
            const AppLogo(size: 58), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5), Text(words.length.toString() + ' калима • омӯзед, гӯш кунед ва барои рӯзи дигар нигоҳ доред', style: const TextStyle(color: Color(0xFF99F6E4))),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        ...words.map((w) => WordCard(word: w, learned: learned.contains(w.english), saved: saved.contains(w.english), speak: speak, onSave: onSave, onLearn: onLearn, onTimer: onTimer)),
      ],
    )),
  );
}

class WordCard extends StatefulWidget {
  final Word word; final bool learned, saved;
  final Future<void> Function(String) speak;
  final Future<void> Function(Word) onSave, onLearn, onTimer;
  const WordCard({super.key, required this.word, required this.learned, required this.saved, required this.speak, required this.onSave, required this.onLearn, required this.onTimer});
  @override State<WordCard> createState() => _WordCardState();
}
class _WordCardState extends State<WordCard> {
  bool pressed = false;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: pressed ? [BoxShadow(color: cyan500.withValues(alpha: .12), blurRadius: 18)] : null),
      child: Card(clipBehavior: Clip.antiAlias, child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => widget.speak(widget.word.english),
        onHighlightChanged: (v) => setState(() => pressed = v),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: cyan500.withValues(alpha: .12), borderRadius: BorderRadius.circular(11)), child: Text(widget.word.topic, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cyan500, fontSize: 11, fontWeight: FontWeight.w900)))),
            const Spacer(),
            IconButton(onPressed: () => widget.onSave(widget.word), tooltip: widget.saved ? 'Аз захираҳо хориҷ кардан' : 'Барои баъд захира кардан', icon: AnimatedSwitcher(duration: const Duration(milliseconds: 160), child: Icon(widget.saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, key: ValueKey(widget.saved), color: widget.saved ? emerald500 : null))),
            IconButton(onPressed: () => widget.speak(widget.word.english), tooltip: 'Гӯш кардан', icon: const Icon(Icons.volume_up_rounded, color: cyan500)),
          ]),
          Align(alignment: Alignment.centerLeft, child: Text(widget.word.english, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
          Align(alignment: Alignment.centerLeft, child: Text(widget.word.pronunciation, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 5),
          Align(alignment: Alignment.centerLeft, child: Text(widget.word.tajik, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(child: FilledButton.tonalIcon(onPressed: widget.learned ? null : () => widget.onLearn(widget.word), icon: Icon(widget.learned ? Icons.check_circle_rounded : Icons.school_rounded), label: Text(widget.learned ? 'Омӯхта шуд' : 'Омӯхтам'))),
            const SizedBox(width: 8),
            Tooltip(message: 'Ёдрас барои «${widget.word.english}»', child: OutlinedButton(onPressed: () => widget.onTimer(widget.word), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)), child: const Icon(Icons.alarm_add_rounded))),
          ]),
        ])),
      )),
    ),
  );
}

class SavedPage extends StatelessWidget {
  final List<Word> words; final Set<String> saved, learned;
  final Future<void> Function(String) speak;
  final Future<void> Function(Word) onSave, onLearn, onTimer;
  const SavedPage({super.key, required this.words, required this.saved, required this.learned, required this.speak, required this.onSave, required this.onLearn, required this.onTimer});

  @override Widget build(BuildContext context) {
    final list = words.where((w) => saved.contains(w.english)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 32), children: [
      Row(children: [const AppLogo(size: 52), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Барои баъд', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        Text(list.length.toString() + ' калима захира шудааст'),
      ])]),
      const SizedBox(height: 16),
      if (list.isEmpty) const EmptyState(icon: Icons.bookmark_border_rounded, title: 'Ҳоло чизе нест', text: 'Калимаҳое, ки имрӯз азёд кардан мехоҳед, бо bookmark барои рӯзи дигар нигоҳ доред.'),
      ...list.map((w) => WordCard(word: w, learned: learned.contains(w.english), saved: true, speak: speak, onSave: onSave, onLearn: onLearn, onTimer: onTimer)),
    ]);
  }
}

class ProgressPage extends StatelessWidget {
  final List<Word> words; final Set<String> learned;
  const ProgressPage({super.key, required this.words, required this.learned});

  @override Widget build(BuildContext context) {
    final pct = words.isEmpty ? 0.0 : learned.length / words.length;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 32), children: [
      Row(children: [const AppLogo(size: 52), const SizedBox(width: 12), Text('Пешрафти ман', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))]),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        SizedBox(width: 150, height: 150, child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(value: pct, strokeWidth: 13, color: emerald500)),
          Column(mainAxisSize: MainAxisSize.min, children: [Text((pct * 100).round().toString() + '%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const Text('пешрафт')]),
        ])),
        const SizedBox(height: 18),
        Text(learned.length.toString() + ' аз ' + words.length.toString() + ' калима омӯхта шуд', style: const TextStyle(fontWeight: FontWeight.w800)),
      ]))),
      const SizedBox(height: 14),
      ...List.generate(5, (i) {
        final week = i + 1;
        final list = words.where((w) => w.week == week).toList();
        final done = list.where((w) => learned.contains(w.english)).length;
        return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
          leading: CircleAvatar(backgroundColor: teal500.withValues(alpha: .14), child: Text(week.toString(), style: const TextStyle(color: teal500, fontWeight: FontWeight.w900))),
          title: Text('Ҳафтаи ' + week.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(done.toString() + ' аз ' + list.length.toString()),
          trailing: SizedBox(width: 70, child: LinearProgressIndicator(value: list.isEmpty ? 0 : done / list.length, color: emerald500)),
        ));
      }),
    ]);
  }
}

class SettingsPage extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final Future<void> Function(String) speak;
  const SettingsPage({super.key, required this.settings, required this.onChanged, required this.speak});

  AppSettings copy({ThemeMode? themeMode, double? textScale, String? voiceGender, double? speechRate}) => AppSettings(
    themeMode: themeMode ?? settings.themeMode,
    textScale: textScale ?? settings.textScale,
    voiceGender: voiceGender ?? settings.voiceGender,
    speechRate: speechRate ?? settings.speechRate,
  );

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Танзимот')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
      const SizedBox(height: 8),
      section(context, Icons.palette_rounded, 'Намуди барнома', [
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('Auto')),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (v) => onChanged(copy(themeMode: v.first)),
        ),
      ]),
      section(context, Icons.text_fields_rounded, 'Андозаи матн', [
        Row(children: [
          const Text('A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Expanded(child: Slider(min: .85, max: 1.25, divisions: 8, value: settings.textScale,
            label: (settings.textScale * 100).round().toString() + '%',
            onChanged: (v) => onChanged(copy(textScale: v)))),
          const Text('A', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        ]),
        Center(child: Text((settings.textScale * 100).round().toString() + '% — пешнамоиши андоза')),
      ]),
      section(context, Icons.record_voice_over_rounded, 'Овози талаффуз', [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'female', icon: Icon(Icons.female), label: Text('Зан')),
            ButtonSegment(value: 'male', icon: Icon(Icons.male), label: Text('Мард')),
          ],
          selected: {settings.voiceGender},
          onSelectionChanged: (v) => onChanged(copy(voiceGender: v.first)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.speed_rounded, color: cyan500), const SizedBox(width: 8), const Text('Суръати овоз'),
          Expanded(child: Slider(min: .25, max: .65, value: settings.speechRate, onChanged: (v) => onChanged(copy(speechRate: v)))),
        ]),
        FilledButton.tonalIcon(onPressed: () => speak('Hello! Let us learn English together.'), icon: const Icon(Icons.volume_up_rounded), label: const Text('Санҷиши овоз')),
      ]),
      section(context, Icons.accessibility_new_rounded, 'Осонии истифода', [
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.phone_android_rounded, color: sky500), title: Text('Responsive layout', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Барои экранҳои гуногун мутобиқ мешавад.')),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.touch_app_rounded, color: teal500), title: Text('Ҳолатҳои тугмаҳо', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Selected, pressed, disabled ва loading бо feedback-и равшан.')),
      ]),
    ])),
  );

  Widget section(BuildContext context, IconData icon, String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: cyan500), const SizedBox(width: 9), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
      const SizedBox(height: 14), ...children,
    ]))),
  );
}

class ContactLine extends StatelessWidget {
  final IconData icon; final String text;
  const ContactLine(this.icon, this.text);
  @override Widget build(BuildContext context) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(icon, color: cyan500), title: Text(text));
}


class TimerSheet extends StatelessWidget {
  final Word word;
  const TimerSheet({super.key, required this.word});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [teal500, cyan500]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.alarm_rounded, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ёдрас барои калима', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(word.english, style: const TextStyle(color: cyan500, fontWeight: FontWeight.w800)),
        ])),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _choice(context, 30, '30 сония', true)), const SizedBox(width: 8),
        Expanded(child: _choice(context, 1, '1 дақиқа')), const SizedBox(width: 8),
        Expanded(child: _choice(context, 5, '5 дақ.')),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _choice(context, 15, '15 дақ.')), const SizedBox(width: 8),
        Expanded(child: _choice(context, 30, '30 дақ.')), const SizedBox(width: 8),
        Expanded(child: _choice(context, 60, '1 соат')),
      ]),
    ]),
  );
  Widget _choice(BuildContext context, int value, String label, [bool seconds = false]) => OutlinedButton.icon(
    onPressed: () => Navigator.pop(context, seconds ? Duration(seconds: value) : Duration(minutes: value)),
    icon: const Icon(Icons.schedule_rounded, size: 18),
    label: Text(label, textAlign: TextAlign.center),
  );
}

class QuizPage extends StatefulWidget {
  final List<Word> words;
  const QuizPage({super.key, required this.words});
  @override State<QuizPage> createState() => _QuizPageState();
}
class _QuizPageState extends State<QuizPage> {
  int index = 0, score = 0;
  bool answered = false;
  Word get current => widget.words[index % widget.words.length];
  List<String> choices() {
    final values = <String>{current.tajik};
    for (final w in widget.words) {
      if (values.length >= 4) break;
      values.add(w.tajik);
    }
    return values.toList()..shuffle();
  }
  @override Widget build(BuildContext context) {
    final options = choices();
    return Scaffold(
      appBar: AppBar(title: const Text('Мушкилоти имрӯз')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LinearProgressIndicator(value: (index + 1) / 5, minHeight: 8, borderRadius: BorderRadius.circular(99), color: cyan500),
        const SizedBox(height: 22),
        Text('Саволи ${index + 1} аз 5', style: const TextStyle(fontWeight: FontWeight.w800, color: cyan500)),
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          const Icon(Icons.translate_rounded, size: 42, color: teal500),
          const SizedBox(height: 10),
          Text(current.english, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          Text(current.pronunciation, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]))),
        const SizedBox(height: 14),
        ...options.map((choice) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: answered ? null : () => setState(() {
              answered = true;
              if (choice == current.tajik) score++;
            }),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(choice, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        )),
        const Spacer(),
        if (answered) FilledButton.icon(
          onPressed: () {
            if (index == 4) {
              showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Офарин! 🎉'),
                content: Text('Натиҷа: $score / 5'),
                actions: [TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Тамом'))],
              ));
            } else {
              setState(() { index++; answered = false; });
            }
          },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(index == 4 ? 'Натиҷа' : 'Саволи нав'),
        ),
      ]))),
    );
  }
}

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Таҳиягар')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 40), children: [
      Center(child: Container(
        width: 116, height: 116, padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [teal500, cyan500, sky500]), boxShadow: [BoxShadow(color: cyan500.withValues(alpha: .22), blurRadius: 24)]),
        child: CircleAvatar(backgroundImage: MemoryImage(base64Decode(_developerPhotoBase64))),
      )),
      const SizedBox(height: 14),
      const Center(child: Text('Majnun Zaynuddinov', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      const SizedBox(height: 4),
      const Center(child: Text('Таҳиягар ва созандаи барнома', style: TextStyle(color: cyan500, fontWeight: FontWeight.w800))),
      const SizedBox(height: 22),
      _contact(Icons.phone_rounded, '+992 98 537 36 35'),
      _contact(Icons.email_rounded, 'mzaynuddinov@gmail.com'),
      _contact(Icons.send_rounded, '@mzaynuddinov'),
      _contact(Icons.camera_alt_outlined, '@mzaynuddinov'),
      _contact(Icons.public_rounded, 'majnun.zaynuddinov'),
      _contact(Icons.play_circle_outline, '@mzaynuddinov'),
    ])),
  );
  Widget _contact(IconData icon, String text) => Card(margin: const EdgeInsets.only(bottom: 9), child: ListTile(leading: Icon(icon, color: cyan500), title: Text(text, style: const TextStyle(fontWeight: FontWeight.w800))));
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Дар бораи барнома')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 40), children: [
      const Center(child: AppLogo(size: 120)),
      const SizedBox(height: 14),
      const Center(child: Text(appName, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
      const SizedBox(height: 5),
      const Center(child: Text('Омӯзиши англисӣ барои кӯдакон', style: TextStyle(color: cyan500, fontWeight: FontWeight.w800))),
      const SizedBox(height: 24),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Имкониятҳо', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _feature(Icons.menu_book_rounded, '5 ҳафта ва 150 калима'),
        _feature(Icons.volume_up_rounded, 'Талаффузи англисӣ бо овози зан/мард'),
        _feature(Icons.bookmark_rounded, 'Захира барои баъд'),
        _feature(Icons.alarm_rounded, 'Ёдраскунии калима бо таймер'),
        _feature(Icons.extension_rounded, 'Мушкилоти кӯтоҳи ҳаррӯза'),
        _feature(Icons.dark_mode_rounded, 'Light / Dark / Auto'),
      ]))),
      const SizedBox(height: 14),
      const Center(child: Text('Offline • Барои кӯдакон • Тоҷикистон 🇹🇯', style: TextStyle(fontWeight: FontWeight.w800))),
      const SizedBox(height: 5),
      const Center(child: Text('Версия 1.0.0', style: TextStyle(color: slate700))),
    ])),
  );
  Widget _feature(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, color: cyan500), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)))]));
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String title, text;
  const EmptyState({super.key, required this.icon, required this.title, required this.text});
  @override Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Icon(icon, size: 52, color: cyan500),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(text, textAlign: TextAlign.center),
      ]),
    ),
  );
}

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, required this.size});
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .22),
    child: SvgPicture.asset('assets/logo.svg', width: size, height: size, fit: BoxFit.cover),
  );
}
