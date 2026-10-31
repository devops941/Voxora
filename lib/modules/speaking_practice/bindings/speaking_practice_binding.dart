import 'package:get/get.dart';
import 'package:voxora/modules/speaking_practice/controllers/speaking_practice_controller.dart';

class SpeakingPracticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpeakingPracticeController>(() => SpeakingPracticeController());
  }
}
