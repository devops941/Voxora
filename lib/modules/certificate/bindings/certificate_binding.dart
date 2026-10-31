import 'package:get/get.dart';
import 'package:voxora/modules/certificate/controllers/certificate_controller.dart';

class CertificateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CertificateController>(() => CertificateController());
  }
}
