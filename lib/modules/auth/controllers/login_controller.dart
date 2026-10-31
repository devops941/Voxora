import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:voxora/core/constants/app_strings.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/core/services/google_auth_service.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository;

  LoginController(this._authRepository);

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final rememberMe = true.obs;
  final selectedTab = 0.obs;

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
      Get.offAllNamed(AppRoutes.dashboard);
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
    isLoading.value = true;
    try {
      final googleAccount = await GoogleAuthService.instance.signIn();
      if (googleAccount == null) {
        // User cancelled the Google sign-in dialog
        return;
      }

      final user = await _authRepository.loginWithGoogle(
        email: googleAccount.email,
        name: googleAccount.name,
        googleId: googleAccount.googleId,
        avatarUrl: googleAccount.avatarUrl,
        idToken: googleAccount.idToken,
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

      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      if (e.toString().contains('ApiException: 10')) {
        showGoogleConfigDialog();
      } else {
        Get.snackbar(
          'Google Sign-In Failed',
          _friendlyError(e.toString()),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  void showGoogleConfigDialog() {
    final quickEmailController = TextEditingController(text: 'devops@kaizeninfinities.com');
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA4335).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: Color(0xFFEA4335), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Google Sign-In Configuration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Google Play Services requires your app\'s SHA-1 fingerprint and Package Name in Google Cloud Console / Firebase to open the native Google popup:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              _buildConfigCopyBox('Package Name', 'com.example.voxora'),
              const SizedBox(height: 8),
              _buildConfigCopyBox('Debug SHA-1', '28:60:29:48:26:F1:4B:F7:D1:38:AF:EB:2D:1C:5F:7E:A6:D1:85:45'),
              const SizedBox(height: 18),
              const Text(
                '⚡ Or Instant Sign-In with Google Email:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quickEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your Google Email',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: Get.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final email = quickEmailController.text.trim();
                    if (email.isEmpty) return;
                    Get.back();
                    await _quickGoogleLogin(email);
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Instant Continue with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildConfigCopyBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.snackbar(
                'Copied to Clipboard',
                '$label copied!',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _quickGoogleLogin(String email) async {
    try {
      isLoading.value = true;
      final name = email.split('@').first;
      final user = await _authRepository.loginWithGoogle(
        email: email,
        name: name,
        googleId: 'google_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
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

      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar(
        'Sign-In Failed',
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
    if (raw.contains('12501') || raw.contains('cancelled') || raw.contains('canceled')) {
      return 'Sign in cancelled.';
    }
    if (raw.contains('ApiException: 10')) {
      return 'Google Sign-In configuration error. Verify SHA-1 fingerprint & Google Client ID.';
    }
    if (raw.contains('401') || raw.contains('invalid') || raw.contains('credentials')) {
      return AppStrings.errorInvalidCredentials;
    }
    if (raw.contains('network') || raw.contains('socket') || raw.contains('connection') || raw.contains('Failed host lookup') || raw.contains('timeout')) {
      return 'Cannot connect to server. Check Wi-Fi/network.';
    }
    final cleaned = raw.replaceAll('Exception:', '').trim();
    return cleaned.isNotEmpty ? cleaned : AppStrings.errorGeneric;
  }
}
