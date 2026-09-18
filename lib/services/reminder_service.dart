import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/word.dart';
import 'tts_service.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  bool timezoneReady = false;
  String? lastError;

  static const _channelId = 'word_review';
  static const _channelName = 'Такрори калимаҳо';
  static const _channelDescription = 'Ёдраскуниҳои калимаҳои англисӣ';

  Future<void> initialize() async {
    if (ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);
      timezoneReady = true;
    } catch (error, stack) {
      debugPrint('Timezone init failed: $error\n$stack');
      timezoneReady = false;
    }

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: handleNotificationResponse,
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      ready = true;
      lastError = null;
    } catch (error, stack) {
      ready = false;
      lastError = error.toString();
      debugPrint('Notification init failed: $error\n$stack');
    }
  }

  static Future<void> handleNotificationResponse(NotificationResponse response) async {
    try {
      final raw = response.payload;
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw);
      if (data is! Map) return;
      final word = '${data['word'] ?? ''}';
      if (word.isEmpty) return;
      await TtsService.instance.speak(
        text: word,
        gender: '${data['gender'] ?? 'female'}',
        rate: (data['rate'] is num) ? (data['rate'] as num).toDouble() : 0.42,
      );
    } catch (error, stack) {
      debugPrint('Notification tap TTS failed: $error\n$stack');
    }
  }

  Future<String> scheduleWord({
    required Word word,
    required Duration delay,
    required String gender,
    required double rate,
  }) async {
    await initialize();
    if (!ready) {
      return 'Ёдрас ҳоло дастрас нест. Барномаро аз нав кушоед ё иҷозати огоҳиро фаъол кунед.';
    }
    if (!timezoneReady) {
      return 'Ёдрас гузошта нашуд. Вақтбандии дастгоҳ дастрас нест.';
    }

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final allowed = await android?.requestNotificationsPermission();
      if (allowed == false) {
        return 'Барои ёдрас иҷозаи огоҳӣ лозим аст. Онро дар танзимоти телефон фаъол кунед.';
      }
      try {
        await android?.requestExactAlarmsPermission();
      } catch (error) {
        debugPrint('Exact alarm permission skipped: $error');
      }

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
      final when = tz.TZDateTime.now(tz.UTC).add(delay);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          icon: '@mipmap/ic_launcher',
        ),
      );
      final payload = jsonEncode({
        'word': word.english,
        'tajik': word.tajik,
        'gender': gender,
        'rate': rate,
      });

      Future<void> schedule(AndroidScheduleMode mode) {
        return _plugin.zonedSchedule(
          id,
          'Вақти такрори калима 📚',
          '${word.displayEnglish} — ${word.tajik}',
          when,
          details,
          androidScheduleMode: mode,
          payload: payload,
        );
      }

      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (error) {
        debugPrint('Exact alarm failed, falling back: $error');
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
      return 'Ёдрас барои «${word.displayEnglish}» гузошта шуд ⏰';
    } catch (error, stack) {
      debugPrint('Schedule failed: $error\n$stack');
      return 'Ёдрас гузошта нашуд. Иҷозаи Alarm/Notification-ро санҷед.';
    }
  }
}
