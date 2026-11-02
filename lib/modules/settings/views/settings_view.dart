import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/modules/settings/controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. User Profile Settings ──────────────────────────────────
              _buildSectionHeader('User Profile Settings', isDark),
              const SizedBox(height: 8),
              _buildProfileSettingsCard(context, isDark),

              const SizedBox(height: 20),

              // ── 2. Account Information ────────────────────────────────────
              _buildSectionHeader('Account Information', isDark),
              const SizedBox(height: 8),
              _buildAccountInfoCard(context, isDark),

              const SizedBox(height: 20),

              // ── 3. Learning Track & English Level ─────────────────────────
              _buildSectionHeader('English Level Track', isDark),
              const SizedBox(height: 8),
              _buildLevelSelectorCard(context, isDark),

              const SizedBox(height: 20),

              // ── 4. Learning Preferences ───────────────────────────────────
              _buildSectionHeader('Learning Preferences', isDark),
              const SizedBox(height: 8),
              _buildLearningPreferencesCard(context, isDark),

              const SizedBox(height: 20),

              // ── 5. Notification Preferences ───────────────────────────────
              _buildSectionHeader('Notification Preferences', isDark),
              const SizedBox(height: 8),
              _buildNotificationPreferencesCard(context, isDark),

              const SizedBox(height: 20),

              // ── 6. Privacy & Legal ────────────────────────────────────────
              _buildSectionHeader('Privacy & Support', isDark),
              const SizedBox(height: 8),
              _buildPrivacyCard(context, isDark),

              const SizedBox(height: 24),

              // ── 7. Logout Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    foregroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Voxora v1.0.0 • AI Spoken English Coach',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey.shade300 : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildProfileSettingsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller.nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.bioController,
            decoration: InputDecoration(
              labelText: 'Bio / Learning Goal',
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.locationController,
            decoration: InputDecoration(
              labelText: 'Location / City',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: controller.isSaving.value ? null : controller.saveProfile,
              icon: controller.isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Profile Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context, bool isDark) {
    final user = controller.user.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? 'Not available',
            isDark: isDark,
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.security_rounded,
            label: 'Sign-in Method',
            value: user?.authProvider == 'google' ? 'Google Authentication' : 'Email & Password',
            isDark: isDark,
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.military_tech_outlined,
            label: 'XP & Coins',
            value: '${user?.xp ?? 0} XP • ${(user?.xp ?? 0) ~/ 10} Coins',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelectorCard(BuildContext context, bool isDark) {
    const levels = ['Beginner', 'Intermediate', 'Advanced'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Switch your 90-day learning curriculum track anytime:',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: levels.map((lvl) {
              final isSelected = controller.selectedLevel.value == lvl;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => controller.updateLevel(lvl),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          lvl,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : const Color(0xFF334155)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPreferencesCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tamil Translation Hints', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Show Tamil meaning for vocabulary & tips', style: TextStyle(fontSize: 12)),
            value: controller.enableTamilTranslation.value,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              controller.enableTamilTranslation.value = val;
              controller.persistPreferences();
            },
          ),
          const Divider(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-play MIRA Voice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Automatically speak lesson prompts', style: TextStyle(fontSize: 12)),
            value: controller.autoPlayAudio.value,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              controller.autoPlayAudio.value = val;
              controller.persistPreferences();
            },
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Practice Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Target minutes per day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              DropdownButton<int>(
                value: controller.dailyGoalMinutes.value,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: [10, 15, 20, 30].map((m) {
                  return DropdownMenuItem<int>(
                    value: m,
                    child: Text('$m mins'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    controller.dailyGoalMinutes.value = val;
                    controller.saveProfile();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily Practice Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Remind me to complete my daily speaking lesson', style: TextStyle(fontSize: 12)),
            value: controller.dailyReminders.value,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              controller.dailyReminders.value = val;
              controller.persistPreferences();
            },
          ),
          const Divider(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Weekly Progress Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Summary of fluency score & completed days', style: TextStyle(fontSize: 12)),
            value: controller.weeklyReport.value,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              controller.weeklyReport.value = val;
              controller.persistPreferences();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 20),
            title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {
              Get.defaultDialog(
                title: 'Privacy Policy',
                middleText:
                    'Voxora respects your privacy. Voice recordings and transcripts are processed solely for educational speech evaluation and feedback. We never sell your personal data.',
                textConfirm: 'Understood',
                confirmTextColor: Colors.white,
                buttonColor: AppColors.primary,
                onConfirm: () => Get.back(),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.article_outlined, color: AppColors.primary, size: 20),
            title: const Text('Terms of Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {
              Get.defaultDialog(
                title: 'Terms of Service',
                middleText:
                    'By using Voxora, you agree to engage respectfully with the AI coach and complete the 90-day learning curriculum in accordance with our educational guidelines.',
                textConfirm: 'Close',
                confirmTextColor: Colors.white,
                buttonColor: AppColors.primary,
                onConfirm: () => Get.back(),
              );
            },
          ),
        ],
      ),
    );
  }
}
