import 'package:get/get.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class ProgressController extends GetxController {
  final LessonRepository _lessonRepository;

  ProgressController({LessonRepository? lessonRepository})
      : _lessonRepository = lessonRepository ?? Get.find<LessonRepository>();

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserProgressModel?> progress = Rx<UserProgressModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProgress();
  }

  @override
  void onReady() {
    super.onReady();
    loadProgress();
  }

  Future<void> loadProgress() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _lessonRepository.getUserProgress();
      progress.value = result;
    } catch (e) {
      errorMessage.value = 'Failed to load progress analytics: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
