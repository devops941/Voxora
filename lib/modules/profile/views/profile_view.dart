import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/data/models/user_model.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserModel? _user;
  bool _isLoading = true;

  // Real or benchmarked learner stats
  int _daysActive = 28;
  int _currentStreak = 7;
  int _totalPoints = 2850;
  String _goalLevel = 'Intermediate';

  // Learning progress scores
  int _overallProgress = 78;
  int _speakingScore = 85;
  int _listeningScore = 72;
  int _grammarScore = 80;
  int _vocabularyScore = 76;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      if (Get.isRegistered<AuthRepository>()) {
        final cached = await Get.find<AuthRepository>().getCachedUser();
        if (mounted && cached != null) {
          _applyUserData(cached);
        }
        final remote = await Get.find<AuthRepository>().getMe();
        if (mounted) {
          _applyUserData(remote);
        }
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<LessonRepository>()) {
        final dash = await Get.find<LessonRepository>().getDashboard();
        if (mounted && dash.isNotEmpty) {
          final completed = (dash['completedDays'] as num?)?.toInt() ?? 0;
          final currentDay = (dash['currentDay'] as num?)?.toInt() ?? 1;
          final streak = (dash['streak'] as num?)?.toInt() ?? 0;
          final level = dash['level']?.toString() ?? _goalLevel;

          final userData = dash['user'] as Map<String, dynamic>?;
          final xp = (userData?['xp'] as num?)?.toInt() ?? _totalPoints;

          final progress = dash['progress'] as Map<String, dynamic>?;
          final completionPct = (progress?['completionPercentage'] as num?)?.toInt();
          final avgScores = progress?['averageScores'] as Map<String, dynamic>?;

          setState(() {
            _daysActive = completed > 0 ? completed : (currentDay > 1 ? currentDay : 28);
            _currentStreak = streak > 0 ? streak : 7;
            _totalPoints = xp > 0 ? xp : 2850;
            _goalLevel = level.isNotEmpty ? level : 'Intermediate';

            if (completionPct != null && completionPct > 0) {
              _overallProgress = completionPct;
            }

            if (avgScores != null) {
              final f = (avgScores['fluency'] as num?)?.toInt() ?? 0;
              final p = (avgScores['pronunciation'] as num?)?.toInt() ?? 0;
              final g = (avgScores['grammar'] as num?)?.toInt() ?? 0;
              final v = (avgScores['vocabulary'] as num?)?.toInt() ?? 0;
              final o = (avgScores['overall'] as num?)?.toInt() ?? 0;

              if (f > 0) _speakingScore = f;
              if (p > 0) _listeningScore = p;
              if (g > 0) _grammarScore = g;
              if (v > 0) _vocabularyScore = v;
              if (o > 0) _overallProgress = o;
            }
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _applyUserData(UserModel user) {
    setState(() {
      _user = user;
      _goalLevel = user.level.isNotEmpty ? user.level : _goalLevel;
      if (user.streak > 0) _currentStreak = user.streak;
      if (user.xp > 0) _totalPoints = user.xp;
    });
  }



  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Voxora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (Get.isRegistered<AuthRepository>()) {
          await Get.find<AuthRepository>().logout();
        }
      } catch (_) {}
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),

            // Top App Bar matching reference
            _buildTopBar(isDark),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProfileData,
                color: const Color(0xFF6366F1),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    children: [
                      // 1. Hero Profile Card
                      _buildHeroProfileCard(isDark),
                      const SizedBox(height: 18),

                      // 2. Learning Progress Card
                      _buildLearningProgressCard(isDark),
                      const SizedBox(height: 18),

                      // 3. Navigation List Card
                      _buildMenuListCard(isDark),
                      const SizedBox(height: 18),

                      // 4. Logout Button Card
                      _buildLogoutButton(isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  // ── 1. Top App Header ──────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 20, right: 20),
      child: Row(
        children: [
          // Voxora Official Brand Logo Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voxora',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF4338CA),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Speak  •  Learn  •  Grow',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Hero Profile Card ───────────────────────────────────────────────────
  Widget _buildHeroProfileCard(bool isDark) {
    final userName = (_user?.name.isNotEmpty == true) ? _user!.name : 'Sharmila R';
    final userBio = (_user?.bio?.isNotEmpty == true)
        ? _user!.bio!
        : 'Better English  •  Bigger Dreams';
    final userLocation = (_user?.location?.isNotEmpty == true)
        ? _user!.location!
        : 'Madurai, India';
    final level = _goalLevel.isNotEmpty ? _goalLevel : 'Intermediate';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [
                  const Color(0xFFE8EEFF).withValues(alpha: 0.85),
                  const Color(0xFFEFF5FF),
                  const Color(0xFFF3E8FF).withValues(alpha: 0.85),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Info Row (Avatar + Details)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/learner_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE0E7FF),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userBio,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          userLocation,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Level Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Stats Inner Card
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                _buildStatItem(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Active',
                  value: '$_daysActive Days',
                  isDark: isDark,
                ),
                _buildStatItem(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF97316),
                  label: 'Streak',
                  value: '$_currentStreak Days',
                  isDark: isDark,
                ),
                _buildStatItem(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: 'Points',
                  value: NumberFormat('#,###').format(_totalPoints),
                  isDark: isDark,
                ),
                _buildStatItem(
                  icon: Icons.track_changes_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  label: 'Goal',
                  value: level,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
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
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Learning Progress Card ──────────────────────────────────────────────
  Widget _buildLearningProgressCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Learning Progress',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.progress),
                child: Row(
                  children: const [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Content Row: Circular Indicator on Left + 4 Skill Bars on Right
          Row(
            children: [
              // Circular Indicator
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: (_overallProgress / 100).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_overallProgress%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Overall\nProgress',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // 4 Skill Bars
              Expanded(
                child: Column(
                  children: [
                    _buildSkillBar(
                      icon: Icons.mic_rounded,
                      iconColor: const Color(0xFF2563EB),
                      label: 'Speaking',
                      value: _speakingScore,
                      barColor: const Color(0xFF2563EB),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildSkillBar(
                      icon: Icons.headphones_rounded,
                      iconColor: const Color(0xFF9333EA),
                      label: 'Listening',
                      value: _listeningScore,
                      barColor: const Color(0xFF9333EA),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildSkillBar(
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Grammar',
                      value: _grammarScore,
                      barColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildSkillBar(
                      icon: Icons.collections_bookmark_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Vocabulary',
                      value: _vocabularyScore,
                      barColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBar({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int value,
    required Color barColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 15),
        const SizedBox(width: 6),
        SizedBox(
          width: 78,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$value%',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── 4. Menu Navigation Card ────────────────────────────────────────────────
  Widget _buildMenuListCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF8B5CF6),
            circleBg: const Color(0xFFF5F3FF),
            title: 'My 90-Day Plan',
            subtitle: 'View your personalized learning journey',
            isDark: isDark,
            onTap: () => Get.toNamed(AppRoutes.curriculum, arguments: {'level': _goalLevel}),
          ),
          Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC)),
          _buildMenuTile(
            icon: Icons.fact_check_rounded,
            iconColor: const Color(0xFF3B82F6),
            circleBg: const Color(0xFFEFF6FF),
            title: 'My Assessments',
            subtitle: 'Check your test results & scores',
            isDark: isDark,
            onTap: () => _showAssessmentsSheet(),
          ),
          Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC)),
          _buildMenuTile(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFF59E0B),
            circleBg: const Color(0xFFFEF3C7),
            title: 'My Achievements',
            subtitle: 'Badges, streaks and milestones',
            isDark: isDark,
            onTap: () => _showAchievementsSheet(),
          ),
          Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC)),
          _buildMenuTile(
            icon: Icons.track_changes_rounded,
            iconColor: const Color(0xFF10B981),
            circleBg: const Color(0xFFECFDF5),
            title: 'Language Goals',
            subtitle: 'Set and track your goals',
            isDark: isDark,
            onTap: () => _showLanguageGoalsSheet(),
          ),
          Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC)),
          _buildMenuTile(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF8B5CF6),
            circleBg: const Color(0xFFF5F3FF),
            title: 'Help & Support',
            subtitle: 'FAQs, contact us, and more',
            isDark: isDark,
            onTap: () => _showHelpSupportSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color circleBg,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? circleBg.withValues(alpha: 0.12) : circleBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 21),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }

  // ── Logout Button ──────────────────────────────────────────────────────────
  Widget _buildLogoutButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _confirmSignOut,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Log Out of Voxora',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Sheet Modals for Menu Items ─────────────────────────────────────

  // 1. Speech Assessment History Sheet
  void _showAssessmentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bottomSafe = MediaQuery.of(ctx).padding.bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomSafe),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fact_check_rounded, color: Color(0xFF3B82F6), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Speech Assessment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Voice & Phonetic Calibration Report',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Level & Mastery Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A8A).withValues(alpha: 0.5), const Color(0xFF0F172A)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$_goalLevel Track',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _goalLevel == 'Advanced' ? 'CEFR C1' : (_goalLevel == 'Intermediate' ? 'CEFR B2' : 'CEFR A2'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Active Voice Calibration • Day $_daysActive of 90',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$_overallProgress%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4 Skill Scores Matrix
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF2563EB),
                      label: 'Fluency',
                      value: _speakingScore,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.record_voice_over_rounded,
                      color: const Color(0xFF10B981),
                      label: 'Pronunciation',
                      value: _listeningScore,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.spellcheck_rounded,
                      color: const Color(0xFF9333EA),
                      label: 'Grammar',
                      value: _grammarScore,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFFF59E0B),
                      label: 'Vocabulary',
                      value: _vocabularyScore,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Retake Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Get.toNamed(AppRoutes.levelSelection);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Retake Speech Calibration',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$value%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Achievements & Badges Sheet
  void _showAchievementsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bottomSafe = MediaQuery.of(ctx).padding.bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomSafe),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Achievements & Badges',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '$_totalPoints Total XP • $_currentStreak-Day Streak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4 Rich Badges Grid
              Row(
                children: [
                  Expanded(
                    child: _buildAchievementCard(
                      emoji: '🔥',
                      color: const Color(0xFFF97316),
                      title: 'Streak Star',
                      value: '$_currentStreak Days',
                      badge: 'Active Daily',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAchievementCard(
                      emoji: '⚡',
                      color: const Color(0xFFF59E0B),
                      title: 'Fluency Hero',
                      value: '$_totalPoints XP',
                      badge: 'Gold Tier',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildAchievementCard(
                      emoji: '🎯',
                      color: const Color(0xFF10B981),
                      title: 'Pronunciation Ace',
                      value: '$_listeningScore% Phonetics',
                      badge: 'Verified',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAchievementCard(
                      emoji: '🌟',
                      color: const Color(0xFF8B5CF6),
                      title: '90-Day Pioneer',
                      value: 'Day $_daysActive / 90',
                      badge: '$_goalLevel Track',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Motivational tip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Practice 15 minutes daily with MIRA to earn streak multipliers and unlock Platinum Badges!',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementCard({
    required String emoji,
    required Color color,
    required String title,
    required String value,
    required String badge,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Language Goals Sheet
  void _showLanguageGoalsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bottomSafe = MediaQuery.of(ctx).padding.bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomSafe),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.track_changes_rounded, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Language Goals',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Target Milestones & Daily Commitment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Goal 1: Daily Speaking Target
              _buildGoalCard(
                icon: Icons.timer_rounded,
                color: const Color(0xFF10B981),
                title: 'Daily Speaking Commitment',
                target: '15 Minutes / Day with MIRA AI',
                status: 'Active Goal',
                progressValue: 0.8,
                progressText: '80% completed today',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // Goal 2: CEFR Proficiency Milestone
              _buildGoalCard(
                icon: Icons.school_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'CEFR Proficiency Milestone',
                target: 'Fluent $_goalLevel Communication',
                status: 'In Progress',
                progressValue: (_daysActive / 90).clamp(0.0, 1.0),
                progressText: 'Day $_daysActive of 90 Track Completed',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // Goal 3: Streak Consistency Target
              _buildGoalCard(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF97316),
                title: 'Weekly Consistency Target',
                target: '7 Consecutive Days Speaking Habit',
                status: '$_currentStreak / 7 Days',
                progressValue: (_currentStreak / 7).clamp(0.0, 1.0),
                progressText: 'Streak multiplier active',
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalCard({
    required IconData icon,
    required Color color,
    required String title,
    required String target,
    required String status,
    required double progressValue,
    required String progressText,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      target,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressText,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Help & Support Sheet
  void _showHelpSupportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bottomSafe = MediaQuery.of(ctx).padding.bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomSafe),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.support_agent_rounded, color: Color(0xFF6366F1), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Help & Support Hub',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '24/7 AI Assistance & Learner Support',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Card 1: Ask MIRA
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF4338CA).withValues(alpha: 0.4), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.3) : const Color(0xFFC7D2FE),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    'Ask MIRA AI Spoken Tutor',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : const Color(0xFF312E81),
                    ),
                  ),
                  subtitle: Text(
                    'Instant English doubt resolution & grammar explanations',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF4338CA),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(AppRoutes.dashboard);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Card 2: Email Support
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email_outlined, color: Color(0xFF0D9488), size: 20),
                  ),
                  title: Text(
                    'Direct Email Support',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: const Text(
                    'support@voxora.ai',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Official',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Card 3: 90-Day Curriculum FAQ
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  title: Text(
                    '90-Day Curriculum Guide',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Learn how scoring, streaks, and phase unlocks work',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(AppRoutes.curriculum, arguments: {'level': _goalLevel});
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 5. Bottom Navigation Bar ───────────────────────────────────────────────
  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: false,
                isDark: isDark,
                onTap: () => Get.offAllNamed(AppRoutes.dashboard),
              ),
              _buildNavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: 'Lessons',
                isActive: false,
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.curriculum, arguments: {'level': _goalLevel}),
              ),

              // Elevated Center Mic Button
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.lesson),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.mic_none_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),

              _buildNavItem(
                icon: Icons.bar_chart_rounded,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Progress',
                isActive: false,
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.progress),
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: true,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF6366F1);
    final inactiveColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
