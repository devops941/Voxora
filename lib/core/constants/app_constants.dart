class AppConstants {
  AppConstants._();

  static const String appName = 'Voxora';
  static const int splashDuration = 3;
  static const int apiTimeout = 30;
  static const int maxRetries = 3;

  static const List<String> englishLevels = [
    'Beginner',
    'Elementary',
    'Intermediate',
    'Upper-Intermediate',
    'Advanced',
  ];

  // Lesson types
  static const String lessonTypeVocabulary = 'vocabulary';
  static const String lessonTypeGrammar = 'grammar';
  static const String lessonTypeSpeaking = 'speaking';
  static const String lessonTypeListening = 'listening';

  // Question types
  static const String questionTypeMultipleChoice = 'multiple_choice';
  static const String questionTypeSpeaking = 'speaking';
  static const String questionTypeFillBlank = 'fill_blank';

  // Storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user_data';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keySelectedLevel = 'selected_level';
  static const String keyThemeMode = 'theme_mode';

  // Animation durations (ms)
  static const int animationFast = 150;
  static const int animationNormal = 300;
  static const int animationSlow = 500;

  // Pagination
  static const int defaultPageSize = 20;

  // Weekly goal default (minutes)
  static const int defaultWeeklyGoalMinutes = 150;
}
