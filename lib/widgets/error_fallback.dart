import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_logo.dart';

class ErrorFallback extends StatelessWidget {
  final VoidCallback? onRetry;

  const ErrorFallback({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 92),
                  const SizedBox(height: 18),
                  const Text(
                    appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: slate900,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Мушкилоти муваққатӣ ба вуҷуд омад.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: teal700,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(backgroundColor: cyan600),
                    child: const Text('Дубора кӯшиш кунед'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
