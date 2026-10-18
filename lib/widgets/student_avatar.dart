import 'dart:io';

import 'package:flutter/material.dart';

import '../models/student.dart';
import '../theme.dart';

class StudentAvatar extends StatelessWidget {
  final Student? student;
  final double radius;

  const StudentAvatar({super.key, required this.student, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final name = student?.name ?? '';
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
    final path = student?.photoPath;
    ImageProvider? image;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        image = ResizeImage(FileImage(file), width: (radius * 4).round().clamp(48, 256).toInt());
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: teal600,
      backgroundImage: image,
      child: image == null
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.72,
              ),
            )
          : null,
    );
  }
}
