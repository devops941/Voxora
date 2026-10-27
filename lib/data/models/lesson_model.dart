class LessonModel {
  final String id;
  final String title;
  final String description;
  final String level;
  final int duration; // in minutes
  final String type; // vocabulary | grammar | speaking | listening
  final bool isCompleted;
  final int order;

  const LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.type,
    required this.isCompleted,
    required this.order,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      level: json['level']?.toString() ?? 'Beginner',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'vocabulary',
      isCompleted: json['is_completed'] == true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level': level,
      'duration': duration,
      'type': type,
      'is_completed': isCompleted,
      'order': order,
    };
  }

  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? level,
    int? duration,
    String? type,
    bool? isCompleted,
    int? order,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  @override
  String toString() =>
      'LessonModel(id: $id, title: $title, type: $type, level: $level)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
