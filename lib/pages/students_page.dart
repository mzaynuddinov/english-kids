import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/student_service.dart';
import '../theme.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Student> students = [];
  String? currentId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await StudentService.instance.init();
      if (!mounted) return;
      setState(() {
        students = List.from(StudentService.instance.students);
        currentId = StudentService.instance.currentStudentId;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Хатогӣ дар боркунӣ: $e')),
      );
    }
  }

  Future<void> _addStudent() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Талабаи нав'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Номи талаба / фарзанд',
            hintText: 'Масалан: Аҳмад',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Захира кардан'),
          ),
        ],
      ),
    );

    if (name == null) return;
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ном холӣ буда наметавонад')),
        );
      }
      return;
    }

    try {
      await StudentService.instance.addStudent(name);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('«$name» илова шуд')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатогӣ: $e')),
        );
      }
    }
  }

  Future<void> _switchTo(String id) async {
    try {
      await StudentService.instance.setCurrentStudent(id);
      await _load();
      if (mounted) {
        final name = StudentService.instance.studentById(id)?.name ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Талабаи ҷорӣ: $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатогӣ дар гузариш: $e')),
        );
      }
    }
  }

  Future<void> _rename(Student student) async {
    final controller = TextEditingController(text: student.name);
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Захира кардан'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await StudentService.instance.renameStudent(student.id, name);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатогӣ: $e')),
        );
      }
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
    if (confirm != true) return;
    try {
      await StudentService.instance.deleteStudent(student.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатогӣ: $e')),
        );
      }
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
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Ҳанӯз талаба нест'),
                      const SizedBox(height: 16),
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
                        leading: CircleAvatar(
                          backgroundColor: isCurrent ? emerald600 : teal600,
                          child: Text(
                            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
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
                            if (value == 'switch') _switchTo(s.id);
                            if (value == 'rename') _rename(s);
                            if (value == 'delete') _delete(s);
                          },
                          itemBuilder: (_) => [
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
