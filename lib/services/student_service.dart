import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../models/word_learning.dart';
import 'preferences_service.dart';
import 'progress_service.dart';
import 'word_learning_service.dart';

class StudentService extends ChangeNotifier {
  StudentService._();
  static final StudentService instance = StudentService._();

  static const _studentsKey = 'students_list';
  static const _currentKey = 'current_student_id';

  List<Student> students = [];
  String? currentStudentId;
  bool _initialized = false;
  Future<void>? _initFuture;
  bool _allowEmptyWrite = false;

  String learnedKey([String? id]) => 'learned_${id ?? currentStudentId ?? "default"}';
  String savedKey([String? id]) => 'saved_${id ?? currentStudentId ?? "default"}';
  String progressKey([String? id]) => 'learning_state_v2_${id ?? currentStudentId ?? "default"}';

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    if (_initialized) return;
    try {
      await _loadStudents();
      await _ensureDefaultAndMigrate();
      await _loadCurrent();
      _initialized = true;
      notifyListeners();
    } catch (error) {
      _initFuture = null;
      rethrow;
    }
  }

  /// Re-reads storage after the app returns to the foreground.
  /// A failed or empty read never erases students that are still in memory,
  /// and an in-memory list is written back if the disk copy is missing.
  Future<void> refreshFromDisk() async {
    await PreferencesService.instance.reloadFromDisk();
    if (!_initialized) {
      await init();
      return;
    }
    final raw = await PreferencesService.instance.loadRaw(_studentsKey);
    if (raw == null) {
      if (students.isNotEmpty) await _saveStudents();
      return;
    }
    List<Student>? disk;
    try {
      if (raw.isEmpty || raw == '[]') {
        disk = [];
      } else {
        final list = jsonDecode(raw) as List;
        disk = list
            .whereType<Map>()
            .map((e) => Student.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (error, stack) {
      debugPrint('Student refresh kept the in-memory list: $error\n$stack');
      return;
    }
    final loaded = disk;
    if (loaded.isEmpty && students.isNotEmpty) {
      await _saveStudents();
      return;
    }
    final byId = <String, Student>{for (final student in loaded) student.id: student};
    var memoryChangedDisk = loaded.length != students.length;
    for (final student in students) {
      final previous = byId[student.id];
      if (previous == null || previous.name != student.name) memoryChangedDisk = true;
      byId[student.id] = student;
    }
    final merged = byId.values.toList();
    final before = students.map((student) => '${student.id}:${student.name}').join('|');
    students = merged;
    await _loadCurrent();
    final after = students.map((student) => '${student.id}:${student.name}').join('|');
    if (memoryChangedDisk && students.isNotEmpty) await _saveStudents();
    if (before != after) notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    students = [];
    currentStudentId = null;
    _initialized = false;
    _initFuture = null;
    _allowEmptyWrite = false;
  }

  Future<void> _loadStudents() async {
    final raw = await PreferencesService.instance.loadRaw(_studentsKey);
    if (raw == null || raw.isEmpty) {
      students = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      students = list
          .whereType<Map>()
          .map((e) => Student.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Failed to parse students: $e');
    }
  }

  Future<bool> _saveStudents() async {
    if (students.isEmpty && !_allowEmptyWrite) {
      final existing = await PreferencesService.instance.loadRaw(_studentsKey);
      if (existing != null && existing.isNotEmpty && existing != '[]') {
        debugPrint('Blocked an empty student list from erasing saved students');
        await _loadStudents();
        notifyListeners();
        return false;
      }
    }
    final ok = await PreferencesService.instance.saveRaw(
      _studentsKey,
      jsonEncode(students.map((s) => s.toJson()).toList()),
    );
    _allowEmptyWrite = false;
    if (!ok) debugPrint('Student list was not written to storage');
    return ok;
  }

  Future<void> _loadCurrent() async {
    currentStudentId = await PreferencesService.instance.loadRaw(_currentKey);
    if (currentStudentId == null || !students.any((s) => s.id == currentStudentId)) {
      currentStudentId = students.isNotEmpty ? students.first.id : null;
      if (currentStudentId != null) {
        await PreferencesService.instance.saveRaw(_currentKey, currentStudentId!);
      }
    }
  }

  Future<void> _ensureDefaultAndMigrate() async {
    if (students.isNotEmpty) return;

    final oldLearned = await PreferencesService.instance.loadSet('learned');
    final oldSaved = await PreferencesService.instance.loadSet('saved');
    final oldProgress = await PreferencesService.instance.loadRaw('learning_state_v2');
    final hasOld = oldLearned.isNotEmpty ||
        oldSaved.isNotEmpty ||
        (oldProgress != null && oldProgress.isNotEmpty);
    if (!hasOld) {
      students = [];
      currentStudentId = null;
      return;
    }

    const defaultId = 'default';
    students = [Student(id: defaultId, name: 'Маълумоти пештара')];
    await _saveStudents();
    if (oldLearned.isNotEmpty) {
      await PreferencesService.instance.saveSet(learnedKey(defaultId), oldLearned);
    }
    if (oldSaved.isNotEmpty) {
      await PreferencesService.instance.saveSet(savedKey(defaultId), oldSaved);
    }
    if (oldProgress != null && oldProgress.isNotEmpty) {
      await PreferencesService.instance.saveRaw(progressKey(defaultId), oldProgress);
    }
    currentStudentId = defaultId;
    await PreferencesService.instance.saveRaw(_currentKey, defaultId);
  }

  Future<Student?> getCurrentStudent() async {
    if (!_initialized) await init();
    try {
      return students.firstWhere((s) => s.id == currentStudentId);
    } catch (_) {
      return students.isNotEmpty ? students.first : null;
    }
  }

  Future<void> setCurrentStudent(String id) async {
    if (!students.any((s) => s.id == id)) return;
    currentStudentId = id;
    await PreferencesService.instance.saveRaw(_currentKey, id);
    await ProgressService.instance.load(key: progressKey(id));
    notifyListeners();
  }

  Future<Student> addStudent(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Ном холӣ аст');
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}_${students.length}';
    final student = Student(id: id, name: trimmed);
    students.add(student);
    final saved = await _saveStudents();
    if (!saved) {
      students.removeWhere((item) => item.id == id);
      notifyListeners();
      throw StateError('Талаба захира нашуд. Боз кӯшиш кунед.');
    }
    if (currentStudentId == null) {
      await setCurrentStudent(id);
    } else {
      notifyListeners();
    }
    return student;
  }

  Future<void> renameStudent(String id, String newName) async {
    final idx = students.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    students[idx] = students[idx].copyWith(name: trimmed);
    final saved = await _saveStudents();
    if (!saved) {
      await _loadStudents();
      return;
    }
    notifyListeners();
  }

  Future<void> deleteStudent(String id) async {
    if (!students.any((s) => s.id == id)) return;
    students.removeWhere((s) => s.id == id);
    if (students.isEmpty) _allowEmptyWrite = true;
    final saved = await _saveStudents();
    if (!saved) {
      await _loadStudents();
      notifyListeners();
      return;
    }
    await PreferencesService.instance.saveSet(learnedKey(id), {});
    await PreferencesService.instance.saveSet(savedKey(id), {});
    await PreferencesService.instance.saveRaw(progressKey(id), '');
    await PreferencesService.instance.saveRaw(wordLearningKey(id), '{"words":{}}');
    WordLearningService.instance.release(id);
    if (currentStudentId == id) {
      currentStudentId = students.isNotEmpty ? students.first.id : null;
      if (currentStudentId != null) {
        await PreferencesService.instance.saveRaw(_currentKey, currentStudentId!);
        await ProgressService.instance.load(key: progressKey());
      } else {
        await PreferencesService.instance.saveRaw(_currentKey, '');
        await ProgressService.instance.load(key: progressKey('none'));
      }
    }
    notifyListeners();
  }

  Student? studentById(String id) {
    try {
      return students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
