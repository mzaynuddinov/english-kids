class Student {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? photoPath;

  Student({
    required this.id,
    required this.name,
    DateTime? createdAt,
    this.photoPath,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        if (photoPath != null && photoPath!.isNotEmpty) 'photoPath': photoPath,
      };

  factory Student.fromJson(Map<String, dynamic> json) {
    final photo = json['photoPath'] as String?;
    return Student(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Талаба',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      photoPath: photo == null || photo.isEmpty ? null : photo,
    );
  }

  Student copyWith({String? name, String? photoPath, bool clearPhoto = false}) => Student(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      );
}
