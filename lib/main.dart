import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'widgets/error_fallback.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();

  runZonedGuarded(() {
    runApp(const EnglishKidsApp());
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

void _installErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: kDebugMode);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  ErrorWidget.builder = (details) {
    debugPrint('Widget build error: ${details.exceptionAsString()}');
    return ErrorFallback(
      onRetry: () => runApp(const EnglishKidsApp()),
    );
  };
}
