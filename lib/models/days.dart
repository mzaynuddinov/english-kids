class WeekDay {
  final String id;
  final String english;
  final String tajik;

  const WeekDay({required this.id, required this.english, required this.tajik});
}

const weekDays = <WeekDay>[
  WeekDay(id: 'day:monday', english: 'Monday', tajik: 'Душанбе'),
  WeekDay(id: 'day:tuesday', english: 'Tuesday', tajik: 'Сешанбе'),
  WeekDay(id: 'day:wednesday', english: 'Wednesday', tajik: 'Чоршанбе'),
  WeekDay(id: 'day:thursday', english: 'Thursday', tajik: 'Панҷшанбе'),
  WeekDay(id: 'day:friday', english: 'Friday', tajik: 'Ҷумъа'),
  WeekDay(id: 'day:saturday', english: 'Saturday', tajik: 'Шанбе'),
  WeekDay(id: 'day:sunday', english: 'Sunday', tajik: 'Якшанбе'),
];

String letterLearningId(String letter) => 'letter:$letter';
