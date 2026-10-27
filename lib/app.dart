import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/bindings/initial_binding.dart';
import 'package:voxora/core/constants/app_constants.dart';
import 'package:voxora/core/routes/app_pages.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_theme.dart';

class VoxoraApp extends StatelessWidget {
  const VoxoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ── Identity ────────────────────────────────
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // ── Navigation ───────────────────────────────
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(
        milliseconds: AppConstants.animationNormal,
      ),

      // ── DI bootstrapping ─────────────────────────
      initialBinding: InitialBinding(),

      // ── Behaviour ────────────────────────────────
      enableLog: true,
      logWriterCallback: (text, {bool isError = false}) {
        // Suppress GetX logs in release builds.
        assert(() {
          debugPrint('[GetX] $text');
          return true;
        }());
      },

      // ── Builder — global responsive overlay scaffold ────────
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.25),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
