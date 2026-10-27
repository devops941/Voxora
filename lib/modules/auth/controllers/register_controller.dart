import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/constants/app_strings.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/modules/auth/widgets/google_account_picker.dart';

class RegisterController extends GetxController {
  final AuthRepository _authRepository;

  RegisterController(this._authRepository);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.validationRequired;
    if (value.trim().length < 2) return AppStrings.validationNameTooShort;
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.validationRequired;
    if (!GetUtils.isEmail(value.trim())) return AppStrings.validationInvalidEmail;
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional or valid
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) {
      return AppStrings.validationInvalidPhone;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.validationRequired;
    if (value.length < 8) return AppStrings.validationPasswordTooShort;
    if (!value.contains(RegExp(r'[A-Z]'))) return AppStrings.validationPasswordNoUppercase;
    if (!value.contains(RegExp(r'[0-9]'))) return AppStrings.validationPasswordNoNumber;
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.validationRequired;
    if (value != passwordController.text) return AppStrings.errorPasswordMismatch;
    return null;
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _authRepository.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );
      Get.offAllNamed(AppRoutes.levelSelection);
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
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

  void goToLogin() => Get.back();

  String _friendlyError(String raw) {
    if (raw.contains('409') || raw.contains('already')) return AppStrings.errorEmailInUse;
    if (raw.contains('network') || raw.contains('socket') || raw.contains('connection') || raw.contains('Failed host lookup') || raw.contains('timeout')) {
      return 'Cannot connect to server (http://192.168.1.22:3000). Check Wi-Fi/network.';
    }
    final cleaned = raw.replaceAll('Exception:', '').trim();
    return cleaned.isNotEmpty ? cleaned : AppStrings.errorGeneric;
  }
}
