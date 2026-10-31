import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voxora/data/models/daily_lesson_model.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';

class SpeakingMessage {
  final String sender; // 'mira' | 'user'
  final String text;
  final SpeechEvaluationScores? scores;
  final String? corrected;
  final String? explanation;
  final List<String> tips;
  final DateTime timestamp;

  SpeakingMessage({
    required this.sender,
    required this.text,
    this.scores,
    this.corrected,
    this.explanation,
    this.tips = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SpeakingPracticeController extends GetxController {
  final LessonRepository _lessonRepository;

  SpeakingPracticeController({LessonRepository? lessonRepository})
      : _lessonRepository = lessonRepository ?? Get.find<LessonRepository>();

  final SpeechToText speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  final RxBool isSpeechAvailable = false.obs;
  final RxBool isListening = false.obs;
  final RxBool isThinking = false.obs;
  final RxBool isTtsSpeaking = false.obs;
  final RxString liveTranscript = ''.obs;
  final RxInt recordDuration = 0.obs;
  Timer? _recordTimer;

  final TextEditingController textController = TextEditingController();

  final List<String> topics = [
    'Casual Small Talk',
    'Job Interview Practice',
    'Ordering at a Restaurant',
    'Travel & Asking Directions',
    'Free Conversational Flow',
  ];

  final Map<String, List<String>> suggestionsMap = {
    'Casual Small Talk': [
      "I'm feeling great today, thanks for asking!",
      "I've been working on my spoken English goals.",
      "Can you teach me a natural conversation idiom?",
    ],
    'Job Interview Practice': [
      "I have several years of experience in my field.",
      "My greatest strength is solving problems collaboratively.",
      "Can you ask me a behavioral interview question?",
    ],
    'Ordering at a Restaurant': [
      "Could I please see today's chef specials?",
      "I'd like to order a cappuccino and a salad, please.",
      "Could we please get the check when you're ready?",
    ],
    'Travel & Asking Directions': [
      "Could you tell me how to get to the nearest station?",
      "What are the top must-see landmarks in this city?",
      "Where can I find authentic local cuisine nearby?",
    ],
    'Free Conversational Flow': [
      "Let's discuss how technology is changing education.",
      "What is the best daily routine to become fluent in English?",
      "Can we practice making friendly conversation at work?",
    ],
  };

  List<String> get currentSuggestions =>
      suggestionsMap[selectedTopic.value] ?? suggestionsMap['Casual Small Talk']!;

  final RxString selectedTopic = 'Casual Small Talk'.obs;
  final RxList<SpeakingMessage> messages = <SpeakingMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initTtsEngine();
    _initSpeechEngine();
    _initConversation();
  }

  @override
  void onClose() {
    _recordTimer?.cancel();
    stopTts();
    try {
      if (speechToText.isListening) {
        speechToText.stop();
      }
    } catch (_) {}
    textController.dispose();
    super.onClose();
  }

  Future<void> _initTtsEngine() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.05);
      await _flutterTts.setVolume(1.0);
      _flutterTts.setStartHandler(() => isTtsSpeaking.value = true);
      _flutterTts.setCompletionHandler(() => isTtsSpeaking.value = false);
      _flutterTts.setErrorHandler((_) => isTtsSpeaking.value = false);
    } catch (e) {
      debugPrint('TTS init error in Practice: $e');
    }
  }

  Future<void> speakMiraText(String text) async {
    try {
      await _flutterTts.stop();
      isTtsSpeaking.value = true;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error in Practice: $e');
      isTtsSpeaking.value = false;
    }
  }

  Future<void> stopTts() async {
    try {
      await _flutterTts.stop();
      isTtsSpeaking.value = false;
    } catch (_) {}
  }

  Future<void> _initSpeechEngine() async {
    try {
      final available = await speechToText.initialize(
        onError: (e) => debugPrint('STT Error in Practice: $e'),
        onStatus: (s) => debugPrint('STT Status in Practice: $s'),
      );
      isSpeechAvailable.value = available;
    } catch (e) {
      debugPrint('STT Init exception in Practice: $e');
    }
  }

  void _initConversation() {
    stopTts();
    messages.clear();
    String intro;
    switch (selectedTopic.value) {
      case 'Job Interview Practice':
        intro = 'Hello! Welcome to your mock interview session. Tell me: What are your key strengths, and what kind of roles do you excel at?';
        break;
      case 'Ordering at a Restaurant':
        intro = 'Welcome to Bistro Voxora! What can I get started for you today?';
        break;
      case 'Travel & Asking Directions':
        intro = 'Hi there, traveler! Where are you headed today, or do you need recommendations for popular city sights?';
        break;
      case 'Free Conversational Flow':
        intro = "Hi! I'm Mira. Let's chat about anything on your mind. How was your day today?";
        break;
      case 'Casual Small Talk':
      default:
        intro = "Hi! I'm Mira, your AI voice tutor. How are you feeling today, and what have you been up to?";
        break;
    }

    messages.add(SpeakingMessage(sender: 'mira', text: intro));
    // Read aloud the intro smoothly
    Future.delayed(const Duration(milliseconds: 400), () {
      speakMiraText(intro);
    });
  }

  void selectTopic(String topic) {
    if (selectedTopic.value != topic) {
      stopTts();
      selectedTopic.value = topic;
      _initConversation();
    }
  }

  Future<void> startListening() async {
    stopTts();
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Microphone Permission',
        'Please enable microphone access in your device settings to speak with Mira.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!isSpeechAvailable.value) {
      await _initSpeechEngine();
    }

    liveTranscript.value = '';
    recordDuration.value = 0;

    try {
      isListening.value = true;
      await speechToText.listen(
        onResult: (result) {
          liveTranscript.value = result.recognizedWords;
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
        ),
      );

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordDuration.value++;
      });
    } catch (e) {
      debugPrint('Start listening error in Practice: $e');
      isListening.value = false;
    }
  }

  Future<void> stopListeningAndSend() async {
    _recordTimer?.cancel();
    try {
      if (speechToText.isListening) {
        await speechToText.stop();
      }
    } catch (_) {}
    isListening.value = false;

    final transcript = liveTranscript.value.trim().isNotEmpty
        ? liveTranscript.value.trim()
        : textController.text.trim();

    if (transcript.isEmpty) return;

    await sendUserResponse(transcript);
  }

  Future<void> sendUserResponse(String userText) async {
    stopTts();
    liveTranscript.value = '';
    textController.clear();

    // Get the last prompt from Mira
    final lastMiraMsg = messages.lastWhere(
      (m) => m.sender == 'mira',
      orElse: () => SpeakingMessage(sender: 'mira', text: 'Tell me about yourself'),
    );

    isThinking.value = true;

    try {
      final eval = await _lessonRepository.evaluateSpokenResponse(
        day: 1,
        miraQuestion: lastMiraMsg.text,
        userTranscript: userText,
        durationSeconds: recordDuration.value > 0 ? recordDuration.value : 10,
        topic: selectedTopic.value,
      );

      // Add user message with evaluated metrics
      messages.add(SpeakingMessage(
        sender: 'user',
        text: userText,
        scores: eval.scores,
        corrected: (eval.corrected.isNotEmpty && eval.corrected != userText) ? eval.corrected : null,
        explanation: eval.explanation,
        tips: eval.pronunciationTips,
      ));

      // Add Mira's reply
      messages.add(SpeakingMessage(
        sender: 'mira',
        text: eval.miraReply,
      ));
      speakMiraText(eval.miraReply);
    } catch (e) {
      messages.add(SpeakingMessage(
        sender: 'user',
        text: userText,
      ));
      const fallbackReply = 'I heard you clearly! Let us keep building on that. What else would you like to share?';
      messages.add(SpeakingMessage(
        sender: 'mira',
        text: fallbackReply,
      ));
      speakMiraText(fallbackReply);
    } finally {
      isThinking.value = false;
    }
  }

  void resetConversation() {
    _initConversation();
  }
}
