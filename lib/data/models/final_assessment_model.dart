class AssessmentQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int marks;

  const AssessmentQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.marks,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      marks: (json['marks'] as num?)?.toInt() ?? 4,
    );
  }
}

class FinalAssessmentModel {
  final String assessmentId;
  final String level;
  final List<AssessmentQuestion> questions;

  const FinalAssessmentModel({
    required this.assessmentId,
    required this.level,
    required this.questions,
  });

  factory FinalAssessmentModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return FinalAssessmentModel(
      assessmentId: data['assessmentId'] as String? ?? '',
      level: data['level'] as String? ?? '',
      questions: (data['questions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AssessmentQuestion.fromJson)
              .toList() ??
          [],
    );
  }
}

class AssessmentResultModel {
  final String assessmentId;
  final int score;
  final double percentage;
  final int correctAnswers;
  final int totalQuestions;
  final int totalMarks;
  final String status;
  final String level;
  final bool isTestMode;

  const AssessmentResultModel({
    required this.assessmentId,
    required this.score,
    required this.percentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.totalMarks,
    required this.status,
    required this.level,
    required this.isTestMode,
  });

  bool get isPassed => status == 'pass';

  factory AssessmentResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AssessmentResultModel(
      assessmentId: data['assessmentId'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0.0,
      correctAnswers: (data['correctAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 25,
      totalMarks: (data['totalMarks'] as num?)?.toInt() ?? 100,
      status: data['status'] as String? ?? 'fail',
      level: data['level'] as String? ?? '',
      isTestMode: data['isTestMode'] as bool? ?? false,
    );
  }
}

class AttemptSummaryModel {
  final String id;
  final String level;
  final int score;
  final double percentage;
  final int correctAnswers;
  final String status;
  final int attemptNumber;
  final bool isTestMode;
  final DateTime? submittedAt;

  const AttemptSummaryModel({
    required this.id,
    required this.level,
    required this.score,
    required this.percentage,
    required this.correctAnswers,
    required this.status,
    required this.attemptNumber,
    required this.isTestMode,
    this.submittedAt,
  });

  bool get isPassed => status == 'pass';

  factory AttemptSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttemptSummaryModel(
      id: json['id'] as String? ?? '',
      level: json['level'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'fail',
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
      isTestMode: json['isTestMode'] as bool? ?? false,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }
}
