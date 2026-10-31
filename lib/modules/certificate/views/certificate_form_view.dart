import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/modules/certificate/controllers/certificate_controller.dart';

class CertificateFormView extends StatelessWidget {
  const CertificateFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CertificateController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Certificate Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test mode banner
              Obx(() {
                if (!controller.isTestMode.value) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFD97706), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'TEST MODE – Certificate will be marked as NOT VALID',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a3a6b), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.card_membership_rounded,
                        color: Color(0xFFFFD700), size: 48),
                    const SizedBox(height: 10),
                    const Text(
                      'Your Certificate of Completion',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fill in your details to generate and download your certificate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Full Name field
              _SectionLabel(label: 'Your Details', isDark: isDark),
              const SizedBox(height: 12),
              TextField(
                controller: controller.fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  isDark: isDark,
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name as shown on certificate',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),

              const SizedBox(height: 14),

              // Email field
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  isDark: isDark,
                  labelText: 'Email Address *',
                  hintText: 'Certificate confirmation will be sent here',
                  prefixIcon: Icons.email_outlined,
                ),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),

              const SizedBox(height: 28),

              // Certificate info cards
              _SectionLabel(label: 'Certificate Information', isDark: isDark),
              const SizedBox(height: 12),

              _InfoCard(
                isDark: isDark,
                icon: Icons.school_outlined,
                label: 'Completed Level',
                value: controller.level,
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _InfoCard(
                isDark: isDark,
                icon: Icons.auto_stories_outlined,
                label: 'Course Name',
                value: controller.courseName,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 10),
              _InfoCard(
                isDark: isDark,
                icon: Icons.calendar_today_outlined,
                label: 'Completion Date',
                value: controller.completionDateStr,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 10),
              _InfoCard(
                isDark: isDark,
                icon: Icons.emoji_events_outlined,
                label: 'Assessment Score',
                value: controller.scoreDisplay,
                color: const Color(0xFFD97706),
              ),

              const SizedBox(height: 36),

              // Download button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: controller.isDownloading.value
                          ? null
                          : controller.generateAndDownload,
                      icon: controller.isDownloading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 22),
                      label: Text(
                        controller.isDownloading.value
                            ? 'Generating Certificate...'
                            : 'Download Your Certificate',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  )),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'PDF will be saved to your Documents folder',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, size: 20),
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 16,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade400),
        ],
      ),
    );
  }
}
