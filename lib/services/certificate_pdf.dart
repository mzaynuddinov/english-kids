import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const certificateFontAsset = 'assets/fonts/NotoSans-Regular.ttf';

String sanitizeStudentFileName(String name) {
  var text = name.trim().replaceAll(RegExp(r'\s+'), '_');
  text = text.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
  text = text.replaceAll(RegExp(r'_+'), '_');
  text = text.replaceAll(RegExp(r'^_+|_+$'), '');
  if (text.isEmpty) return 'Student';
  if (text.length > 40) return text.substring(0, 40);
  return text;
}

String certificateFileName(String studentName, DateTime when, {int suffix = 0}) {
  final safe = sanitizeStudentFileName(studentName);
  final stamp = '${when.year.toString().padLeft(4, '0')}-'
      '${when.month.toString().padLeft(2, '0')}-'
      '${when.day.toString().padLeft(2, '0')}_'
      '${when.hour.toString().padLeft(2, '0')}-'
      '${when.minute.toString().padLeft(2, '0')}-'
      '${when.second.toString().padLeft(2, '0')}';
  final extra = suffix <= 0 ? '' : '_$suffix';
  return '${safe}_Certificate_$stamp$extra.pdf';
}

String certificatePublicId(String studentId, int completedAtMillis) {
  final bytes = '$studentId|$completedAtMillis'.codeUnits;
  var hash = 0xcbf29ce484222325;
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0').substring(0, 12).toUpperCase();
}

String formatCertificateDate(DateTime when) {
  final day = when.day.toString().padLeft(2, '0');
  final month = when.month.toString().padLeft(2, '0');
  return '$day.$month.${when.year}';
}

Future<Uint8List> buildCertificatePdf({
  required String studentName,
  required int wordCount,
  required DateTime completedAt,
  required String certificateId,
  Uint8List? photoJpeg,
}) async {
  final data = await rootBundle.load(certificateFontAsset);
  final fontBytes = data.buffer.asUint8List();
  return Isolate.run<Uint8List>(() async {
    return renderCertificatePdf(
      fontBytes: fontBytes,
      studentName: studentName,
      wordCount: wordCount,
      completedAt: completedAt,
      certificateId: certificateId,
      photoJpeg: photoJpeg,
    );
  });
}

Future<Uint8List> renderCertificatePdf({
  required Uint8List fontBytes,
  required String studentName,
  required int wordCount,
  required DateTime completedAt,
  required String certificateId,
  Uint8List? photoJpeg,
}) {
  final font = pw.Font.ttf(fontBytes.buffer.asByteData(fontBytes.offsetInBytes, fontBytes.length));
  final style = pw.TextStyle(font: font, color: PdfColor.fromInt(0xFF334155));
  final doc = pw.Document(
    title: certificateId,
    author: 'Anglisiro Omuz',
    keywords: certificateId,
  );
  final date = formatCertificateDate(completedAt);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromInt(0xFFD4AF37), width: 3),
          ),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFF1E3A5F), width: 1),
            ),
            padding: const pw.EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Англисиро Омӯз',
                  style: style.copyWith(fontSize: 14, color: PdfColor.fromInt(0xFF0F766E)),
                ),
                pw.SizedBox(height: 18),
                pw.Text(
                  'СЕРТИФИКАТ',
                  style: style.copyWith(fontSize: 32, color: PdfColor.fromInt(0xFF1E3A5F)),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'CERTIFICATE OF ACHIEVEMENT',
                  style: style.copyWith(fontSize: 12, color: PdfColor.fromInt(0xFF64748B)),
                ),
                pw.SizedBox(height: 22),
                if (photoJpeg != null)
                  pw.Container(
                    width: 92,
                    height: 92,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColor.fromInt(0xFFD4AF37), width: 2),
                    ),
                    child: pw.ClipOval(
                      child: pw.Image(
                        pw.MemoryImage(photoJpeg),
                        width: 92,
                        height: 92,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  )
                else
                  pw.Container(
                    width: 92,
                    height: 92,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColor.fromInt(0xFFCCFBF1),
                    ),
                    child: pw.Text(
                      studentName.isEmpty ? '?' : studentName.substring(0, 1),
                      style: style.copyWith(fontSize: 28, color: PdfColor.fromInt(0xFF0F766E)),
                    ),
                  ),
                pw.SizedBox(height: 18),
                pw.Text(
                  'Ин сертификат тасдиқ мекунад, ки',
                  style: style.copyWith(fontSize: 13),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  studentName,
                  style: style.copyWith(fontSize: 26, color: PdfColor.fromInt(0xFF0F172A)),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'тамоми $wordCount калимаи англисиро омӯхтааст.',
                  style: style.copyWith(fontSize: 13),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'has learned all $wordCount English vocabulary words.',
                  style: style.copyWith(fontSize: 11, color: PdfColor.fromInt(0xFF64748B)),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Spacer(),
                pw.Text(
                  '✓ $wordCount калима / $wordCount Words',
                  style: style.copyWith(fontSize: 14, color: PdfColor.fromInt(0xFFB45309)),
                ),
                pw.SizedBox(height: 18),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Сана / Date', style: style.copyWith(fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
                        pw.Text(date, style: style.copyWith(fontSize: 12, color: PdfColor.fromInt(0xFF0F172A))),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Рақам / ID', style: style.copyWith(fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
                        pw.Text(certificateId, style: style.copyWith(fontSize: 12, color: PdfColor.fromInt(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Барномаи омӯзиш. Ин мӯҳри расмии мактаб нест.',
                  style: style.copyWith(fontSize: 9, color: PdfColor.fromInt(0xFF64748B)),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  return doc.save();
}
