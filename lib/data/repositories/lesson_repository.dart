import 'package:voxora/data/models/answer_model.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/data/models/lesson_model.dart';
import 'package:voxora/data/providers/lesson_provider.dart';

class LessonRepository {
  final LessonProvider _lessonProvider;

  LessonRepository(this._lessonProvider);

  /// Returns all lessons, optionally filtered by [level].
  Future<List<LessonModel>> getLessons({String? level}) async {
    return _lessonProvider.getLessons(level: level);
  }

  /// Returns a single lesson by [id].
  Future<LessonModel> getLessonById(String id) async {
    return _lessonProvider.getLessonById(id);
  }

  /// Submits an [answer] for the given [lessonId] and returns evaluated result.
  Future<AnswerModel> submitAnswer({
    required String lessonId,
    required AnswerModel answer,
  }) async {
    return _lessonProvider.submitAnswer(
      lessonId: lessonId,
      answer: answer,
    );
  }

  /// Retrieves today's scheduled 90-day lesson from backend.
  Future<Map<String, dynamic>> getTodayLesson() async {
    return _lessonProvider.getTodayLesson();
  }

  /// Retrieves aggregated dashboard data from MongoDB.
  Future<Map<String, dynamic>> getDashboard() async {
    return _lessonProvider.getDashboard();
  }

  /// Retrieves a specific day's lesson (Day 1 - 90).
  Future<Map<String, dynamic>> getDayLesson(int day, {String? level}) async {
    return _lessonProvider.getDayLesson(day, level: level);
  }

  /// Retrieves the complete 90-day learning plan, optionally filtered by [level].
  Future<Map<String, dynamic>> getPlan({String? level}) async {
    return _lessonProvider.getPlan(level: level);
  }

  /// Sets the user's active learning curriculum track level.
  Future<Map<String, dynamic>> setLevel(String level) async {
    return _lessonProvider.setLevel(level);
  }

  /// Evaluates spoken user response against Mira's question with real-time feedback.
  Future<SpeechEvaluationModel> evaluateSpokenResponse({
    required int day,
    required String miraQuestion,
    required String userTranscript,
    int durationSeconds = 10,
    String? topic,
  }) async {
    return _lessonProvider.evaluateSpokenResponse(
      day: day,
      miraQuestion: miraQuestion,
      userTranscript: userTranscript,
      durationSeconds: durationSeconds,
      topic: topic,
    );
  }

  /// Marks a daily lesson as completed in MongoDB.
  Future<Map<String, dynamic>> completeLesson({
    required int day,
    required int score,
    int timeSpentSeconds = 600,
    List<dynamic>? exchanges,
  }) async {
    return _lessonProvider.completeLesson(
      day: day,
      score: score,
      timeSpentSeconds: timeSpentSeconds,
      exchanges: exchanges,
    );
  }

  /// Retrieves user's comprehensive learning progress & analytics.
  Future<UserProgressModel> getUserProgress() async {
    return _lessonProvider.getUserProgress();
  }

  /// Asks a doubt or question to MIRA during the lesson.
  Future<String> askDoubt({
    required int day,
    required String userQuestion,
    String? topic,
  }) async {
    return _lessonProvider.askDoubt(
      day: day,
      userQuestion: userQuestion,
      topic: topic,
    );
  }
}

