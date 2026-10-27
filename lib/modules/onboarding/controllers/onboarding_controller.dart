import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/storage/local_storage.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  static const int totalPages = 3;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) => currentPage.value = index;

  void nextPage() {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void skip() => _finish();

  Future<void> _finish() async {
    await Get.find<LocalStorage>().setOnboardingComplete();
    Get.offAllNamed(AppRoutes.login);
  }
}
