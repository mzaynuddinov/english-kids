import 'dart:async';

import 'package:flutter/material.dart';

import 'models/settings.dart';
import 'pages/home_shell.dart';
import 'services/preferences_service.dart';
import 'services/reminder_service.dart';
import 'theme.dart';
import 'widgets/error_fallback.dart';

class EnglishKidsApp extends StatefulWidget {
  const EnglishKidsApp({super.key});

  @override
  State<EnglishKidsApp> createState() => _EnglishKidsAppState();
}

class _EnglishKidsAppState extends State<EnglishKidsApp> {
  AppSettings settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    try {
      final loaded = await PreferencesService.instance.loadSettings();
      if (mounted) setState(() => settings = loaded);
    } catch (error, stack) {
      debugPrint('Settings bootstrap failed: $error\n$stack');
    }
    try {
      await ReminderService.instance.initialize();
    } catch (error, stack) {
      debugPrint('Reminder bootstrap failed: $error\n$stack');
    }
  }

  Future<void> _save(AppSettings next) async {
    setState(() => settings = next);
    try {
      await PreferencesService.instance.saveSettings(next);
    } catch (error, stack) {
      debugPrint('Settings save failed: $error\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: settings.themeMode,
      builder: (builderContext, child) {
        MediaQueryData data;
        try {
          data = MediaQuery.of(builderContext);
        } catch (_) {
          data = MediaQueryData.fromView(View.of(builderContext));
        }
        return MediaQuery(
          data: data.copyWith(
            textScaler: TextScaler.linear(settings.textScale.clamp(0.85, 1.25)),
          ),
          child: child ?? const ErrorFallback(),
        );
      },
      home: HomeShell(settings: settings, onSettingsChanged: _save),
    );
  }
}
