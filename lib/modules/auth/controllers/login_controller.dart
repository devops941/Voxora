import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/constants/app_strings.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/modules/auth/widgets/google_account_picker.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository;

  LoginController(this._authRepository);

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validationRequired;
    }
    final trimmed = value.trim();
    final isEmail = GetUtils.isEmail(trimmed);
    final isPhone = RegExp(r'^[0-9+\s\-()]{7,15}$').hasMatch(trimmed);
    if (!isEmail && !isPhone) {
      return 'Enter a valid email or mobile number';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.validationRequired;
    if (value.length < 8) return AppStrings.validationPasswordTooShort;
    return null;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _authRepository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Get.offAllNamed(AppRoutes.levelSelection);
    } catch (e) {
      Get.snackbar(
        'Sign In Failed',
        _friendlyError(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueWithGoogle() async {
    final context = Get.context;
    if (context == null) return;

    final selectedAccount = await GoogleAccountPicker.show(context);
    if (selectedAccount == null) return;

    isLoading.value = true;
    try {
      final user = await _authRepository.loginWithGoogle(
        email: selectedAccount.email,
        name: selectedAccount.name,
        googleId: selectedAccount.googleId,
        avatarUrl: selectedAccount.avatarUrl,
      );

      Get.snackbar(
        'Signed in with Google! 🎉',
        'Welcome to Voxora, ${user.name}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );

      Get.offAllNamed(AppRoutes.levelSelection);
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Failed',
        _friendlyError(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goToRegister() => Get.toNamed(AppRoutes.register);

  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);

  String _friendlyError(String raw) {
    if (raw.contains('401') || raw.contains('invalid') || raw.contains('credentials')) {
      return AppStrings.errorInvalidCredentials;
    }
    if (raw.contains('network') || raw.contains('socket') || raw.contains('connection') || raw.contains('Failed host lookup') || raw.contains('timeout')) {
      return 'Cannot connect to server (http://192.168.1.22:3000). Check Wi-Fi/network.';
    }
    final cleaned = raw.replaceAll('Exception:', '').trim();
    return cleaned.isNotEmpty ? cleaned : AppStrings.errorGeneric;
  }
}
