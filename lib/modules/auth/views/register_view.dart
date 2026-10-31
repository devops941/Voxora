import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/register_controller.dart';
import '../widgets/auth_widgets.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive horizontal padding
    final hPadding = (size.width * 0.048).clamp(16.0, 24.0);
    final primaryBlue = const Color(0xFF3B82F6);
    final headerColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subheaderColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF161F30).withValues(alpha: 0.8)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              size: 20,
            ),
            onPressed: controller.goToLogin,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 24).clamp(0.0, double.infinity),
                ),
                child: Center(
                  child: Form(
                    key: controller.formKey,
                    child: AuthCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Brand Logo Badge ──────────────────────
                          Image.asset(
                            'assets/images/logo.png',
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // ── Centered Heading ──────────────────────
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: headerColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join and start your 90-day journey',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subheaderColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Full Name Field ───────────────────────
                          AuthTextField(
                            controller: controller.nameController,
                            hintText: 'Full Name',
                            prefixIcon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            validator: controller.validateName,
                          ),

                          const SizedBox(height: 12),

                          // ── Email Address Field ───────────────────
                          AuthTextField(
                            controller: controller.emailController,
                            hintText: 'Email Address',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: controller.validateEmail,
                          ),

                          const SizedBox(height: 12),

                          // ── Mobile Number Field ───────────────────
                          AuthTextField(
                            controller: controller.phoneController,
                            hintText: 'Mobile Number',
                            prefixIcon: Icons.phone_iphone_rounded,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: controller.validatePhone,
                          ),

                          const SizedBox(height: 12),

                          // ── Password Field ────────────────────────
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

                          const SizedBox(height: 18),

                          // ── Register Button ───────────────────────
                          Obx(
                            () => AuthPrimaryButton(
                              label: 'Register',
                              onPressed: controller.register,
                              isLoading: controller.isLoading.value,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Already have an account? Login ────────
                          Center(
                            child: TextButton(
                              onPressed: controller.goToLogin,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                    color: subheaderColor,
                                    fontSize: 13.5,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
