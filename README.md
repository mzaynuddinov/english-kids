# Англисиро Омӯз

**Англисиро Омӯз** — барномаи офлайнӣ барои кӯдакони тоҷик, ки калимаҳои англисиро бо талаффуз, маъно, такрор ва бозии кӯтоҳ меомӯзонад.

Версия: **1.1.0+11**

## Мақсад

Кӯдак дар 5 ҳафта 150 калимаи англисиро меомӯзад: гӯш мекунад, захира мекунад, «омӯхтам» мезанад ва бо ёдрас такрор мекунад.

## Имкониятҳо

- Луғати офлайнӣ (`data/vocabulary.json`) бо калимаи англисӣ, талаффуз ва маънои тоҷикӣ
- Нақшаи 5-ҳафтаинаи омӯзиш
- Гӯш кардани калима бо TTS
- Интихоби овози зан / мард (агар дастгоҳ чунин овоз дошта бошад)
- «Барои баъд» ва «Омӯхтам» бо нигоҳдории ҳолат
- Ёдраси калима: 30 сония, 1 / 5 / 15 / 30 дақиқа, 1 соат
- Огоҳии Android бо калима ва маъно
- Пешрафти умумӣ ва ҳафтаина
- «Мушкилоти имрӯз» — 5 саволи кӯтоҳ
- Light / Dark / Auto ва андозаи матн 85%–125%
- Саҳифаҳои алоҳида: Танзимот, Таҳиягар, Дар бораи барнома
- Тарҳи мутобиқ ба экранҳои хурд ва калон

## Чаро экрани сиёҳ ислоҳ шуд

APK-и қаблӣ сохта мешуд, вале дар телефон экрани сиёҳ мемонд. Сабабҳои асосӣ:

1. **Хатои MediaQuery дар `MaterialApp.builder`** — `MediaQuery.of(context)` аз виҷети болои `MaterialApp` гирифта мешуд. Дар он ҷо MediaQuery нест. Дар реҷаи release Flutter ErrorWidget-и холӣ нишон медиҳад → экрани сиёҳ.
2. **Оғози барнома баста мешуд** — пеш аз `runApp()` TTS не, вале `flutter_local_notifications` ва `AndroidAlarmManager.initialize()` интизорӣ мешуданд. Агар плагин ё иҷозат хато кунад, UI ҳеҷ гоҳ намеояд.
3. **ErrorWidget дар release холӣ аст** — ҳар хатои build экрани сиёҳ мемонд.

Ҳоло:

- аввал UI кушода мешавад;
- хидматҳои ихтиёрӣ баъд аз кадри аввал бо `try/catch` оғоз меёбанд;
- агар TTS, огоҳӣ ё ёдрас кор накунад, саҳифаи асосӣ ҳамоно кушода мемонад;
- логотип PNG-и аслии муштарӣ аст, на SVG-и ноустувор.

## Меъморӣ

- `lib/main.dart` — оғози бехатар ва error handling
- `lib/app.dart` — `MaterialApp`, мавзӯъ, андозаи матн
- `lib/pages/` — саҳифаҳо
- `lib/services/tts_service.dart` — TTS-и танбал (lazy) бо интихоби овози англисӣ
- `lib/services/reminder_service.dart` — ёдрасҳо тавассути `flutter_local_notifications`
- `lib/services/vocabulary_service.dart` — боркунии муҳофизавии луғат
- `lib/services/preferences_service.dart` — SharedPreferences бо fallback
- `data/vocabulary.json` — 150 калима
- `assets/logo.png` — логотипи аслӣ
- `assets/developer.png` — акси таҳиягар
- `tool/configure_android.py` — танзими такроршавандаи Android барои CI

Плагини `android_alarm_manager_plus` хориҷ карда шуд: он оғозро ноустувор мекард. Ёдрасҳо ҳоло бо notification-и банақшагирифташуда кор мекунанд.

## TTS

Овоз **пеш аз кадри аввал** оғоз намеёбад.

Тартиби интихоб:

1. Овозҳои locale-и англисӣ
2. Ҷинси дархостшуда, агар metadata ё ном онро нишон диҳад
3. Агар набошад — дигар овози англисӣ
4. Ҳеҷ гоҳ барнома намеафтад

Овозҳои Samantha / Daniel / Alex ҳатмӣ нестанд. Агар овози мардона дар дастгоҳ набошад, паём нишон дода мешавад ва овози англисии дастрас истифода мешавад.

## Ёдрасҳо ва огоҳӣ

Аз корти калима тугмаи **⏰ Ёдраси калима** (на тақвим)-ро пахш кунед.

Дар вақти муайян:

- огоҳии Android бо калима ва маъно меояд;
- агар кӯдак огоҳиро пахш кунад, барнома калимаро хонданӣ мешавад.

Маҳдудиятҳои Android:

- Android 13+ иҷозати Notification мехоҳад
- ёдрасҳои дақиқ иҷозати Exact Alarm мехоҳанд
- баъзе истеҳсолкунандагон TTS-ро дар пасзамина манъ мекунанд
- батарея / battery optimization метавонад ёдрасро дер кунад

Агар TTS дар пасзамина кор накунад, **огоҳӣ ҳамоно нишон дода мешавад**.

## Номи барнома

Номи намоён ҳамеша:

**Англисиро Омӯз**

«English Kids» ҳамчун номи барнома истифода намешавад. Идентификатори техникии баста `english_kids` аст.

## Сохтани APK

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

GitHub Actions ҳангоми push ба `main`:

1. Checkout
2. Java 17 ва Flutter
3. `flutter create --platforms=android`
4. `tool/configure_android.py` (иҷозатҳо, ном, desugaring, Impeller off)
5. `flutter pub get`
6. launcher icon ва splash
7. `flutter analyze`
8. `flutter test`
9. `flutter build apk --release`
10. боргузории artifact

Танҳо як workflow. Concurrency дорад, build-ҳои ҳамзамон бекор карда мешаванд.

## Таҳиягар

**Majnun Zaynuddinov**

- Телефон: +992 98 537 36 35
- Почта: mzaynuddinov@gmail.com
- Telegram: [@mzaynuddinov](https://t.me/mzaynuddinov)
- Instagram: [@mzaynuddinov](https://instagram.com/mzaynuddinov)
- Facebook: [majnun.zaynuddinov](https://facebook.com/majnun.zaynuddinov)
- YouTube: [@mzaynuddinov](https://youtube.com/@mzaynuddinov)

## Тағйироти 1.1.0

- Ислоҳи экрани сиёҳ ҳангоми кушодани APK
- Оғози бехатар: UI аввал, хидматҳо баъд
- Ёдрасҳо бе `android_alarm_manager_plus`
- Логотип ва акси таҳиягари аслӣ
- TTS ва notification дигар оғозро намебанданд
- Саҳифаи хатогии дӯстона барои кӯдакон

© Majnun Zaynuddinov
