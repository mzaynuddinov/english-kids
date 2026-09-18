class AlphabetLetter {
  final String letter;
  final String ipa;
  final String word;
  final String tajik;
  final String emoji;
  final String wordIpa;

  const AlphabetLetter({
    required this.letter,
    required this.ipa,
    required this.word,
    required this.tajik,
    required this.emoji,
    required this.wordIpa,
  });

  String get id => letter;
}

const alphabetLetters = <AlphabetLetter>[
  AlphabetLetter(letter: 'A', ipa: '/eɪ/', word: 'Apple', tajik: 'Себ', emoji: '🍎', wordIpa: '/ˈæpəl/'),
  AlphabetLetter(letter: 'B', ipa: '/biː/', word: 'Ball', tajik: 'Тӯб', emoji: '⚽', wordIpa: '/bɔːl/'),
  AlphabetLetter(letter: 'C', ipa: '/siː/', word: 'Cat', tajik: 'Гурба', emoji: '🐱', wordIpa: '/kæt/'),
  AlphabetLetter(letter: 'D', ipa: '/diː/', word: 'Dog', tajik: 'Саг', emoji: '🐶', wordIpa: '/dɒɡ/'),
  AlphabetLetter(letter: 'E', ipa: '/iː/', word: 'Egg', tajik: 'Тухм', emoji: '🥚', wordIpa: '/eɡ/'),
  AlphabetLetter(letter: 'F', ipa: '/ef/', word: 'Fish', tajik: 'Моҳӣ', emoji: '🐟', wordIpa: '/fɪʃ/'),
  AlphabetLetter(letter: 'G', ipa: '/dʒiː/', word: 'Goat', tajik: 'Буз', emoji: '🐐', wordIpa: '/ɡəʊt/'),
  AlphabetLetter(letter: 'H', ipa: '/eɪtʃ/', word: 'Hat', tajik: 'Кулоҳ', emoji: '🎩', wordIpa: '/hæt/'),
  AlphabetLetter(letter: 'I', ipa: '/aɪ/', word: 'Ice', tajik: 'Ях', emoji: '🧊', wordIpa: '/aɪs/'),
  AlphabetLetter(letter: 'J', ipa: '/dʒeɪ/', word: 'Juice', tajik: 'Шарбат', emoji: '🧃', wordIpa: '/dʒuːs/'),
  AlphabetLetter(letter: 'K', ipa: '/keɪ/', word: 'Kite', tajik: 'Коғазпар', emoji: '🪁', wordIpa: '/kaɪt/'),
  AlphabetLetter(letter: 'L', ipa: '/el/', word: 'Lion', tajik: 'Шер', emoji: '🦁', wordIpa: '/ˈlaɪən/'),
  AlphabetLetter(letter: 'M', ipa: '/em/', word: 'Moon', tajik: 'Моҳ', emoji: '🌙', wordIpa: '/muːn/'),
  AlphabetLetter(letter: 'N', ipa: '/en/', word: 'Nest', tajik: 'Лона', emoji: '🪺', wordIpa: '/nest/'),
  AlphabetLetter(letter: 'O', ipa: '/oʊ/', word: 'Orange', tajik: 'Апельсин', emoji: '🍊', wordIpa: '/ˈɒrɪndʒ/'),
  AlphabetLetter(letter: 'P', ipa: '/piː/', word: 'Pen', tajik: 'Қалам', emoji: '🖊️', wordIpa: '/pen/'),
  AlphabetLetter(letter: 'Q', ipa: '/kjuː/', word: 'Queen', tajik: 'Малика', emoji: '👑', wordIpa: '/kwiːn/'),
  AlphabetLetter(letter: 'R', ipa: '/ɑːr/', word: 'Rain', tajik: 'Борон', emoji: '🌧️', wordIpa: '/reɪn/'),
  AlphabetLetter(letter: 'S', ipa: '/es/', word: 'Sun', tajik: 'Офтоб', emoji: '☀️', wordIpa: '/sʌn/'),
  AlphabetLetter(letter: 'T', ipa: '/tiː/', word: 'Tree', tajik: 'Дарахт', emoji: '🌳', wordIpa: '/triː/'),
  AlphabetLetter(letter: 'U', ipa: '/juː/', word: 'Umbrella', tajik: 'Чатр', emoji: '☂️', wordIpa: '/ʌmˈbrelə/'),
  AlphabetLetter(letter: 'V', ipa: '/viː/', word: 'Van', tajik: 'Мошин', emoji: '🚐', wordIpa: '/væn/'),
  AlphabetLetter(letter: 'W', ipa: '/ˈdʌbəljuː/', word: 'Water', tajik: 'Об', emoji: '💧', wordIpa: '/ˈwɔːtə/'),
  AlphabetLetter(letter: 'X', ipa: '/eks/', word: 'X-ray', tajik: 'Рентген', emoji: '🦴', wordIpa: '/ˈeksreɪ/'),
  AlphabetLetter(letter: 'Y', ipa: '/waɪ/', word: 'Yellow', tajik: 'Зард', emoji: '💛', wordIpa: '/ˈjeləʊ/'),
  AlphabetLetter(letter: 'Z', ipa: '/zed/', word: 'Zebra', tajik: 'Зебра', emoji: '🦓', wordIpa: '/ˈzebrə/'),
];
