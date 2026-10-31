import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:voxora/core/constants/api_constants.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/storage/local_storage.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/data/repositories/auth_repository.dart';

class LevelSelectionView extends StatefulWidget {
  const LevelSelectionView({super.key});

  @override
  State<LevelSelectionView> createState() => _LevelSelectionViewState();
}

enum LearningLevel { beginner, intermediate, advanced }

class _LevelSelectionViewState extends State<LevelSelectionView>
    with SingleTickerProviderStateMixin {
  LearningLevel _selectedLevel = LearningLevel.beginner;

  // Flow step: 0 = Choose Level, 1 = AI Speaking Test, 2 = 90-Day Schedule Result
  int _currentStep = 0;

  // Speech & Recording state
  bool _isRecording = false;
  bool _hasRecorded = false;
  int _recordSeconds = 0;
  Timer? _timer;

  // Live Speech Recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _speechTranscript = '';

  // Analysis loading state
  bool _isAnalyzing = false;
  String _analyzingStatus = 'Analyzing your speech with MIRA AI...';

  // Analysis Result
  Map<String, dynamic>? _assessmentResult;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) => debugPrint('Speech status: $val'),
      );
      if (mounted) {
        setState(() => _speechEnabled = available);
      }
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _timer?.cancel();
      try {
        if (_speechToText.isListening) {
          await _speechToText.stop();
        }
      } catch (_) {}
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
      });
    } else {
      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _recordSeconds = 0;
        _speechTranscript = '';
      });

      if (_speechEnabled) {
        try {
          await _speechToText.listen(
            onResult: (result) {
              if (mounted) {
                setState(() {
                  _speechTranscript = result.recognizedWords;
                });
              }
            },
            listenOptions: SpeechListenOptions(
              listenFor: const Duration(seconds: 40),
              pauseFor: const Duration(seconds: 5),
            ),
          );
        } catch (e) {
          debugPrint('Speech listen error: $e');
        }
      }

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 30) {
          _timer?.cancel();
          try {
            _speechToText.stop();
          } catch (_) {}
          setState(() {
            _isRecording = false;
            _hasRecorded = true;
          });
        }
      });
    }
  }

  void _useSampleSpeech(String sample) {
    setState(() {
      _speechTranscript = sample;
      _hasRecorded = true;
      _recordSeconds = 18;
    });
  }

  String _getDefaultTranscriptForLevel() {
    if (_selectedLevel == LearningLevel.beginner) {
      return 'Hello MIRA, my name is Sharmila. I am from Chennai. I love reading books and I want to speak English fluently with confidence.';
    } else if (_selectedLevel == LearningLevel.intermediate) {
      return 'I have been working as a professional for two years. I can manage everyday conversations, but I want to speak without hesitating in meetings.';
    } else {
      return 'In my perspective, effective communication in English requires not only vocabulary, but also proper intonation and executive confidence.';
    }
  }

  Future<void> _analyzeAndGenerateSchedule() async {
    final transcript = _speechTranscript.trim().isNotEmpty
        ? _speechTranscript.trim()
        : _getDefaultTranscriptForLevel();

    setState(() {
      _isAnalyzing = true;
      _analyzingStatus = 'Analyzing pronunciation clarity & speech rate...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _analyzingStatus = 'Evaluating grammar, connective words & fluency...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _analyzingStatus = 'Synthesizing your custom 90-day learning roadmap...';
    });

    final levelName = _selectedLevel == LearningLevel.beginner
        ? 'Beginner'
        : _selectedLevel == LearningLevel.intermediate
            ? 'Intermediate'
            : 'Advanced';

    String? token;
    String? userId;
    try {
      if (Get.isRegistered<LocalStorage>()) {
        final storage = Get.find<LocalStorage>();
        token = await storage.getToken();
        final user = await storage.getUser();
        userId = user?.id;
      }
    } catch (_) {}

    final Map<String, dynamic> requestData = {
      'transcript': transcript,
      'selectedLevel': levelName,
      'durationSeconds': _recordSeconds > 0 ? _recordSeconds : 18,
    };
    if (userId != null && userId.isNotEmpty) {
      requestData['userId'] = userId;
    }

    final Map<String, dynamic> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/ai/assess-speech',
        data: requestData,
        options: Options(headers: headers),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        _assessmentResult = response.data['data'] as Map<String, dynamic>;
      } else {
        _assessmentResult = _computeLocalAssessment(transcript, levelName);
      }
    } catch (e) {
      debugPrint('Speech assessment network fallback: $e');
      _assessmentResult = _computeLocalAssessment(transcript, levelName);
    }

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _currentStep = 2; // Move to Schedule result screen
    });
  }

  Map<String, dynamic> _computeLocalAssessment(String transcript, String level) {
    final words = transcript.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;
    final wpm = (_recordSeconds > 0) ? ((wordCount / _recordSeconds) * 60).round() : 95;

    int fluency = (wpm >= 70 && wpm <= 135) ? 84 : 74;
    int pronunciation = (level == 'Beginner') ? 80 : (level == 'Intermediate' ? 85 : 89);
    int grammar = (wordCount > 10) ? 82 : 75;
    int vocabulary = (wordCount > 14) ? 84 : 76;

    String strength = 'Clear speech tone and natural communicative willingness.';
    String focusArea = 'Building sentence connectors and reducing pauses between thoughts.';
    String feedback = 'Good conversational potential! Daily practice will give you spontaneous flow.';

    if (level == 'Beginner') {
      strength = 'Understandable self-introduction with good basic clarity.';
      focusArea = 'Expanding vocabulary from basic words to full sentence patterns.';
      feedback = 'MIRA AI detected high enthusiasm! Regular 15-min practice will build instant confidence.';
    } else if (level == 'Intermediate') {
      strength = 'Good sentence structure and communicative confidence.';
      focusArea = 'Tense consistency and smooth transitions between ideas.';
      feedback = 'Strong conversational foundation! Ready for workplace and interview fluency.';
    } else {
      strength = 'Fluent articulation and broad vocabulary.';
      focusArea = 'Polishing accent rhythm, idiomatic expressions, and professional presence.';
      feedback = 'High speaking ability! Perfecting native cadence and leadership communication.';
    }

    return {
      'transcript': transcript,
      'recommendedLevel': level,
      'levelBadge': '$level Level',
      'scores': {
        'fluency': fluency,
        'pronunciation': pronunciation,
        'grammar': grammar,
        'vocabulary': vocabulary,
      },
      'diagnosis': {
        'strength': strength,
        'focusArea': focusArea,
        'feedbackSummary': feedback,
      },
      'schedule': [
        {
          'month': 1,
          'daysRange': 'Days 1 – 30',
          'title': level == 'Beginner'
              ? 'Foundation & Daily Sentence Flow'
              : 'Fluency Habit & Hesitation Removal',
          'desc': level == 'Beginner'
              ? 'Daily 15-min speaking with MIRA, essential 500 spoken words, small talk greetings & introductions.'
              : 'Eliminating mental translation, conversational connectors (so, because, although), daily impromptu speech drills.',
          'colorHex': '#2563EB',
        },
        {
          'month': 2,
          'daysRange': 'Days 31 – 60',
          'title': level == 'Beginner'
              ? 'Conversational Confidence & Everyday English'
              : 'Workplace English & Spontaneous Storytelling',
          'desc': level == 'Beginner'
              ? 'Asking questions naturally, expressing opinions, ordering food, shopping & everyday interactions.'
              : 'Handling meetings, job interview answers, explaining ideas smoothly without pausing.',
          'colorHex': '#059669',
        },
        {
          'month': 3,
          'daysRange': 'Days 61 – 90',
          'title': level == 'Beginner'
              ? 'Fluency Habit & Confident Public Speaking'
              : 'Accent Polish & Native Expressions',
          'desc': level == 'Beginner'
              ? 'Speaking without fear in groups, phone calls in English, automatic sentence building.'
              : 'Advanced idioms, natural intonation, effortless English thinking and executive presentation skills.',
          'colorHex': '#7C3AED',
        },
      ],
    };
  }

  Future<void> _finishAndGoToDashboard() async {
    final levelName = _assessmentResult?['recommendedLevel'] ??
        (_selectedLevel == LearningLevel.beginner
            ? 'Beginner'
            : _selectedLevel == LearningLevel.intermediate
                ? 'Intermediate'
                : 'Advanced');

    try {
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().updateLevel(levelName.toString());
      }
    } catch (_) {}

    Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPadding = (size.width * 0.065).clamp(20.0, 32.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2563EB),
            size: 24,
          ),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: _currentStep == 0
              ? _buildLevelSelectionStep(context, isDark, size, hPadding)
              : _currentStep == 1
                  ? _buildAiSpeakingAssessmentStep(context, isDark, size, hPadding)
                  : _build90DayScheduleStep(context, isDark, size, hPadding),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STEP 1: CHOOSE YOUR LEVEL (Matching Mockup 6 Exactly)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildLevelSelectionStep(
    BuildContext context,
    bool isDark,
    Size size,
    double hPadding,
  ) {
    final primaryBlue = const Color(0xFF2563EB);
    final headerColor = isDark ? AppColors.textPrimaryDark : const Color(0xFF1B3B6F);
    final subheaderColor = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    return SingleChildScrollView(
      key: const ValueKey(1),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          Text(
            'Choose Your Level',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: headerColor,
              fontSize: (size.width * 0.068).clamp(24.0, 28.0),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select the level that matches your current English speaking ability.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subheaderColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),

          SizedBox(height: (size.height * 0.038).clamp(24.0, 38.0)),

          // Beginner Card
          _buildLevelCard(
            level: LearningLevel.beginner,
            title: 'Beginner',
            description: 'I am new to English and want to build a strong foundation.',
            icon: Icons.school_rounded,
            cardBgColor: isDark ? const Color(0xFF0F291E) : const Color(0xFFF0FDF4),
            cardBorderColor: _selectedLevel == LearningLevel.beginner
                ? const Color(0xFF22C55E)
                : (isDark ? const Color(0xFF166534) : const Color(0xFFDCFCE7)),
            iconBgColor: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
            titleColor: const Color(0xFF16A34A),
            radioActiveColor: const Color(0xFF16A34A),
          ),

          const SizedBox(height: 16),

          // Intermediate Card
          _buildLevelCard(
            level: LearningLevel.intermediate,
            title: 'Intermediate',
            description: 'I can handle basic conversations and everyday situations.',
            icon: Icons.chat_bubble_outline_rounded,
            cardBgColor: isDark ? const Color(0xFF0F2342) : const Color(0xFFEFF6FF),
            cardBorderColor: _selectedLevel == LearningLevel.intermediate
                ? const Color(0xFF3B82F6)
                : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE)),
            iconBgColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
            titleColor: const Color(0xFF2563EB),
            radioActiveColor: const Color(0xFF2563EB),
          ),

          const SizedBox(height: 16),

          // Advanced Card
          _buildLevelCard(
            level: LearningLevel.advanced,
            title: 'Advanced',
            description: 'I can speak fluently and handle complex topics.',
            icon: Icons.workspace_premium_rounded,
            cardBgColor: isDark ? const Color(0xFF27173E) : const Color(0xFFFAF5FF),
            cardBorderColor: _selectedLevel == LearningLevel.advanced
                ? const Color(0xFFA855F7)
                : (isDark ? const Color(0xFF581C87) : const Color(0xFFEDE9FE)),
            iconBgColor: isDark ? const Color(0xFF581C87) : const Color(0xFFEDE9FE),
            titleColor: const Color(0xFF9333EA),
            radioActiveColor: const Color(0xFF9333EA),
          ),

          SizedBox(height: (size.height * 0.05).clamp(32.0, 48.0)),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentStep = 1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continue to AI Voice Check',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required LearningLevel level,
    required String title,
    required String description,
    required IconData icon,
    required Color cardBgColor,
    required Color cardBorderColor,
    required Color iconBgColor,
    required Color titleColor,
    required Color radioActiveColor,
  }) {
    final isSelected = _selectedLevel == level;

    return InkWell(
      onTap: () => setState(() => _selectedLevel = level),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cardBorderColor,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: titleColor.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(icon, color: titleColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? radioActiveColor : const Color(0xFF94A3B8),
                  width: isSelected ? 6.5 : 2.0,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STEP 2: AI VOICE SPEAKING ASSESSMENT (MIRA Test Topic + Live Speech)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildAiSpeakingAssessmentStep(
    BuildContext context,
    bool isDark,
    Size size,
    double hPadding,
  ) {
    final promptTopic = _selectedLevel == LearningLevel.beginner
        ? 'Introduce yourself: Tell MIRA your name, where you are from, what you do, and why you want to speak fluent English.'
        : _selectedLevel == LearningLevel.intermediate
            ? 'Describe a challenge you faced when speaking English in front of people, or describe your daily work/study routine.'
            : 'Share your perspective on how artificial intelligence and global careers are transforming modern communication.';

    final sampleSpeech = _selectedLevel == LearningLevel.beginner
        ? 'Hello MIRA, my name is Sharmila. I am from Chennai. I love reading books and I want to speak English fluently with confidence.'
        : _selectedLevel == LearningLevel.intermediate
            ? 'I have been working as a professional for two years. I can manage everyday conversations, but I want to speak without hesitating in meetings.'
            : 'In my perspective, effective communication in English requires not only vocabulary, but also proper intonation and executive confidence.';

    final levelTitle = _selectedLevel == LearningLevel.beginner
        ? 'Beginner'
        : _selectedLevel == LearningLevel.intermediate
            ? 'Intermediate'
            : 'Advanced';

    return SingleChildScrollView(
      key: const ValueKey(2),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 16),
                const SizedBox(width: 6),
                Text(
                  'AI Speaking Check • $levelTitle',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Speak with MIRA',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1B3B6F),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Speak for 15-30 seconds. MIRA AI will evaluate your speech and schedule your personalized 90-day roadmap.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
          ),

          const SizedBox(height: 20),

          // MIRA AI Prompt Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Assessment Topic',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"$promptTopic"',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Live Speech Recognition Transcript Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording
                    ? const Color(0xFFEF4444)
                    : (_hasRecorded ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1)),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isRecording ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                      size: 16,
                      color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isRecording ? 'Listening live...' : 'What MIRA AI Hears:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _speechTranscript.isNotEmpty
                      ? '"$_speechTranscript"'
                      : _isRecording
                          ? 'Speak now, your words will appear here in real time...'
                          : 'Tap the mic below and speak in English, or choose a sample intro.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: _speechTranscript.isNotEmpty
                        ? (isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B))
                        : const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Quick sample speech chip
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _useSampleSpeech(sampleSpeech),
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: const Text('Use Sample Speech', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Pulsing Mic Button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isRecording
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? const Color(0xFFEF4444) : const Color(0xFF2563EB))
                          .withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _isRecording
                ? 'Recording... 00:${_recordSeconds.toString().padLeft(2, '0')} / 00:30'
                : _hasRecorded
                    ? 'Voice Captured (00:${_recordSeconds.toString().padLeft(2, '0')})'
                    : 'Tap microphone to start speaking',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _isRecording
                  ? const Color(0xFFDC2626)
                  : _hasRecorded
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 24),

          // Submit & Analyze Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_hasRecorded || _speechTranscript.isNotEmpty || _recordSeconds > 2) &&
                      !_isAnalyzing
                  ? _analyzeAndGenerateSchedule
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isAnalyzing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _analyzingStatus,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Analyze Speech & Schedule 90-Day Plan ⚡',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STEP 3: PERSONALIZED 90-DAY SCHEDULE GENERATED FROM SPEECH
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _build90DayScheduleStep(
    BuildContext context,
    bool isDark,
    Size size,
    double hPadding,
  ) {
    final scores = _assessmentResult?['scores'] as Map<String, dynamic>? ?? {};
    final diagnosis = _assessmentResult?['diagnosis'] as Map<String, dynamic>? ?? {};
    final scheduleList = _assessmentResult?['schedule'] as List<dynamic>? ?? [];
    final levelBadge = _assessmentResult?['levelBadge'] ??
        (_selectedLevel == LearningLevel.beginner
            ? 'Beginner A1'
            : _selectedLevel == LearningLevel.intermediate
                ? 'Intermediate B1'
                : 'Advanced C1');
    final spokenTranscript = _assessmentResult?['transcript'] ?? _speechTranscript;

    return Column(
      key: const ValueKey(3),
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 34),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your 90-Day Plan is Ready!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1B3B6F),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customized by MIRA AI based on your spoken evaluation ($levelBadge)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),

                const SizedBox(height: 18),

                // What You Spoke Bubble
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Assessed Speech',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          Text(
                            '${_recordSeconds > 0 ? _recordSeconds : 18}s spoken',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"$spokenTranscript"',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Speech Evaluation Scores Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreChip('Fluency', '${scores['fluency'] ?? 82}%'),
                      Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                      _buildScoreChip('Pronunciation', '${scores['pronunciation'] ?? 80}%'),
                      Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                      _buildScoreChip('Grammar', '${scores['grammar'] ?? 84}%'),
                      Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                      _buildScoreChip('Vocab', '${scores['vocabulary'] ?? 78}%'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AI Speech Diagnosis (Strength & Focus Area)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'MIRA AI Speech Diagnosis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🌟 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              'Strength: ${diagnosis['strength'] ?? 'Clear communicative tone'}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎯 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              'Focus Area: ${diagnosis['focusArea'] ?? 'Eliminating pauses & connective words'}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 90-Day Roadmap Months (Dynamically generated)
                ...scheduleList.map((m) {
                  final monthMap = m as Map<String, dynamic>;
                  final monthNumber = monthMap['month']?.toString() ?? '1';
                  final daysRange = monthMap['daysRange']?.toString() ?? 'Days 1 – 30';
                  final title = monthMap['title']?.toString() ?? 'Spoken English Growth';
                  final desc = monthMap['desc']?.toString() ?? '';
                  final colorHex = monthMap['colorHex']?.toString() ?? '#2563EB';
                  final color = _parseColor(colorHex);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMonthScheduleCard(
                      monthNumber: monthNumber,
                      daysRange: daysRange,
                      title: title,
                      desc: desc,
                      color: color,
                      badgeColor: color.withValues(alpha: 0.14),
                      isDark: isDark,
                    ),
                  );
                }),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Sticky Bottom CTA Bar with Safe Area ────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            hPadding,
            12,
            hPadding,
            MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom + 8
                : 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _finishAndGoToDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.white),
                label: const Text(
                  'Start Day 1 with MIRA 🚀',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }

  Widget _buildScoreChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF16A34A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthScheduleCard({
    required String monthNumber,
    required String daysRange,
    required String title,
    required String desc,
    required Color color,
    required Color badgeColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  monthNumber,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysRange,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
