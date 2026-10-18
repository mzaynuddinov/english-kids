import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/student.dart';
import '../services/certificate_pdf.dart';
import '../services/certificate_store.dart';
import '../services/progress_service.dart';
import '../widgets/student_avatar.dart';

class CertificatePage extends StatefulWidget {
  final Student student;
  final int wordCount;
  final int? completedAtMillis;

  const CertificatePage({
    super.key,
    required this.student,
    required this.wordCount,
    this.completedAtMillis,
  });

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  Uint8List? photo;
  bool saving = false;
  late int completedAt;

  @override
  void initState() {
    super.initState();
    completedAt = widget.completedAtMillis ?? DateTime.now().millisecondsSinceEpoch;
    if (widget.completedAtMillis == null) {
      unawaited(ProgressService.instance.syncCertificate(earned: true, nowMillis: completedAt));
    }
    final path = widget.student.photoPath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        photo = file.readAsBytesSync();
      }
    }
  }

  Future<void> _download() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final completed = DateTime.fromMillisecondsSinceEpoch(completedAt);
      final id = certificatePublicId(widget.student.id, completedAt);
      final bytes = await buildCertificatePdf(
        studentName: widget.student.name,
        wordCount: widget.wordCount,
        completedAt: completed,
        certificateId: id,
        photoJpeg: photo,
      );
      final generatedAt = DateTime.now();
      final file = await saveCertificateFile(
        directory: await certificateFolder(),
        studentName: widget.student.name,
        generatedAt: generatedAt,
        bytes: bytes,
      );
      if (!await file.exists() || await file.length() <= 0) {
        throw StateError('Файли PDF навишта нашуд');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF захира шуд: ${file.path.split(Platform.pathSeparator).last}')),
      );
      try {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf', name: file.uri.pathSegments.last)],
        );
      } catch (error, stack) {
        debugPrint('Certificate share skipped: $error\n$stack');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF захира нашуд: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = DateTime.fromMillisecondsSinceEpoch(completedAt);
    final date = formatCertificateDate(completed);
    final id = certificatePublicId(widget.student.id, completedAt);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text('Сертификат'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E3A5F),
        actions: [
          IconButton(
            tooltip: 'Боргирии PDF',
            onPressed: saving ? null : _download,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 210 / 297,
                    child: _CertificateSheet(
                      student: widget.student,
                      wordCount: widget.wordCount,
                      date: date,
                      certificateId: id,
                      photo: photo,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : _download,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(saving ? 'Сохта мешавад...' : 'Боргирии PDF'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateSheet extends StatelessWidget {
  final Student student;
  final int wordCount;
  final String date;
  final String certificateId;
  final Uint8List? photo;

  const _CertificateSheet({
    required this.student,
    required this.wordCount,
    required this.date,
    required this.certificateId,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD4AF37), width: 6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1E3A5F))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
            child: Column(
              children: [
                const Text('Англисиро Омӯз', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E))),
                const SizedBox(height: 10),
                const Text(
                  'СЕРТИФИКАТ',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: Color(0xFF1E3A5F)),
                ),
                const Text(
                  'CERTIFICATE OF ACHIEVEMENT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                photo == null
                    ? StudentAvatar(student: student, radius: 28)
                    : CircleAvatar(radius: 28, backgroundImage: MemoryImage(photo!)),
                const SizedBox(height: 10),
                const Text('Ин сертификат тасдиқ мекунад, ки', textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  student.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'тамоми $wordCount калимаи англисиро омӯхтааст.',
                  textAlign: TextAlign.center,
                ),
                Text(
                  'has learned all $wordCount English vocabulary words.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
                const Spacer(),
                Text(
                  '✓ $wordCount калима / $wordCount Words',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Сана', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text(date, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Рақам', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text(certificateId, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Барномаи омӯзиш. Ин мӯҳри расмии мактаб нест.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
