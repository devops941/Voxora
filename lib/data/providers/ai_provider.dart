import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/constants/api_constants.dart';

class AiProvider {
  final ApiClient _apiClient;

  AiProvider(this._apiClient);

  /// Sends a [message] to the AI chat endpoint.
  ///
  /// [context] is an optional list of previous messages in
  /// `[{'role': 'user'|'assistant', 'content': '...'}]` format.
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    List<Map<String, String>>? context,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.aiChat,
      data: {
        'message': message,
        'context': context ?? [],
      },
    );
    return response.data ?? {};
  }

  /// Requests AI feedback for a spoken response.
  ///
  /// [audioBase64] is the base-64-encoded audio recording.
  /// [transcript] is the text transcription of the user's speech.
  Future<Map<String, dynamic>> getFeedback({
    required String audioBase64,
    required String transcript,
    String? questionText,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.aiFeedback,
      data: {
        'audio': audioBase64,
        'transcript': transcript,
        'question': questionText,
      },
    );
    return response.data ?? {};
  }

  /// Requests a personalised curriculum plan for the given English [level].
  Future<Map<String, dynamic>> getCurriculumPlan({
    required String level,
    Map<String, dynamic>? preferences,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.aiCurriculum,
      data: {
        'level': level,
        'preferences': ?preferences,
      },
    );
    return response.data ?? {};
  }
}
