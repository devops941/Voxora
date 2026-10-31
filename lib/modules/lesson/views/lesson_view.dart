import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/modules/lesson/controllers/lesson_controller.dart';
import 'package:voxora/modules/lesson/widgets/mira_avatar_widget.dart';

class LessonView extends GetView<LessonController> {
  const LessonView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final hPadding = (size.width * 0.05).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final lesson = controller.dailyLesson.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DAY ${controller.dayNumber.value} OF 90',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                lesson?.topic ?? 'Daily Lesson',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }),
        actions: [
          // Elapsed session timer badge
          Obx(() {
            final secs = controller.sessionElapsedSeconds.value;
            final m = (secs ~/ 60).toString().padLeft(2, '0');
            final s = (secs % 60).toString().padLeft(2, '0');
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$m:$s',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            );
          }),
          // Ask Doubt Button in AppBar
          IconButton(
            icon: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFFEAB308),
            ),
            tooltip: 'Ask MIRA a Doubt',
            onPressed: () => _showAskDoubtSheet(context, isDark),
          ),
        ],
      ),
      body: Obx(() {
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
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () =>
                        controller.loadLesson(controller.dayNumber.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final lesson = controller.dailyLesson.value;
        if (lesson == null) {
          return const Center(child: Text('No lesson data found'));
        }

        return Column(
          children: [
            // ── Phase Selector Header ───────────────────────────────
            _buildPhaseHeader(isDark),

            // ── Voice MIRA Floating Audio Controller Bar ────────────
            _buildMiraVoiceBar(isDark),

            // ── Main Phase Body ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hPadding,
                  12,
                  hPadding,
                  48 + MediaQuery.of(context).padding.bottom,
                ),
                child: _buildPhaseContent(context, isDark, size),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Two-Phase Step Bar ─────────────────────────────────────────────
  Widget _buildPhaseHeader(bool isDark) {
    return Obx(() {
      final current = controller.currentPhase.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        child: Row(
          children: [
            // Phase 1 Tab
            Expanded(
              child: InkWell(
                onTap: () => controller.setPhase(1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: current == 1
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: current == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 15,
                        color: current == 1 ? AppColors.primary : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Phase 1: Learn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: current == 1
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: current == 1
                                ? AppColors.primary
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700]),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Phase 2 Tab
            Expanded(
              child: InkWell(
                onTap: () => controller.setPhase(2),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: current == 2
                        ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: current == 2
                          ? const Color(0xFF16A34A)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 15,
                        color: current == 2
                            ? const Color(0xFF16A34A)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Phase 2: Speak',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: current == 2
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: current == 2
                                ? const Color(0xFF16A34A)
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700]),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── MIRA Voice Audio Player Bar ───────────────────────────────────
  Widget _buildMiraVoiceBar(bool isDark) {
    return Obx(() {
      final isSpeaking = controller.isTtsSpeaking.value;
      final isPaused = controller.isTtsPaused.value;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSpeaking
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSpeaking
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSpeaking ? AppColors.primary : Colors.grey[600],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpeaking
                        ? 'MIRA is Teaching & Speaking...'
                        : isPaused
                        ? 'MIRA Voice Paused'
                        : 'MIRA Voice Audio Ready',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSpeaking
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                    ),
                  ),
                  Text(
                    'Natural voice audio with pause & replay controls',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Play / Pause Toggle
            if (isSpeaking)
              IconButton(
                icon: const Icon(
                  Icons.pause_circle_filled_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: () => controller.pauseTts(),
                tooltip: 'Pause MIRA Voice',
              )
            else if (isPaused)
              IconButton(
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: () => controller.resumeTts(),
                tooltip: 'Resume MIRA Voice',
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.replay_circle_filled_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: () => controller.replayCurrentSection(),
                tooltip: 'Replay Section',
              ),
            // Stop button
            if (isSpeaking || isPaused)
              IconButton(
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: Colors.grey,
                  size: 24,
                ),
                onPressed: () => controller.stopTts(),
                tooltip: 'Stop Audio',
              ),
          ],
        ),
      );
    });
  }

  // ── Phase Router ──────────────────────────────────────────────────
  Widget _buildPhaseContent(BuildContext context, bool isDark, Size size) {
    switch (controller.currentPhase.value) {
      case 1:
        return _buildPhase1Teaching(context, isDark);
      case 2:
        return _buildPhase2Speaking(context, isDark, size);
      case 3:
      default:
        return _buildPhase3Completion(context, isDark);
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // PHASE 1: AI TEACHING (15 Mins)
  // ═════════════════════════════════════════════════════════════════
  Widget _buildPhase1Teaching(BuildContext context, bool isDark) {
    final lesson = controller.dailyLesson.value!;
    final teaching = lesson.teachingContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Animated MIRA Teacher Avatar with Procedural Lip-Sync ───
        const MiraAvatarWidget(size: 110, showControls: true),

        const SizedBox(height: 14),

        // ── Tamil Hints & Translation Toggle Bar ────────────────────
        Obx(() {
          final isTamilOn = controller.showTamilHints.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isTamilOn
                  ? const Color(0xFFEAB308).withValues(alpha: 0.12)
                  : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTamilOn
                    ? const Color(0xFFEAB308).withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: Color(0xFFEAB308),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tamil Explanations (தமிழ் விளக்கம்)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Show Tamil hints for vocabulary, grammar rules & dialogue',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isTamilOn,
                  onChanged: (val) => controller.showTamilHints.value = val,
                  activeThumbColor: const Color(0xFFEAB308),
                  activeTrackColor: const Color(0xFFEAB308)
                      .withValues(alpha: 0.5),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 14),

        // ── Lesson Objective & Full Lesson Card ─────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DAY ${lesson.day} • ${lesson.difficulty.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => controller.teachFullLesson(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Teach Lesson 🔊',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lesson.topic,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lesson.objective,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.4,
                ),
              ),
              if (teaching != null &&
                  teaching.intro.whyLearnThis.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          teaching.intro.whyLearnThis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Obx(() {
                if (controller.showTamilHints.value &&
                    teaching != null &&
                    teaching.intro.tamilOverview != null &&
                    teaching.intro.tamilOverview!.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🇮🇳 ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Text(
                            teaching.intro.tamilOverview!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Sub-step switcher (Vocabulary, Grammar, Practical Dialogue) ─
        Obx(() {
          final subStep = controller.teachingSubStep.value;
          return Row(
            children: [
              _buildSubStepChip('1. Vocabulary', 0, subStep == 0, isDark),
              const SizedBox(width: 8),
              _buildSubStepChip('2. Grammar', 1, subStep == 1, isDark),
              const SizedBox(width: 8),
              _buildSubStepChip('3. Conversation', 2, subStep == 2, isDark),
            ],
          );
        }),

        const SizedBox(height: 14),

        // ── Sub-step Dynamic Content ───────────────────────────────
        Obx(() {
          switch (controller.teachingSubStep.value) {
            case 0:
              return _buildVocabularySection(lesson, isDark);
            case 1:
              return _buildGrammarSection(lesson, isDark);
            case 2:
            default:
              return _buildConversationDialogueSection(lesson, isDark);
          }
        }),

        const SizedBox(height: 24),

        // ── Continue to Phase 2 Button ─────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => controller.setPhase(2),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text(
              'Start Phase 2: Speaking Practice 🎙️',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubStepChip(
    String label,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => controller.setTeachingSubStep(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[300] : Colors.grey[800]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Vocabulary Section ─────────────────────────────────────────────
  Widget _buildVocabularySection(DailyLessonModel lesson, bool isDark) {
    final vocabItems = lesson.teachingContent?.vocabularyItems ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Key Vocabulary & Meanings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final allVocab = vocabItems.isNotEmpty
                    ? vocabItems.map((v) => v.word).join(', ')
                    : lesson.vocabularyFocus.join(', ');
                controller.speakLessonText(
                  "Key vocabulary words for today: $allVocab. Repeat each word after me.",
                );
              },
              icon: const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Read All',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (vocabItems.isNotEmpty)
          ...vocabItems.map((v) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            v.word,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => controller.repeatSentence(
                          '${v.word}. ${v.exampleSentence}',
                        ),
                        tooltip: 'Pronounce Word',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    v.meaning,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Obx(() {
                    if (controller.showTamilHints.value &&
                        v.tamilMeaning != null &&
                        v.tamilMeaning!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'தமிழ் பொருள்: ${v.tamilMeaning!}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Example: "${v.exampleSentence}"',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey[200] : Colors.grey[800],
                            height: 1.35,
                          ),
                        ),
                        Obx(() {
                          if (controller.showTamilHints.value &&
                              v.tamilExample != null &&
                              v.tamilExample!.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'உதாரணம்: ${v.tamilExample!}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          })
        else
          ...lesson.vocabularyFocus.map((word) {
            final example = _getWordExample(word, lesson.topic);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Example: "$example"',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () =>
                        controller.repeatSentence('$word. $example'),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Grammar & Common Mistakes Section ─────────────────────────────
  Widget _buildGrammarSection(DailyLessonModel lesson, bool isDark) {
    final grammarRules = lesson.teachingContent?.grammarRules ?? [];
    final commonMistakes = lesson.teachingContent?.commonMistakes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Grammar Rules & Common Mistakes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final rule = grammarRules.isNotEmpty
                    ? grammarRules.first.ruleName
                    : lesson.grammarFocus.join('. ');
                controller.speakLessonText(
                  "Today's grammar focus: $rule. Let's learn how to speak it accurately.",
                );
              },
              icon: const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: Color(0xFF8B5CF6),
              ),
              label: const Text(
                'Read Rule',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1. Grammar Rule Cards
        if (grammarRules.isNotEmpty)
          ...grammarRules.map((rule) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule.ruleName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rule.explanation,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  if (rule.formula != null && rule.formula!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Formula: ${rule.formula!}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ],
                  Obx(() {
                    if (controller.showTamilHints.value &&
                        rule.tamilExplanation != null &&
                        rule.tamilExplanation!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'தமிழ் குறிப்பு: ${rule.tamilExplanation!}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD97706),
                            height: 1.35,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 10),
                  ...rule.examples.map(
                    (ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              ex,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? Colors.grey[200]
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => controller.repeatSentence(ex),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              size: 16,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
        else
          ...lesson.grammarFocus.map((point) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Text(
                point,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),

        const SizedBox(height: 10),

        // 2. Common Mistakes Cards
        if (commonMistakes.isNotEmpty) ...[
          const Text(
            '⚠️ Common Mistakes & Fixes:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          ...commonMistakes.map((m) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('❌ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Incorrect: "${m.incorrect}"',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✅ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Say instead: "${m.correct}"',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => controller.repeatSentence(m.correct),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          size: 16,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Why: ${m.explanation}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  Obx(() {
                    if (controller.showTamilHints.value &&
                        m.tamilExplanation != null &&
                        m.tamilExplanation!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'விளக்கம்: ${m.tamilExplanation!}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // ── Practical Conversation & Real-Life Dialogue Section ───────────
  Widget _buildConversationDialogueSection(
    DailyLessonModel lesson,
    bool isDark,
  ) {
    final scenario = lesson.teachingContent?.realLifeScenario;
    final steps = lesson.teachingContent?.stepByStepGuide ?? [];
    final recap = lesson.teachingContent?.recap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Step-by-Step Practical Speaking Guide
        if (steps.isNotEmpty) ...[
          const Text(
            'Step-by-Step Practical Guide',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...steps.map((st) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Step ${st.stepNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          st.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    st.explanation,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Try saying: "${st.practicalExample}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // 2. Real-Life Two-Person Dialogue
        Row(
          children: [
            Expanded(
              child: Text(
                scenario?.title ?? 'Conversation Dialogue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                if (scenario != null && scenario.dialogue.isNotEmpty) {
                  final text = scenario.dialogue
                      .map((d) => '${d.speaker} says: ${d.english}')
                      .join('. ');
                  controller.speakLessonText(text);
                } else {
                  controller.speakLessonText(
                    "Let's practice real dialogue for today's lesson!",
                  );
                }
              },
              icon: const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Read All',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (scenario != null && scenario.context.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            scenario.context,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
        const SizedBox(height: 8),

        if (scenario != null && scenario.dialogue.isNotEmpty)
          ...scenario.dialogue.map((line) {
            final isMira = line.speaker.toUpperCase().contains('MIRA');
            return _buildDialogueBubble(
              sender: line.speaker,
              avatarBg: isMira ? AppColors.primary : const Color(0xFF10B981),
              text: line.english,
              tamilText: line.tamil,
              isDark: isDark,
            );
          })
        else ...[
          _buildDialogueBubble(
            sender: 'MIRA',
            avatarBg: AppColors.primary,
            text:
                'Hello! When you talk about ${lesson.topic}, what is the first thing that comes to your mind?',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildDialogueBubble(
            sender: 'YOU (Student)',
            avatarBg: const Color(0xFF10B981),
            text: 'I think about expressing my ideas clearly and choosing the right words without hesitating.',
            isDark: isDark,
          ),
        ],

        // 3. Recap & Comprehension Check
        if (recap != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Lesson Recap & Check Question',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...recap.summaryPoints.map(
                  (pt) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✓ ',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            pt,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '❓ Quick Check Question:',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recap.comprehensionQuestion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 Model Answer: "${recap.suggestedAnswer}"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDialogueBubble({
    required String sender,
    required Color avatarBg,
    required String text,
    String? tamilText,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarBg,
            child: Text(
              sender.startsWith('M') ? 'M' : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: avatarBg,
                      ),
                    ),
                    InkWell(
                      onTap: () => controller.repeatSentence(text),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    height: 1.35,
                  ),
                ),
                Obx(() {
                  if (controller.showTamilHints.value &&
                      tamilText != null &&
                      tamilText.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'தமிழ்: $tamilText',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFD97706),
                          height: 1.3,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // PHASE 2: SPEAKING PRACTICE (15 Mins)
  // ═════════════════════════════════════════════════════════════════
  Widget _buildPhase2Speaking(BuildContext context, bool isDark, Size size) {
    final questions = controller.allQuestions;
    final qIndex = controller.currentQuestionIndex.value.clamp(
      0,
      questions.length - 1,
    );
    final currentQ = questions[qIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Animated MIRA Avatar with Lip-Sync for Speaking Practice ─
        const MiraAvatarWidget(
          size: 96,
          showControls: false,
          subtitleText: 'Practice answering MIRA through your microphone',
        ),

        const SizedBox(height: 14),

        // Question Progress Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${qIndex + 1} of ${questions.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
            Text(
              'Exchanges: ${controller.completedExchanges.length}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // MIRA Question Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF132F24) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.record_voice_over_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'MIRA ASKS:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                              letterSpacing: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => controller.readCurrentQuestion(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF10B981),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Listen 🔊',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currentQ,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF064E3B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Microphone Recording & Voice Exchange Area ───────────────
        _buildVoiceRecordingBox(context, isDark),

        const SizedBox(height: 16),

        // ── Evaluation Results Card ─────────────────────────────────
        Obx(() {
          final eval = controller.lastEvaluation.value;
          if (eval == null) return const SizedBox.shrink();
          return _buildEvaluationCard(eval, isDark);
        }),

        const SizedBox(height: 20),

        // ── Action Buttons (Retry, Doubts, Next Question) ───────────
        Obx(() {
          final hasEval = controller.lastEvaluation.value != null;
          return Column(
            children: [
              if (hasEval)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.retryCurrentQuestion(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Repeat Answer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.nextQuestionOrFinish(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          qIndex < questions.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          qIndex < questions.length - 1
                              ? 'Next Question'
                              : 'Finish Lesson 🎉',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              // Ask Doubt to MIRA button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showAskDoubtSheet(context, isDark),
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFFEAB308),
                  ),
                  label: const Text(
                    'Have a Doubt? Ask MIRA 💡',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEAB308),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildVoiceRecordingBox(BuildContext context, bool isDark) {
    return Obx(() {
      final isListening = controller.isListening.value;
      final isEvaluating = controller.isEvaluating.value;
      final transcript = controller.liveTranscript.value;
      final duration = controller.recordDuration.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isListening
                ? const Color(0xFFEF4444)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isListening ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isListening
                  ? Colors.redAccent.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Live Transcript or Prompt text
            Text(
              isEvaluating
                  ? 'Analyzing your voice, grammar, and fluency with MIRA...'
                  : isListening
                  ? (transcript.isEmpty
                        ? 'Listening... Speak your answer now!'
                        : '"$transcript"')
                  : (transcript.isEmpty
                        ? 'Tap the microphone to speak your answer to MIRA'
                        : '"$transcript"'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: transcript.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: isListening
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                height: 1.4,
              ),
            ),

            if (isListening) ...[
              const SizedBox(height: 8),
              Text(
                '00:${duration.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Big Center Mic Button
            GestureDetector(
              onTap: isEvaluating
                  ? null
                  : () {
                      if (isListening) {
                        controller.stopListeningAndEvaluate();
                      } else {
                        controller.startListening();
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? Colors.redAccent
                      : isEvaluating
                      ? Colors.grey
                      : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isListening ? Colors.redAccent : AppColors.primary)
                              .withValues(alpha: 0.35),
                      blurRadius: isListening ? 18 : 10,
                      spreadRadius: isListening ? 4 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: isEvaluating
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              isListening
                  ? 'Tap to Stop & Evaluate'
                  : isEvaluating
                  ? 'Processing feedback...'
                  : 'Tap to Speak',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── AI Evaluation Result Card ──────────────────────────────────────
  Widget _buildEvaluationCard(SpeechEvaluationModel eval, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'MIRA Evaluation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${eval.scores.overall}% Score',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (eval.caseType != null && eval.caseType!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCaseTypeBadge(eval.caseType!),
          ],

          // MIRA's Conversational Analysis & Feedback
          if (eval.miraReply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mira's Feedback:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eval.miraReply,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF064E3B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Scores Bar (Fluency, Grammar, Pronunciation)
          Row(
            children: [
              _buildScoreBadge(
                'Fluency',
                '${eval.scores.fluency}%',
                Colors.blue,
                isDark,
              ),
              const SizedBox(width: 6),
              _buildScoreBadge(
                'Grammar',
                '${eval.scores.grammar}%',
                Colors.purple,
                isDark,
              ),
              const SizedBox(width: 6),
              _buildScoreBadge(
                'Pronunciation',
                '${eval.scores.pronunciation}%',
                Colors.green,
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Corrected sentence highlight
          if (eval.corrected.isNotEmpty && eval.corrected != eval.original) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ More Natural Way to Say It:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${eval.corrected}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eval.explanation,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                eval.explanation,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Pronunciation tips
          if (eval.pronunciationTips.isNotEmpty) ...[
            Text(
              '🗣️ Pronunciation Guidance:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            ...eval.pronunciationTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $tip',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],

          // Dynamic Progressive Next Question Card
          if (eval.nextSuggestedQuestion != null &&
              eval.nextSuggestedQuestion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Next Progressive Question:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eval.nextSuggestedQuestion!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF064E3B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaseTypeBadge(String caseType) {
    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;

    switch (caseType) {
      case 'CASE_A_CORRECT':
        badgeColor = const Color(0xFF10B981);
        badgeLabel = 'Spot-on English! 🌟';
        badgeIcon = Icons.stars_rounded;
        break;
      case 'CASE_B_GRAMMAR_MISTAKE':
        badgeColor = const Color(0xFFF59E0B);
        badgeLabel = 'Grammar Polish 💡';
        badgeIcon = Icons.lightbulb_rounded;
        break;
      case 'CASE_C_INCOMPLETE':
        badgeColor = const Color(0xFF3B82F6);
        badgeLabel = 'Complete Your Thought 🔄';
        badgeIcon = Icons.more_horiz_rounded;
        break;
      case 'CASE_D_UNRELATED':
        badgeColor = const Color(0xFF8B5CF6);
        badgeLabel = 'Stay on Topic 🎯';
        badgeIcon = Icons.track_changes_rounded;
        break;
      case 'CASE_E_SHORT':
        badgeColor = const Color(0xFF6366F1);
        badgeLabel = 'Expand into Full Sentence 📝';
        badgeIcon = Icons.format_size_rounded;
        break;
      case 'CASE_F_EMPTY_FAILED':
        badgeColor = const Color(0xFFEF4444);
        badgeLabel = 'Voice Not Detected 🎙️';
        badgeIcon = Icons.mic_off_rounded;
        break;
      case 'CASE_G_VALID_ALTERNATIVE':
        badgeColor = const Color(0xFF06B6D4);
        badgeLabel = 'Natural Alternative Phrasing ✨';
        badgeIcon = Icons.thumb_up_alt_rounded;
        break;
      default:
        badgeColor = AppColors.primary;
        badgeLabel = 'Evaluation Feedback';
        badgeIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // PHASE 3: SESSION COMPLETION & CELEBRATION
  // ═════════════════════════════════════════════════════════════════
  Widget _buildPhase3Completion(BuildContext context, bool isDark) {
    final lesson = controller.dailyLesson.value!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // Big Celebration Badge
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Day ${lesson.day} Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Mastered: ${lesson.topic}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: 24),

            // Score & Rewards Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRewardItem(
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF10B981),
                      value: '${controller.overallLessonScore.value}%',
                      label: 'Speaking Score',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRewardItem(
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFF59E0B),
                      value: '+${controller.earnedXp.value} Pts',
                      label: 'Practice Points',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRewardItem(
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFEF4444),
                      value:
                          '${controller.newStreak.value} ${controller.newStreak.value == 1 ? 'Day' : 'Days'}',
                      label: 'Daily Streak',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Return to Home button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.finishAndReturnHome(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  'Continue to Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ask Doubt Bottom Sheet ─────────────────────────────────────────
  void _showAskDoubtSheet(BuildContext context, bool isDark) {
    Get.bottomSheet(
      Builder(
        builder: (sheetContext) {
          final mediaQuery = MediaQuery.of(sheetContext);
          final bottomInset = mediaQuery.viewInsets.bottom;
          final bottomSafe = mediaQuery.padding.bottom;
          final bottomPadding = bottomInset > 0
              ? (bottomInset + 16.0)
              : (bottomSafe > 0 ? bottomSafe + 24.0 : 28.0);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              color: Color(0xFFEAB308),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ask MIRA Any Doubt',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Type or speak any grammar, pronunciation, or vocabulary question. MIRA will explain it clearly with examples.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.doubtInputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (q) {
                      if (q.trim().isNotEmpty) {
                        controller.askDoubt(q.trim());
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g., When do I say "went" vs "have gone"?',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          final q = controller.doubtInputController.text;
                          controller.askDoubt(q);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(() {
                    if (controller.isAskingDoubt.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    final answer = controller.lastDoubtAnswer.value;
                    if (answer.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💡 MIRA Explains:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCA8A04),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            answer,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => controller.repeatSentence(answer),
                              icon: const Icon(Icons.volume_up_rounded, size: 16),
                              label: const Text(
                                'Hear Explanation 🔊',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  String _getWordExample(String word, String topic) {
    final lower = word.toLowerCase();
    if (lower.contains('introduce') || lower.contains('hello')) {
      return "Let me introduce myself: I am passionate about learning English.";
    } else if (lower.contains('parent') ||
        lower.contains('father') ||
        lower.contains('mother')) {
      return "My parents always encourage and support me to speak fluent English.";
    } else if (lower.contains('sibling') ||
        lower.contains('brother') ||
        lower.contains('sister')) {
      return "I often practice daily English conversations with my siblings at home.";
    } else if (lower.contains('family')) {
      return "Spending quality time with my family brings me tremendous joy.";
    } else if (lower.contains('friend') || lower.contains('colleague')) {
      return "My colleagues communicate in English during our daily morning meetings.";
    } else if (lower.contains('hesitate')) {
      return "Don't hesitate to speak; practice leads to effortless confidence.";
    } else if (lower.contains('articulate')) {
      return "She gave an articulate and persuasive answer during the interview.";
    } else if (lower.contains('fluent') || lower.contains('fluency')) {
      return "Consistent 15-minute voice drills make your speech truly fluent.";
    }
    return "I use '$word' frequently when discussing $topic.";
  }
}
