import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/data/models/user_model.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class SettingsController extends GetxController {
  final isLoading = true.obs;
  final isSaving = false.obs;

  final user = Rxn<UserModel>();

  // Profile controllers
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();

  // Learning & Track
  final selectedLevel = 'Beginner'.obs;
  final dailyGoalMinutes = 20.obs;

  // Notification Preferences
  final dailyReminders = true.obs;
  final reminderTime = '20:00'.obs;
  final weeklyReport = true.obs;

  // Learning Preferences
  final speechSpeed = 'Normal'.obs; // Slow, Normal, Fast
  final enableTamilTranslation = true.obs;
  final autoPlayAudio = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    locationController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      if (Get.isRegistered<AuthRepository>()) {
        final cached = await Get.find<AuthRepository>().getCachedUser();
        if (cached != null) {
          _applyUser(cached);
        }

        final remote = await Get.find<AuthRepository>().getMe();
        _applyUser(remote);
      }
    } catch (e) {
      debugPrint('[SettingsController] loadSettings error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyUser(UserModel u) {
    user.value = u;
    nameController.text = u.name;
    bioController.text = u.bio ?? '';
    locationController.text = u.location ?? '';
    if (u.level.isNotEmpty) {
      selectedLevel.value = u.level;
    }
    dailyGoalMinutes.value = u.dailyGoalMinutes;
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Validation', 'Name cannot be empty', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    try {
      final apiClient = Get.find<ApiClient>();
      final res = await apiClient.patch<Map<String, dynamic>>(
        '/users/me',
        data: {
          'name': name,
          'bio': bioController.text.trim(),
          'location': locationController.text.trim(),
          'dailyGoalMinutes': dailyGoalMinutes.value,
        },
      );

      final updated = res.data?['data'] ?? res.data;
      if (updated is Map<String, dynamic>) {
        user.value = UserModel.fromJson(updated);
      }

      Get.snackbar(
        'Profile Updated',
        'Your profile changes have been saved!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Could not update profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateLevel(String newLevel) async {
    if (selectedLevel.value == newLevel) return;

    isSaving.value = true;
    try {
      if (Get.isRegistered<LessonRepository>()) {
        await Get.find<LessonRepository>().setLevel(newLevel);
      }

      final apiClient = Get.find<ApiClient>();
      await apiClient.patch<Map<String, dynamic>>(
        '/users/me',
        data: {'level': newLevel},
      );

      selectedLevel.value = newLevel;

      Get.snackbar(
        'Curriculum Switched',
        'Active 90-day track updated to $newLevel level!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF6366F1),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update level track. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> persistPreferences() async {
    try {
      final apiClient = Get.find<ApiClient>();
      await apiClient.patch<Map<String, dynamic>>(
        '/users/me',
        data: {
          'preferences': {
            'dailyReminders': dailyReminders.value,
            'reminderTime': reminderTime.value,
            'weeklyReport': weeklyReport.value,
            'speechSpeed': speechSpeed.value,
            'enableTamilTranslation': enableTamilTranslation.value,
            'autoPlayAudio': autoPlayAudio.value,
          },
        },
      );
    } catch (e) {
      debugPrint('[SettingsController] persistPreferences notice: $e');
    }
  }

  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Voxora?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
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
}

