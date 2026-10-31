import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://voxora-iota-plum.vercel.app/api/v1';
  }

  static int get timeoutMs =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleAuth = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';

  // User endpoints
  static const String userMe = '/users/me';
  static const String userUpdate = '/users/me';
  static const String userAvatar = '/users/me/avatar';

  // Curriculum endpoints
  static const String curriculum = '/curriculum';

  // Dashboard endpoint
  static const String dashboard = '/dashboard';

  // Lesson endpoints
  static const String lessons = '/lessons';
  static const String lessonById = '/lessons/{id}';
  static const String lessonSubmit = '/lessons/{id}/submit';
  static const String lessonToday = '/lessons/today';
  static const String lessonEvaluateResponse = '/lessons/evaluate-response';
  static const String lessonComplete = '/lessons/complete';
  static const String lessonPlan = '/lessons/plan';
  static const String lessonSetLevel = '/lessons/set-level';
  static const String lessonDay = '/lessons/day/{day}';
  static const String lessonProgress = '/lessons/progress';
  static const String lessonAskDoubt = '/lessons/ask-doubt';

  // Final Assessment endpoints
  static const String finalAssessmentEligibility = '/final-assessment/eligibility';
  static const String finalAssessmentStart = '/final-assessment/start';
  static const String finalAssessmentSubmit = '/final-assessment/submit';
  static const String finalAssessmentAttempts = '/final-assessment/attempts';

  // Certificate endpoints
  static const String certificateGenerate = '/certificate';
  static const String certificateDownload = '/certificate/download/{certificateId}';

  // AI endpoints
  static const String aiChat = '/ai/chat';
  static const String aiFeedback = '/ai/feedback';
  static const String aiCurriculum = '/ai/curriculum';
  static const String aiAssessSpeech = '/ai/assess-speech';

  // Speech endpoints
  static const String speechAnalyze = '/speech/analyze';

  // Progress endpoints
  static const String progress = '/lessons/progress';
  static const String progressUpdate = '/progress/update';
  static const String progressStreak = '/progress/streak';

  /// Builds a URL by replacing path parameters.
  /// Example: buildUrl('/lessons/{id}', {'id': '123'}) => '/lessons/123'
  static String buildUrl(String path, Map<String, String> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
