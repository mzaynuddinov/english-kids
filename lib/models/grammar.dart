class GrammarExample {
  final String english;
  final String tajik;
  const GrammarExample(this.english, this.tajik);
}

class GrammarQuiz {
  final String prompt;
  final String expected;
  final List<String> options;
  const GrammarQuiz({required this.prompt, required this.expected, required this.options});
}

class GrammarLesson {
  final String id;
  final String title;
  final String tajik;
  final String explain;
  final List<GrammarExample> examples;
  final List<GrammarQuiz> quiz;

  const GrammarLesson({
    required this.id,
    required this.title,
    required this.tajik,
    required this.explain,
    required this.examples,
    required this.quiz,
  });
}

const grammarLessons = <GrammarLesson>[
  GrammarLesson(
    id: 'i_am',
    title: 'I am',
    tajik: 'Ман ҳастам',
    explain: '«I am» мегӯяд, ки ту кӣ ҳастӣ ё чӣ ҳол дорӣ.',
    examples: [
      GrammarExample('I am a student.', 'Ман хонанда ҳастам.'),
      GrammarExample('I am happy.', 'Ман хушҳол ҳастам.'),
      GrammarExample('I am seven.', 'Ман ҳафтсола ҳастам.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ман хушҳол ҳастам.', expected: 'I am happy.', options: ['I am happy.', 'You are happy.', 'He is happy.']),
    ],
  ),
  GrammarLesson(
    id: 'you_are',
    title: 'You are',
    tajik: 'Ту ҳастӣ',
    explain: '«You are» ба дӯстат мегӯяд, ки ӯ чӣ гуна аст.',
    examples: [
      GrammarExample('You are kind.', 'Ту меҳрубон ҳастӣ.'),
      GrammarExample('You are my friend.', 'Ту дӯсти ман ҳастӣ.'),
      GrammarExample('You are ready.', 'Ту тайёр ҳастӣ.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ту меҳрубон ҳастӣ.', expected: 'You are kind.', options: ['I am kind.', 'You are kind.', 'She is kind.']),
    ],
  ),
  GrammarLesson(
    id: 'he_is',
    title: 'He is',
    tajik: 'Ӯ (писар) аст',
    explain: '«He is» барои писар ё мард аст.',
    examples: [
      GrammarExample('He is a boy.', 'Ӯ писар аст.'),
      GrammarExample('He is brave.', 'Ӯ шуҷоъ аст.'),
      GrammarExample('He is my brother.', 'Ӯ бародари ман аст.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ӯ писар аст.', expected: 'He is a boy.', options: ['She is a boy.', 'He is a boy.', 'I am a boy.']),
    ],
  ),
  GrammarLesson(
    id: 'she_is',
    title: 'She is',
    tajik: 'Ӯ (духтар) аст',
    explain: '«She is» барои духтар ё зан аст.',
    examples: [
      GrammarExample('She is a girl.', 'Ӯ духтар аст.'),
      GrammarExample('She is kind.', 'Ӯ меҳрубон аст.'),
      GrammarExample('She is my sister.', 'Ӯ хоҳари ман аст.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ӯ духтар аст.', expected: 'She is a girl.', options: ['He is a girl.', 'She is a girl.', 'You are a girl.']),
    ],
  ),
  GrammarLesson(
    id: 'it_is',
    title: 'It is',
    tajik: 'Ин аст',
    explain: '«It is» барои чизҳо, ҳайвонот ва ҳаво аст.',
    examples: [
      GrammarExample('It is a cat.', 'Ин гурба аст.'),
      GrammarExample('It is hot.', 'Ҳаво гарм аст.'),
      GrammarExample('It is my book.', 'Ин китоби ман аст.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ин гурба аст.', expected: 'It is a cat.', options: ['He is a cat.', 'It is a cat.', 'She is a cat.']),
    ],
  ),
  GrammarLesson(
    id: 'this_is',
    title: 'This is',
    tajik: 'Ин (наздик) аст',
    explain: '«This is» барои чизи наздик аст.',
    examples: [
      GrammarExample('This is an apple.', 'Ин себ аст.'),
      GrammarExample('This is my bag.', 'Ин сумкаи ман аст.'),
      GrammarExample('This is a pencil.', 'Ин қалам аст.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ин себ аст.', expected: 'This is an apple.', options: ['These are apples.', 'This is an apple.', 'That is a bag.']),
    ],
  ),
  GrammarLesson(
    id: 'these_are',
    title: 'These are',
    tajik: 'Инҳо ҳастанд',
    explain: '«These are» барои якчанд чизи наздик аст.',
    examples: [
      GrammarExample('These are books.', 'Инҳо китобҳоянд.'),
      GrammarExample('These are my toys.', 'Инҳо бозичаҳои мананд.'),
      GrammarExample('These are red apples.', 'Инҳо себҳои сурханд.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Инҳо китобҳоянд.', expected: 'These are books.', options: ['This is a book.', 'These are books.', 'It is a book.']),
    ],
  ),
  GrammarLesson(
    id: 'i_have',
    title: 'I have',
    tajik: 'Ман дорам',
    explain: '«I have» мегӯяд, ки ту чӣ дорӣ.',
    examples: [
      GrammarExample('I have a cat.', 'Ман гурба дорам.'),
      GrammarExample('I have two hands.', 'Ман ду даст дорам.'),
      GrammarExample('I have a red bag.', 'Ман сумкаи сурх дорам.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ман гурба дорам.', expected: 'I have a cat.', options: ['I am a cat.', 'I have a cat.', 'I like a cat.']),
    ],
  ),
  GrammarLesson(
    id: 'i_like',
    title: 'I like',
    tajik: 'Ба ман маъқул аст',
    explain: '«I like» мегӯяд, ки ту чӣ дӯст медорӣ.',
    examples: [
      GrammarExample('I like milk.', 'Ба ман шир маъқул аст.'),
      GrammarExample('I like my teacher.', 'Ба ман муаллимам маъқул аст.'),
      GrammarExample('I like to play.', 'Ба ман бозӣ кардан маъқул аст.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ба ман шир маъқул аст.', expected: 'I like milk.', options: ['I have milk.', 'I like milk.', 'I am milk.']),
    ],
  ),
  GrammarLesson(
    id: 'present',
    title: 'I play / I eat',
    tajik: 'Ҳозираи содда',
    explain: 'Барои кори ҳаррӯза: I + феъл. Барои he/she: феъл + s.',
    examples: [
      GrammarExample('I play every day.', 'Ман ҳар рӯз бозӣ мекунам.'),
      GrammarExample('She eats an apple.', 'Ӯ себ мехӯрад.'),
      GrammarExample('We go to school.', 'Мо ба мактаб меравем.'),
    ],
    quiz: [
      GrammarQuiz(prompt: 'Ман ҳар рӯз бозӣ мекунам.', expected: 'I play every day.', options: ['I am play.', 'I play every day.', 'She play every day.']),
    ],
  ),
];
