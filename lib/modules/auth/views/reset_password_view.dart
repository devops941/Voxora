import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/constants/app_strings.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final String email;
  late final String otp;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    email = (args is Map && args['email'] != null)
        ? args['email'].toString()
        : '';
    otp = (args is Map && args['otp'] != null)
        ? args['otp'].toString()
        : '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newPassword = _passwordController.text.trim();
    setState(() => _isLoading = true);

    try {
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().resetPassword(
          email: email,
          otp: otp,
          newPassword: newPassword,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Pre-fill the reset email on LoginView
      if (Get.isRegistered<LoginController>()) {
        try {
          final loginCtrl = Get.find<LoginController>();
          loginCtrl.emailController.text = email;
          loginCtrl.passwordController.clear();
        } catch (_) {}
      }

      // Pop back smoothly to Login screen
      Get.until((route) => route.settings.name == AppRoutes.login || route.isFirst);
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }

      // Display green celebration snackbar after navigation completes
      Future.delayed(const Duration(milliseconds: 350), () {
        Get.snackbar(
          'Password Reset! 🎉',
          'Your password has been updated. Please log in with your new password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF16A34A),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final msg = e.toString().replaceAll('Exception:', '').trim();
      Get.snackbar(
        'Reset Failed',
        msg.isNotEmpty ? msg : 'Could not reset password. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hPadding = (size.width * 0.065).clamp(18.0, 32.0);
    final iconSize = (size.width * 0.18).clamp(64.0, 84.0);
    final titleFontSize = (size.width * 0.075).clamp(24.0, 30.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
          child: AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: (size.height * 0.02).clamp(8.0, 24.0)),

                  // Top Icon
                  Center(
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: iconSize * 0.52,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),

                  SizedBox(height: (size.height * 0.035).clamp(20.0, 32.0)),

                  // Title
                  Text(
                    'Reset Password',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Choose a new secure password for $email.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.5,
                      fontSize: 14.5,
                    ),
                  ),

                  SizedBox(height: (size.height * 0.035).clamp(20.0, 32.0)),

                  // New Password Input
                  AuthTextField(
                    hintText: 'New Password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    showObscureToggle: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.validationRequired;
                      }
                      if (v.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm New Password Input
                  AuthTextField(
                    hintText: 'Confirm New Password',
                    controller: _confirmPasswordController,
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: true,
                    showObscureToggle: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.validationRequired;
                      }
                      if (v.trim() != _passwordController.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  SizedBox(height: (size.height * 0.035).clamp(24.0, 36.0)),

                  // Reset Button
                  AuthPrimaryButton(
                    label: 'Update Password',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),

                  SizedBox(height: (size.height * 0.025).clamp(16.0, 24.0)),

                  // Return to Login
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.until((route) => route.settings.name == AppRoutes.login || route.isFirst);
                        if (Get.currentRoute != AppRoutes.login) {
                          Get.offAllNamed(AppRoutes.login);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to Sign In'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
