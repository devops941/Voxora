import 'package:get/get.dart';
import 'package:voxora/modules/progress/controllers/progress_controller.dart';

class ProgressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProgressController>(() => ProgressController());
  }
}
