class ProgressModel {
  final String userId;
  final int totalLessons;
  final int completedLessons;
  final int currentStreak; // days
  final int longestStreak; // days
  final int totalMinutes;
  final int weeklyGoal; // minutes
  final int weeklyProgress; // minutes this week
  final String level;
  final int xpPoints;

  const ProgressModel({
    required this.userId,
    required this.totalLessons,
    required this.completedLessons,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalMinutes,
    required this.weeklyGoal,
    required this.weeklyProgress,
    required this.level,
    required this.xpPoints,
  });

  /// Completion percentage as a value between 0.0 and 1.0.
  double get completionPercentage {
    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons).clamp(0.0, 1.0);
  }

  /// Weekly goal progress as a value between 0.0 and 1.0.
  double get weeklyGoalPercentage {
    if (weeklyGoal == 0) return 0.0;
    return (weeklyProgress / weeklyGoal).clamp(0.0, 1.0);
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      userId: json['user_id']?.toString() ?? '',
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
      weeklyGoal: (json['weekly_goal'] as num?)?.toInt() ?? 150,
      weeklyProgress: (json['weekly_progress'] as num?)?.toInt() ?? 0,
      level: json['level']?.toString() ?? 'Beginner',
      xpPoints: (json['xp_points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_lessons': totalLessons,
      'completed_lessons': completedLessons,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_minutes': totalMinutes,
      'weekly_goal': weeklyGoal,
      'weekly_progress': weeklyProgress,
      'level': level,
      'xp_points': xpPoints,
    };
  }

  ProgressModel copyWith({
    String? userId,
    int? totalLessons,
    int? completedLessons,
    int? currentStreak,
    int? longestStreak,
    int? totalMinutes,
    int? weeklyGoal,
    int? weeklyProgress,
    String? level,
    int? xpPoints,
  }) {
    return ProgressModel(
      userId: userId ?? this.userId,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      level: level ?? this.level,
      xpPoints: xpPoints ?? this.xpPoints,
    );
  }

  @override
  String toString() =>
      'ProgressModel(userId: $userId, completed: $completedLessons/$totalLessons, streak: $currentStreak)';
}
