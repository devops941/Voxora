import 'package:get/get.dart';

import 'package:voxora/core/constants/app_constants.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/storage/local_storage.dart';

class SplashController extends GetxController {
  late final LocalStorage _localStorage;

  @override
  void onInit() {
    super.onInit();
    // LocalStorage is registered by InitialBinding before SplashBinding runs.
    _localStorage = Get.find<LocalStorage>();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(
      const Duration(seconds: AppConstants.splashDuration),
    );
    await _decideRoute();
  }

  Future<void> _decideRoute() async {
    final token = await _localStorage.getToken();
    final onboardingDone = await _localStorage.isOnboardingComplete();

    if (token != null && token.isNotEmpty) {
      // Valid session — go straight to dashboard.
      Get.offAllNamed(AppRoutes.dashboard);
    } else if (!onboardingDone) {
      // First launch — show onboarding.
      Get.offAllNamed(AppRoutes.onboarding);
    } else {
      // Returning user without a token — show login.
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
