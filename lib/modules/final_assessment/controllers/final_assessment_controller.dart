import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/data/models/final_assessment_model.dart';
import 'package:voxora/data/repositories/final_assessment_repository.dart';

class FinalAssessmentController extends GetxController {
  // Eligibility
  final isCheckingEligibility = false.obs;
  final isEligible = false.obs;
  final ineligibleReason = ''.obs;
  final isTestMode = false.obs;
  final selectedLevel = 'Beginner'.obs;

  // Assessment session
  final isLoading = false.obs;
  final isAssessmentStarted = false.obs;
  final questions = <AssessmentQuestion>[].obs;
  final assessmentId = ''.obs;
  final currentQuestionIndex = 0.obs;
  final selectedAnswers = <String, int>{}.obs;

  AssessmentResultModel? result;

  @override
  void onInit() {
    super.onInit();
    checkEligibility(selectedLevel.value);
  }

  void selectLevel(String level) {
    if (selectedLevel.value == level) return;
    selectedLevel.value = level;
    isEligible.value = false;
    ineligibleReason.value = '';
    checkEligibility(level);
  }

  Future<void> checkEligibility(String level) async {
    isCheckingEligibility.value = true;
    try {
      final repo = Get.find<FinalAssessmentRepository>();
      final data = await repo.checkEligibility(level);
      isEligible.value = data['eligible'] as bool? ?? false;
      isTestMode.value = data['isTestMode'] as bool? ?? false;
      ineligibleReason.value = data['reason'] as String? ?? '';
    } catch (e) {
      isEligible.value = false;
      ineligibleReason.value = 'Unable to check eligibility. Please try again.';
    } finally {
      isCheckingEligibility.value = false;
    }
  }

  Future<void> startAssessment() async {
    if (!isEligible.value) return;
    isLoading.value = true;
    try {
      final repo = Get.find<FinalAssessmentRepository>();
      final assessment = await repo.startAssessment(selectedLevel.value);
      assessmentId.value = assessment.assessmentId;
      questions.assignAll(assessment.questions);
      selectedAnswers.clear();
      currentQuestionIndex.value = 0;
      isAssessmentStarted.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start assessment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectAnswer(String questionId, int optionIndex) {
    selectedAnswers[questionId] = optionIndex;
    selectedAnswers.refresh();
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
    } else {
      _showSubmitConfirmation();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex.value > 0) {
      currentQuestionIndex.value--;
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      currentQuestionIndex.value = index;
    }
  }

  void _showSubmitConfirmation() {
    final answered = selectedAnswers.length;
    final total = questions.length;
    Get.defaultDialog(
      title: 'Submit Assessment?',
      middleText:
          'Answered: $answered of $total questions.\n\nAre you sure you want to submit?',
      textConfirm: 'Submit Now',
      textCancel: 'Review Answers',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF7C3AED),
      onConfirm: () {
        Get.back();
        submitAssessment();
      },
    );
  }

  Future<void> submitAssessment() async {
    isLoading.value = true;
    try {
      final repo = Get.find<FinalAssessmentRepository>();
      result = await repo.submitAssessment(
        assessmentId.value,
        Map<String, int>.from(selectedAnswers),
      );
      Get.toNamed(AppRoutes.assessmentResult, arguments: result);
    } catch (e) {
      Get.snackbar(
        'Submission Failed',
        'Could not submit assessment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void retryAssessment() {
    isAssessmentStarted.value = false;
    questions.clear();
    selectedAnswers.clear();
    currentQuestionIndex.value = 0;
    assessmentId.value = '';
    result = null;
    startAssessment();
  }

  void resetToLevelSelection() {
    isAssessmentStarted.value = false;
    questions.clear();
    selectedAnswers.clear();
    currentQuestionIndex.value = 0;
    assessmentId.value = '';
    result = null;
  }
}
