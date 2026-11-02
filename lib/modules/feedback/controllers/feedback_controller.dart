import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class FeedbackController extends GetxController {
  final isLoading = true.obs;
  final selectedTabIndex = 0.obs; // 0 = Performance, 1 = History

  // Performance metrics
  final grammarScore = 0.obs;
  final pronunciationScore = 0.obs;
  final fluencyScore = 0.obs;
  final vocabularyScore = 0.obs;
  final sentenceFormationScore = 0.obs;
  final overallScore = 0.obs;

  final grammarFeedback = ''.obs;
  final pronunciationTips = <String>[].obs;
  final fluencyObservation = ''.obs;
  final suggestedWords = <String>[].obs;
  final sentenceAdvice = ''.obs;

  final strengths = <String>[].obs;
  final weaknesses = <String>[].obs;
  final suggestions = <String>[].obs;

  final historyList = <Map<String, dynamic>>[].obs;
  final selectedHistoryItem = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _initFromArguments();
    loadFeedbackData();
  }

  void _initFromArguments() {
    final args = Get.arguments;
    if (args is Map) {
      if (args['scores'] is Map) {
        final s = args['scores'] as Map;
        grammarScore.value = (s['grammar'] as num?)?.toInt() ?? 80;
        pronunciationScore.value = (s['pronunciation'] as num?)?.toInt() ?? 85;
        fluencyScore.value = (s['fluency'] as num?)?.toInt() ?? 82;
        vocabularyScore.value = (s['vocabulary'] as num?)?.toInt() ?? 78;
        sentenceFormationScore.value = (s['sentenceFormation'] as num?)?.toInt() ?? 80;
        overallScore.value = (s['overall'] as num?)?.toInt() ?? 81;
      }
      if (args['explanation'] != null) {
        grammarFeedback.value = args['explanation'].toString();
      }
      if (args['pronunciationTips'] is List) {
        pronunciationTips.assignAll(
          List<String>.from(args['pronunciationTips'].map((e) => e.toString())),
        );
      }
      if (args['strengths'] is List) {
        strengths.assignAll(
          List<String>.from(args['strengths'].map((e) => e.toString())),
        );
      }
      if (args['weaknesses'] is List) {
        weaknesses.assignAll(
          List<String>.from(args['weaknesses'].map((e) => e.toString())),
        );
      }
      if (args['suggestions'] is List) {
        suggestions.assignAll(
          List<String>.from(args['suggestions'].map((e) => e.toString())),
        );
      }
    }
  }

  Future<void> loadFeedbackData() async {
    isLoading.value = true;
    try {
      final apiClient = Get.find<ApiClient>();

      // 1. Fetch real Feedback History from backend MongoDB
      try {
        final res = await apiClient.get<Map<String, dynamic>>('/ai/feedback/history');
        final data = res.data?['data'];
        if (data is List) {
          historyList.assignAll(
            data.whereType<Map<String, dynamic>>().toList(),
          );
        }
      } catch (err) {
        debugPrint('[FeedbackController] History fetch notice: $err');
      }

      // 2. If metrics were not supplied via arguments, extract from history or dashboard
      if (overallScore.value == 0) {
        if (historyList.isNotEmpty) {
          final latest = historyList.first;
          final sc = latest['scores'] as Map<String, dynamic>?;
          if (sc != null) {
            grammarScore.value = (sc['grammar'] as num?)?.toInt() ?? 80;
            pronunciationScore.value = (sc['pronunciation'] as num?)?.toInt() ?? 85;
            fluencyScore.value = (sc['fluency'] as num?)?.toInt() ?? 82;
            vocabularyScore.value = (sc['vocabulary'] as num?)?.toInt() ?? 78;
            sentenceFormationScore.value = 80;
            overallScore.value = (latest['overallScore'] as num?)?.toInt() ?? 81;
          }
          if (latest['summary'] != null) {
            grammarFeedback.value = latest['summary'].toString();
          }
          if (latest['pronunciationTips'] is List) {
            pronunciationTips.assignAll(
              List<String>.from(latest['pronunciationTips'].map((e) => e.toString())),
            );
          }
        } else if (Get.isRegistered<LessonRepository>()) {
          final dash = await Get.find<LessonRepository>().getDashboard();
          final prog = dash['progress'] as Map<String, dynamic>?;
          final avg = prog?['averageScores'] as Map<String, dynamic>?;
          if (avg != null) {
            grammarScore.value = (avg['grammar'] as num?)?.toInt() ?? 75;
            pronunciationScore.value = (avg['pronunciation'] as num?)?.toInt() ?? 80;
            fluencyScore.value = (avg['fluency'] as num?)?.toInt() ?? 78;
            vocabularyScore.value = (avg['vocabulary'] as num?)?.toInt() ?? 76;
            sentenceFormationScore.value = 75;
            overallScore.value = (avg['overall'] as num?)?.toInt() ?? 77;
          }
          if (dash['personalizedSuggestions'] is List) {
            suggestions.assignAll(
              List<String>.from(dash['personalizedSuggestions'].map((e) => e.toString())),
            );
          }
        }
      }

      // Populate default strengths & suggestions if empty
      if (strengths.isEmpty) {
        strengths.addAll([
          'Clear communication attempt and enthusiastic tone',
          'Good word comprehension and responsive flow',
        ]);
      }
      if (weaknesses.isEmpty) {
        weaknesses.addAll([
          'Preposition usage in time phrases (e.g. at vs in)',
          'Occasional mid-thought hesitation when searching for vocabulary',
        ]);
      }
      if (suggestions.isEmpty) {
        suggestions.addAll([
          'Speak with MIRA for 15 minutes daily to build spontaneous cadence.',
          'Focus on articulating consonant endings (-ed, -s, -t) distinctly.',
          'Review the vocabulary cards and use each in everyday conversation.',
        ]);
      }
      if (pronunciationTips.isEmpty) {
        pronunciationTips.addAll([
          'Maintain an open vocal posture to lengthen vowel sounds naturally.',
          'Pause between clauses rather than between single words.',
        ]);
      }
      if (grammarFeedback.isEmpty) {
        grammarFeedback.value = 'Consistent tense usage and solid sentence foundation.';
      }
    } catch (e) {
      debugPrint('[FeedbackController] load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectHistoryItem(Map<String, dynamic> item) {
    selectedHistoryItem.value = item;
    final sc = item['scores'] as Map<String, dynamic>?;
    if (sc != null) {
      grammarScore.value = (sc['grammar'] as num?)?.toInt() ?? 80;
      pronunciationScore.value = (sc['pronunciation'] as num?)?.toInt() ?? 85;
      fluencyScore.value = (sc['fluency'] as num?)?.toInt() ?? 82;
      vocabularyScore.value = (sc['vocabulary'] as num?)?.toInt() ?? 78;
      sentenceFormationScore.value = 80;
      overallScore.value = (item['overallScore'] as num?)?.toInt() ?? 81;
    }
    if (item['summary'] != null) {
      grammarFeedback.value = item['summary'].toString();
    }
    if (item['pronunciationTips'] is List) {
      pronunciationTips.assignAll(
        List<String>.from(item['pronunciationTips'].map((e) => e.toString())),
      );
    }
    selectedTabIndex.value = 0; // Switch to overview
  }
}

