import 'package:flutter/material.dart';

const appName = 'Англисиро Омӯз';
const appVersion = '2.2.0';

const emerald500 = Color(0xFF10B981);
const emerald600 = Color(0xFF059669);
const emerald700 = Color(0xFF047857);
const teal500 = Color(0xFF14B8A6);
const teal600 = Color(0xFF0D9488);
const teal700 = Color(0xFF0F766E);
const cyan500 = Color(0xFF06B6D4);
const cyan600 = Color(0xFF0891B2);
const cyan700 = Color(0xFF0E7490);
const sky500 = Color(0xFF0EA5E9);
const blue500 = Color(0xFF3B82F6);
const blue600 = Color(0xFF2563EB);
const indigo500 = Color(0xFF6366F1);
const indigo600 = Color(0xFF4F46E5);
const indigo700 = Color(0xFF4338CA);
const slate700 = Color(0xFF334155);
const slate800 = Color(0xFF1E293B);
const slate900 = Color(0xFF0F172A);
const slate950 = Color(0xFF020617);

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seed = dark ? cyan500 : teal600;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: dark ? slate950 : const Color(0xFFF1F5F9),
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: dark ? slate950 : const Color(0xFFF1F5F9),
      foregroundColor: dark ? Colors.white : slate900,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? slate900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: dark ? slate950 : Colors.white,
      indicatorColor: dark
          ? cyan500.withValues(alpha: 0.18)
          : teal500.withValues(alpha: 0.16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
