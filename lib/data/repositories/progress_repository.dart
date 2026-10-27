import 'package:voxora/data/models/progress_model.dart';
import 'package:voxora/data/providers/progress_provider.dart';

class ProgressRepository {
  final ProgressProvider _progressProvider;

  ProgressRepository(this._progressProvider);

  /// Fetches the progress record for [userId].
  Future<ProgressModel> getProgress(String userId) async {
    return _progressProvider.getProgress(userId);
  }

  /// Pushes updated progress data and returns the refreshed model.
  Future<ProgressModel> updateProgress(Map<String, dynamic> progressData) async {
    return _progressProvider.updateProgress(progressData);
  }
}
