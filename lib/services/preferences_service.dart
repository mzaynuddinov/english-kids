import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';

/// SharedPreferences plus a JSON file.
///
/// A timed-out or wiped preference cache must not be treated as an empty
/// database. The file copy restores students, the PIN, and learning records.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  SharedPreferences? _prefs;
  bool _ready = false;
  Future<void> _tail = Future<void>.value();
  bool _fileLoaded = false;
  final Map<String, Object> _memory = {};
  final Map<String, String> _fileCache = {};
  @visibleForTesting
  bool debugFailWrites = false;

  static const _revKey = '__rev';

  Future<T> _sync<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> init() {
    return _sync(_doInit);
  }

  Future<void> _doInit() async {
    if (_ready && _prefs != null) return;
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 8),
        );
        try {
          await prefs.reload();
        } catch (error) {
          debugPrint('SharedPreferences reload skipped: $error');
        }
        _prefs = prefs;
        _ready = true;
        await _loadFile();
        await _reconcile();
        return;
      } catch (error, stack) {
        lastError = error;
        debugPrint('SharedPreferences attempt ${attempt + 1} failed: $error\n$stack');
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
    _ready = false;
    _prefs = null;
    await _loadFile();
    debugPrint('SharedPreferences unavailable, file copy only: $lastError');
  }

  Future<void> reloadFromDisk() {
    return _sync(() async {
      await _doInit();
      try {
        await _prefs?.reload();
      } catch (error, stack) {
        debugPrint('SharedPreferences reload failed: $error\n$stack');
      }
      _fileLoaded = false;
      await _loadFile();
      await _reconcile();
    });
  }

  Future<AppSettings> loadSettings() {
    return _sync(() async {
      await _doInit();
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
    });
  }

  Future<void> saveSettings(AppSettings settings) {
    return _sync(() async {
      await _doInit();
      await _writeInt('themeMode', settings.themeMode.index);
      await _writeDouble('textScale', settings.textScale);
      await _writeString('voiceGender', settings.voiceGender);
      await _writeDouble('speechRate', settings.speechRate);
    });
  }

  Future<Set<String>> loadSet(String key) {
    return _sync(() async {
      await _doInit();
      return _loadSet(key);
    });
  }

  Future<bool> saveSet(String key, Set<String> values) {
    return _sync(() async {
      await _doInit();
      return _saveSet(key, values);
    });
  }

  Future<String?> loadRaw(String key) {
    return _sync(() async {
      await _doInit();
      return _loadRaw(key);
    });
  }

  Future<bool> saveRaw(String key, String value) {
    return _sync(() async {
      await _doInit();
      return _saveRaw(key, value);
    });
  }

  Set<String> _loadSet(String key) {
    try {
      final prefs = _prefs;
      if (prefs != null && prefs.containsKey(key)) {
        final list = prefs.getStringList(key) ?? <String>[];
        _memory[key] = list;
        return {...list};
      }
      final stored = _fileCache['set:$key'];
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          final list = [for (final item in decoded) '$item'];
          _memory[key] = list;
          unawaited(prefs?.setStringList(key, list));
          return {...list};
        }
      }
      final mem = _memory[key];
      if (mem is List<String>) return {...mem};
      return <String>{};
    } catch (error, stack) {
      debugPrint('Corrupt set $key: $error\n$stack');
      final mem = _memory[key];
      if (mem is List<String>) return {...mem};
      return <String>{};
    }
  }

  Future<bool> _saveSet(String key, Set<String> values) async {
    if (debugFailWrites) return false;
    final list = values.toList();
    _bumpRev();
    _memory[key] = list;
    _fileCache['set:$key'] = jsonEncode(list);
    final fileOk = await _writeFile();
    var prefsOk = false;
    try {
      final prefs = _prefs;
      if (prefs != null) {
        prefsOk = await prefs.setStringList(key, list);
        if (prefsOk) await _writePrefsRev(prefs);
      }
    } catch (error, stack) {
      debugPrint('Failed to persist $key: $error\n$stack');
    }
    return prefsOk || fileOk;
  }

  String? _loadRaw(String key) {
    try {
      final prefs = _prefs;
      if (prefs != null && prefs.containsKey(key)) {
        final disk = prefs.getString(key);
        if (disk != null) {
          _memory[key] = disk;
          return disk;
        }
      }
      final stored = _fileCache[key];
      if (stored != null) {
        _memory[key] = stored;
        if (prefs != null && !prefs.containsKey(key)) {
          unawaited(prefs.setString(key, stored));
        }
        return stored;
      }
      final mem = _memory[key];
      return mem is String ? mem : null;
    } catch (error, stack) {
      debugPrint('Corrupt raw $key: $error\n$stack');
      final mem = _memory[key];
      return mem is String ? mem : null;
    }
  }

  Future<bool> _saveRaw(String key, String value) async {
    if (debugFailWrites) return false;
    _bumpRev();
    _memory[key] = value;
    _fileCache[key] = value;
    final fileOk = await _writeFile();
    var prefsOk = false;
    try {
      final prefs = _prefs;
      if (prefs != null) {
        prefsOk = await prefs.setString(key, value);
        if (prefsOk) await _writePrefsRev(prefs);
      }
    } catch (error) {
      debugPrint('writeRaw $key failed: $error');
    }
    return prefsOk || fileOk;
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
    _fileCache[key] = value;
    try {
      await _prefs?.setString(key, value);
    } catch (error) {
      debugPrint('writeString $key failed: $error');
    }
    await _writeFile();
  }

  Future<void> _loadFile() async {
    if (_fileLoaded) return;
    _fileLoaded = true;
    try {
      final file = await _storeFile();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      _fileCache
        ..clear()
        ..addAll({
          for (final entry in decoded.entries) '${entry.key}': '${entry.value}',
        });
    } catch (error) {
      debugPrint('Durable store read skipped: $error');
    }
  }

  Future<void> _restoreMissing() async {
    final prefs = _prefs;
    if (prefs == null || _fileCache.isEmpty) return;
    try {
      for (final entry in _fileCache.entries.toList()) {
        if (entry.key == _revKey) continue;
        if (entry.key.startsWith('set:')) {
          final key = entry.key.substring(4);
          if (prefs.containsKey(key)) continue;
          final decoded = jsonDecode(entry.value);
          if (decoded is List) {
            await prefs.setStringList(key, [for (final item in decoded) '$item']);
          }
        } else if (!prefs.containsKey(entry.key)) {
          await prefs.setString(entry.key, entry.value);
        }
      }
    } catch (error, stack) {
      debugPrint('Durable restore skipped: $error\n$stack');
    }
  }

  /// The JSON file is written with a flush. SharedPreferences can still be
  /// holding an older copy when the process comes back. The higher revision
  /// wins, so a slow or stale preference cache cannot hide saved students.
  Future<void> _reconcile() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final fileRev = _fileRev();
    final prefsRev = _prefsRev();
    if (fileRev > prefsRev) {
      for (final entry in _fileCache.entries.toList()) {
        if (entry.key == _revKey) continue;
        try {
          if (entry.key.startsWith('set:')) {
            final key = entry.key.substring(4);
            final decoded = jsonDecode(entry.value);
            if (decoded is List) {
              await prefs.setStringList(key, [for (final item in decoded) '$item']);
            }
          } else {
            await prefs.setString(entry.key, entry.value);
          }
        } catch (error, stack) {
          debugPrint('Durable reconcile skipped ${entry.key}: $error\n$stack');
        }
      }
      try {
        await prefs.setString(_revKey, '$fileRev');
      } catch (error) {
        debugPrint('Durable revision write skipped: $error');
      }
      return;
    }
    await _restoreMissing();
  }

  int _prefsRev() {
    try {
      return int.tryParse(_prefs?.getString(_revKey) ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  int _fileRev() => int.tryParse(_fileCache[_revKey] ?? '') ?? 0;

  void _bumpRev() {
    final next = (_fileRev() > _prefsRev() ? _fileRev() : _prefsRev()) + 1;
    _fileCache[_revKey] = '$next';
    _memory[_revKey] = '$next';
  }

  Future<void> _writePrefsRev(SharedPreferences prefs) async {
    final rev = _fileCache[_revKey];
    if (rev == null) return;
    await prefs.setString(_revKey, rev);
  }

  Future<bool> _writeFile() async {
    try {
      final file = await _storeFile();
      await file.writeAsString(jsonEncode(_fileCache), flush: true);
      return true;
    } catch (error) {
      debugPrint('Durable store write skipped: $error');
      return false;
    }
  }

  Future<File> _storeFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/anglisiro_store.json');
  }

  @visibleForTesting
  void debugSeedFile(Map<String, String> values) {
    _fileCache
      ..clear()
      ..addAll(values);
    _fileLoaded = true;
  }

  @visibleForTesting
  void debugReset() {
    _prefs = null;
    _ready = false;
    _fileLoaded = false;
    _tail = Future<void>.value();
    _memory.clear();
    _fileCache.clear();
    debugFailWrites = false;
  }
}
