import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/constants/app_strings.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';
import 'package:voxora/shared/widgets/app_button.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _pages = [
    _PageData(
      imagePath: 'assets/images/onboard.png',
      fit: BoxFit.cover,
      icon: Icons.mic_rounded,
      accentColor: AppColors.primary,
      title: AppStrings.onboardingTitle1,
      subtitle: AppStrings.onboardingSubtitle1,
    ),
    _PageData(
      imagePath: 'assets/images/robo.png',
      fit: BoxFit.contain,
      backgroundColor: Color(0xFFEDF5FE),
      icon: Icons.school_rounded,
      accentColor: AppColors.secondary,
      title: AppStrings.onboardingTitle2,
      subtitle: AppStrings.onboardingSubtitle2,
    ),
    _PageData(
      imagePath: 'assets/images/mira_teacher.png',
      fit: BoxFit.contain,
      backgroundColor: Color(0xFFFFF0F0),
      icon: Icons.auto_awesome_rounded,
      accentColor: AppColors.accent,
      title: AppStrings.onboardingTitle3,
      subtitle: AppStrings.onboardingSubtitle3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPadding = (size.width * 0.06).clamp(16.0, 28.0);
    final bPadding = (size.height * 0.035).clamp(16.0, 32.0);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar / Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 4, right: hPadding * 0.6),
                child: Obx(
                  () => AnimatedOpacity(
                    opacity: controller.currentPage.value <
                            OnboardingController.totalPages - 1
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: controller.skip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        AppStrings.skip,
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Responsive Slider Pages
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),

            // Bottom controls: Dots & Next/Get Started Button
            Padding(
              padding: EdgeInsets.fromLTRB(hPadding, 6, hPadding, bPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DotIndicator(
                    total: OnboardingController.totalPages,
                    currentIndex: controller.currentPage,
                  ),
                  SizedBox(height: (size.height * 0.025).clamp(16.0, 24.0)),
                  Obx(
                    () => AppButton(
                      label: controller.currentPage.value ==
                              OnboardingController.totalPages - 1
                          ? AppStrings.getStarted
                          : AppStrings.next,
                      onPressed: controller.nextPage,
                      trailingIcon: controller.currentPage.value ==
                              OnboardingController.totalPages - 1
                          ? null
                          : Icons.arrow_forward_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final String? imagePath;
  final BoxFit fit;
  final Color? backgroundColor;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  const _PageData({
    this.imagePath,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        // Proportional card height that scales smoothly on any device
        final cardHeight = (availableHeight * 0.52).clamp(170.0, 310.0);
        final titleFontSize = (availableWidth * 0.06).clamp(20.0, 25.0);
        final subtitleFontSize = (availableWidth * 0.038).clamp(13.5, 15.5);
        final horizontalPadding = (availableWidth * 0.06).clamp(16.0, 26.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // Hero Image Container
                    Container(
                      height: cardHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: data.backgroundColor ??
                            (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.black : data.accentColor)
                                .withValues(alpha: isDark ? 0.35 : 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ],
                        border: Border.all(
                          color: (isDark ? Colors.white : data.accentColor)
                              .withValues(alpha: isDark ? 0.08 : 0.10),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: data.imagePath != null
                            ? Padding(
                                padding: data.fit == BoxFit.contain
                                    ? const EdgeInsets.all(16.0)
                                    : EdgeInsets.zero,
                                child: Image.asset(
                                  data.imagePath!,
                                  fit: data.fit,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _FallbackIcon(data: data),
                                ),
                              )
                            : _FallbackIcon(data: data),
                      ),
                    ),

                    SizedBox(height: (availableHeight * 0.035).clamp(16.0, 28.0)),

                    Text(
                      data.title,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        data.subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.5,
                          fontSize: subtitleFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final _PageData data;
  const _FallbackIcon({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: data.accentColor.withValues(alpha: 0.12),
        ),
        child: Icon(
          data.icon,
          size: 52,
          color: data.accentColor,
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int total;
  final RxInt currentIndex;

  const _DotIndicator({required this.total, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == currentIndex.value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: active
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.22),
            ),
          );
        }),
      ),
    );
  }
}
