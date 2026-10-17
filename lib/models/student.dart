import 'dart:convert';

class Student {
  final String id;
  final String name;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Талаба',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Student copyWith({String? name}) => Student(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
      );
}
