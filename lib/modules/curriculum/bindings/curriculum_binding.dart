import 'package:get/get.dart';
import 'package:voxora/modules/curriculum/controllers/curriculum_controller.dart';

class CurriculumBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CurriculumController>(() => CurriculumController(), fenix: true);
  }
}
