import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  SharedPreferences? _prefs;
  bool _ready = false;
  Future<void>? _initFuture;

  final Map<String, Object> _memory = {};

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    if (_ready) return;
    try {
      _prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 4),
      );
    } catch (error, stack) {
      debugPrint('SharedPreferences unavailable: $error\n$stack');
      _prefs = null;
    }
    _ready = true;
  }

  Future<AppSettings> loadSettings() async {
    await init();
    try {
      return AppSettings(
        themeMode: AppSettings.themeModeFromIndex(_readInt('themeMode')),
        textScale: AppSettings.scaleFrom(_readDouble('textScale')),
        voiceGender: AppSettings.genderFrom(_readString('voiceGender')),
        speechRate: AppSettings.rateFrom(_readDouble('speechRate')),
      );
    } catch (error, stack) {
      debugPrint('Corrupt settings, using defaults: $error\n$stack');
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await init();
    await _writeInt('themeMode', settings.themeMode.index);
    await _writeDouble('textScale', settings.textScale);
    await _writeString('voiceGender', settings.voiceGender);
    await _writeDouble('speechRate', settings.speechRate);
  }

  Future<Set<String>> loadSet(String key) async {
    await init();
    try {
      final list = _prefs?.getStringList(key) ?? (_memory[key] as List<String>?);
      return {...?list};
    } catch (error, stack) {
      debugPrint('Corrupt set $key: $error\n$stack');
      return <String>{};
    }
  }

  Future<void> saveSet(String key, Set<String> values) async {
    await init();
    final list = values.toList();
    _memory[key] = list;
    try {
      await _prefs?.setStringList(key, list);
    } catch (error, stack) {
      debugPrint('Failed to persist $key: $error\n$stack');
    }
  }

  Future<String?> loadRaw(String key) async {
    await init();
    try {
      return _prefs?.getString(key) ?? _memory[key] as String?;
    } catch (error, stack) {
      debugPrint('Corrupt raw $key: $error\n$stack');
      return null;
    }
  }

  Future<void> saveRaw(String key, String value) async {
    await init();
    _memory[key] = value;
    try {
      await _prefs?.setString(key, value);
    } catch (error) {
      debugPrint('writeRaw $key failed: $error');
    }
  }

  int? _readInt(String key) {
    try {
      return _prefs?.getInt(key);
    } catch (_) {
      return null;
    }
  }

  double? _readDouble(String key) {
    try {
      return _prefs?.getDouble(key);
    } catch (_) {
      return null;
    }
  }

  String? _readString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeInt(String key, int value) async {
    _memory[key] = value;
    try {
      await _prefs?.setInt(key, value);
    } catch (error) {
      debugPrint('writeInt $key failed: $error');
    }
  }

  Future<void> _writeDouble(String key, double value) async {
    _memory[key] = value;
    try {
      await _prefs?.setDouble(key, value);
    } catch (error) {
      debugPrint('writeDouble $key failed: $error');
    }
  }

  Future<void> _writeString(String key, String value) async {
    _memory[key] = value;
    try {
      await _prefs?.setString(key, value);
    } catch (error) {
      debugPrint('writeString $key failed: $error');
    }
  }

  @visibleForTesting
  void debugReset() {
    _prefs = null;
    _ready = false;
    _initFuture = null;
    _memory.clear();
  }
}
