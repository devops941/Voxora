import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/constants/api_constants.dart';
import 'package:voxora/data/models/final_assessment_model.dart';

class FinalAssessmentProvider {
  final ApiClient _apiClient;

  FinalAssessmentProvider(this._apiClient);

  Future<Map<String, dynamic>> checkEligibility(String level) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.finalAssessmentEligibility,
      queryParameters: {'level': level},
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<FinalAssessmentModel> startAssessment(String level) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.finalAssessmentStart,
      data: {'level': level},
    );
    return FinalAssessmentModel.fromJson(response.data ?? {});
  }

  Future<AssessmentResultModel> submitAssessment(
    String assessmentId,
    Map<String, int> answers,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.finalAssessmentSubmit,
      data: {'assessmentId': assessmentId, 'answers': answers},
    );
    return AssessmentResultModel.fromJson(response.data ?? {});
  }

  Future<List<AttemptSummaryModel>> getAttempts(String level) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.finalAssessmentAttempts,
      queryParameters: level.isNotEmpty ? {'level': level} : null,
    );
    final list = response.data?['data'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AttemptSummaryModel.fromJson)
        .toList();
  }
}
