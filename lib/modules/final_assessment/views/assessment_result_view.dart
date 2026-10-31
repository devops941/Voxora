import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/data/models/final_assessment_model.dart';
import 'package:voxora/modules/final_assessment/controllers/final_assessment_controller.dart';

class AssessmentResultView extends StatelessWidget {
  AssessmentResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final result = Get.arguments as AssessmentResultModel?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result data found.')),
      );
    }

    final isPassed = result.isPassed;
    final statusColor = isPassed ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Assessment Result',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Result icon
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.12),
                ),
                child: Icon(
                  isPassed
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 68,
                  color: statusColor,
                ),
              ),

              const SizedBox(height: 18),

              // PASS / FAIL badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isPassed ? 'PASSED' : 'FAILED',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.8,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${result.score}',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      'out of ${result.totalMarks}',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${result.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                            label: 'Correct',
                            value: '${result.correctAnswers}',
                            icon: Icons.check_rounded,
                            color: AppColors.success),
                        Container(
                            width: 1, height: 40, color: AppColors.borderLight),
                        _StatItem(
                            label: 'Wrong',
                            value:
                                '${result.totalQuestions - result.correctAnswers}',
                            icon: Icons.close_rounded,
                            color: AppColors.error),
                        Container(
                            width: 1, height: 40, color: AppColors.borderLight),
                        _StatItem(
                            label: 'Questions',
                            value: '${result.totalQuestions}',
                            icon: Icons.quiz_outlined,
                            color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _Chip(
                            label: result.level,
                            color: AppColors.primary),
                        if (result.isTestMode)
                          _Chip(
                              label: 'DEV TEST MODE',
                              color: Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Message
              Text(
                isPassed
                    ? '🎉 Congratulations! You passed the ${result.level} Final Assessment. Download your certificate below!'
                    : '💪 You need 65% to pass. Review your ${result.level} lessons and try again — you\'ve got this!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: 30),

              // Get Certificate button (PASS only)
              if (isPassed) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(
                      AppRoutes.certificateForm,
                      arguments: {
                        'assessmentId': result.assessmentId,
                        'level': result.level,
                        'score': result.score,
                        'percentage': result.percentage,
                        'isTestMode': result.isTestMode,
                      },
                    ),
                    icon: const Icon(Icons.card_membership_rounded, size: 22),
                    label: const Text('Get Your Certificate',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Retry / Back button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (isPassed) {
                      Get.until(
                          (route) => route.settings.name == AppRoutes.dashboard);
                    } else {
                      Get.back();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (Get.isRegistered<FinalAssessmentController>()) {
                          Get.find<FinalAssessmentController>()
                              .retryAssessment();
                        }
                      });
                    }
                  },
                  icon: Icon(isPassed
                      ? Icons.home_rounded
                      : Icons.refresh_rounded),
                  label: Text(
                    isPassed ? 'Back to Home' : 'Retry Assessment',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: isPassed ? AppColors.primary : AppColors.error),
                    foregroundColor:
                        isPassed ? AppColors.primary : AppColors.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}
