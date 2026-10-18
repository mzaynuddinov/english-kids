import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'certificate_pdf.dart';

Future<Directory> certificateFolder() async {
  final root = await getApplicationDocumentsDirectory();
  final dir = Directory('${root.path}/certificates');
  await dir.create(recursive: true);
  return dir;
}

Future<File> saveCertificateFile({
  required Directory directory,
  required String studentName,
  required DateTime generatedAt,
  required Uint8List bytes,
}) async {
  if (bytes.length < 5) {
    throw StateError('Файли PDF холӣ аст');
  }
  await directory.create(recursive: true);
  var suffix = 0;
  File file;
  do {
    file = File('${directory.path}/${certificateFileName(studentName, generatedAt, suffix: suffix)}');
    suffix++;
  } while (await file.exists());
  await file.writeAsBytes(bytes, flush: true);
  final written = await file.length();
  if (written <= 0) {
    throw StateError('Файли PDF навишта нашуд');
  }
  return file;
}
