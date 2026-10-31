import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/modules/splash/bindings/splash_binding.dart';
import 'package:voxora/modules/splash/views/splash_view.dart';
import 'package:voxora/modules/onboarding/bindings/onboarding_binding.dart';
import 'package:voxora/modules/onboarding/views/onboarding_view.dart';
import 'package:voxora/modules/auth/bindings/auth_binding.dart';
import 'package:voxora/modules/auth/views/login_view.dart';
import 'package:voxora/modules/auth/views/register_view.dart';
import 'package:voxora/modules/auth/views/forgot_password_view.dart';
import 'package:voxora/modules/auth/views/verify_otp_view.dart';
import 'package:voxora/modules/auth/views/reset_password_view.dart';
import 'package:voxora/modules/dashboard/views/dashboard_view.dart';
import 'package:voxora/modules/level_selection/views/level_selection_view.dart';
import 'package:voxora/modules/profile/views/profile_view.dart';
import 'package:voxora/modules/curriculum/bindings/curriculum_binding.dart';
import 'package:voxora/modules/curriculum/views/curriculum_view.dart';
import 'package:voxora/modules/lesson/bindings/lesson_binding.dart';
import 'package:voxora/modules/lesson/views/lesson_view.dart';
import 'package:voxora/modules/speaking_practice/bindings/speaking_practice_binding.dart';
import 'package:voxora/modules/speaking_practice/views/speaking_practice_view.dart';
import 'package:voxora/modules/certificate/bindings/certificate_binding.dart';
import 'package:voxora/modules/certificate/views/certificate_form_view.dart';
import 'package:voxora/modules/final_assessment/bindings/final_assessment_binding.dart';
import 'package:voxora/modules/final_assessment/views/assessment_result_view.dart';
import 'package:voxora/modules/final_assessment/views/final_assessment_view.dart';
import 'package:voxora/modules/progress/bindings/progress_binding.dart';
import 'package:voxora/modules/progress/views/progress_view.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.verifyOtp,
      page: () => const VerifyOtpView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.levelSelection,
      page: () => const LevelSelectionView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.curriculum,
      page: () => const CurriculumView(),
      binding: CurriculumBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.lesson,
      page: () => const LessonView(),
      binding: LessonBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.speakingPractice,
      page: () => const SpeakingPracticeView(),
      binding: SpeakingPracticeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.feedback,
      page: () => const _PlaceholderView(name: 'Feedback'),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.progress,
      page: () => const ProgressView(),
      binding: ProgressBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const _PlaceholderView(name: 'Settings'),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.finalAssessment,
      page: () => FinalAssessmentView(),
      binding: FinalAssessmentBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.assessmentResult,
      page: () => AssessmentResultView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.certificateForm,
      page: () => const CertificateFormView(),
      binding: CertificateBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}

/// Responsive scaffold used until each secondary feature module is implemented.
class _PlaceholderView extends StatelessWidget {
  final String name;
  const _PlaceholderView({required this.name});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPadding = (size.width * 0.08).clamp(20.0, 40.0);

    return Scaffold(
      appBar: AppBar(title: Text(name), elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.construction_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature is being tuned for your fluency journey.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
