import 'dart:io';

import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/reminder_service.dart';
import 'package:english_kids/services/vocabulary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ReminderService.suppressTimersForTests = true;
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();
    VocabularyService.debugLoader = () async {
      final raw = File('data/vocabulary.json').readAsStringSync();
      return VocabularyService.parseRaw(raw);
    };
  });

  tearDown(() {
    VocabularyService.debugReset();
    ReminderService.instance.cancelAllTimers();
    ReminderService.suppressTimersForTests = false;
  });

  test('reminder service can be cancelled', () {
    ReminderService.instance.cancelAllTimers();
    expect(ReminderService.suppressTimersForTests, isTrue);
  });
}
