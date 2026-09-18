import 'dart:async';
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
    required int repeats,
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

      final snap = ProgressService.instance.snapshot;
      for (final existing in snap.reminders.where((r) => r.wordId == word.id)) {
        _cancelTimers(existing.id);
        await _cancelNotes(existing.notificationIds);
      }

      final count = repeats.clamp(1, 10);
      final now = DateTime.now().millisecondsSinceEpoch;
      final base = now.remainder(100000000);
      final ids = [for (var i = 1; i <= count; i++) base + i];
      final reminder = WordReminder(
        id: 'r-$base',
        wordId: word.id,
        english: word.english,
        tajik: word.tajik,
        pronunciation: word.pronunciation,
        intervalMs: delay.inMilliseconds,
        repeatTotal: count,
        nextAt: now + delay.inMilliseconds,
        createdAt: now,
        notificationIds: ids,
      );

      for (var i = 0; i < count; i++) {
        final when = tz.TZDateTime.now(tz.UTC).add(delay * (i + 1));
        await _scheduleOne(
          id: ids[i],
          when: when,
          reminder: reminder,
          step: i + 1,
          gender: gender,
          rate: rate,
        );
      }
      _armForeground(reminder, gender, rate);

      final next = [...snap.reminders.where((r) => r.wordId != word.id && !r.finished), reminder];
      await ProgressService.instance.save(snap.copyWith(reminders: next));
      return 'Ёдрас барои «${word.displayEnglish}» гузошта шуд: $count маротиба';
    } catch (error, stack) {
      debugPrint('Schedule failed: $error\n$stack');
      return 'Ёдрас гузошта нашуд. Иҷозаи Alarm/Notification-ро санҷед.';
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required tz.TZDateTime when,
    required WordReminder reminder,
    required int step,
    required String gender,
    required double rate,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          '${_cap(reminder.english)} — ${reminder.tajik}\nТакрор: $step / ${reminder.repeatTotal}',
          contentTitle: 'Вақти омӯзиш! 🔊',
        ),
      ),
    );
    final payload = jsonEncode({
      'id': reminder.id,
      'word': reminder.english,
      'tajik': reminder.tajik,
      'gender': gender,
      'rate': rate,
      'step': step,
      'total': reminder.repeatTotal,
    });

    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id,
        'Вақти омӯзиш! 🔊',
        '${_cap(reminder.english)} — ${reminder.tajik}',
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
  }

  void _armForeground(WordReminder reminder, String gender, double rate) {
    _cancelTimers(reminder.id);
    final remaining = reminder.repeatTotal - reminder.completed;
    if (remaining <= 0) return;
    final timers = <Timer>[];
    for (var i = 0; i < remaining; i++) {
      final step = reminder.completed + i + 1;
      final delay = Duration(milliseconds: reminder.intervalMs * (i + 1));
      timers.add(Timer(delay, () => unawaited(_fire(reminder.id, step, gender, rate))));
    }
    _timers[reminder.id] = timers;
  }

  void rearmActive(String gender, double rate) {
    for (final reminder in ProgressService.instance.snapshot.reminders) {
      if (reminder.paused || reminder.finished) continue;
      _armForeground(reminder, gender, rate);
    }
  }

  Future<void> _fire(String id, int step, String gender, double rate) async {
    try {
      var snap = ProgressService.instance.snapshot;
      final current = snap.reminders.where((r) => r.id == id);
      if (current.isEmpty) return;
      var reminder = current.first;
      if (reminder.paused || reminder.finished) return;
      final done = step.clamp(0, reminder.repeatTotal);
      reminder = reminder.copyWith(
        completed: done,
        nextAt: done >= reminder.repeatTotal
            ? reminder.nextAt
            : DateTime.now().millisecondsSinceEpoch + reminder.intervalMs,
        finished: done >= reminder.repeatTotal,
      );
      final list = snap.reminders.map((r) => r.id == id ? reminder : r).toList();
      await ProgressService.instance.save(snap.copyWith(reminders: list));
      try {
        await TtsService.instance.speak(text: reminder.english, gender: gender, rate: rate);
      } catch (error) {
        debugPrint('Foreground TTS skipped: $error');
      }
      onForegroundFire?.call(reminder);
    } catch (error, stack) {
      debugPrint('Reminder fire failed: $error\n$stack');
    }
  }

  Future<void> pause(String id) async {
    _cancelTimers(id);
    final snap = ProgressService.instance.snapshot;
    final list = snap.reminders.map((r) {
      if (r.id != id) return r;
      unawaited(_cancelNotes(r.notificationIds));
      return r.copyWith(paused: true);
    }).toList();
    await ProgressService.instance.save(snap.copyWith(reminders: list));
  }

  Future<void> resume(String id, String gender, double rate) async {
    final snap = ProgressService.instance.snapshot;
    final found = snap.reminders.where((r) => r.id == id);
    if (found.isEmpty) return;
    var reminder = found.first.copyWith(paused: false);
    final remaining = reminder.repeatTotal - reminder.completed;
    if (remaining <= 0) {
      reminder = reminder.copyWith(finished: true);
      await ProgressService.instance.save(
        snap.copyWith(reminders: snap.reminders.map((r) => r.id == id ? reminder : r).toList()),
      );
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = now.remainder(100000000);
    final ids = [for (var i = 1; i <= remaining; i++) base + i];
    reminder = reminder.copyWith(nextAt: now + reminder.intervalMs, notificationIds: ids);
    await ProgressService.instance.save(
      snap.copyWith(reminders: snap.reminders.map((r) => r.id == id ? reminder : r).toList()),
    );
    try {
      await initialize();
      if (ready && timezoneReady) {
        for (var i = 0; i < remaining; i++) {
          final when = tz.TZDateTime.now(tz.UTC).add(Duration(milliseconds: reminder.intervalMs * (i + 1)));
          await _scheduleOne(
            id: ids[i],
            when: when,
            reminder: reminder,
            step: reminder.completed + i + 1,
            gender: gender,
            rate: rate,
          );
        }
      }
    } catch (error) {
      debugPrint('Resume schedule skipped: $error');
    }
    _armForeground(reminder, gender, rate);
  }

  Future<void> delete(String id) async {
    _cancelTimers(id);
    final snap = ProgressService.instance.snapshot;
    final target = snap.reminders.where((r) => r.id == id);
    if (target.isNotEmpty) await _cancelNotes(target.first.notificationIds);
    await ProgressService.instance.save(
      snap.copyWith(reminders: snap.reminders.where((r) => r.id != id).toList()),
    );
  }

  Future<void> _cancelNotes(List<int> ids) async {
    for (final id in ids) {
      try {
        await _plugin.cancel(id);
      } catch (_) {}
    }
  }

  void _cancelTimers(String id) {
    final list = _timers.remove(id);
    if (list == null) return;
    for (final t in list) {
      t.cancel();
    }
  }

  String _cap(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }
}
