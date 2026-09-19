import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'preferences_service.dart';

class PinService {
  PinService._();
  static final PinService instance = PinService._();

  static const _hashKey = 'parent_pin_hash';
  static const _saltKey = 'parent_pin_salt';

  Future<bool> hasPin() async {
    final hash = await PreferencesService.instance.loadRaw(_hashKey);
    return hash != null && hash.isNotEmpty;
  }

  bool validFormat(String pin) {
    return RegExp(r'^\d{4,6}$').hasMatch(pin);
  }

  String digest(String pin, String salt) {
    final bytes = utf8.encode('anglisiro-omuz|$salt|$pin');
    var h = 0xcbf29ce484222325;
    for (final b in bytes) {
      h ^= b;
      h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    for (final b in bytes.reversed) {
      h ^= (b << 1);
      h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(16, '0');
  }

  Future<String> _salt() async {
    var salt = await PreferencesService.instance.loadRaw(_saltKey);
    if (salt == null || salt.isEmpty) {
      salt = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      await PreferencesService.instance.saveRaw(_saltKey, salt);
    }
    return salt;
  }

  Future<bool> setPin(String pin) async {
    if (!validFormat(pin)) return false;
    try {
      final salt = await _salt();
      await PreferencesService.instance.saveRaw(_hashKey, digest(pin, salt));
      return true;
    } catch (error, stack) {
      debugPrint('PIN save failed: $error\n$stack');
      return false;
    }
  }

  Future<bool> verify(String pin) async {
    try {
      final stored = await PreferencesService.instance.loadRaw(_hashKey);
      if (stored == null || stored.isEmpty) return false;
      final salt = await _salt();
      return stored == digest(pin, salt);
    } catch (error, stack) {
      debugPrint('PIN verify failed: $error\n$stack');
      return false;
    }
  }

  Future<void> clear() async {
    await PreferencesService.instance.saveRaw(_hashKey, '');
  }
}
