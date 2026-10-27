class AnswerModel {
  final String questionId;
  final String userAnswer;
  final bool isCorrect;
  final double score; // 0.0 – 100.0
  final String? feedback;
  final String? audioFilePath;

  const AnswerModel({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.score,
    this.feedback,
    this.audioFilePath,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      questionId: json['question_id']?.toString() ?? '',
      userAnswer: json['user_answer']?.toString() ?? '',
      isCorrect: json['is_correct'] == true,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      feedback: json['feedback']?.toString(),
      audioFilePath: json['audio_file_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
      'score': score,
      'feedback': feedback,
      'audio_file_path': audioFilePath,
    };
  }

  AnswerModel copyWith({
    String? questionId,
    String? userAnswer,
    bool? isCorrect,
    double? score,
    String? feedback,
    String? audioFilePath,
  }) {
    return AnswerModel(
      questionId: questionId ?? this.questionId,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      audioFilePath: audioFilePath ?? this.audioFilePath,
    );
  }

  @override
  String toString() =>
      'AnswerModel(questionId: $questionId, isCorrect: $isCorrect, score: $score)';
}
