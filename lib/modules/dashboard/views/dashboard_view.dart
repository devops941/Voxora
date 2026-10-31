import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';
import 'package:voxora/data/models/user_model.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class DailyWordItem {
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String meaning;
  final String tamilMeaning;
  final String exampleSentence;
  final String dailyTip;

  const DailyWordItem({
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.meaning,
    required this.tamilMeaning,
    required this.exampleSentence,
    required this.dailyTip,
  });
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedNavIndex = 0;
  UserModel? _user;
  int _streak = 0;
  int _currentDay = 1;
  String _todayTopic = 'Daily Spoken English';
  String _level = 'Beginner';
  int _completedDays = 0;

  int _currentWordIndex = 0;
  final Set<int> _bookmarkedWordIndices = {};

  static const List<DailyWordItem> _dailyWords = [
    DailyWordItem(
      word: 'Articulate',
      phonetic: '/ɑːrˈtɪk.jə.lət/',
      partOfSpeech: 'Adjective • Clear Speech',
      meaning: 'Able to express thoughts and ideas clearly and fluently.',
      tamilMeaning: 'தெளிவாக பேசக்கூடிய',
      exampleSentence: 'She gave an articulate and confident answer in the interview.',
      dailyTip: 'Use when someone explains ideas simply and with clarity.',
    ),
    DailyWordItem(
      word: 'Hesitate',
      phonetic: '/ˈhez.ɪ.teɪt/',
      partOfSpeech: 'Verb • Fluency Booster',
      meaning: 'To pause or delay before speaking due to uncertainty.',
      tamilMeaning: 'தயங்குதல் / இடைநிறுத்தம்',
      exampleSentence: "Don't hesitate to speak English; making mistakes helps you learn!",
      dailyTip: 'Say "I won\'t hesitate" instead of saying "I am shy to speak".',
    ),
    DailyWordItem(
      word: 'Spontaneous',
      phonetic: '/spɒnˈteɪ.ni.əs/',
      partOfSpeech: 'Adjective • Natural Speech',
      meaning: 'Speaking naturally and easily without memorized scripts.',
      tamilMeaning: 'இயல்பான பேச்சு',
      exampleSentence: 'With daily speaking practice, your answers become spontaneous.',
      dailyTip: 'The goal of conversational English is spontaneous flow.',
    ),
    DailyWordItem(
      word: 'Wrap up',
      phonetic: '/ræp ʌp/',
      partOfSpeech: 'Phrasal Verb • Workplace',
      meaning: 'To bring a discussion, meeting, or activity to a finish.',
      tamilMeaning: 'நிறைவு செய்தல் / முடித்தல்',
      exampleSentence: "Let's wrap up our discussion and summarize the key action points.",
      dailyTip: 'Commonly used in corporate and client calls instead of "finish".',
    ),
    DailyWordItem(
      word: 'Get the hang of',
      phonetic: '/ɡet ðə hæŋ ʌv/',
      partOfSpeech: 'Idiom • Daily English',
      meaning: 'To master or understand how to speak something with practice.',
      tamilMeaning: 'பழகிக்கொள்ளுதல்',
      exampleSentence: "Don't worry! You will get the hang of English conversation quickly.",
      dailyTip: 'Say "I am getting the hang of it" when your fluency improves.',
    ),
    DailyWordItem(
      word: 'Eloquent',
      phonetic: '/ˈel.ə.kwənt/',
      partOfSpeech: 'Adjective • Advanced',
      meaning: 'Expressing ideas in an elegant, fluent, and persuasive way.',
      tamilMeaning: 'நேர்த்தியான ஈர்க்கும் பேச்சு',
      exampleSentence: 'His eloquent presentation impressed everyone in the conference.',
      dailyTip: 'Top-tier word used to praise impressive communication.',
    ),
    DailyWordItem(
      word: 'Persuasive',
      phonetic: '/pərˈsweɪ.sɪv/',
      partOfSpeech: 'Adjective • Communication',
      meaning: 'Good at convincing others to agree with your viewpoint.',
      tamilMeaning: 'நம்ப வைக்கும் பேச்சுத்திறன்',
      exampleSentence: 'She made a persuasive argument during the team discussion.',
      dailyTip: 'Essential word for negotiation, presentations, and sales.',
    ),
    DailyWordItem(
      word: 'Cut to the chase',
      phonetic: '/kʌt tu ðə tʃeɪs/',
      partOfSpeech: 'Idiom • Direct Speaking',
      meaning: 'To get straight to the main point without wasting time.',
      tamilMeaning: 'நேரடியாக விஷயத்திற்கு வருதல்',
      exampleSentence: 'We have limited time, so let us cut to the chase.',
      dailyTip: 'Common workplace idiom used when time is short.',
    ),
  ];

  void _nextWord() {
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _dailyWords.length;
    });
  }

  void _toggleBookmark(int index) {
    setState(() {
      if (_bookmarkedWordIndices.contains(index)) {
        _bookmarkedWordIndices.remove(index);
        Get.snackbar(
          'Bookmark Removed',
          '${_dailyWords[index].word} removed from saved vocabulary.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        _bookmarkedWordIndices.add(index);
        Get.snackbar(
          'Saved to Vocabulary ⭐',
          '${_dailyWords[index].word} added to your daily flashcards!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    });
  }


  String _getGreetingWithUser() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour >= 4 && hour < 12) {
      greeting = 'Good Morning';
      emoji = '☀️';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '🌤️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    final rawName = _user?.name.trim() ?? '';
    if (rawName.isNotEmpty) {
      final firstName = rawName.split(' ').first;
      final formattedName = firstName.isNotEmpty
          ? '${firstName[0].toUpperCase()}${firstName.substring(1)}'
          : firstName;
      return '$greeting, $formattedName $emoji';
    }

    return '$greeting $emoji';
  }

  void _practiceWordSentence(DailyWordItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding > 0 ? bottomPadding + 14 : 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Icon + Title + Close
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Word & Sentence Meaning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Word Title
              Text(
                item.word,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),

              // Phonetic, Part of speech & Tamil Meaning
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    item.phonetic,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.partOfSpeech,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.tamilMeaning,
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Meaning Box ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Meaning:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.meaning,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Example Sentence Box ─────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 15, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Example in Daily Conversation:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${item.exampleSentence}"',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Speaking Tip / Usage Context ─────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 15, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Text(
                          'Speaking Tip:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.dailyTip,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Clean Got It / Dismiss Button ─────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Got it! 👍',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentWordIndex = _getTodayWordIndex();
    _loadUser();
  }

  int _getTodayWordIndex() {
    final now = DateTime.now();
    // Day of the year ensures that every calendar day automatically has its own word:
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return dayOfYear % _dailyWords.length;
  }

  Future<void> _loadUser() async {
    if (Get.isRegistered<AuthRepository>()) {
      final user = await Get.find<AuthRepository>().getCachedUser();
      if (mounted && user != null) {
        setState(() {
          _user = user;
          _streak = user.streak;
          _level = user.level;
        });
      }
    }
    if (Get.isRegistered<LessonRepository>()) {
      try {
        final dashData = await Get.find<LessonRepository>().getDashboard();
        if (mounted && dashData.isNotEmpty) {
          setState(() {
            _currentDay = (dashData['currentDay'] as num?)?.toInt() ?? 1;
            _completedDays = (dashData['completedDays'] as num?)?.toInt() ?? 0;
            _streak = (dashData['streak'] as num?)?.toInt() ?? _streak;
            if (dashData['level'] != null) {
              _level = dashData['level'].toString();
            }
            final todayLesson = dashData['todayLesson'] as Map<String, dynamic>?;
            if (todayLesson != null && todayLesson['topic'] != null) {
              _todayTopic = todayLesson['topic'].toString();
            }
            final userData = dashData['user'] as Map<String, dynamic>?;
            if (userData != null) {
              _user = UserModel.fromJson(userData);
            }
          });
          return;
        }
      } catch (_) {}

      try {
        final todayData = await Get.find<LessonRepository>().getTodayLesson();
        if (mounted) {
          setState(() {
            _currentDay = (todayData['currentDay'] as num?)?.toInt() ?? 1;
            _completedDays = (todayData['completedDays'] as num?)?.toInt() ?? 0;
            _streak = (todayData['streak'] as num?)?.toInt() ?? _streak;
            final lesson = todayData['lesson'] as Map<String, dynamic>?;
            if (lesson != null && lesson['topic'] != null) {
              _todayTopic = lesson['topic'].toString();
            }
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Voxora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().logout();
      }
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive sizing tokens
    final hPadding = (size.width * 0.05).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: hPadding,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  (_user?.name.isNotEmpty == true
                          ? _user!.name[0]
                          : 'V')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _getGreetingWithUser(),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 17.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ready to speak English today?',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Streak Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_streak',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          SizedBox(width: hPadding * 0.5),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Daily Word / Vocabulary Card ─────────────────
              _buildWordOfTheDayHeroCard(context, isDark, size),

              const SizedBox(height: 18),

              // ── Today's Scheduled Lesson Hero CTA ─────────────────
              _buildTodayLessonCard(context, isDark),

              const SizedBox(height: 18),

              // ── Daily Goal Progress ───────────────────────────────
              _buildDailyGoalCard(context, isDark),

              const SizedBox(height: 22),

              // ── Section Title: Curriculum Modules ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Curriculum Modules',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Get.toNamed(
                        AppRoutes.curriculum,
                        arguments: {
                          'level': 'Advanced',
                          'moduleTitle': 'Pronunciation & Accent Mastery',
                        },
                      );
                      _loadUser();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Module Cards List
              _buildModuleCard(
                context,
                isDark,
                title: 'Everyday Conversations',
                subtitle: 'Greetings, introductions & small talk',
                level: 'A1 • Beginner',
                targetLevel: 'Beginner',
                progress: (_completedDays / 30).clamp(0.0, 1.0),
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                isLocked: false,
              ),
              const SizedBox(height: 12),
              _buildModuleCard(
                context,
                isDark,
                title: 'Professional Workplace English',
                subtitle: 'Meetings, emails & presentation speech',
                level: 'B1 • Intermediate',
                targetLevel: 'Intermediate',
                progress: ((_completedDays - 30) / 30).clamp(0.0, 1.0),
                icon: Icons.business_center_outlined,
                color: AppColors.secondary,
                isLocked: _currentDay < 31,
                lockMessage: 'Complete all Beginner classes (Days 1–30) first to unlock Phase 2!',
              ),
              const SizedBox(height: 12),
              _buildModuleCard(
                context,
                isDark,
                title: 'Pronunciation & Accent Mastery',
                subtitle: 'Vowel clarity, phonetics & rhythm',
                level: 'C1 • Advanced',
                targetLevel: 'Advanced',
                progress: ((_completedDays - 60) / 30).clamp(0.0, 1.0),
                icon: Icons.record_voice_over_outlined,
                color: AppColors.accent,
                isLocked: _currentDay < 61,
                lockMessage: 'Complete all Intermediate classes (Days 31–60) first to unlock Phase 3!',
              ),

              const SizedBox(height: 24),

              // ── Daily Quick Speaking Prompt ───────────────────────
              _buildDailyChallengeCard(context, isDark),

              const SizedBox(height: 18),

              // ── Final Assessment CTA ──────────────────────────────
              _buildFinalAssessmentCard(context, isDark),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (i) async {
          if (i == 1) {
            setState(() => _selectedNavIndex = i);
            await Get.toNamed(AppRoutes.speakingPractice);
            if (mounted) setState(() => _selectedNavIndex = 0);
            return;
          }
          if (i == 2) {
            setState(() => _selectedNavIndex = i);
            await Get.toNamed(
              AppRoutes.curriculum,
              arguments: {'level': _level},
            );
            if (mounted) {
              setState(() => _selectedNavIndex = 0);
              _loadUser();
            }
            return;
          }
          if (i == 3) {
            setState(() => _selectedNavIndex = i);
            await Get.toNamed(AppRoutes.profile);
            if (mounted) setState(() => _selectedNavIndex = 0);
            return;
          }
          setState(() => _selectedNavIndex = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Curriculum',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildWordOfTheDayHeroCard(BuildContext context, bool isDark, Size size) {
    final item = _dailyWords[_currentWordIndex];
    final isBookmarked = _bookmarkedWordIndices.contains(_currentWordIndex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Row: Badge + Word Counter + Actions ─────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.amberAccent),
                    SizedBox(width: 4),
                    Text(
                      'Word of the Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentWordIndex + 1}/${_dailyWords.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _nextWord,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Next',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _toggleBookmark(_currentWordIndex),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 14,
                        color: isBookmarked ? Colors.amberAccent : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Word & Phonetic ──────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 3),
              Text(
                item.phonetic,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Tags: Part of speech & Tamil Meaning ─────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.partOfSpeech,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.tamilMeaning,
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Meaning & Example sentence ────────────────────────
          Text(
            '${item.meaning} "${item.exampleSentence}"',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 11.5,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // ── Compact Action: View Sentence Button ──────────────
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _practiceWordSentence(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A8A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 15),
              label: const Text(
                'View Sentence & Meaning',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLessonCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 15),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "TODAY'S LESSON • DAY $_currentDay",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '15 Mins',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Day $_currentDay: $_todayTopic',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            'Practice pronunciation and daily spoken phrases with MIRA AI voice tutor.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.lesson,
                    arguments: {'day': _currentDay},
                  )?.then((_) => _loadUser());
                },
                borderRadius: BorderRadius.circular(14),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Start Today's Lesson",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            height: 1.2,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(BuildContext context, bool isDark) {
    final pct = (_completedDays / 90.0).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.progress),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '90-Day Goal: $_completedDays / 90 Lessons',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontSize: 14.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(pct * 100).round()}% curriculum completed',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Row(
                  children: [
                    Text(
                      'Analytics',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required String level,
    required double progress,
    required IconData icon,
    required Color color,
    String? targetLevel,
    bool isLocked = false,
    String? lockMessage,
  }) {
    return InkWell(
      onTap: () async {
        if (isLocked) {
          Get.snackbar(
            'Module Locked 🔒',
            lockMessage ?? 'Complete previous modules first to unlock!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF1E293B),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        }
        await Get.toNamed(
          AppRoutes.curriculum,
          arguments: {
            'level': targetLevel ?? 'Beginner',
            'moduleTitle': title,
          },
        );
        _loadUser();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLocked ? Icons.lock_outline_rounded : icon,
                color: isLocked ? (isDark ? Colors.grey[500] : Colors.grey[400]) : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.grey.withValues(alpha: 0.15)
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            color: isLocked ? (isDark ? Colors.grey[400] : Colors.grey[600]) : color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 10, color: Color(0xFFD97706)),
                              SizedBox(width: 2),
                              Text(
                                'Locked',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 14.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              size: isLocked ? 20 : 24,
              color: isLocked
                  ? (isDark ? Colors.grey[600] : Colors.grey[400])
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                "Today's Pronunciation Challenge",
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"Confidence comes from taking action every single day."',
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF14532D),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed(AppRoutes.speakingPractice);
              },
              icon: const Icon(Icons.record_voice_over_rounded, size: 18),
              label: const Text('Practice with Mira'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalAssessmentCard(BuildContext context, bool isDark) {
    final isEligible = _completedDays >= 90;
    const cardColor = Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.finalAssessment),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEligible
                ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
                : [const Color(0xFF374151), const Color(0xFF1F2937)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isEligible ? cardColor : Colors.black)
                  .withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isEligible
                    ? Icons.emoji_events_rounded
                    : Icons.lock_outline_rounded,
                color: isEligible ? const Color(0xFFFFD700) : Colors.white54,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEligible ? 'Final Assessment Ready!' : 'Final Assessment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isEligible
                        ? 'Take your 25-question test and earn your certificate'
                        : 'Complete all 90 days to unlock your final assessment',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
