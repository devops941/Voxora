import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class CurriculumController extends GetxController {
  final LessonRepository _lessonRepository;

  CurriculumController({LessonRepository? lessonRepository})
      : _lessonRepository = lessonRepository ?? Get.find<LessonRepository>();

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final RxInt selectedPhase = 1.obs; // 1, 2, or 3
  final RxList<DailyLessonModel> allLessons = <DailyLessonModel>[].obs;
  final RxInt currentDay = 1.obs;
  final RxInt completedDays = 0.obs;
  final RxInt totalDays = 90.obs;
  final RxInt streakCount = 0.obs;
  final RxString startingLevel = 'Beginner'.obs;
  final RxString selectedLevel = 'Beginner'.obs;
  final RxString activeTrackLevel = 'Beginner'.obs;
  final RxBool isUserActivePlan = true.obs;
  final RxString moduleTitle = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initFromArguments();
    loadPlan();
  }

  @override
  void onReady() {
    super.onReady();
    final args = Get.arguments;
    if (args is Map && args['level'] != null) {
      final newLevel = args['level'].toString();
      final newTitle = args['moduleTitle']?.toString() ?? '';
      selectLevel(newLevel);
      if (newTitle.isNotEmpty) {
        moduleTitle.value = newTitle;
      }
    }
  }

  void _initFromArguments() {
    final args = Get.arguments;
    if (args is Map) {
      if (args['level'] != null && args['level'].toString().isNotEmpty) {
        final lvl = args['level'].toString();
        selectedLevel.value = lvl;
        if (lvl.toLowerCase() == 'intermediate') {
          selectedPhase.value = 2;
          moduleTitle.value = 'Professional Workplace English';
        } else if (lvl.toLowerCase() == 'advanced' || lvl.toLowerCase() == 'all levels') {
          selectedLevel.value = 'Advanced';
          selectedPhase.value = 3;
          moduleTitle.value = 'Pronunciation & Accent Mastery';
        } else {
          selectedPhase.value = 1;
          moduleTitle.value = 'Everyday Conversations';
        }
      }
      if (args['moduleTitle'] != null && args['moduleTitle'].toString().isNotEmpty) {
        moduleTitle.value = args['moduleTitle'].toString();
      }
    }
  }

  Future<void> loadPlan({String? level}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final targetLevel = level ?? selectedLevel.value;
      final planData = await _lessonRepository.getPlan(level: targetLevel);

      startingLevel.value = planData['startingLevel']?.toString() ?? 'Beginner';
      activeTrackLevel.value = planData['activeTrackLevel']?.toString() ?? 'Beginner';
      isUserActivePlan.value = planData['isUserActivePlan'] == true;

      currentDay.value = (planData['currentDay'] as num?)?.toInt() ?? 1;
      completedDays.value = (planData['completedDays'] as num?)?.toInt() ?? 0;
      final tDays = (planData['totalDays'] as num?)?.toInt() ?? 90;
      totalDays.value = tDays > 0 ? tDays : 90;
      streakCount.value = (planData['streakCount'] as num?)?.toInt() ?? 0;

      // Keep user-selected level and phase intact
      if (selectedLevel.value.toLowerCase() == 'intermediate') {
        selectedPhase.value = 2;
        if (moduleTitle.value.isEmpty) {
          moduleTitle.value = 'Professional Workplace English';
        }
      } else if (selectedLevel.value.toLowerCase() == 'advanced' || selectedLevel.value.toLowerCase() == 'all levels') {
        selectedLevel.value = 'Advanced';
        selectedPhase.value = 3;
        if (moduleTitle.value.isEmpty) {
          moduleTitle.value = 'Pronunciation & Accent Mastery';
        }
      } else if (selectedLevel.value.toLowerCase() == 'beginner') {
        selectedPhase.value = 1;
        if (moduleTitle.value.isEmpty) {
          moduleTitle.value = 'Everyday Conversations';
        }
      } else {
        if (currentDay.value <= 30) {
          selectedPhase.value = 1;
        } else if (currentDay.value <= 60) {
          selectedPhase.value = 2;
        } else {
          selectedPhase.value = 3;
        }
      }

      final rawLessons = planData['lessons'] as List? ?? [];
      final List<DailyLessonModel> parsed = [];
      for (final item in rawLessons) {
        try {
          if (item is DailyLessonModel) {
            parsed.add(item);
          } else if (item is Map) {
            parsed.add(DailyLessonModel.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (err) {
          debugPrint('[Curriculum] Error parsing single lesson item: $err');
        }
      }
      allLessons.value = parsed;
      debugPrint('[Curriculum] Successfully loaded ${parsed.length} lessons. Filtered count: ${filteredLessons.length}');
    } catch (e, st) {
      debugPrint('[Curriculum] Error in loadPlan: $e\n$st');
      errorMessage.value = 'Failed to load 90-day learning curriculum: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void selectLevel(String level) {
    final lower = level.toLowerCase();
    if (lower == 'intermediate') {
      selectedLevel.value = 'Intermediate';
      selectedPhase.value = 2;
      moduleTitle.value = 'Professional Workplace English';
    } else if (lower == 'advanced' || lower == 'all levels' || lower == 'all') {
      selectedLevel.value = 'Advanced';
      selectedPhase.value = 3;
      moduleTitle.value = 'Pronunciation & Accent Mastery';
    } else {
      selectedLevel.value = 'Beginner';
      selectedPhase.value = 1;
      moduleTitle.value = 'Everyday Conversations';
    }

    if (allLessons.isEmpty) {
      loadPlan(level: selectedLevel.value);
    }
  }

  Future<void> setActiveTrack() async {
    try {
      isLoading.value = true;
      await _lessonRepository.setLevel(selectedLevel.value);
      await loadPlan(level: selectedLevel.value);
      Get.snackbar(
        'Active Track Updated 🎉',
        'Your daily 90-day curriculum is now set to ${selectedLevel.value}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Could not update active track: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<DailyLessonModel> get filteredLessons {
    if (allLessons.isEmpty) return [];

    if (selectedPhase.value == 0) {
      return allLessons;
    }

    if (selectedPhase.value == 1) {
      final p1 = allLessons.where((l) => l.phase == 1 || (l.day >= 1 && l.day <= 30)).toList();
      return p1.isNotEmpty ? p1 : allLessons;
    }

    if (selectedPhase.value == 2) {
      final p2 = allLessons.where((l) => l.phase == 2 || (l.day >= 31 && l.day <= 60)).toList();
      return p2.isNotEmpty ? p2 : allLessons;
    }

    if (selectedPhase.value == 3) {
      final p3 = allLessons.where((l) => l.phase == 3 || (l.day >= 61 && l.day <= 90)).toList();
      return p3.isNotEmpty ? p3 : allLessons;
    }

    return allLessons.where((l) => l.phase == selectedPhase.value).toList();
  }

  bool isLevelUnlocked(String level) {
    final lower = level.toLowerCase();
    if (lower == 'beginner') return true;
    if (lower == 'intermediate') return currentDay.value >= 31;
    if (lower == 'advanced' || lower == 'all levels' || lower == 'all') {
      return currentDay.value >= 61;
    }
    return true;
  }

  bool isPhaseUnlocked(int phase) {
    if (phase == 1) return true;
    if (phase == 2) return currentDay.value >= 31;
    if (phase == 3) return currentDay.value >= 61;
    return true;
  }

  bool isLessonUnlocked(DailyLessonModel lesson) {
    // Only 1 lesson per day:
    // Past completed days (lesson.day < currentDay) can be revised.
    // Today's lesson (lesson.day == currentDay) is active.
    // Future days are locked. Day 1 is always unlocked as the starting point.
    if (lesson.day == 1) return true;
    return lesson.day <= currentDay.value;
  }

  void selectPhase(int phase) {
    selectedPhase.value = phase;
    if (phase == 1) {
      selectedLevel.value = 'Beginner';
      moduleTitle.value = 'Everyday Conversations';
    } else if (phase == 2) {
      selectedLevel.value = 'Intermediate';
      moduleTitle.value = 'Professional Workplace English';
      if (!isPhaseUnlocked(2)) {
        Get.snackbar(
          'Phase 2 Locked 🔒',
          'Complete all Beginner classes (Days 1–30) first to unlock Phase 2!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E293B),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      }
    } else if (phase == 3) {
      selectedLevel.value = 'Advanced';
      moduleTitle.value = 'Pronunciation & Accent Mastery';
      if (!isPhaseUnlocked(3)) {
        Get.snackbar(
          'Phase 3 Locked 🔒',
          'Complete all Intermediate classes (Days 31–60) first to unlock Phase 3!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E293B),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void openLesson(DailyLessonModel lesson) {
    if (isLessonUnlocked(lesson)) {
      Get.toNamed(
        AppRoutes.lesson,
        arguments: {
          'day': lesson.day,
          'level': selectedLevel.value,
        },
      )?.then((_) => loadPlan(level: selectedLevel.value));
    } else {
      String lockMessage;
      if (lesson.day > 60 && currentDay.value < 61) {
        lockMessage = '🔒 Advanced is Locked! Complete Intermediate (Days 31–60) first to unlock Phase 3.';
      } else if (lesson.day > 30 && currentDay.value < 31) {
        lockMessage = '🔒 Intermediate is Locked! Complete Beginner (Days 1–30) first to unlock Phase 2.';
      } else {
        lockMessage = '🔒 Day ${lesson.day} is locked! Complete Day ${lesson.day - 1} first. (Only 1 class per day)';
      }

      Get.snackbar(
        'Lesson Locked 🔒',
        lockMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
