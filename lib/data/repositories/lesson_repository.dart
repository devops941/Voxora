import 'package:voxora/data/models/answer_model.dart';
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
}
