import 'package:voxora/data/models/final_assessment_model.dart';
import 'package:voxora/data/providers/final_assessment_provider.dart';

class FinalAssessmentRepository {
  final FinalAssessmentProvider _provider;

  FinalAssessmentRepository(this._provider);

  Future<Map<String, dynamic>> checkEligibility(String level) =>
      _provider.checkEligibility(level);

  Future<FinalAssessmentModel> startAssessment(String level) =>
      _provider.startAssessment(level);

  Future<AssessmentResultModel> submitAssessment(
    String assessmentId,
    Map<String, int> answers,
  ) =>
      _provider.submitAssessment(assessmentId, answers);

  Future<List<AttemptSummaryModel>> getAttempts(String level) =>
      _provider.getAttempts(level);
}
