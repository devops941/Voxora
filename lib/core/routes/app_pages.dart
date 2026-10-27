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
import 'package:voxora/modules/dashboard/views/dashboard_view.dart';
import 'package:voxora/modules/level_selection/views/level_selection_view.dart';

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
      page: () => const _PlaceholderView(name: 'Curriculum'),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.lesson,
      page: () => const _PlaceholderView(name: 'Lesson'),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.speakingPractice,
      page: () => const _PlaceholderView(name: 'Speaking Practice'),
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
      page: () => const _PlaceholderView(name: 'Progress'),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const _PlaceholderView(name: 'Profile'),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const _PlaceholderView(name: 'Settings'),
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
      appBar: AppBar(
        title: Text(name),
        elevation: 0,
      ),
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
