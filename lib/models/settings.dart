import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final double textScale;
  final String voiceGender;
  final double speechRate;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1,
    this.voiceGender = 'female',
    this.speechRate = 0.42,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    String? voiceGender,
    double? speechRate,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textScale: (textScale ?? this.textScale).clamp(0.85, 1.25),
      voiceGender: voiceGender ?? this.voiceGender,
      speechRate: (speechRate ?? this.speechRate).clamp(0.25, 0.65),
    );
  }

  static ThemeMode themeModeFromIndex(int? value) {
    if (value == null || value < 0 || value >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[value];
  }

  static double scaleFrom(double? value) {
    if (value == null || value.isNaN || value.isInfinite) return 1;
    return value.clamp(0.85, 1.25);
  }

  static double rateFrom(double? value) {
    if (value == null || value.isNaN || value.isInfinite) return 0.42;
    return value.clamp(0.25, 0.65);
  }

  static String genderFrom(String? value) {
    if (value == 'male' || value == 'female') return value!;
    return 'female';
  }
}
