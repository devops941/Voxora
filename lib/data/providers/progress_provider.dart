import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/constants/api_constants.dart';
import 'package:voxora/data/models/progress_model.dart';

class ProgressProvider {
  final ApiClient _apiClient;

  ProgressProvider(this._apiClient);

  /// Fetches the progress record for the given [userId].
  Future<ProgressModel> getProgress(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.progress,
      queryParameters: {'user_id': userId},
    );
    final data = response.data ?? {};
    return ProgressModel.fromJson(data['data'] ?? data);
  }

  /// Pushes an updated [progressData] map to the server and returns the
  /// refreshed [ProgressModel].
  Future<ProgressModel> updateProgress(Map<String, dynamic> progressData) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.progressUpdate,
      data: progressData,
    );
    final data = response.data ?? {};
    return ProgressModel.fromJson(data['data'] ?? data);
  }
}
