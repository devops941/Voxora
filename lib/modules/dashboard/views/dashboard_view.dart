import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';
import 'package:voxora/data/models/user_model.dart';
import 'package:voxora/data/repositories/auth_repository.dart';

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

  void _playWordAudio(DailyWordItem item) {
    Get.snackbar(
      '🔊 Pronunciation: ${item.word}',
      '${item.phonetic}\n"${item.exampleSentence}"',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E3A8A),
      colorText: Colors.white,
      icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  void _practiceWordSentence(DailyWordItem item) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.record_voice_over_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Practice Word in Sentence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.word,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${item.phonetic} • ${item.tamilMeaning}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Read aloud:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${item.exampleSentence}"',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.snackbar(
                    'Great Pronunciation! 🎯',
                    'Accurate pronunciation of "${item.word}"! Accuracy: 96%',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF16A34A),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.mic_rounded),
                label: const Text(
                  'Tap to Speak & Check Accuracy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
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
        setState(() => _user = user);
      }
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
    final greetingFontSize = (size.width * 0.06).clamp(20.0, 26.0);

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
                  Text(
                    'Hello, ${_user?.name.split(" ").first ?? "Learner"} 👋',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: greetingFontSize * 0.72,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_user?.level ?? "Beginner"} Level • Day 1 of 90',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔥', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text(
                  '3',
                  style: TextStyle(
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
                    onPressed: () {},
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
                progress: 0.6,
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _buildModuleCard(
                context,
                isDark,
                title: 'Professional Workplace English',
                subtitle: 'Meetings, emails & presentation speech',
                level: 'B1 • Intermediate',
                progress: 0.2,
                icon: Icons.business_center_outlined,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              _buildModuleCard(
                context,
                isDark,
                title: 'Pronunciation & Accent Mastery',
                subtitle: 'Vowel clarity, phonetics & rhythm',
                level: 'All Levels',
                progress: 0.0,
                icon: Icons.record_voice_over_outlined,
                color: AppColors.accent,
              ),

              const SizedBox(height: 24),

              // ── Daily Quick Speaking Prompt ───────────────────────
              _buildDailyChallengeCard(context, isDark),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (i) => setState(() => _selectedNavIndex = i),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Bar: Badge + Next Word + Bookmark ─────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.amberAccent),
                    SizedBox(width: 6),
                    Text(
                      'Word of the Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _nextWord,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _toggleBookmark(_currentWordIndex),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 16,
                        color: isBookmarked ? Colors.amberAccent : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Main Word & Audio Button ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.word,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.phonetic,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _playWordAudio(item),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Color(0xFF1E3A8A),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Tags: Part of speech & Tamil Meaning ─────────────
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.partOfSpeech,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.tamilMeaning,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Meaning & Example Box ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.meaning,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      size: 16,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '"${item.exampleSentence}"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Action Row: Practice Button & Counter ────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _practiceWordSentence(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.record_voice_over_rounded, size: 16),
                  label: const Text(
                    'Practice In Sentence',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_currentWordIndex + 1}/${_dailyWords.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(BuildContext context, bool isDark) {
    return Container(
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
                        Icons.timer_outlined,
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
                            'Daily Goal: 15 / 20 mins',
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
                            '75% completed today',
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
              const Text(
                '5 min left',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
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
  }) {
    return Container(
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ],
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
            child: OutlinedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Pronunciation Challenge',
                  'Listening to phrase and analyzing your voice...',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Listen & Repeat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
