import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:english_kids/models/student.dart';
import 'package:english_kids/models/word.dart';
import 'package:english_kids/services/certificate_pdf.dart';
import 'package:english_kids/services/certificate_store.dart';
import 'package:english_kids/services/pin_service.dart';
import 'package:english_kids/services/preferences_service.dart';
import 'package:english_kids/services/profile_photo.dart';
import 'package:english_kids/services/progress_service.dart';
import 'package:english_kids/services/reminder_service.dart';
import 'package:english_kids/services/student_service.dart';
import 'package:english_kids/services/vocabulary_service.dart';
import 'package:english_kids/services/word_learning_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const apple = Word(
    english: 'apple',
    pronunciation: 'a',
    tajik: 'себ',
    week: 1,
    topic: 'Fruit',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReminderService.suppressTimersForTests = true;
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    WordLearningService.instance.debugReset();
    ProgressService.instance.debugReset();
    PinService.instance.debugReset();
    VocabularyService.debugReset();
  });

  tearDown(() {
    PreferencesService.instance.debugBeforeWrite = null;
    PreferencesService.instance.debugFailWrites = false;
    WordLearningService.instance.debugBeforeOpen = null;
  });

  test('a cached student switch keeps each learned set and does not read storage again', () async {
    await StudentService.instance.init();
    final first = await StudentService.instance.addStudent('Насим');
    final second = await StudentService.instance.addStudent('Ҳадиса');
    await WordLearningService.instance.openStudent(
      studentId: first.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    await WordLearningService.instance.setFlag(apple.id, learned: true);
    await WordLearningService.instance.openStudent(
      studentId: second.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    final reads = WordLearningService.instance.diskReads;
    final prefs = PreferencesService.instance.prefsReads;
    final loads = VocabularyService.loadCalls;
    final watch = Stopwatch()..start();
    expect(WordLearningService.instance.activate(first.id), isTrue);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
    expect(WordLearningService.instance.activate(second.id), isTrue);
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
    expect(WordLearningService.instance.activate(first.id), isTrue);
    expect(WordLearningService.instance.studentId, first.id);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(200));
    expect(WordLearningService.instance.diskReads, reads);
    expect(PreferencesService.instance.prefsReads, prefs);
    expect(VocabularyService.loadCalls, loads);
  });

  test('a slower student open cannot replace the student selected later', () async {
    await StudentService.instance.init();
    final first = await StudentService.instance.addStudent('Насим');
    final second = await StudentService.instance.addStudent('Ҳадиса');
    await WordLearningService.instance.openStudent(
      studentId: first.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    await WordLearningService.instance.setFlag(apple.id, learned: true);
    final gate = Completer<void>();
    WordLearningService.instance.debugBeforeOpen = () => gate.future;
    final pending = WordLearningService.instance.openStudent(
      studentId: second.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(WordLearningService.instance.activate(first.id), isTrue);
    expect(WordLearningService.instance.studentId, first.id);
    gate.complete();
    await pending;
    expect(WordLearningService.instance.studentId, first.id);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
    expect(WordLearningService.instance.activate(second.id), isTrue);
    expect(WordLearningService.instance.of(apple.id).learned, isFalse);
    expect(WordLearningService.instance.activate(first.id), isTrue);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
  });

  test('cached progress switches without another storage read', () async {
    await StudentService.instance.init();
    final first = await StudentService.instance.addStudent('Насим');
    final second = await StudentService.instance.addStudent('Ҳадиса');
    await ProgressService.instance.load(key: StudentService.instance.progressKey(first.id));
    expect(
      await ProgressService.instance.save(ProgressService.instance.snapshot.copyWith(letters: {'A'})),
      isTrue,
    );
    await ProgressService.instance.load(key: StudentService.instance.progressKey(second.id));
    expect(
      await ProgressService.instance.save(ProgressService.instance.snapshot.copyWith(letters: {'B'})),
      isTrue,
    );
    final prefs = PreferencesService.instance.prefsReads;
    final watch = Stopwatch()..start();
    await ProgressService.instance.load(key: StudentService.instance.progressKey(first.id));
    expect(ProgressService.instance.snapshot.letters, contains('A'));
    expect(ProgressService.instance.snapshot.letters, isNot(contains('B')));
    await ProgressService.instance.load(key: StudentService.instance.progressKey(second.id));
    expect(ProgressService.instance.snapshot.letters, contains('B'));
    expect(ProgressService.instance.snapshot.letters, isNot(contains('A')));
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(200));
    expect(PreferencesService.instance.prefsReads, prefs);
  });

  test('an older student switch cannot overwrite the newer selection', () async {
    await StudentService.instance.init();
    final first = await StudentService.instance.addStudent('Насим');
    final second = await StudentService.instance.addStudent('Ҳадиса');
    final gate = Completer<void>();
    PreferencesService.instance.debugBeforeWrite = () => gate.future;
    final older = StudentService.instance.setCurrentStudent(second.id);
    final newer = StudentService.instance.setCurrentStudent(first.id);
    expect(StudentService.instance.currentStudentId, first.id);
    gate.complete();
    await older;
    await newer;
    expect(StudentService.instance.currentStudentId, first.id);
    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.currentStudentId, first.id);
  });

  test('old student records and the PIN survive a schema marker', () async {
    SharedPreferences.setMockInitialValues({
      'students_list': jsonEncode([
        {'id': 's1', 'name': 'Насим', 'createdAt': '2026-01-02T00:00:00.000'},
      ]),
      'current_student_id': 's1',
      'learning_state_v2_s1': jsonEncode({'letters': ['A'], 'listens': 4}),
    });
    PreferencesService.instance.debugReset();
    StudentService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.students.single.photoPath, isNull);
    expect(StudentService.instance.students.single.name, 'Насим');
    expect(await PreferencesService.instance.loadRaw('data_schema'), '2');
    await ProgressService.instance.load(key: StudentService.instance.progressKey('s1'));
    expect(ProgressService.instance.snapshot.letters, contains('A'));
    expect(ProgressService.instance.snapshot.listens, 4);
    expect(await PinService.instance.setPin('2468'), isTrue);

    StudentService.instance.debugReset();
    PreferencesService.instance.debugReset();
    ProgressService.instance.debugReset();
    PinService.instance.debugReset();
    await StudentService.instance.init();
    expect(StudentService.instance.students.single.name, 'Насим');
    expect(StudentService.instance.students.single.id, 's1');
    expect(await PinService.instance.verify('2468'), isTrue);
    await ProgressService.instance.load(key: 'learning_state_v2_s1');
    expect(ProgressService.instance.snapshot.letters, contains('A'));
  });

  test('a profile photo can be cropped, replaced, and removed without touching learning', () async {
    final source = img.fill(
      img.Image(width: 80, height: 40),
      color: img.ColorRgb8(220, 10, 10),
    );
    for (var y = 0; y < 40; y++) {
      for (var x = 0; x < 40; x++) {
        source.setPixel(x, y, img.ColorRgb8(10, 10, 220));
      }
    }
    final bytes = Uint8List.fromList(img.encodeJpg(source, quality: 95));
    expect(cropSquareJpeg(Uint8List.fromList([1, 2, 3])), isNull);
    final left = cropSquareJpeg(bytes, centerX: 0, centerY: 0.5, zoom: 1, edge: 24);
    final right = cropSquareJpeg(bytes, centerX: 1, centerY: 0.5, zoom: 1, edge: 24);
    expect(left, isNotNull);
    expect(right, isNotNull);
    final leftImage = img.decodeJpg(left!);
    final rightImage = img.decodeJpg(right!);
    expect(leftImage!.width, 24);
    expect(rightImage!.height, 24);
    final leftPixel = leftImage.getPixel(4, 4);
    final rightPixel = rightImage.getPixel(4, 4);
    expect(leftPixel.b, greaterThan(leftPixel.r));
    expect(rightPixel.r, greaterThan(rightPixel.b));

    await StudentService.instance.init();
    final student = await StudentService.instance.addStudent('Насим');
    await WordLearningService.instance.openStudent(
      studentId: student.id,
      vocab: const [apple],
      legacyLearned: {},
      legacySaved: {},
    );
    await WordLearningService.instance.setFlag(apple.id, learned: true);
    final folder = Directory('${Directory.systemTemp.path}/anglisiro_profile_photos/profile_photos');
    final firstPath = await ProfilePhotoStore.saveBytes(folder, '${student.id}_a', left);
    final secondPath = await ProfilePhotoStore.saveBytes(folder, '${student.id}_b', right);
    await StudentService.instance.setPhoto(student.id, firstPath);
    expect(StudentService.instance.studentById(student.id)!.photoPath, firstPath);
    expect(StudentService.instance.studentById(student.id)!.id, student.id);
    await StudentService.instance.setPhoto(student.id, secondPath);
    expect(File(firstPath).existsSync(), isFalse);
    expect(File(secondPath).existsSync(), isTrue);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);

    PreferencesService.instance.debugFailWrites = true;
    await expectLater(
      StudentService.instance.setPhoto(student.id, '$secondPath-missing'),
      throwsStateError,
    );
    expect(StudentService.instance.studentById(student.id)!.photoPath, secondPath);
    expect(WordLearningService.instance.of(apple.id).learned, isTrue);
  });

  test('student JSON without a photo still loads', () {
    final student = Student.fromJson({
      'id': 's1',
      'name': 'Насим',
      'createdAt': '2026-01-02T00:00:00.000',
    });
    expect(student.photoPath, isNull);
    expect(student.toJson().containsKey('photoPath'), isFalse);
    final again = Student.fromJson({...student.toJson(), 'photoPath': '/profile_photos/s1.jpg'});
    expect(again.id, 's1');
    expect(again.photoPath, '/profile_photos/s1.jpg');
  });

  test('the 500-word certificate date is stored once and cleared if no longer earned', () async {
    await ProgressService.instance.load(key: 'learning_state_v2_s1');
    await ProgressService.instance.syncCertificate(earned: false, nowMillis: 50);
    expect(ProgressService.instance.snapshot.certificateAt, isNull);
    await ProgressService.instance.syncCertificate(earned: true, nowMillis: 1000);
    expect(ProgressService.instance.snapshot.certificateAt, 1000);
    await ProgressService.instance.syncCertificate(earned: true, nowMillis: 2000);
    expect(ProgressService.instance.snapshot.certificateAt, 1000);
    await ProgressService.instance.syncCertificate(earned: false);
    expect(ProgressService.instance.snapshot.certificateAt, isNull);
    final restored = ProgressSnapshot.fromJson({'letters': ['Z'], 'listens': 2});
    expect(restored.certificateAt, isNull);
    expect(restored.letters, contains('Z'));
  });

  test('certificate filename, A4 PDF header, id, and photo are real', () async {
    final when = DateTime(2026, 10, 18, 14, 35, 22);
    expect(
      certificateFileName('Nasim', when),
      'Nasim_Certificate_2026-10-18_14-35-22.pdf',
    );
    expect(
      certificateFileName('A/B:C*?', when),
      'A_B_C_Certificate_2026-10-18_14-35-22.pdf',
    );
    expect(certificateFileName('   ', when), 'Student_Certificate_2026-10-18_14-35-22.pdf');
    expect(
      certificateFileName('Насим', when, suffix: 2),
      'Насим_Certificate_2026-10-18_14-35-22_2.pdf',
    );
    final id = certificatePublicId('s1', 1000);
    expect(id, certificatePublicId('s1', 1000));
    expect(id, isNot(certificatePublicId('s2', 1000)));

    final photo = cropSquareJpeg(
      Uint8List.fromList(img.encodeJpg(img.Image(width: 16, height: 16))),
      edge: 16,
    );
    final font = (await rootBundle.load(certificateFontAsset)).buffer.asUint8List();
    final bytes = await renderCertificatePdf(
      fontBytes: font,
      studentName: 'Насим',
      wordCount: 500,
      completedAt: when,
      certificateId: id,
      photoJpeg: photo,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final latin = latin1.decode(bytes, allowInvalid: true);
    expect(latin.contains('595'), isTrue);
    expect(latin.contains('841'), isTrue);
    expect(latin.contains(id), isTrue);
    expect(latin.contains('DCTDecode'), isTrue);

    final folder = await Directory.systemTemp.createTemp('certificates');
    final file = await saveCertificateFile(
      directory: folder,
      studentName: 'Nasim',
      generatedAt: when,
      bytes: bytes,
    );
    expect(file.existsSync(), isTrue);
    expect(file.path, endsWith('Nasim_Certificate_2026-10-18_14-35-22.pdf'));
    expect(await file.length(), greaterThan(1000));
    final again = await saveCertificateFile(
      directory: folder,
      studentName: 'Nasim',
      generatedAt: when,
      bytes: bytes,
    );
    expect(again.path, endsWith('Nasim_Certificate_2026-10-18_14-35-22_1.pdf'));
    final built = await buildCertificatePdf(
      studentName: 'Насим',
      wordCount: 500,
      completedAt: when,
      certificateId: id,
      photoJpeg: photo,
    );
    expect(String.fromCharCodes(built.take(5)), '%PDF-');
    expect(built.length, greaterThan(1000));
  });
}
