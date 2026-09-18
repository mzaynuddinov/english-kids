import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const EnglishKidsApp());

class Word {
  final String english, pronunciation, tajik, topic;
  final int week;
  const Word(this.english, this.pronunciation, this.tajik, this.week, this.topic);
  factory Word.fromList(List<dynamic> x) =>
      Word(x[0] as String, x[1] as String, x[2] as String, x[3] as int, x[4] as String);
}

class EnglishKidsApp extends StatelessWidget {
  const EnglishKidsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'English Kids',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B5FEF)),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Word> words = [];
  Set<String> learned = {};
  final FlutterTts tts = FlutterTts();

  final weekNames = const {
    1: 'Салом ва ҳиссиёт',
    2: 'Рақамҳо ва рангҳо',
    3: 'Оила ва бадани инсон',
    4: 'Ҳайвонот ва грамматика',
    5: 'Хӯрок, нӯшокиҳо ва феълҳо',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('data/vocabulary.json');
    final prefs = await SharedPreferences.getInstance();
    final data = (jsonDecode(raw) as List).map((e) => Word.fromList(e)).toList();
    setState(() {
      words = data;
      learned = prefs.getStringList('learned')?.toSet() ?? {};
    });
  }

  Future<void> _speak(String text) async {
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  Future<void> _openWeek(int week) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => WeekPage(
        week: week,
        title: weekNames[week]!,
        words: words.where((w) => w.week == week).toList(),
        learned: learned,
        speak: _speak,
      ),
    ));
    final prefs = await SharedPreferences.getInstance();
    setState(() => learned = prefs.getStringList('learned')?.toSet() ?? learned);
  }

  @override
  Widget build(BuildContext context) {
    final progress = words.isEmpty ? 0.0 : learned.length / words.length;
    return Scaffold(
      body: SafeArea(
        child: words.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('🌟 English Kids', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Англисӣ барои кӯдакони 8–10 сола'),
                  const SizedBox(height: 18),
                  Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Пешрафти шумо', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Text(learned.length.toString() + ' аз 150 калима омӯхта шуд'),
                    ],
                  ))),
                ]),
              )),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.builder(
                  itemCount: 5,
                  itemBuilder: (_, i) {
                    final week = i + 1;
                    final weekWords = words.where((w) => w.week == week).toList();
                    final done = weekWords.where((w) => learned.contains(w.english)).length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        leading: CircleAvatar(child: Text(week.toString())),
                        title: Text(weekNames[week]!, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(done.toString() + ' / ' + weekWords.length.toString() + ' калима'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                        onTap: () => _openWeek(week),
                      ),
                    );
                  },
                ),
              ),
            ]),
      ),
    );
  }
}

class WeekPage extends StatefulWidget {
  final int week;
  final String title;
  final List<Word> words;
  final Set<String> learned;
  final Future<void> Function(String) speak;
  const WeekPage({super.key, required this.week, required this.title, required this.words, required this.learned, required this.speak});
  @override State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  Future<void> _markLearned(Word word) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('learned')?.toSet() ?? {};
    current.add(word.english);
    await prefs.setStringList('learned', current.toList());
    setState(() => widget.learned.add(word.english));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Ҳафтаи ' + widget.week.toString())),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(widget.words.length.toString() + ' калима'),
        const SizedBox(height: 14),
        ...widget.words.map((word) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(word.english, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                IconButton(
                  tooltip: 'Гӯш кардан',
                  onPressed: () => widget.speak(word.english),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ]),
              Text(word.pronunciation, style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 5),
              Text(word.tajik, style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _markLearned(word),
                  icon: Icon(widget.learned.contains(word.english) ? Icons.check : Icons.school),
                  label: Text(widget.learned.contains(word.english) ? 'Омӯхта шуд' : 'Омӯхтам'),
                ),
              ),
            ]),
          ),
        )),
      ],
    ),
  );
}
