import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/data/models/final_assessment_model.dart';
import 'package:voxora/modules/final_assessment/controllers/final_assessment_controller.dart';

class FinalAssessmentView extends StatelessWidget {
  const FinalAssessmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FinalAssessmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isAssessmentStarted.value) {
        return _AssessmentScreen(controller: controller, isDark: isDark);
      }
      return _LevelSelectionScreen(controller: controller, isDark: isDark);
    });
  }
}

// ── Level Selection ───────────────────────────────────────────────────────────

class _LevelSelectionScreen extends StatelessWidget {
  final FinalAssessmentController controller;
  final bool isDark;

  const _LevelSelectionScreen({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Final Assessment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Final Assessment',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '25 AI questions  •  4 marks each  •  100 marks total\nPass score: 65/100 (65%)',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Select Your Level',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),

              // Level cards
              ...['Beginner', 'Intermediate', 'Advanced'].map((level) {
                return Obx(() {
                  final isSelected = controller.selectedLevel.value == level;
                  final levelColor = level == 'Beginner'
                      ? AppColors.levelBeginner
                      : level == 'Intermediate'
                          ? AppColors.levelIntermediate
                          : AppColors.levelAdvanced;
                  final icon = level == 'Beginner'
                      ? Icons.school_outlined
                      : level == 'Intermediate'
                          ? Icons.trending_up_rounded
                          : Icons.workspace_premium_outlined;
                  final subtitle = level == 'Beginner'
                      ? 'Days 1–30 • Foundation & Daily Routines'
                      : level == 'Intermediate'
                          ? 'Days 31–60 • Conversational Confidence'
                          : 'Days 61–90 • Fluency Mastery';

                  return GestureDetector(
                    onTap: () => controller.selectLevel(level),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.12)
                                  : levelColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon,
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : levelColor,
                                size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isSelected
                                        ? const Color(0xFF7C3AED)
                                        : (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF7C3AED), size: 22),
                        ],
                      ),
                    ),
                  );
                });
              }),

              const SizedBox(height: 16),

              // Eligibility status
              Obx(() {
                if (controller.isCheckingEligibility.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED), strokeWidth: 2.5),
                    ),
                  );
                }
                if (controller.isTestMode.value && controller.isEligible.value) {
                  return _StatusBanner(
                    icon: Icons.warning_amber_rounded,
                    message:
                        'DEV TEST MODE — 90-day requirement bypassed for testing only',
                    color: Colors.amber,
                  );
                }
                if (controller.isEligible.value) {
                  return _StatusBanner(
                    icon: Icons.check_circle_outline_rounded,
                    message:
                        'You are eligible! Ready to take the Final Assessment.',
                    color: AppColors.success,
                  );
                }
                if (controller.ineligibleReason.value.isNotEmpty) {
                  return _StatusBanner(
                    icon: Icons.lock_outline_rounded,
                    message: controller.ineligibleReason.value,
                    color: AppColors.error,
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 28),

              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          controller.isEligible.value && !controller.isLoading.value
                              ? controller.startAssessment
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        disabledBackgroundColor: isDark
                            ? AppColors.borderDark
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Start Assessment',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _StatusBanner(
      {required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MCQ Question Screen ───────────────────────────────────────────────────────

class _AssessmentScreen extends StatelessWidget {
  final FinalAssessmentController controller;
  final bool isDark;

  const _AssessmentScreen(
      {required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final idx = controller.currentQuestionIndex.value;
      final total = controller.questions.length;
      if (total == 0) {
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
      final question = controller.questions[idx];
      final answered = controller.selectedAnswers.length;

      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              Get.defaultDialog(
                title: 'Quit Assessment?',
                middleText:
                    'Your progress will be lost. Are you sure you want to quit?',
                textConfirm: 'Quit',
                textCancel: 'Continue',
                confirmTextColor: Colors.white,
                buttonColor: AppColors.error,
                onConfirm: () {
                  Get.back();
                  controller.resetToLevelSelection();
                },
              );
            },
          ),
          title: Text(
            'Question ${idx + 1} of $total',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$answered/$total',
                style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (idx + 1) / total,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.cardDark
                        : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Question + Options
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question card
                      _QuestionCard(
                          question: question,
                          idx: idx,
                          isDark: isDark),
                      const SizedBox(height: 14),

                      // Options
                      ..._buildOptions(question, isDark),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Navigation bar
              _NavigationBar(
                  controller: controller,
                  idx: idx,
                  total: total,
                  isDark: isDark),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildOptions(AssessmentQuestion question, bool isDark) {
    const labels = ['A', 'B', 'C', 'D'];
    return List.generate(question.options.length, (i) {
      return Obx(() {
        final isSelected = controller.selectedAnswers[question.id] == i;
        return GestureDetector(
          onTap: () => controller.selectAnswer(question.id, i),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : (isDark
                            ? AppColors.cardDark
                            : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.options[i],
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                      height: 1.35,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF7C3AED), size: 18),
              ],
            ),
          ),
        );
      });
    });
  }
}

class _QuestionCard extends StatelessWidget {
  final AssessmentQuestion question;
  final int idx;
  final bool isDark;

  const _QuestionCard(
      {required this.question, required this.idx, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${idx + 1}  •  ${question.marks} marks',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final FinalAssessmentController controller;
  final int idx;
  final int total;
  final bool isDark;

  const _NavigationBar(
      {required this.controller,
      required this.idx,
      required this.total,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
            top: BorderSide(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: Row(
        children: [
          if (idx > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: controller.previousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side:
                      const BorderSide(color: Color(0xFF7C3AED)),
                  foregroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Previous',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          if (idx > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          idx < total - 1 ? 'Next' : 'Submit Assessment',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                )),
          ),
        ],
      ),
    );
  }
}
