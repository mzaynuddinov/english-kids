import 'dart:async';

import 'package:flutter/widgets.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import '../models/word.dart';
import 'progress_service.dart';
import 'tts_service.dart';

typedef ReminderCallback = void Function(WordReminder reminder);

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Map<String, List<Timer>> _timers = {};
  bool ready = false;
  bool timezoneReady = false;
  String? lastError;
  ReminderCallback? onForegroundFire;

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

  // ... rest of methods with test guards and cancelAllTimers ...
}