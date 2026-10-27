import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/theme/app_colors.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_widgets.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive horizontal padding
    final hPadding = (size.width * 0.065).clamp(20.0, 32.0);
    final primaryBlue = const Color(0xFF2563EB);
    final headerColor = isDark ? AppColors.textPrimaryDark : const Color(0xFF1B3B6F);
    final subheaderColor = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : primaryBlue,
            size: 24,
          ),
          onPressed: controller.goToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // ── Centered Heading ────────────────────────────────
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: headerColor,
                    fontSize: (size.width * 0.068).clamp(24.0, 28.0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join and start your 90-day journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subheaderColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: (size.height * 0.035).clamp(24.0, 36.0)),

                // ── Full Name Field ─────────────────────────────────
                AuthTextField(
                  controller: controller.nameController,
                  hintText: 'Full Name',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: controller.validateName,
                ),

                const SizedBox(height: 14),

                // ── Email Address Field ─────────────────────────────
                AuthTextField(
                  controller: controller.emailController,
                  hintText: 'Email Address',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: controller.validateEmail,
                ),

                const SizedBox(height: 14),

                // ── Mobile Number Field ─────────────────────────────
                AuthTextField(
                  controller: controller.phoneController,
                  hintText: 'Mobile Number',
                  prefixIcon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: controller.validatePhone,
                ),

                const SizedBox(height: 14),

                // ── Password Field ──────────────────────────────────
                AuthTextField(
                  controller: controller.passwordController,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  showObscureToggle: true,
                  textInputAction: TextInputAction.done,
                  validator: controller.validatePassword,
                  onFieldSubmitted: (_) => controller.register(),
                ),

                SizedBox(height: (size.height * 0.028).clamp(20.0, 28.0)),

                // ── Register Button ─────────────────────────────────
                Obx(
                  () => AuthPrimaryButton(
                    label: 'Register',
                    onPressed: controller.register,
                    isLoading: controller.isLoading.value,
                  ),
                ),

                const SizedBox(height: 16),

                // ── "or" Divider ────────────────────────────────────
                const AuthOrDivider(),

                const SizedBox(height: 16),

                // ── Continue with Google ────────────────────────────
                GoogleSignInButton(
                  onPressed: controller.continueWithGoogle,
                ),

                SizedBox(height: (size.height * 0.035).clamp(24.0, 36.0)),

                // ── Already have an account? Login ──────────────────
                Center(
                  child: TextButton(
                    onPressed: controller.goToLogin,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF475569),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
