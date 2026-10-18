import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/profile_photo.dart';
import '../services/student_service.dart';
import '../theme.dart';
import '../widgets/student_avatar.dart';
import 'photo_crop_page.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Student> students = [];
  String? currentId;
  bool loading = true;
  bool _adding = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    StudentService.instance.addListener(_onStudents);
    _load();
  }

  @override
  void dispose() {
    StudentService.instance.removeListener(_onStudents);
    super.dispose();
  }

  void _onStudents() {
    if (!mounted) return;
    setState(() {
      students = List.from(StudentService.instance.students);
      currentId = StudentService.instance.currentStudentId;
      loading = false;
    });
  }

  Future<void> _load() async {
    if (mounted && !loading) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      await StudentService.instance.init();
      if (!mounted) return;
      setState(() {
        students = List.from(StudentService.instance.students);
        currentId = StudentService.instance.currentStudentId;
        loading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        students = List.from(StudentService.instance.students);
        currentId = StudentService.instance.currentStudentId;
        loading = false;
        loadError = 'Рӯйхат бор нашуд. Боз кӯшиш кунед.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Хатогӣ дар боркунӣ: $e')),
      );
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addStudent() async {
    if (_adding) return;
    final controller = TextEditingController();
    var closed = false;
    var picked = false;
    Uint8List? photo;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Талабаи нав'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Номи талаба / фарзанд',
                  hintText: 'Масалан: Аҳмад',
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (value) {
                  if (closed) return;
                  closed = true;
                  Navigator.pop(ctx, value.trim());
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    try {
                      final bytes = await pickCroppedProfilePhoto(ctx);
                      if (bytes == null) return;
                      setLocal(() {
                        photo = bytes;
                        picked = true;
                      });
                    } catch (_) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Галерея кушода нашуд. Иҷозатро санҷед.')),
                      );
                    }
                  },
                  child: Text(picked ? 'Акс интихоб шуд' : 'Иловаи акс'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (closed) return;
                closed = true;
                Navigator.pop(ctx);
              },
              child: const Text('Бекор'),
            ),
            FilledButton(
              onPressed: () {
                if (closed) return;
                closed = true;
                Navigator.pop(ctx, controller.text.trim());
              },
              child: const Text('Захира кардан'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (name == null || !mounted) return;
    if (name.isEmpty) {
      _toast('Ном холӣ буда наметавонад');
      return;
    }

    _adding = true;
    try {
      final future = StudentService.instance.addStudent(name);
      _toast('«$name» илова шуд');
      final created = await future;
      final bytes = photo;
      if (bytes != null) {
        final folder = await ProfilePhotoStore.appFolder();
        final path = await ProfilePhotoStore.saveBytes(
          folder,
          '${created.id}_${DateTime.now().microsecondsSinceEpoch}',
          bytes,
        );
        try {
          await StudentService.instance.setPhoto(created.id, path);
        } catch (_) {
          await ProfilePhotoStore.deleteIfOwned(path);
          rethrow;
        }
      }
    } catch (e) {
      _toast('Хатогӣ: $e');
    } finally {
      _adding = false;
    }
  }

  Future<void> _switchTo(String id) async {
    final name = StudentService.instance.studentById(id)?.name ?? '';
    try {
      final future = StudentService.instance.setCurrentStudent(id);
      _toast('Талабаи ҷорӣ: $name');
      await future;
    } catch (e) {
      _toast('Хатогӣ дар гузариш: $e');
    }
  }

  Future<void> _changePhoto(Student student) async {
    try {
      final bytes = await pickCroppedProfilePhoto(context);
      if (bytes == null || !mounted) return;
      final folder = await ProfilePhotoStore.appFolder();
      final path = await ProfilePhotoStore.saveBytes(
        folder,
        '${student.id}_${DateTime.now().microsecondsSinceEpoch}',
        bytes,
      );
      try {
        await StudentService.instance.setPhoto(student.id, path);
      } catch (_) {
        await ProfilePhotoStore.deleteIfOwned(path);
        rethrow;
      }
      if (mounted) _toast('Акс захира шуд');
    } catch (error) {
      _toast('Акс захира нашуд. Иҷозати галереяро санҷед.');
    }
  }

  Future<void> _rename(Student student) async {
    final controller = TextEditingController(text: student.name);
    var closed = false;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тағйири ном'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Номи нав'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (closed) return;
              closed = true;
              Navigator.pop(ctx);
            },
            child: const Text('Бекор'),
          ),
          FilledButton(
            onPressed: () {
              if (closed) return;
              closed = true;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Захира кардан'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final future = StudentService.instance.renameStudent(student.id, name);
      _toast('Ном иваз шуд');
      await future;
    } catch (e) {
      _toast('Хатогӣ: $e');
    }
  }

  Future<void> _delete(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нест кардан'),
        content: Text('Талабаи «${student.name}» ва ҳамаи пешрафти ӯ нест карда шавад?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Бекор')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Нест'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final future = StudentService.instance.deleteStudent(student.id);
      _toast('«${student.name}» аз рӯйхат гирифта шуд');
      await future;
    } catch (e) {
      _toast('Хатогӣ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Талабагон / Фарзандон'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _addStudent,
            tooltip: '+ Илова кардани талаба',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(loadError == null ? Icons.people_outline : Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(loadError ?? 'Ҳанӯз талаба нест'),
                      const SizedBox(height: 16),
                      if (loadError != null) ...[
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Боз кӯшиш'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FilledButton.icon(
                        onPressed: _addStudent,
                        icon: const Icon(Icons.person_add),
                        label: const Text('+ Илова кардани талаба'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final isCurrent = s.id == currentId;
                    return Card(
                      color: isCurrent ? const Color(0xFFECFDF5) : null,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: StudentAvatar(student: s, radius: 22),
                        title: Text(
                          s.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isCurrent ? emerald700 : null,
                          ),
                        ),
                        subtitle: Text(isCurrent ? 'Талабаи ҷорӣ' : 'Барои интихоб пахш кунед'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'photo') unawaited(_changePhoto(s));
                            if (value == 'switch') _switchTo(s.id);
                            if (value == 'rename') _rename(s);
                            if (value == 'delete') _delete(s);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'photo', child: Text('Акс')),
                            if (!isCurrent)
                              const PopupMenuItem(value: 'switch', child: Text('Интихоб кардан')),
                            const PopupMenuItem(value: 'rename', child: Text('Тағйири ном')),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Нест кардан', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: isCurrent ? null : () => _switchTo(s.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addStudent,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('+ Илова кардани талаба'),
            ),
    );
  }
}
