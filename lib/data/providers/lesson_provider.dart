import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/constants/api_constants.dart';
import 'package:voxora/data/models/answer_model.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/data/models/lesson_model.dart';

class LessonProvider {
  final ApiClient _apiClient;

  LessonProvider(this._apiClient);

  /// Retrieves lessons filtered by [level].
  Future<List<LessonModel>> getLessons({String? level}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.lessons,
      queryParameters: level != null ? {'level': level} : null,
    );

    final data = response.data;
    final rawList = data?['data'] ?? data?['lessons'] ?? [];
    if (rawList is! List) return [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(LessonModel.fromJson)
        .toList();
  }

  /// Retrieves a single lesson by its [id].
  Future<LessonModel> getLessonById(String id) async {
    final path = ApiConstants.buildUrl(ApiConstants.lessonById, {'id': id});
    final response = await _apiClient.get<Map<String, dynamic>>(path);
    final data = response.data ?? {};
    return LessonModel.fromJson(data['data'] ?? data);
  }

  /// Submits an [answer] for a question within a lesson.
  Future<AnswerModel> submitAnswer({
    required String lessonId,
    required AnswerModel answer,
  }) async {
    final path = ApiConstants.buildUrl(
      ApiConstants.lessonSubmit,
      {'id': lessonId},
    );
    final response = await _apiClient.post<Map<String, dynamic>>(
      path,
      data: answer.toJson(),
    );
    final data = response.data ?? {};
    return AnswerModel.fromJson(data['data'] ?? data);
  }

  /// Retrieves today's scheduled 90-day lesson from backend.
  Future<Map<String, dynamic>> getTodayLesson() async {
    final response = await _apiClient.get<Map<String, dynamic>>(ApiConstants.lessonToday);
    final data = response.data?['data'] ?? response.data ?? {};
    return data as Map<String, dynamic>;
  }

  /// Retrieves aggregated dashboard data from MongoDB.
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.get<Map<String, dynamic>>(ApiConstants.dashboard);
    final data = response.data?['data'] ?? response.data ?? {};
    return data as Map<String, dynamic>;
  }

  /// Retrieves a specific day's lesson (Day 1 - 90).
  Future<Map<String, dynamic>> getDayLesson(int day, {String? level}) async {
    final path = ApiConstants.buildUrl(ApiConstants.lessonDay, {'day': day.toString()});
    final response = await _apiClient.get<Map<String, dynamic>>(
      path,
      queryParameters: level != null ? {'level': level} : null,
    );
    final data = response.data?['data'] ?? response.data ?? {};
    return data as Map<String, dynamic>;
  }

  /// Retrieves the complete 90-day learning plan, optionally for a specific level.
  Future<Map<String, dynamic>> getPlan({String? level}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.lessonPlan,
      queryParameters: level != null ? {'level': level} : null,
    );
    final data = response.data?['data'] ?? response.data ?? {};
    return data as Map<String, dynamic>;
  }

  /// Sets the user's active learning curriculum track level.
  Future<Map<String, dynamic>> setLevel(String level) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.lessonSetLevel,
      data: {'level': level},
    );
    final data = response.data?['data'] ?? response.data ?? {};
    return data as Map<String, dynamic>;
  }

  /// Evaluates spoken user response against Mira's question with real-time feedback.
  Future<SpeechEvaluationModel> evaluateSpokenResponse({
    required int day,
    required String miraQuestion,
    required String userTranscript,
    int durationSeconds = 10,
    String? topic,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.lessonEvaluateResponse,
      data: {
        'day': day,
        'miraQuestion': miraQuestion,
        'userTranscript': userTranscript,
        'durationSeconds': durationSeconds,
        'topic': ?topic,
      },
    );
    final data = response.data?['data'] ?? response.data ?? {};
    return SpeechEvaluationModel.fromJson(data as Map<String, dynamic>);
  }

  /// Marks a daily lesson as completed in MongoDB.
  Future<Map<String, dynamic>> completeLesson({
    required int day,
    required int score,
    int timeSpentSeconds = 600,
    List<dynamic>? exchanges,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.lessonComplete,
      data: {
        'day': day,
        'score': score,
        'timeSpentSeconds': timeSpentSeconds,
        'exchanges': exchanges ?? [],
      },
    );
    final data = response.data?['data'] ?? response.data ?? {};
    return data as Map<String, dynamic>;
  }

  /// Retrieves user's comprehensive learning progress & analytics.
  Future<UserProgressModel> getUserProgress() async {
    final response = await _apiClient.get<Map<String, dynamic>>(ApiConstants.lessonProgress);
    final data = response.data?['data'] ?? response.data ?? {};
    return UserProgressModel.fromJson(data as Map<String, dynamic>);
  }

  /// Asks a doubt or question to MIRA during the lesson.
  Future<String> askDoubt({
    required int day,
    required String userQuestion,
    String? topic,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.lessonAskDoubt,
      data: {
        'day': day,
        'userQuestion': userQuestion,
        'topic': topic,
      },
    );
    final data = response.data?['data'] ?? response.data ?? {};
    return data['answer']?.toString() ?? 'Keep practicing with confidence!';
  }
}

