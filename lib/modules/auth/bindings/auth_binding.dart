import 'package:get/get.dart';

import 'package:voxora/data/repositories/auth_repository.dart';
import '../controllers/login_controller.dart';
import '../controllers/register_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<AuthRepository>()),
    );
    Get.lazyPut<RegisterController>(
      () => RegisterController(Get.find<AuthRepository>()),
    );
  }
}
