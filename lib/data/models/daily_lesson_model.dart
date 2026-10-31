class DailyLessonModel {
  final int day;
  final int phase;
  final String topic;
  final String objective;
  final List<String> targetSkills;
  final String difficulty;
  final List<String> vocabularyFocus;
  final List<String> grammarFocus;
  final List<String> speakingActivities;
  final List<String> miraQuestions;
  final int expectedDurationMinutes;
  final List<String> evaluationCriteria;
  final String? revisionTask;
  final String status; // 'pending' | 'in_progress' | 'completed'
  final int score;
  final DateTime? completedAt;
  final TeachingContentModel? teachingContent;

  const DailyLessonModel({
    required this.day,
    required this.phase,
    required this.topic,
    required this.objective,
    required this.targetSkills,
    required this.difficulty,
    required this.vocabularyFocus,
    required this.grammarFocus,
    required this.speakingActivities,
    required this.miraQuestions,
    required this.expectedDurationMinutes,
    required this.evaluationCriteria,
    this.revisionTask,
    required this.status,
    required this.score,
    this.completedAt,
    this.teachingContent,
  });

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';

  factory DailyLessonModel.fromJson(Map<String, dynamic> json) {
    return DailyLessonModel(
      day: (json['day'] as num?)?.toInt() ?? 1,
      phase: (json['phase'] as num?)?.toInt() ?? 1,
      topic: json['topic']?.toString() ?? 'Daily Speaking Practice',
      objective: json['objective']?.toString() ?? 'Practice speaking English fluently with Mira.',
      targetSkills: (json['targetSkills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      difficulty: json['difficulty']?.toString() ?? 'Beginner',
      vocabularyFocus: (json['vocabularyFocus'] as List?)?.map((e) => e.toString()).toList() ?? [],
      grammarFocus: (json['grammarFocus'] as List?)?.map((e) => e.toString()).toList() ?? [],
      speakingActivities: (json['speakingActivities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      miraQuestions: (json['miraQuestions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      expectedDurationMinutes: (json['expectedDurationMinutes'] as num?)?.toInt() ?? 15,
      evaluationCriteria: (json['evaluationCriteria'] as List?)?.map((e) => e.toString()).toList() ?? [],
      revisionTask: json['revisionTask']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      score: (json['score'] as num?)?.toInt() ?? 0,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      teachingContent: json['teachingContent'] != null
          ? TeachingContentModel.fromJson(json['teachingContent'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'phase': phase,
      'topic': topic,
      'objective': objective,
      'targetSkills': targetSkills,
      'difficulty': difficulty,
      'vocabularyFocus': vocabularyFocus,
      'grammarFocus': grammarFocus,
      'speakingActivities': speakingActivities,
      'miraQuestions': miraQuestions,
      'expectedDurationMinutes': expectedDurationMinutes,
      'evaluationCriteria': evaluationCriteria,
      'revisionTask': revisionTask,
      'status': status,
      'score': score,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

class SpeechEvaluationScores {
  final int grammar;
  final int fluency;
  final int pronunciation;
  final int overall;

  const SpeechEvaluationScores({
    required this.grammar,
    required this.fluency,
    required this.pronunciation,
    required this.overall,
  });

  factory SpeechEvaluationScores.fromJson(Map<String, dynamic> json) {
    return SpeechEvaluationScores(
      grammar: (json['grammar'] as num?)?.toInt() ?? 0,
      fluency: (json['fluency'] as num?)?.toInt() ?? 0,
      pronunciation: (json['pronunciation'] as num?)?.toInt() ?? 0,
      overall: (json['overall'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grammar': grammar,
      'fluency': fluency,
      'pronunciation': pronunciation,
      'overall': overall,
    };
  }
}

class GrammarCorrection {
  final String original;
  final String corrected;
  final String explanation;

  const GrammarCorrection({
    required this.original,
    required this.corrected,
    required this.explanation,
  });

  factory GrammarCorrection.fromJson(Map<String, dynamic> json) {
    return GrammarCorrection(
      original: json['original']?.toString() ?? '',
      corrected: json['corrected']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'corrected': corrected,
      'explanation': explanation,
    };
  }
}

class SpeechEvaluationModel {
  final String original;
  final String corrected;
  final String explanation;
  final List<String> pronunciationTips;
  final SpeechEvaluationScores scores;
  final String miraReply;
  final String? caseType;
  final String? nextSuggestedQuestion;
  final bool isLessonComplete;

  const SpeechEvaluationModel({
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.pronunciationTips,
    required this.scores,
    required this.miraReply,
    this.caseType,
    this.nextSuggestedQuestion,
    required this.isLessonComplete,
  });

  factory SpeechEvaluationModel.fromJson(Map<String, dynamic> json) {
    return SpeechEvaluationModel(
      original: json['original']?.toString() ?? '',
      corrected: json['corrected']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      pronunciationTips: (json['pronunciationTips'] as List?)?.map((e) => e.toString()).toList() ?? [],
      scores: SpeechEvaluationScores.fromJson(json['scores'] as Map<String, dynamic>? ?? {}),
      miraReply: json['miraReply']?.toString() ?? 'Well done! Keep speaking with confidence.',
      caseType: json['caseType']?.toString(),
      nextSuggestedQuestion: json['nextSuggestedQuestion']?.toString(),
      isLessonComplete: json['isLessonComplete'] == true,
    );
  }
}

class UserProgressModel {
  final int completedDays;
  final int totalDays;
  final int completionPercentage;
  final int currentDay;
  final int streak;
  final int xp;
  final String level;
  final SpeechEvaluationScores averageScores;
  final List<WeakArea> weakAreas;
  final List<RecentAttempt> recentAttempts;
  final List<PhaseStat> phaseStats;
  final bool hasEvaluations;
  final int totalEvaluationsCount;

  const UserProgressModel({
    required this.completedDays,
    required this.totalDays,
    required this.completionPercentage,
    required this.currentDay,
    required this.streak,
    required this.xp,
    required this.level,
    required this.averageScores,
    required this.weakAreas,
    required this.recentAttempts,
    required this.phaseStats,
    this.hasEvaluations = false,
    this.totalEvaluationsCount = 0,
  });

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    final scoresJson = json['averageScores'] as Map<String, dynamic>? ?? {};
    final parsedScores = SpeechEvaluationScores.fromJson(scoresJson);
    final hasEvals = json['hasEvaluations'] == true ||
        (json['totalEvaluationsCount'] as num? ?? 0) > 0 ||
        parsedScores.overall > 0;
    final totalEvals = (json['totalEvaluationsCount'] as num?)?.toInt() ?? (hasEvals ? 1 : 0);

    return UserProgressModel(
      completedDays: (json['completedDays'] as num?)?.toInt() ?? 0,
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 90,
      completionPercentage: (json['completionPercentage'] as num?)?.toInt() ?? 0,
      currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: json['level']?.toString() ?? 'Beginner',
      averageScores: parsedScores,
      weakAreas: (json['weakAreas'] as List?)?.map((e) => WeakArea.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      recentAttempts: (json['recentAttempts'] as List?)?.map((e) => RecentAttempt.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      phaseStats: (json['phaseStats'] as List?)?.map((e) => PhaseStat.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      hasEvaluations: hasEvals,
      totalEvaluationsCount: totalEvals,
    );
  }
}

class WeakArea {
  final String area;
  final String advice;

  const WeakArea({required this.area, required this.advice});

  factory WeakArea.fromJson(Map<String, dynamic> json) {
    return WeakArea(
      area: json['area']?.toString() ?? '',
      advice: json['advice']?.toString() ?? '',
    );
  }
}

class RecentAttempt {
  final int day;
  final String topic;
  final int overallScore;
  final DateTime? createdAt;

  const RecentAttempt({
    required this.day,
    required this.topic,
    required this.overallScore,
    this.createdAt,
  });

  factory RecentAttempt.fromJson(Map<String, dynamic> json) {
    return RecentAttempt(
      day: (json['day'] as num?)?.toInt() ?? 1,
      topic: json['topic']?.toString() ?? '',
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 80,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class PhaseStat {
  final int phase;
  final String title;
  final int completed;
  final int total;

  const PhaseStat({
    required this.phase,
    required this.title,
    required this.completed,
    required this.total,
  });

  double get progressPercentage => total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

  factory PhaseStat.fromJson(Map<String, dynamic> json) {
    return PhaseStat(
      phase: (json['phase'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 30,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// RICH TEACHING CONTENT MODELS (Voice + On-Screen Learning)
// ═══════════════════════════════════════════════════════════════════

class TeachingContentModel {
  final LessonIntro intro;
  final LessonExplanation explanation;
  final List<TeachingStep> stepByStepGuide;
  final RealLifeScenario realLifeScenario;
  final List<VocabularyItem> vocabularyItems;
  final List<GrammarRuleModel> grammarRules;
  final List<CommonMistakeModel> commonMistakes;
  final LessonRecap recap;
  final String spokenScript;

  const TeachingContentModel({
    required this.intro,
    required this.explanation,
    required this.stepByStepGuide,
    required this.realLifeScenario,
    required this.vocabularyItems,
    required this.grammarRules,
    required this.commonMistakes,
    required this.recap,
    required this.spokenScript,
  });

  factory TeachingContentModel.fromJson(Map<String, dynamic> json) {
    return TeachingContentModel(
      intro: LessonIntro.fromJson(json['intro'] as Map<String, dynamic>? ?? {}),
      explanation: LessonExplanation.fromJson(json['explanation'] as Map<String, dynamic>? ?? {}),
      stepByStepGuide: (json['stepByStepGuide'] as List?)
              ?.map((e) => TeachingStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      realLifeScenario: RealLifeScenario.fromJson(json['realLifeScenario'] as Map<String, dynamic>? ?? {}),
      vocabularyItems: (json['vocabularyItems'] as List?)
              ?.map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      grammarRules: (json['grammarRules'] as List?)
              ?.map((e) => GrammarRuleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      commonMistakes: (json['commonMistakes'] as List?)
              ?.map((e) => CommonMistakeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recap: LessonRecap.fromJson(json['recap'] as Map<String, dynamic>? ?? {}),
      spokenScript: json['spokenScript']?.toString() ?? '',
    );
  }
}

class LessonIntro {
  final String greeting;
  final String objective;
  final String whyLearnThis;
  final String? tamilOverview;

  const LessonIntro({
    required this.greeting,
    required this.objective,
    required this.whyLearnThis,
    this.tamilOverview,
  });

  factory LessonIntro.fromJson(Map<String, dynamic> json) {
    return LessonIntro(
      greeting: json['greeting']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      whyLearnThis: json['whyLearnThis']?.toString() ?? '',
      tamilOverview: json['tamilOverview']?.toString(),
    );
  }
}

class LessonExplanation {
  final String concept;
  final String whenToUse;
  final String whyToUse;
  final String? tamilNotes;

  const LessonExplanation({
    required this.concept,
    required this.whenToUse,
    required this.whyToUse,
    this.tamilNotes,
  });

  factory LessonExplanation.fromJson(Map<String, dynamic> json) {
    return LessonExplanation(
      concept: json['concept']?.toString() ?? '',
      whenToUse: json['whenToUse']?.toString() ?? '',
      whyToUse: json['whyToUse']?.toString() ?? '',
      tamilNotes: json['tamilNotes']?.toString(),
    );
  }
}

class TeachingStep {
  final int stepNumber;
  final String title;
  final String explanation;
  final String practicalExample;
  final String? tamilHint;

  const TeachingStep({
    required this.stepNumber,
    required this.title,
    required this.explanation,
    required this.practicalExample,
    this.tamilHint,
  });

  factory TeachingStep.fromJson(Map<String, dynamic> json) {
    return TeachingStep(
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      practicalExample: json['practicalExample']?.toString() ?? '',
      tamilHint: json['tamilHint']?.toString(),
    );
  }
}

class RealLifeScenario {
  final String title;
  final String context;
  final List<DialogueLine> dialogue;

  const RealLifeScenario({
    required this.title,
    required this.context,
    required this.dialogue,
  });

  factory RealLifeScenario.fromJson(Map<String, dynamic> json) {
    return RealLifeScenario(
      title: json['title']?.toString() ?? 'Real-Life Scenario',
      context: json['context']?.toString() ?? '',
      dialogue: (json['dialogue'] as List?)
              ?.map((e) => DialogueLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DialogueLine {
  final String speaker;
  final String english;
  final String? tamil;
  final String? notes;

  const DialogueLine({
    required this.speaker,
    required this.english,
    this.tamil,
    this.notes,
  });

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speaker: json['speaker']?.toString() ?? 'MIRA',
      english: json['english']?.toString() ?? '',
      tamil: json['tamil']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class VocabularyItem {
  final String word;
  final String meaning;
  final String? tamilMeaning;
  final String exampleSentence;
  final String? tamilExample;

  const VocabularyItem({
    required this.word,
    required this.meaning,
    this.tamilMeaning,
    required this.exampleSentence,
    this.tamilExample,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      word: json['word']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      tamilMeaning: json['tamilMeaning']?.toString(),
      exampleSentence: json['exampleSentence']?.toString() ?? '',
      tamilExample: json['tamilExample']?.toString(),
    );
  }
}

class GrammarRuleModel {
  final String ruleName;
  final String explanation;
  final String? formula;
  final List<String> examples;
  final String? tamilExplanation;

  const GrammarRuleModel({
    required this.ruleName,
    required this.explanation,
    this.formula,
    required this.examples,
    this.tamilExplanation,
  });

  factory GrammarRuleModel.fromJson(Map<String, dynamic> json) {
    return GrammarRuleModel(
      ruleName: json['ruleName']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      formula: json['formula']?.toString(),
      examples: (json['examples'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tamilExplanation: json['tamilExplanation']?.toString(),
    );
  }
}

class CommonMistakeModel {
  final String incorrect;
  final String correct;
  final String explanation;
  final String? tamilExplanation;

  const CommonMistakeModel({
    required this.incorrect,
    required this.correct,
    required this.explanation,
    this.tamilExplanation,
  });

  factory CommonMistakeModel.fromJson(Map<String, dynamic> json) {
    return CommonMistakeModel(
      incorrect: json['incorrect']?.toString() ?? '',
      correct: json['correct']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      tamilExplanation: json['tamilExplanation']?.toString(),
    );
  }
}

class LessonRecap {
  final List<String> summaryPoints;
  final String comprehensionQuestion;
  final String suggestedAnswer;

  const LessonRecap({
    required this.summaryPoints,
    required this.comprehensionQuestion,
    required this.suggestedAnswer,
  });

  factory LessonRecap.fromJson(Map<String, dynamic> json) {
    return LessonRecap(
      summaryPoints: (json['summaryPoints'] as List?)?.map((e) => e.toString()).toList() ?? [],
      comprehensionQuestion: json['comprehensionQuestion']?.toString() ?? '',
      suggestedAnswer: json['suggestedAnswer']?.toString() ?? '',
    );
  }
}
