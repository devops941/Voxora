import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/constants/api_constants.dart';
import 'package:voxora/data/models/answer_model.dart';
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
}
