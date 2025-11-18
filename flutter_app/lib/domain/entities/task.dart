class Task {
  // Entidad que representa una tarea en el dominio de negocio
  final String id;
  final String title;
  final bool completed;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.completed == completed &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ completed.hashCode ^ updatedAt.hashCode;
  }
}