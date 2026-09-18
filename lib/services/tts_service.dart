import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'voice_selector.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  VoiceSelection? lastSelection;
  bool _configuring = false;

  Future<void> speak({
    required String text,
    required String gender,
    required double rate,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return;
    try {
      final tts = _tts ??= FlutterTts();
      await _configure(tts, gender: gender, rate: rate);
      await tts.stop();
      await tts.speak(value);
    } catch (error, stack) {
      debugPrint('TTS speak failed: $error\n$stack');
    }
  }

  Future<VoiceSelection?> preview({
    required String gender,
    required double rate,
  }) async {
    await speak(
      text: 'Hello! Let us learn English together.',
      gender: gender,
      rate: rate,
    );
    return lastSelection;
  }

  Future<void> dispose() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    _tts = null;
  }

  Future<void> _configure(
    FlutterTts tts, {
    required String gender,
    required double rate,
  }) async {
    if (_configuring) return;
    _configuring = true;
    try {
      await tts.setLanguage('en-US').timeout(const Duration(seconds: 2));
    } catch (error) {
      debugPrint('TTS setLanguage failed: $error');
    }
    try {
      await tts.setSpeechRate(rate.clamp(0.25, 0.65));
    } catch (error) {
      debugPrint('TTS setSpeechRate failed: $error');
    }
    try {
      await tts.setPitch(1);
      await tts.setVolume(1);
    } catch (_) {}

    try {
      final raw = await tts.getVoices.timeout(const Duration(seconds: 3));
      final voices = normalizeVoices(raw);
      final selection = selectEnglishVoice(voices: voices, gender: gender);
      lastSelection = selection;
      if (selection.voice != null) {
        await tts.setVoice({
          'name': selection.voice!['name'] ?? '',
          'locale': selection.voice!['locale'] ?? 'en-US',
        });
      }
    } catch (error, stack) {
      debugPrint('TTS voice discovery failed: $error\n$stack');
    } finally {
      _configuring = false;
    }
  }
}
