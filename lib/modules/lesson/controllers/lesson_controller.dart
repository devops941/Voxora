import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class LessonController extends GetxController with WidgetsBindingObserver {
  final LessonRepository _lessonRepository;

  LessonController({LessonRepository? lessonRepository})
      : _lessonRepository = lessonRepository ?? Get.find<LessonRepository>();

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final Rx<DailyLessonModel?> dailyLesson = Rx<DailyLessonModel?>(null);
  final RxInt dayNumber = 1.obs;

  // ── Two Distinct Lesson Phases ─────────────────────────────────────
  // 1: Phase 1 – AI Teaching (15 min)
  // 2: Phase 2 – Speaking Practice (15 min)
  // 3: Session Complete & Celebration
  final RxInt currentPhase = 1.obs;
  final RxInt teachingSubStep = 0.obs; // 0: Vocab & Meaning, 1: Grammar Rules, 2: Dialogue

  // Session Duration Timer
  final RxInt sessionElapsedSeconds = 0.obs;
  final RxBool isSessionPaused = false.obs;
  Timer? _sessionTimer;

  // ── MIRA Voice TTS Engine ─────────────────────────────────────────
  final FlutterTts _flutterTts = FlutterTts();
  final RxBool isTtsSpeaking = false.obs;
  final RxBool isTtsPaused = false.obs;
  final RxString currentTtsText = ''.obs;

  // ── Phase 2: Speech Recording & AI Evaluation ─────────────────────
  final SpeechToText _speechToText = SpeechToText();
  final RxBool isSpeechAvailable = false.obs;
  final RxBool isListening = false.obs;
  final RxString liveTranscript = ''.obs;
  final RxInt recordDuration = 0.obs;
  Timer? _recordTimer;

  final RxInt currentQuestionIndex = 0.obs;
  final RxBool isEvaluating = false.obs;
  final Rx<SpeechEvaluationModel?> lastEvaluation = Rx<SpeechEvaluationModel?>(null);
  final RxList<Map<String, dynamic>> completedExchanges = <Map<String, dynamic>>[].obs;
  final RxInt earnedXp = 0.obs;
  final RxInt newStreak = 0.obs;
  final RxInt overallLessonScore = 0.obs;

  // Dynamic question queue & Tamil hints toggle
  static const int maxQuestionsPerLesson = 5;
  final RxList<String> dynamicQuestions = <String>[].obs;
  final RxBool showTamilHints = true.obs;

  List<String> get allQuestions {
    final list = dynamicQuestions.isNotEmpty
        ? dynamicQuestions
        : (dailyLesson.value?.miraQuestions ?? []);
    if (list.isNotEmpty) {
      return list.take(maxQuestionsPerLesson).toList();
    }
    return [
      'Hello! Welcome to Voxora. What is your name and where are you from?',
      'Nice to meet you! What do you do for work or study?',
      'What are your favorite hobbies or what do you like to do on weekends?',
      'Why do you want to learn English, and what is your dream speaking goal?',
      'Can you say one full sentence: "I am practicing English every day to speak fluently and confidently"?',
    ];
  }

  // Doubt asking state
  final RxBool isAskingDoubt = false.obs;
  final RxString lastDoubtAnswer = ''.obs;
  final TextEditingController doubtInputController = TextEditingController();

  // Text fallback controller
  final TextEditingController textInputController = TextEditingController();

  final RxString lessonLevel = ''.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    final args = Get.arguments;
    if (args is Map) {
      if (args['day'] != null) {
        dayNumber.value = int.tryParse(args['day'].toString()) ?? 1;
      }
      if (args['level'] != null) {
        lessonLevel.value = args['level'].toString();
      }
    }

    _initTtsEngine();
    _initSpeechEngine();
    _startSessionTimer();
    loadLesson(dayNumber.value, level: lessonLevel.value.isNotEmpty ? lessonLevel.value : null);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _recordTimer?.cancel();
    _stopTtsInternal();
    try {
      if (_speechToText.isListening) {
        _speechToText.stop();
      }
    } catch (_) {}
    textInputController.dispose();
    doubtInputController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause TTS & recording on backgrounding or phone calls
      pauseTts();
      if (isListening.value) {
        _speechToText.stop();
        isListening.value = false;
        _recordTimer?.cancel();
      }
      isSessionPaused.value = true;
    } else if (state == AppLifecycleState.resumed) {
      isSessionPaused.value = false;
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isSessionPaused.value) {
        sessionElapsedSeconds.value++;
      }
    });
  }

  // ── TTS Engine Configuration ──────────────────────────────────────
  Future<void> _initTtsEngine() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48); // friendly, clear cadence
      await _flutterTts.setPitch(1.05); // warm voice
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        isTtsSpeaking.value = true;
        isTtsPaused.value = false;
      });

      _flutterTts.setCompletionHandler(() {
        isTtsSpeaking.value = false;
        isTtsPaused.value = false;
      });

      _flutterTts.setPauseHandler(() {
        isTtsSpeaking.value = false;
        isTtsPaused.value = true;
      });

      _flutterTts.setContinueHandler(() {
        isTtsSpeaking.value = true;
        isTtsPaused.value = false;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        isTtsSpeaking.value = false;
        isTtsPaused.value = false;
      });
    } catch (e) {
      debugPrint('TTS Initialization Notice: $e');
    }
  }

  Future<void> speakLessonText(String text) async {
    if (text.trim().isEmpty) return;
    try {
      // Prevent overlapping speech and recording
      if (isListening.value) {
        await _speechToText.stop();
        isListening.value = false;
        _recordTimer?.cancel();
      }

      currentTtsText.value = text;
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Speak exception: $e');
    }
  }

  Future<void> pauseTts() async {
    try {
      if (isTtsSpeaking.value) {
        await _flutterTts.pause();
        isTtsSpeaking.value = false;
        isTtsPaused.value = true;
      }
    } catch (_) {}
  }

  Future<void> resumeTts() async {
    try {
      if (isTtsPaused.value && currentTtsText.value.isNotEmpty) {
        await _flutterTts.speak(currentTtsText.value);
      }
    } catch (_) {}
  }

  Future<void> replayCurrentSection() async {
    if (currentTtsText.value.isNotEmpty) {
      await speakLessonText(currentTtsText.value);
    }
  }

  Future<void> repeatSentence(String sentence) async {
    await speakLessonText(sentence);
  }

  Future<void> stopTts() async {
    await _stopTtsInternal();
  }

  Future<void> _stopTtsInternal() async {
    try {
      await _flutterTts.stop();
      isTtsSpeaking.value = false;
      isTtsPaused.value = false;
    } catch (_) {}
  }

  // ── Speech-to-Text Initialization ─────────────────────────────────
  Future<void> _initSpeechEngine() async {
    try {
      final available = await _speechToText.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
      isSpeechAvailable.value = available;
    } catch (e) {
      debugPrint('STT Init exception: $e');
      isSpeechAvailable.value = false;
    }
  }

  // ── Lesson Data Loading ───────────────────────────────────────────
  Future<void> loadLesson(int day, {String? level}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      _stopTtsInternal();

      final targetLevel = level ?? (lessonLevel.value.isNotEmpty ? lessonLevel.value : null);
      final res = await _lessonRepository.getDayLesson(day, level: targetLevel);
      final lessonData = res['lesson'];
      if (lessonData != null) {
        dailyLesson.value = DailyLessonModel.fromJson(lessonData as Map<String, dynamic>);
        dayNumber.value = dailyLesson.value?.day ?? day;
        currentPhase.value = 1;
        teachingSubStep.value = 0;

        final lesson = dailyLesson.value;
        if (lesson != null && lesson.miraQuestions.isNotEmpty) {
          dynamicQuestions.assignAll(lesson.miraQuestions.take(maxQuestionsPerLesson));
        }
        currentQuestionIndex.value = 0;

        // Auto-welcome readout for Phase 1 (speaks full teaching script if available)
        final spokenScript = lesson?.teachingContent?.spokenScript;
        final topic = lesson?.topic ?? 'Daily English';
        final speech = (spokenScript != null && spokenScript.isNotEmpty)
            ? spokenScript
            : "Welcome to Day $day of Voxora! Today, we are mastering: $topic. Let's explore the core lesson concepts, dialogue, and vocabulary together.";

        Future.delayed(const Duration(milliseconds: 600), () {
          speakLessonText(speech);
        });
      } else {
        errorMessage.value = 'Failed to load Day $day lesson details.';
      }
    } catch (e) {
      errorMessage.value = 'Unable to connect to Voxora server: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> teachFullLesson() async {
    final lesson = dailyLesson.value;
    final script = lesson?.teachingContent?.spokenScript;
    if (script != null && script.isNotEmpty) {
      await speakLessonText(script);
    } else {
      await replayCurrentSection();
    }
  }

  // ── Phase Navigation ──────────────────────────────────────────────
  void setPhase(int phase) {
    if (phase >= 1 && phase <= 3) {
      _stopTtsInternal();
      currentPhase.value = phase;
      if (phase == 2) {
        // Announce Phase 2 Speaking Practice
        Future.delayed(const Duration(milliseconds: 400), () {
          readCurrentQuestion();
        });
      }
    }
  }

  void setTeachingSubStep(int step) {
    if (step >= 0 && step <= 2) {
      teachingSubStep.value = step;
      _stopTtsInternal();
    }
  }

  void readCurrentQuestion() {
    final questions = allQuestions;
    final q = questions[currentQuestionIndex.value.clamp(0, questions.length - 1)];
    speakLessonText('Question ${currentQuestionIndex.value + 1}: $q');
  }

  // ── Phase 2: Speech Recording & Evaluation ────────────────────────
  Future<void> startListening() async {
    // Stop TTS so MIRA does not record herself
    await _stopTtsInternal();

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Microphone Permission Required',
        'Please grant microphone permission to practice spoken English with Mira.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!isSpeechAvailable.value) {
      await _initSpeechEngine();
    }

    liveTranscript.value = '';
    recordDuration.value = 0;
    lastEvaluation.value = null;

    try {
      isListening.value = true;
      await _speechToText.listen(
        onResult: (result) {
          liveTranscript.value = result.recognizedWords;
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
        ),
      );

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordDuration.value++;
      });
    } catch (e) {
      debugPrint('Start listening error: $e');
      isListening.value = false;
    }
  }

  Future<void> stopListeningAndEvaluate() async {
    _recordTimer?.cancel();
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}
    isListening.value = false;

    final transcript = liveTranscript.value.trim().isNotEmpty
        ? liveTranscript.value.trim()
        : textInputController.text.trim();

    if (transcript.isEmpty) {
      Get.snackbar(
        'No speech detected',
        'Tap the microphone and speak your answer clearly to Mira.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await evaluateSpokenAnswer(transcript);
  }

  Future<void> submitManualInput() async {
    final text = textInputController.text.trim();
    if (text.isEmpty) return;
    textInputController.clear();
    await evaluateSpokenAnswer(text);
  }

  Future<void> evaluateSpokenAnswer(String transcript) async {
    final lesson = dailyLesson.value;
    if (lesson == null) return;

    final questions = allQuestions;
    final currentQ = questions[currentQuestionIndex.value.clamp(0, questions.length - 1)];

    try {
      isEvaluating.value = true;
      final eval = await _lessonRepository.evaluateSpokenResponse(
        day: lesson.day,
        miraQuestion: currentQ,
        userTranscript: transcript,
        durationSeconds: recordDuration.value > 0 ? recordDuration.value : 12,
      );

      lastEvaluation.value = eval;

      // Add dynamic next question from backend if present and queue hasn't reached 5
      if (dynamicQuestions.length < maxQuestionsPerLesson &&
          eval.nextSuggestedQuestion != null &&
          eval.nextSuggestedQuestion!.trim().isNotEmpty &&
          !dynamicQuestions.contains(eval.nextSuggestedQuestion!.trim())) {
        dynamicQuestions.add(eval.nextSuggestedQuestion!.trim());
      }

      // Add to completed exchanges list
      completedExchanges.add({
        'miraPrompt': currentQ,
        'userAudioTranscript': transcript,
        'durationSeconds': recordDuration.value > 0 ? recordDuration.value : 12,
        'scores': eval.scores.toJson(),
        'corrections': [
          if (eval.corrected.isNotEmpty && eval.corrected != transcript)
            {
              'original': eval.original,
              'corrected': eval.corrected,
              'explanation': eval.explanation,
            }
        ],
        'pronunciationTips': eval.pronunciationTips,
      });

      // MIRA speaks feedback
      if (eval.miraReply.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 400), () {
          speakLessonText(eval.miraReply);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Evaluation Notice',
        'Could not evaluate voice response: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isEvaluating.value = false;
    }
  }

  void retryCurrentQuestion() {
    _stopTtsInternal();
    liveTranscript.value = '';
    lastEvaluation.value = null;
    recordDuration.value = 0;
  }

  Future<void> nextQuestionOrFinish() async {
    _stopTtsInternal();
    final lesson = dailyLesson.value;
    if (lesson == null) return;

    final questions = allQuestions;

    if (currentQuestionIndex.value < questions.length - 1 &&
        currentQuestionIndex.value < maxQuestionsPerLesson - 1) {
      currentQuestionIndex.value++;
      liveTranscript.value = '';
      lastEvaluation.value = null;
      recordDuration.value = 0;
      readCurrentQuestion();
    } else {
      await completeDailyLesson();
    }
  }

  // ── Ask Doubt to MIRA ─────────────────────────────────────────────
  Future<void> askDoubt(String userQuestion) async {
    final q = userQuestion.trim();
    if (q.isEmpty) return;

    try {
      isAskingDoubt.value = true;
      final answer = await _lessonRepository.askDoubt(
        day: dayNumber.value,
        userQuestion: q,
        topic: dailyLesson.value?.topic,
      );
      lastDoubtAnswer.value = answer;
      doubtInputController.clear();

      // Read MIRA's explanation aloud
      speakLessonText(answer);
    } catch (e) {
      lastDoubtAnswer.value = "Here is a quick tip: In everyday English, keep your sentence simple and clear! Practice repeating after me.";
    } finally {
      isAskingDoubt.value = false;
    }
  }

  // ── Session Completion (MongoDB Persistence) ──────────────────────
  Future<void> completeDailyLesson() async {
    final lesson = dailyLesson.value;
    if (lesson == null) return;

    try {
      isLoading.value = true;
      _stopTtsInternal();

      int totalScore = 0;
      for (final ex in completedExchanges) {
        final scores = ex['scores'] as Map<String, dynamic>?;
        totalScore += (scores?['overall'] as num?)?.toInt() ?? 85;
      }
      final avgScore = completedExchanges.isNotEmpty
          ? (totalScore / completedExchanges.length).round()
          : 85;
      overallLessonScore.value = avgScore;

      final result = await _lessonRepository.completeLesson(
        day: lesson.day,
        score: avgScore,
        timeSpentSeconds: sessionElapsedSeconds.value > 0 ? sessionElapsedSeconds.value : 900,
        exchanges: completedExchanges,
      );

      earnedXp.value = (result['xpEarned'] as num?)?.toInt() ?? 85;
      newStreak.value = (result['streak'] as num?)?.toInt() ?? 1;

      // Refresh cached user profile
      if (Get.isRegistered<AuthRepository>()) {
        try {
          await Get.find<AuthRepository>().getMe();
        } catch (_) {}
      }

      currentPhase.value = 3; // Celebration Step!
      speakLessonText("Congratulations! You have completed Day ${lesson.day} with a score of $avgScore percent! Fantastic progress!");
    } catch (e) {
      Get.snackbar(
        'Completion Notice',
        'Lesson attempt saved: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      currentPhase.value = 3;
    } finally {
      isLoading.value = false;
    }
  }

  void finishAndReturnHome() {
    _stopTtsInternal();
    Get.offAllNamed(AppRoutes.dashboard);
  }
}
