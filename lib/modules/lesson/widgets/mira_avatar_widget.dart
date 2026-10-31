import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/modules/lesson/controllers/lesson_controller.dart';

/// Interactive, Animated MIRA Avatar with Procedural Lip-Sync
/// Synchronizes mouth movement with TTS voice audio playback and returns
/// to a natural resting smile expression when idle, paused, or completed.
class MiraAvatarWidget extends StatefulWidget {
  final double size;
  final bool showControls;
  final String? subtitleText;

  /// Toggle to control visibility of MIRA Teacher character image (assets/images/mira_teacher.png).
  static const bool enableAvatarImage = true;

  /// Toggle to control procedural mouth lip-sync animation overlay.
  /// Set to false to preserve MIRA's natural static expression without artificial mouth movement.
  static const bool enableMouthLipSync = false;

  const MiraAvatarWidget({
    super.key,
    this.size = 130,
    this.showControls = true,
    this.subtitleText,
  });

  @override
  State<MiraAvatarWidget> createState() => _MiraAvatarWidgetState();
}

class _MiraAvatarWidgetState extends State<MiraAvatarWidget> with TickerProviderStateMixin {
  late final LessonController controller;

  // Lip-sync mouth animation controller
  late final AnimationController _mouthAnimController;
  // Ambient breathing / speech glow ring controller
  late final AnimationController _glowController;
  // Sound waves audio spectrum controller
  late final AnimationController _spectrumController;

  Worker? _speakingWorker;
  Worker? _pauseWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LessonController>();

    // Mouth animation cycles rapidly (approx 4 Hz) while speaking to simulate natural phonemes
    _mouthAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Glow aura breathes smoothly
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Spectrum bars oscillate rhythmically
    _spectrumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Reactively trigger animations based on TTS voice state
    _speakingWorker = ever(controller.isTtsSpeaking, (bool isSpeaking) {
      if (mounted) {
        if (isSpeaking) {
          if (MiraAvatarWidget.enableMouthLipSync) {
            _mouthAnimController.repeat(reverse: true);
          }
          _spectrumController.repeat(reverse: true);
        } else {
          if (MiraAvatarWidget.enableMouthLipSync) {
            _mouthAnimController.animateTo(0.0, duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
          }
          _spectrumController.stop();
        }
      }
    });

    _pauseWorker = ever(controller.isTtsPaused, (bool isPaused) {
      if (mounted && isPaused) {
        if (MiraAvatarWidget.enableMouthLipSync) {
          _mouthAnimController.animateTo(0.0, duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
        }
        _spectrumController.stop();
      }
    });

    // If already speaking on mount
    if (controller.isTtsSpeaking.value) {
      if (MiraAvatarWidget.enableMouthLipSync) {
        _mouthAnimController.repeat(reverse: true);
      }
      _spectrumController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _speakingWorker?.dispose();
    _pauseWorker?.dispose();
    _mouthAnimController.dispose();
    _glowController.dispose();
    _spectrumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isSpeaking = controller.isTtsSpeaking.value;
      final isPaused = controller.isTtsPaused.value;
      final isListening = controller.isListening.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSpeaking
              ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSpeaking
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isListening
                    ? Colors.redAccent.withValues(alpha: 0.4)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight)),
            width: isSpeaking || isListening ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSpeaking)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar Character Image (assets/images/mira_teacher.png) ──
            if (MiraAvatarWidget.enableAvatarImage) ...[
              Center(
                child: SizedBox(
                  width: widget.size + 24,
                  height: widget.size + 24,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulsing Glow Halo
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          final glow = isSpeaking ? _glowController.value * 12 : 2.0;
                          final haloColor = isSpeaking
                              ? AppColors.primary.withValues(alpha: 0.35 + _glowController.value * 0.25)
                              : (isListening
                                  ? Colors.redAccent.withValues(alpha: 0.35)
                                  : const Color(0xFF38BDF8).withValues(alpha: 0.2));

                          return Container(
                            width: widget.size + 14 + glow,
                            height: widget.size + 14 + glow,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: haloColor, width: isSpeaking ? 3.0 : 1.8),
                              boxShadow: [
                                BoxShadow(
                                  color: haloColor,
                                  blurRadius: isSpeaking ? 16 + glow : 6,
                                  spreadRadius: isSpeaking ? 2 : 0,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Avatar Portrait Frame
                      Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(
                            color: isSpeaking
                                ? AppColors.primary
                                : (isListening ? Colors.redAccent : const Color(0xFF64748B)),
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Base MIRA Character Image
                              Image.asset(
                                'assets/images/mira_teacher.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.primary,
                                    child: const Center(
                                      child: Icon(Icons.school_rounded, color: Colors.white, size: 48),
                                    ),
                                  );
                                },
                              ),

                              // Procedural Mouth Lip-Sync Canvas Layer (Enabled only if enableMouthLipSync is true)
                              if (MiraAvatarWidget.enableMouthLipSync)
                                AnimatedBuilder(
                                  animation: _mouthAnimController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: Size(widget.size, widget.size),
                                      painter: _MiraLipSyncPainter(
                                        openness: isSpeaking ? _mouthAnimController.value : 0.0,
                                        isSpeaking: isSpeaking,
                                        avatarSize: widget.size,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Live mic badge when listening
                      if (isListening)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.redAccent, blurRadius: 8),
                              ],
                            ),
                            child: const Icon(Icons.mic, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Dynamic Audio Spectrum Waves ───────────────────────────
            if (isSpeaking)
              SizedBox(
                height: 18,
                child: AnimatedBuilder(
                  animation: _spectrumController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(7, (index) {
                        final phase = (index * 0.25) + (_spectrumController.value * 2 * math.pi);
                        final barHeight = 4.0 + (math.sin(phase).abs() * 12.0);
                        return Container(
                          width: 3.5,
                          height: barHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    );
                  },
                ),
              )
            else if (MiraAvatarWidget.enableAvatarImage)
              const SizedBox(height: 18),

            const SizedBox(height: 4),

            // ── Status Pill Badge ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSpeaking
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isPaused
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : (isListening
                            ? Colors.redAccent.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)))),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSpeaking
                          ? AppColors.primary
                          : (isPaused
                              ? const Color(0xFFF59E0B)
                              : (isListening ? Colors.redAccent : Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSpeaking
                        ? 'MIRA is Speaking & Teaching'
                        : (isPaused
                            ? 'MIRA Voice Paused'
                            : (isListening ? 'Listening to You...' : 'MIRA Ready to Teach')),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isSpeaking
                          ? AppColors.primary
                          : (isPaused
                              ? const Color(0xFFD97706)
                              : (isListening
                                  ? Colors.redAccent
                                  : (isDark ? Colors.grey[300] : Colors.grey[700]))),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.subtitleText != null && widget.subtitleText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.subtitleText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Interactive Playback Controls ─────────────────────────
            if (widget.showControls) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Play / Pause Button
                  if (isSpeaking)
                    ElevatedButton.icon(
                      onPressed: () => controller.pauseTts(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.pause_rounded, size: 18),
                      label: const Text('Pause', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else if (isPaused)
                    ElevatedButton.icon(
                      onPressed: () => controller.resumeTts(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        final lesson = controller.dailyLesson.value;
                        final script = lesson?.teachingContent?.spokenScript;
                        if (script != null && script.isNotEmpty) {
                          controller.speakLessonText(script);
                        } else {
                          controller.replayCurrentSection();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('Teach Lesson 🔊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                  // Replay Button
                  OutlinedButton.icon(
                    onPressed: () => controller.replayCurrentSection(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: const Text('Replay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),

                  // Stop Button
                  if (isSpeaking || isPaused)
                    IconButton(
                      onPressed: () => controller.stopTts(),
                      icon: const Icon(Icons.stop_circle_outlined, color: Colors.grey, size: 26),
                      tooltip: 'Stop Audio',
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// Custom Painter for realistic lip-sync mouth animation on MIRA
class _MiraLipSyncPainter extends CustomPainter {
  final double openness; // 0.0 (closed resting smile) to 1.0 (fully open vowel)
  final bool isSpeaking;
  final double avatarSize;

  _MiraLipSyncPainter({
    required this.openness,
    required this.isSpeaking,
    required this.avatarSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSpeaking || openness < 0.05) {
      // Natural resting smile is preserved directly on the underlying image
      return;
    }

    // Coordinates mapped precisely to MIRA's mouth region in mira_teacher.png
    // The mouth is horizontally centered and vertically at ~63.5% of the portrait height
    final centerX = size.width * 0.505;
    final mouthY = size.height * 0.635;
    final mouthWidth = size.width * (0.16 + (openness * 0.04));
    final mouthHeight = size.height * (0.02 + (openness * 0.075));

    final mouthRect = Rect.fromCenter(
      center: Offset(centerX, mouthY),
      width: mouthWidth,
      height: mouthHeight,
    );

    // 1. Inner oral cavity shadow (natural dark depth)
    final cavityPaint = Paint()
      ..color = const Color(0xFF381414).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawOval(mouthRect, cavityPaint);

    // 2. Hint of upper teeth line
    if (openness > 0.3) {
      final teethPaint = Paint()
        ..color = const Color(0xFFFDF8F6).withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;

      final teethRect = Rect.fromLTWH(
        mouthRect.left + (mouthWidth * 0.18),
        mouthRect.top + 1.0,
        mouthWidth * 0.64,
        mouthHeight * 0.32,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(teethRect, const Radius.circular(2)), teethPaint);
    }

    // 3. Natural upper and lower lip contour with warm lipstick tone matching MIRA
    final lipPaint = Paint()
      ..color = const Color(0xFFC45A65).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final upperLipPath = Path();
    upperLipPath.moveTo(mouthRect.left - 1, mouthY);
    upperLipPath.quadraticBezierTo(centerX, mouthRect.top - 1.5, mouthRect.right + 1, mouthY);
    canvas.drawPath(upperLipPath, lipPaint);

    final lowerLipPath = Path();
    lowerLipPath.moveTo(mouthRect.left - 1, mouthY);
    lowerLipPath.quadraticBezierTo(centerX, mouthRect.bottom + 1.5, mouthRect.right + 1, mouthY);
    canvas.drawPath(lowerLipPath, lipPaint);
  }

  @override
  bool shouldRepaint(covariant _MiraLipSyncPainter oldDelegate) {
    return oldDelegate.openness != openness || oldDelegate.isSpeaking != isSpeaking;
  }
}
