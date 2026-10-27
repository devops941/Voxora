class QuestionModel {
  final String id;
  final String lessonId;
  final String text;
  final String type; // multiple_choice | speaking | fill_blank
  final List<String> options;
  final String correctAnswer;
  final String? audioUrl;

  const QuestionModel({
    required this.id,
    required this.lessonId,
    required this.text,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.audioUrl,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final List<String> parsedOptions;
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    } else {
      parsedOptions = [];
    }

    return QuestionModel(
      id: json['id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'multiple_choice',
      options: parsedOptions,
      correctAnswer: json['correct_answer']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'text': text,
      'type': type,
      'options': options,
      'correct_answer': correctAnswer,
      'audio_url': audioUrl,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? lessonId,
    String? text,
    String? type,
    List<String>? options,
    String? correctAnswer,
    String? audioUrl,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  @override
  String toString() =>
      'QuestionModel(id: $id, type: $type, lessonId: $lessonId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
