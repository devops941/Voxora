import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/modules/speaking_practice/controllers/speaking_practice_controller.dart';

class SpeakingPracticeView extends GetView<SpeakingPracticeController> {
  const SpeakingPracticeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final hPadding = (size.width * 0.045).clamp(14.0, 20.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            size: 20,
          ),
          onPressed: () {
            controller.stopTts();
            Get.back();
          },
        ),
        title: Row(
          children: [
            // ── Real MIRA Teacher Avatar with Online Badge ──────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/mira_teacher.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primary,
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // ── Title & Live Status (Expanded to prevent overflow) ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'MIRA AI Voice Coach',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final isListening = controller.isListening.value;
                    final isThinking = controller.isThinking.value;
                    final isSpeaking = controller.isTtsSpeaking.value;

                    String statusText;
                    Color statusColor;

                    if (isListening) {
                      statusText = 'Listening to you...';
                      statusColor = Colors.redAccent;
                    } else if (isThinking) {
                      statusText = 'Analyzing your speech...';
                      statusColor = const Color(0xFF8B5CF6);
                    } else if (isSpeaking) {
                      statusText = 'MIRA is speaking 🔊';
                      statusColor = AppColors.primary;
                    } else {
                      statusText = 'Online • Real-time Feedback';
                      statusColor = const Color(0xFF16A34A);
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            tooltip: 'Restart Conversation',
            onPressed: () => controller.resetConversation(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Modern Topic Selector Pills Bar ───────────────────
            _buildTopicSelector(isDark),

            // ── Chat Stream ───────────────────────────────────────
            Expanded(
              child: Obx(() {
                final msgs = controller.messages;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: msgs.length,
                  itemBuilder: (context, idx) {
                    final msg = msgs[idx];
                    return _buildMessageBubble(msg, isDark);
                  },
                );
              }),
            ),

            // ── Interactive Quick Suggestions Bar ─────────────────
            _buildQuickSuggestions(isDark),

            // ── Live Speech Waveform / Transcript Bar ─────────────
            _buildLiveTranscriptBar(isDark),

            // ── Bottom Voice & Text Input Control Bar ─────────────
            _buildBottomControls(context, isDark),
          ],
        ),
      ),
    );
  }

  // ── Modern Topic Selector ──────────────────────────────────────────
  Widget _buildTopicSelector(bool isDark) {
    final topicIcons = {
      'Casual Small Talk': '💬',
      'Job Interview Practice': '💼',
      'Ordering at a Restaurant': '🍽️',
      'Travel & Asking Directions': '✈️',
      'Free Conversational Flow': '⚡',
    };

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: controller.topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final topic = controller.topics[i];
          final icon = topicIcons[topic] ?? '🎯';

          return Obx(() {
            final isSelected = controller.selectedTopic.value == topic;
            return InkWell(
              onTap: () => controller.selectTopic(topic),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      topic,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  // ── Chat Bubble ───────────────────────────────────────────────────
  Widget _buildMessageBubble(SpeakingMessage msg, bool isDark) {
    final isMira = msg.sender == 'mira';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMira ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          // MIRA Teacher Real Avatar
          if (isMira) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/mira_teacher.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Message Card & Feedbacks
          Flexible(
            child: Column(
              crossAxisAlignment: isMira ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // Speech Bubble Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMira
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isMira
                        ? (isDark ? AppColors.surfaceDark : Colors.white)
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMira ? 4 : 18),
                      bottomRight: Radius.circular(isMira ? 18 : 4),
                    ),
                    border: isMira
                        ? Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            width: 1.2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isMira
                            ? Colors.black.withValues(alpha: 0.04)
                            : const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: isMira
                              ? (isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B))
                              : Colors.white,
                          height: 1.45,
                          letterSpacing: 0.1,
                        ),
                      ),

                      // Replay Speaker Icon for MIRA voice
                      if (isMira) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => controller.speakMiraText(msg.text),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.volume_up_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Listen to MIRA',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── AI Speech Evaluation Score Badges (for user answers) ──
                if (!isMira && msg.scores != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildSmallScore('Overall', '${msg.scores!.overall}%', const Color(0xFF2563EB)),
                        _buildSmallScore('Fluency', '${msg.scores!.fluency}%', const Color(0xFF16A34A)),
                        _buildSmallScore('Grammar', '${msg.scores!.grammar}%', const Color(0xFF7C3AED)),
                        _buildSmallScore('Pronounce', '${msg.scores!.pronunciation}%', const Color(0xFFD97706)),
                      ],
                    ),
                  ),
                ],

                // ── AI Grammar Tip & Improvement Box ────────────────────
                if (!isMira && msg.corrected != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF261D1A) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.red.withValues(alpha: 0.3) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_fix_high_rounded, color: Color(0xFFDC2626), size: 15),
                            SizedBox(width: 6),
                            Text(
                              '💡 More Natural English:',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${msg.corrected}"',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                            height: 1.35,
                          ),
                        ),
                        if (msg.explanation != null && msg.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            msg.explanation!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : const Color(0xFFB91C1C),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScore(String label, String score, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        Text(
          score,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ── Quick Suggestions Bar ──────────────────────────────────────────
  Widget _buildQuickSuggestions(bool isDark) {
    return Obx(() {
      final suggestions = controller.currentSuggestions;
      if (suggestions.isEmpty || controller.isListening.value) {
        return const SizedBox.shrink();
      }

      return Container(
        height: 36,
        margin: const EdgeInsets.only(bottom: 6),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final prompt = suggestions[i];
            return InkWell(
              onTap: () => controller.sendUserResponse(prompt),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ── Live Speech Waves / Transcript Indicator ───────────────────────
  Widget _buildLiveTranscriptBar(bool isDark) {
    return Obx(() {
      final isListening = controller.isListening.value;
      final transcript = controller.liveTranscript.value;

      if (!isListening && transcript.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          border: Border(
            top: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transcript.isEmpty ? 'Listening... Speak your sentence now' : '"$transcript"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '00:${controller.recordDuration.value.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Bottom Voice & Text Input Controls ─────────────────────────────
  Widget _buildBottomControls(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text Input Field Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Speak or type to MIRA...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (txt) {
                        final trimmed = txt.trim();
                        if (trimmed.isNotEmpty) {
                          controller.sendUserResponse(trimmed);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(34, 34),
                    ),
                    onPressed: () {
                      final txt = controller.textController.text.trim();
                      if (txt.isNotEmpty) {
                        controller.sendUserResponse(txt);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Big Glowing Gradient Mic Button
          Obx(() {
            final isListening = controller.isListening.value;
            final isThinking = controller.isThinking.value;

            return GestureDetector(
              onTap: isThinking
                  ? null
                  : () {
                      if (isListening) {
                        controller.stopListeningAndSend();
                      } else {
                        controller.startListening();
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isListening
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: (isListening ? Colors.redAccent : const Color(0xFF2563EB))
                          .withValues(alpha: 0.4),
                      blurRadius: isListening ? 16 : 8,
                      spreadRadius: isListening ? 2 : 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: isThinking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : Icon(
                          isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
