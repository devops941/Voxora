import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';

class Helpers {
  Helpers._();

  // ── Duration formatting ───────────────────────────

  /// Formats seconds into mm:ss (e.g. 125 → "2:05").
  static String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats minutes into a human-readable string (e.g. 90 → "1h 30m").
  static String formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  // ── Date formatting ───────────────────────────────

  /// Formats a [DateTime] as "MMM d, yyyy" (e.g. "Jan 5, 2026").
  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats a [DateTime] as a relative label: "Today", "Yesterday", or the date.
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return formatDate(date);
  }

  // ── Text utilities ────────────────────────────────

  /// Truncates [text] to [maxLength] characters, appending "…" if needed.
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  /// Capitalises the first letter of each word.
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  // ── GetX snackbars ────────────────────────────────

  static void showSuccessSnackbar(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Success',
      message,
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_outline, color: AppColors.white),
      titleText: Text(
        title ?? 'Success',
        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.white),
      ),
      messageText: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
      ),
    );
  }

  static void showErrorSnackbar(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Error',
      message,
      backgroundColor: AppColors.error,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline, color: AppColors.white),
      titleText: Text(
        title ?? 'Error',
        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.white),
      ),
      messageText: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
      ),
    );
  }

  static void showInfoSnackbar(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Info',
      message,
      backgroundColor: AppColors.info,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.info_outline, color: AppColors.white),
      titleText: Text(
        title ?? 'Info',
        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.white),
      ),
      messageText: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
      ),
    );
  }

  static void showWarningSnackbar(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Warning',
      message,
      backgroundColor: AppColors.warning,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_outlined, color: AppColors.white),
      titleText: Text(
        title ?? 'Warning',
        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.white),
      ),
      messageText: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
      ),
    );
  }

  // ── Loading dialog ────────────────────────────────

  static void showLoading({String message = 'Please wait...'}) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // ── Score colour helper ───────────────────────────

  static Color scoreColor(double score) {
    if (score >= 80) return AppColors.scoreExcellent;
    if (score >= 60) return AppColors.scoreGood;
    if (score >= 40) return AppColors.scoreFair;
    return AppColors.scorePoor;
  }

  // ── Level colour helper ───────────────────────────

  static Color levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.levelBeginner;
      case 'elementary':
        return AppColors.levelElementary;
      case 'intermediate':
        return AppColors.levelIntermediate;
      case 'upper-intermediate':
        return AppColors.levelUpperIntermediate;
      case 'advanced':
        return AppColors.levelAdvanced;
      default:
        return AppColors.primary;
    }
  }
}
