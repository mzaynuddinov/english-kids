import 'package:flutter/material.dart';

import '../models/student.dart';

class CertificatePage extends StatelessWidget {
  final Student student;
  final int wordCount;

  const CertificatePage({
    super.key,
    required this.student,
    required this.wordCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text('Сертификат'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E3A5F),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD4AF37), width: 8),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 56, color: Color(0xFFD4AF37)),
                    const SizedBox(height: 8),
                    const Text(
                      'СЕРТИФИКАТ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'CERTIFICATE OF ACHIEVEMENT',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Ин сертификат тасдиқ мекунад, ки',
                      style: TextStyle(fontSize: 15, color: Color(0xFF334155)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'тамоми $wordCount калимаи англисиро бомуваффақият омӯхтааст.',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'has successfully mastered all English vocabulary words.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 120,
                              height: 1,
                              color: const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 6),
                            const Text('Сана', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(date, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              width: 120,
                              height: 1,
                              color: const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 6),
                            const Text('Англисиро Омӯз', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const Text('Барномаи омӯзиш', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✓ 500 калима / 500 Words',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
