import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/modules/curriculum/controllers/curriculum_controller.dart';

class CurriculumView extends GetView<CurriculumController> {
  const CurriculumView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final hPadding = (size.width * 0.05).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 58,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Obx(() {
          final modTitle = controller.moduleTitle.value;
          final phase = controller.selectedPhase.value;
          final displayTitle = modTitle.isNotEmpty
              ? modTitle
              : (phase == 1
                  ? 'Everyday Conversations'
                  : phase == 2
                      ? 'Professional Workplace English'
                      : 'Pronunciation & Accent Mastery');
          final phaseSubtitle = phase == 1
              ? 'Phase 1 • Days 1–30 • Beginner'
              : phase == 2
                  ? 'Phase 2 • Days 31–60 • Intermediate'
                  : 'Phase 3 • Days 61–90 • Advanced';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                phaseSubtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }),
        actions: [
          Obx(() => Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.streakCount.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 6),
            child: _buildLevelSelector(isDark),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 14),
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadPlan(level: controller.selectedLevel.value),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final lessons = controller.filteredLessons;

          return Column(
            children: [
              const SizedBox(height: 6),

              // ── Overall 90-Day Progress Header ─────────────────────
              _buildProgressHeader(isDark, hPadding),

              const SizedBox(height: 12),

              // ── Phase Switcher Tabs (2-line clean responsive layout) ─
              _buildPhaseTabs(isDark, hPadding),

              // ── Locked Phase Notice Banner (when phase is locked) ──
              _buildLockedPhaseNotice(isDark, hPadding),

              const SizedBox(height: 6),

              // ── Lessons List Timeline ─────────────────────────────
              Expanded(
                child: lessons.isEmpty
                    ? _buildEmptyPhaseState(isDark, hPadding)
                    : RefreshIndicator(
                        onRefresh: () => controller.loadPlan(level: controller.selectedLevel.value),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 4),
                          physics: const BouncingScrollPhysics(),
                          itemCount: lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = lessons[index];
                            return _buildTimelineLessonCard(lesson, isDark);
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyPhaseState(bool isDark, double hPadding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(hPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined, size: 44, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              'No lessons found for Phase ${controller.selectedPhase.value}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh or switch phases',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => controller.loadPlan(level: controller.selectedLevel.value),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal Level Selector for Beginner, Intermediate, and Advanced tracks
  Widget _buildLevelSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() => Row(
        children: [
          _buildLevelOption('Beginner', 'Beginner', isDark),
          _buildLevelOption('Intermediate', 'Intermediate', isDark),
          _buildLevelOption('Advanced', 'Advanced', isDark),
        ],
      )),
    );
  }

  Widget _buildLevelOption(String level, String label, bool isDark) {
    final isSelected = controller.selectedLevel.value.toLowerCase() == level.toLowerCase();
    final isActiveTrack = controller.activeTrackLevel.value.toLowerCase() == level.toLowerCase();

    return Expanded(
      child: InkWell(
        onTap: () => controller.selectLevel(level),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!controller.isLevelUnlocked(level)) ...[
                Icon(
                  Icons.lock_rounded,
                  size: 11,
                  color: isSelected ? Colors.white70 : (isDark ? Colors.grey[500] : Colors.grey[600]),
                ),
                const SizedBox(width: 4),
              ] else if (isActiveTrack) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: isSelected ? Colors.white : const Color(0xFF16A34A),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(bool isDark, double hPadding) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Track: ${controller.selectedLevel.value}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (controller.isUserActivePlan.value)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Builder(
                      builder: (context) {
                        final total = controller.totalDays.value > 0 ? controller.totalDays.value : 90;
                        return Text(
                          'Day ${controller.currentDay.value} of $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!controller.isUserActivePlan.value)
                ElevatedButton.icon(
                  onPressed: () => controller.setActiveTrack(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text(
                    'Set Active',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Builder(
                    builder: (context) {
                      final total = controller.totalDays.value > 0 ? controller.totalDays.value : 90;
                      final completed = controller.completedDays.value;
                      final pct = ((completed / total) * 100).round();
                      return Text(
                        '$pct% Completed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final total = controller.totalDays.value > 0 ? controller.totalDays.value : 90;
              final completed = controller.completedDays.value;
              final frac = (completed / total).clamp(0.0, 1.0);
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: frac.isNaN ? 0.0 : frac,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Clean responsive Phase Switcher with Phase 1, Phase 2, and Phase 3 tabs
  Widget _buildPhaseTabs(bool isDark, double hPadding) {
    return Obx(() {
      final activePhase = controller.selectedPhase.value;
      return Container(
        height: 52,
        margin: EdgeInsets.symmetric(horizontal: hPadding),
        child: Row(
          children: [
            _buildPhaseTabItem(1, 'Phase 1', 'Days 1–30', activePhase == 1, isDark),
            const SizedBox(width: 8),
            _buildPhaseTabItem(2, 'Phase 2', 'Days 31–60', activePhase == 2, isDark),
            const SizedBox(width: 8),
            _buildPhaseTabItem(3, 'Phase 3', 'Days 61–90', activePhase == 3, isDark),
          ],
        ),
      );
    });
  }

  Widget _buildPhaseTabItem(int phase, String title, String subtitle, bool isSelected, bool isDark) {
    final isUnlocked = controller.isPhaseUnlocked(phase);

    return Expanded(
      child: InkWell(
        onTap: () => controller.selectPhase(phase),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isUnlocked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock_rounded,
                      size: 11,
                      color: isSelected ? Colors.white70 : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedPhaseNotice(bool isDark, double hPadding) {
    return Obx(() {
      final phase = controller.selectedPhase.value;
      final isUnlocked = controller.isPhaseUnlocked(phase);
      if (isUnlocked) return const SizedBox.shrink();

      final msg = phase == 2
          ? 'Phase 2 is Locked 🔒 • Complete Beginner (Days 1–30) first to unlock!'
          : 'Phase 3 is Locked 🔒 • Complete Intermediate (Days 31–60) first to unlock!';

      return Container(
        margin: EdgeInsets.symmetric(horizontal: hPadding, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimelineLessonCard(DailyLessonModel lesson, bool isDark) {
    final currentDay = controller.currentDay.value;
    final isCompleted = lesson.isCompleted || (controller.isUserActivePlan.value && lesson.day < currentDay);
    final isCurrent = controller.isUserActivePlan.value && lesson.day == currentDay;
    final isUnlocked = controller.isLessonUnlocked(lesson);
    final isMilestone = lesson.day % 15 == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => controller.openLesson(lesson),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCurrent
                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Day Indicator Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                      : isCurrent
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? Colors.grey[850] : Colors.grey[200]),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24)
                      : isCurrent
                          ? const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28)
                          : Icon(
                              Icons.lock_outline_rounded,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                              size: 20,
                            ),
                ),
              ),

              const SizedBox(width: 14),

              // Title & details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'DAY ${lesson.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isCurrent
                                ? AppColors.primary
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                        if (isMilestone) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '★ Milestone',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                        if (lesson.score > 0) ...[
                          const Spacer(),
                          Text(
                            '${lesson.score}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.topic,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.grammarFocus.isNotEmpty
                          ? lesson.grammarFocus.first
                          : lesson.objective,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                isUnlocked ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                size: isUnlocked ? 24 : 18,
                color: isUnlocked
                    ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
