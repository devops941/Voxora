import 'package:get/get.dart';
import 'package:voxora/modules/final_assessment/controllers/final_assessment_controller.dart';

class FinalAssessmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FinalAssessmentController>(() => FinalAssessmentController());
  }
}
