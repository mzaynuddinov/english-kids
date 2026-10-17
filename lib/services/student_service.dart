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

  String learnedKey([String? id]) => 'learned_${id ?? currentStudentId ?? "default"}';
  String savedKey([String? id]) => 'saved_${id ?? currentStudentId ?? "default"}';
  String progressKey([String? id]) => 'learning_state_v2_${id ?? currentStudentId ?? "default"}';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _loadStudents();
      await _ensureDefaultAndMigrate();
      await _loadCurrent();
      notifyListeners();
    } catch (error) {
      _initialized = false;
      rethrow;
    }
  }

  @visibleForTesting
  void debugReset() {
    students = [];
    currentStudentId = null;
    _initialized = false;
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
      students = [];
    }
  }

  Future<void> _saveStudents() async {
    await PreferencesService.instance.saveRaw(
      _studentsKey,
      jsonEncode(students.map((s) => s.toJson()).toList()),
    );
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
    if (currentStudentId == null) await init();
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
    await _saveStudents();
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
    await _saveStudents();
    notifyListeners();
  }

  Future<void> deleteStudent(String id) async {
    if (!students.any((s) => s.id == id)) return;
    students.removeWhere((s) => s.id == id);
    await _saveStudents();
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
