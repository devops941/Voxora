import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/constants/app_strings.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().forgotPassword(email);
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      Get.snackbar(
        'OTP Sent! 📩',
        'A 6-digit verification code was sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );

      // Navigate to OTP Verification Screen
      Get.toNamed(AppRoutes.verifyOtp, arguments: {'email': email});
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Get.snackbar(
        'Notice',
        'If that email is registered, an OTP has been sent. Proceeding to verification.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      Get.toNamed(AppRoutes.verifyOtp, arguments: {'email': email});
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
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
          child: AuthCard(
            child: _buildFormState(
              context,
              isDark,
              iconSize,
              titleFontSize,
              size,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(
    BuildContext context,
    bool isDark,
    double iconSize,
    double titleFontSize,
    Size size,
  ) {
    return Form(
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
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: iconSize * 0.52,
                color: AppColors.primary,
              ),
            ),
          ),

          SizedBox(height: (size.height * 0.035).clamp(20.0, 32.0)),

          // Title
          Text(
            AppStrings.forgotPassword,
            style: AppTextStyles.headingLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Enter your registered email address. We will send you a 6-digit OTP code to verify and reset your password.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
              fontSize: 14.5,
            ),
          ),

          SizedBox(height: (size.height * 0.035).clamp(20.0, 32.0)),

          // Email Input
          AuthTextField(
            hintText: 'Email Address',
            controller: _emailController,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppStrings.validationRequired;
              }
              if (!GetUtils.isEmail(v.trim())) {
                return AppStrings.validationInvalidEmail;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),

          SizedBox(height: (size.height * 0.035).clamp(20.0, 32.0)),

          // Reset button
          AuthPrimaryButton(
            label: 'Send Verification OTP',
            onPressed: _submit,
            isLoading: _isLoading,
          ),

          SizedBox(height: (size.height * 0.025).clamp(16.0, 24.0)),

          // Return to Login
          Center(
            child: TextButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Sign In'),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
