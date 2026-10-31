import Anthropic from '@anthropic-ai/sdk';
import { GoogleGenAI } from '@google/genai';
import logger from '../../utils/logger';
import { analyzeStudentDoubt } from './doubt_analyzer';
import { Assessment, IAssessment } from '../assessments/assessment.model';
import { LearningPlan, ILearningPlan, IDailyLesson } from '../curriculum/plan.model';
import { build90DayCurriculum } from '../curriculum/curriculum_generator';
import { generateTeachingContent } from '../curriculum/teaching_content_generator';
import { evaluateSpokenSubmission } from './speech_evaluator';
import { LessonAttempt } from '../lessons/lesson_attempt.model';
import { User } from '../users/user.model';
import mongoose from 'mongoose';

export interface SpeechAssessmentDTO {
  transcript: string;
  selectedLevel?: string;
  durationSeconds?: number;
  userId?: string;
}

export interface SpeechScore {
  fluency: number;
  pronunciation: number;
  grammar: number;
  vocabulary: number;
  overall: number;
}

export interface MonthPlan {
  month: number;
  daysRange: string;
  title: string;
  desc: string;
  focusAreas: string[];
  colorHex: string;
}

export interface SpeechAssessmentResult {
  assessmentId?: string;
  transcript: string;
  recommendedLevel: string;
  levelBadge: string;
  dailyGoalMinutes: number;
  scores: SpeechScore;
  diagnosis: {
    strength: string;
    focusArea: string;
    feedbackSummary: string;
  };
  schedule: MonthPlan[];
  plan?: ILearningPlan;
}

export class AIService {
  private anthropic: Anthropic | null = null;
  private gemini: GoogleGenAI | null = null;
  private claudeModel: string = 'claude-3-5-haiku-20241022';
  private geminiModel: string = 'gemini-2.5-flash';

  constructor() {
    // 1. Initialize Claude (Primary Provider)
    const anthropicKey = process.env.ANTHROPIC_API_KEY;
    this.claudeModel = process.env.ANTHROPIC_MODEL || 'claude-3-5-haiku-20241022';
    if (anthropicKey && anthropicKey.length > 10 && !anthropicKey.includes('dummy') && !anthropicKey.includes('xxxx')) {
      try {
        this.anthropic = new Anthropic({
          apiKey: anthropicKey,
          timeout: 5000,
        });
        logger.info(`🤖 [Primary AI] Anthropic Claude client initialized (Model: ${this.claudeModel})`);
      } catch (err: any) {
        logger.warn(`Anthropic client init notice: ${err?.message || err}`);
      }
    } else {
      logger.warn('⚠️ Anthropic API key not configured or placeholder.');
    }

    // 2. Initialize Gemini (Automatic Fallback Provider)
    const geminiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;
    this.geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
    if (geminiKey && geminiKey.length > 10 && !geminiKey.includes('dummy') && !geminiKey.includes('xxxx')) {
      try {
        // AQ... keys are the new Google AI Studio format — use Bearer auth instead of x-goog-api-key
        this.gemini = geminiKey.startsWith('AQ')
          ? new GoogleGenAI({ httpOptions: { headers: { 'Authorization': `Bearer ${geminiKey}` } } })
          : new GoogleGenAI({ apiKey: geminiKey });
        logger.info(`🤖 [Fallback AI] Google Gemini client initialized (Model: ${this.geminiModel})`);
      } catch (err: any) {
        logger.warn(`Gemini client init notice: ${err?.message || err}`);
      }
    } else {
      logger.warn('⚠️ Gemini API key not configured or placeholder.');
    }
  }

  /**
   * Evaluates user's spoken speech, stores assessment in MongoDB, and generates persistent 90-day plan.
   */
  async assessSpeech(data: SpeechAssessmentDTO): Promise<SpeechAssessmentResult> {
    const rawTranscript = (data.transcript || '').trim();
    const duration = data.durationSeconds && data.durationSeconds > 0 ? data.durationSeconds : 15;
    const selectedLevel = (data.selectedLevel || 'Beginner') as 'Beginner' | 'Intermediate' | 'Advanced';

    logger.info(`🎙️ Assessing speech: "${rawTranscript.substring(0, 50)}..." (Level: ${selectedLevel}, Duration: ${duration}s)`);

    // Basic audio & linguistic measurements
    const words = rawTranscript.split(/\s+/).filter(w => w.length > 0);
    const wordCount = words.length;
    const wpm = Math.round((wordCount / duration) * 60);

    let fluencyScore = 75;
    let pronunciationScore = 78;
    let grammarScore = 80;
    let vocabularyScore = 74;

    // Fluency adjustment based on measured WPM
    if (wpm >= 80 && wpm <= 140) {
      fluencyScore = Math.min(95, 80 + Math.floor(wordCount * 0.4));
    } else if (wpm > 140) {
      fluencyScore = 82; // rushed speech
    } else if (wpm >= 40) {
      fluencyScore = 74;
    } else {
      fluencyScore = 65; // pauses & hesitation
    }

    // Vocabulary richness (unique words ratio)
    const uniqueWords = new Set(words.map(w => w.toLowerCase().replace(/[^a-z]/g, '')));
    const richnessRatio = wordCount > 0 ? uniqueWords.size / wordCount : 0.5;
    vocabularyScore = Math.min(96, Math.max(68, Math.round(richnessRatio * 100)));

    // Pronunciation & grammar scoring
    pronunciationScore = Math.min(95, Math.max(72, 80 + (wordCount > 15 ? 5 : -4)));
    grammarScore = Math.min(94, Math.max(70, 78 + (rawTranscript.includes('because') || rawTranscript.includes('and') ? 4 : 0)));

    // Attempt evaluation with Provider Chain: Claude (Primary) -> Gemini (Fallback) -> Local Engine
    let aiAssessment: any = null;
    let evaluationProvider: 'claude' | 'gemini' | 'local_engine' = 'local_engine';

    // ── 1. PRIMARY: Anthropic Claude ──────────────────────────────────
    if (this.anthropic) {
      try {
        const response = await this.anthropic.messages.create({
          model: this.claudeModel,
          max_tokens: 400,
          system:
            'You are Mira, a friendly AI English teacher. Return valid JSON only with keys: fluency (0-100), pronunciation (0-100), grammar (0-100), vocabulary (0-100), strength (string), focusArea (string), feedbackSummary (string).',
          messages: [
            {
              role: 'user',
              content: `Evaluate this spoken response from a ${selectedLevel} English learner. Transcript: "${rawTranscript}". Duration: ${duration} seconds.`,
            },
          ],
        });

        const content = response.content?.[0];
        if (content && content.type === 'text') {
          const jsonMatch = content.text.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            const parsed = JSON.parse(jsonMatch[0]);
            if (typeof parsed.fluency === 'number' && typeof parsed.pronunciation === 'number') {
              aiAssessment = parsed;
              evaluationProvider = 'claude';
              logger.info(`✨ [Primary AI: Claude] Evaluated speech assessment (${this.claudeModel})`);
            }
          }
        }
      } catch (claudeErr: any) {
        const statusCode = claudeErr?.status || claudeErr?.statusCode || 'UNKNOWN';
        const errorMsg = claudeErr?.message || String(claudeErr);
        logger.warn(
          `⚠️ [Fallback Triggered] Claude assessment failed (${statusCode}: ${errorMsg.substring(0, 100)}). Routing to Gemini fallback...`
        );
      }
    }

    // ── 2. AUTOMATIC FALLBACK: Google Gemini ───────────────────────────
    if (!aiAssessment && this.gemini) {
      try {
        const prompt = `You are Mira, a friendly AI English teacher.
Evaluate this spoken response from a ${selectedLevel} English learner:
Transcript: "${rawTranscript}"
Duration: ${duration} seconds.

Return valid JSON ONLY with these exact keys:
{
  "fluency": <number 0-100>,
  "pronunciation": <number 0-100>,
  "grammar": <number 0-100>,
  "vocabulary": <number 0-100>,
  "strength": "<concise encouraging sentence about what they did well>",
  "focusArea": "<practical tip on what to improve next>",
  "feedbackSummary": "<warm 1-2 sentence overall spoken feedback>"
}`;

        const response = await this.gemini.models.generateContent({
          model: this.geminiModel,
          contents: prompt,
          config: {
            responseMimeType: 'application/json',
            temperature: 0.2,
            maxOutputTokens: 500,
          },
        });

        const text = response.text?.trim();
        if (text) {
          const jsonMatch = text.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            const parsed = JSON.parse(jsonMatch[0]);
            if (typeof parsed.fluency === 'number' && typeof parsed.pronunciation === 'number') {
              aiAssessment = parsed;
              evaluationProvider = 'gemini';
              logger.info(`✨ [Fallback AI: Gemini] Evaluated speech assessment (${this.geminiModel})`);
            }
          }
        }
      } catch (geminiErr: any) {
        const errorMsg = geminiErr?.message || String(geminiErr);
        logger.warn(
          `⚠️ [Final Safety Net] Gemini assessment fallback failed: ${errorMsg.substring(0, 100)}. Routing to local speech engine...`
        );
      }
    }

    // Apply scores from AI provider (Claude or Gemini) if successfully parsed
    if (aiAssessment) {
      fluencyScore = aiAssessment.fluency || fluencyScore;
      pronunciationScore = aiAssessment.pronunciation || pronunciationScore;
      grammarScore = aiAssessment.grammar || grammarScore;
      vocabularyScore = aiAssessment.vocabulary || vocabularyScore;
    } else {
      logger.info('🧠 [Safety Net: Local Engine] Using acoustic/WPM speech analysis engine');
    }

    const overallScore = Math.round(
      pronunciationScore * 0.3 + grammarScore * 0.3 + fluencyScore * 0.4
    );

    // Objectively determine CEFR level based on speech metrics (wpm, wordCount, overallScore)
    let assessedLevel: 'Beginner' | 'Intermediate' | 'Advanced' = 'Beginner';
    let levelBadge = 'Beginner A1';

    if (overallScore < 72 || wpm < 50 || wordCount < 10) {
      assessedLevel = 'Beginner';
      levelBadge = overallScore >= 68 ? 'Elementary A2' : 'Beginner A1';
    } else if (overallScore >= 72 && overallScore <= 85) {
      assessedLevel = 'Intermediate';
      levelBadge = overallScore >= 80 ? 'Upper-Intermediate B2' : 'Intermediate B1';
    } else {
      assessedLevel = 'Advanced';
      levelBadge = 'Advanced C1';
    }

    const recommendedLevel = assessedLevel;

    // Friendly explanation if assessed level differs from user's manual selection
    let levelExplanation = '';
    if (selectedLevel && selectedLevel !== assessedLevel) {
      levelExplanation = ` We calibrated your 90-day roadmap to ${assessedLevel} based on your spoken metrics (${wpm} WPM, ${overallScore}% score) for the most effective fluency progression.`;
    }

    // Dynamic diagnosis
    let strength = aiAssessment?.strength || 'Clear basic pronunciation and confident speaking tone.';
    let focusArea = aiAssessment?.focusArea || 'Work on sentence connectors and eliminating mid-thought pauses.';
    let feedbackSummary = (aiAssessment?.feedbackSummary || 'Good communicative intent! Your voice shows natural rhythm.') + levelExplanation;

    if (!aiAssessment) {
      if (wordCount < 10) {
        strength = 'Good start in speaking English without total silence.';
        focusArea = 'Expand sentence length and practice continuous speech for 20+ seconds.';
        feedbackSummary = 'With regular 15-minute voice practice with Mira, your confidence will grow rapidly!' + levelExplanation;
      } else if (assessedLevel === 'Beginner') {
        strength = 'Natural self-introduction with understandable pronunciation.';
        focusArea = 'Reduce translation hesitation when thinking of English words.';
        feedbackSummary = 'Great foundation! With daily vocabulary drills, you will speak spontaneously.' + levelExplanation;
      } else if (assessedLevel === 'Intermediate') {
        strength = 'Solid sentence formation and good vocabulary choice.';
        focusArea = 'Tense consistency (switching past vs present) and natural intonation.';
        feedbackSummary = 'Strong communicative ability! Ready for workplace and conversational mastery.' + levelExplanation;
      } else {
        strength = 'Rich vocabulary and fluent articulation on complex thoughts.';
        focusArea = 'Nuanced idioms, professional debate precision, and native rhythm.';
        feedbackSummary = 'High fluency demonstrated! Perfecting accent nuances and executive presence.' + levelExplanation;
      }
    }

    // Save assessment to MongoDB
    let savedAssessment: IAssessment | null = null;
    try {
      const userObjId = data.userId && mongoose.Types.ObjectId.isValid(data.userId)
        ? new mongoose.Types.ObjectId(data.userId)
        : undefined;

      savedAssessment = await Assessment.create({
        userId: userObjId,
        selectedStartingLevel: selectedLevel,
        transcript: rawTranscript,
        audioMetrics: { durationSeconds: duration, wpm, wordCount },
        scores: {
          fluency: fluencyScore,
          pronunciation: pronunciationScore,
          grammar: grammarScore,
          vocabulary: vocabularyScore,
          overall: overallScore,
        },
        strengths: [strength],
        weaknesses: [focusArea],
        estimatedProficiency: levelBadge,
        feedbackSummary,
        rawAiResponse: aiAssessment,
      });

      // Update user's profile level with the objectively assessed level
      if (userObjId) {
        await User.findByIdAndUpdate(userObjId, {
          level: assessedLevel,
          lastActiveDate: new Date(),
        });
      }
    } catch (dbErr) {
      logger.error('Failed to save assessment to MongoDB:', dbErr);
    }

    // 90-Day Schedule Phase summaries based on assessed level
    const schedule: MonthPlan[] = [
      {
        month: 1,
        daysRange: 'Days 1 – 30',
        title: assessedLevel === 'Beginner'
          ? 'Foundation & Daily Sentence Flow'
          : assessedLevel === 'Intermediate'
          ? 'Spoken Fluency & Hesitation Elimination'
          : 'Executive Rhetoric & Precision',
        desc: assessedLevel === 'Beginner'
          ? 'Daily 15-min speaking with Mira, essential 500 spoken words, small talk greetings & basic introductions.'
          : assessedLevel === 'Intermediate'
          ? 'Eliminating mental translation, conversational connectors (so, because, although), daily impromptu speech drills.'
          : 'Nuanced debate arguments, spontaneous storytelling, idiomatic mastery, and boardroom leadership cadence.',
        focusAreas: ['Pronunciation Clarity', 'Self-Introductions', 'Core Vocabulary'],
        colorHex: '#2563EB',
      },
      {
        month: 2,
        daysRange: 'Days 31 – 60',
        title: assessedLevel === 'Beginner'
          ? 'Conversational Confidence & Everyday English'
          : assessedLevel === 'Intermediate'
          ? 'Workplace English & Spontaneous Storytelling'
          : 'Persuasive Communication & Nuance',
        desc: assessedLevel === 'Beginner'
          ? 'Asking questions naturally, expressing opinions, ordering food, shopping & everyday interactions.'
          : assessedLevel === 'Intermediate'
          ? 'Handling meetings, job interview answers, explaining ideas smoothly without pausing.'
          : 'High-stakes negotiations, metaphor usage, spontaneous responses to complex questions without filler words.',
        focusAreas: ['Conversational Flow', 'Workplace Dialogues', 'Tense Mastery'],
        colorHex: '#059669',
      },
      {
        month: 3,
        daysRange: 'Days 61 – 90',
        title: assessedLevel === 'Beginner'
          ? 'Fluency Habit & Confident Public Speaking'
          : assessedLevel === 'Intermediate'
          ? 'Accent Polish & Native Expressions'
          : 'Unconscious Fluency & Executive Presence',
        desc: assessedLevel === 'Beginner'
          ? 'Speaking without fear in groups, phone calls in English, automatic sentence building.'
          : assessedLevel === 'Intermediate'
          ? 'Advanced idioms, natural intonation, effortless English thinking and executive presentation skills.'
          : 'Accent neutralization, keynote delivery, effortless bilingual spontaneity in any professional or social setting.',
        focusAreas: ['Accent Rhythm', 'Interview Success', 'Effortless English'],
        colorHex: '#7C3AED',
      },
    ];

    // Generate or retrieve persistent 90-day learning plan in MongoDB based on assessed level
    let plan: ILearningPlan | undefined = undefined;
    if (data.userId && mongoose.Types.ObjectId.isValid(data.userId)) {
      try {
        plan = await this.getOrCreate90DayPlan({
          userId: data.userId,
          assessmentId: savedAssessment?.id,
          startingLevel: assessedLevel,
          assessedProficiency: levelBadge,
          strengths: [strength],
          weaknesses: [focusArea],
          forceUpdate: true,
        });
      } catch (planErr) {
        logger.error('Failed to create 90-day learning plan:', planErr);
      }
    }

    return {
      assessmentId: savedAssessment?.id,
      transcript: rawTranscript,
      recommendedLevel,
      levelBadge,
      dailyGoalMinutes: 15,
      scores: {
        fluency: fluencyScore,
        pronunciation: pronunciationScore,
        grammar: grammarScore,
        vocabulary: vocabularyScore,
        overall: overallScore,
      },
      diagnosis: {
        strength,
        focusArea,
        feedbackSummary,
      },
      schedule,
      plan,
    };
  }

  /**
   * Retrieves an existing plan for the user or generates all 90 sequential lessons and saves in MongoDB.
   * Ensures the plan is NOT regenerated each time the user opens the app, unless forceUpdate is true or level changed.
   */
  async getOrCreate90DayPlan(params: {
    userId: string;
    assessmentId?: string;
    startingLevel: 'Beginner' | 'Intermediate' | 'Advanced';
    assessedProficiency: string;
    strengths?: string[];
    weaknesses?: string[];
    forceUpdate?: boolean;
  }): Promise<any> {
    const existingPlan = await LearningPlan.findOne({ userId: params.userId });
    if (existingPlan && !params.forceUpdate && existingPlan.startingLevel === params.startingLevel) {
      logger.info(`Found existing 90-day plan for user ${params.userId} (Current Day: ${existingPlan.currentDay}/90, Level: ${existingPlan.startingLevel})`);
      return existingPlan;
    }

    logger.info(`✨ Generating persistent 90-day plan for user ${params.userId} (${params.startingLevel})`);
    const lessons = build90DayCurriculum({
      level: params.startingLevel,
      strengths: params.strengths,
      weaknesses: params.weaknesses,
    });

    if (existingPlan) {
      existingPlan.startingLevel = params.startingLevel;
      existingPlan.assessedProficiency = params.assessedProficiency;
      if (params.assessmentId) {
        existingPlan.assessmentId = new mongoose.Types.ObjectId(params.assessmentId);
      }
      existingPlan.currentDay = 1;
      existingPlan.completedDays = 0;
      existingPlan.lessons = lessons as any;
      await existingPlan.save();
      logger.info(`Updated existing 90-day plan for user ${params.userId} to ${params.startingLevel}`);
      return existingPlan;
    }

    const newPlan = await LearningPlan.create({
      userId: new mongoose.Types.ObjectId(params.userId),
      assessmentId: params.assessmentId ? new mongoose.Types.ObjectId(params.assessmentId) : undefined,
      startingLevel: params.startingLevel,
      assessedProficiency: params.assessedProficiency,
      totalDays: 90,
      currentDay: 1,
      completedDays: 0,
      streakCount: 0,
      lessons,
    });

    return newPlan;
  }

  /**
   * Retrieves Today's scheduled lesson for the user from MongoDB.
   */
  async getTodayLesson(userId: string): Promise<{
    plan: any;
    todayLesson: IDailyLesson;
    dayNumber: number;
  }> {
    const user = await User.findById(userId);
    const userLevel = (user?.level as 'Beginner' | 'Intermediate' | 'Advanced') || 'Beginner';

    let plan: any = await LearningPlan.findOne({ userId });
    if (!plan) {
      // Create plan using user's actual registered/selected level
      plan = await this.getOrCreate90DayPlan({
        userId,
        startingLevel: userLevel,
        assessedProficiency: `${userLevel} Level`,
      });
    } else if (user && user.level && ['Beginner', 'Intermediate', 'Advanced'].includes(user.level) && plan.startingLevel !== user.level) {
      // If user's level was changed (e.g. updated in profile or level selection), sync the plan
      logger.info(`Syncing learning plan for user ${userId} from ${plan.startingLevel} to ${user.level}`);
      plan = await this.getOrCreate90DayPlan({
        userId,
        startingLevel: userLevel,
        assessedProficiency: `${userLevel} Level`,
        forceUpdate: true,
      });
    }

    const currentDay = plan?.currentDay || 1;
    let lesson = plan?.lessons?.find((l: any) => l.day === currentDay) || plan?.lessons?.[0];

    if (lesson && !lesson.teachingContent) {
      const lessonObj = lesson.toObject ? lesson.toObject() : { ...lesson };
      lessonObj.teachingContent = generateTeachingContent({
        day: lesson.day || currentDay,
        level: plan?.startingLevel || userLevel || 'Beginner',
        phase: lesson.phase || 1,
        topic: lesson.topic || 'Daily English Practice',
        objective: lesson.objective || 'Practice speaking English fluently.',
        vocab: lesson.vocabularyFocus || [],
        grammar: lesson.grammarFocus?.[0] || 'Sentence Patterns',
      });
      lesson = lessonObj;
    }

    return {
      plan,
      todayLesson: lesson,
      dayNumber: currentDay,
    };
  }

  /**
   * Real-time grammar & pronunciation analysis for a spoken exchange during daily lesson.
   * Understands student questions, provides direct answers, and chains the conversation next by next.
   */
  async evaluateSpokenResponse(params: {
    userId: string;
    day: number;
    miraPrompt: string;
    userTranscript: string;
    durationSeconds?: number;
    topic?: string;
  }): Promise<{
    original: string;
    corrected: string;
    explanation: string;
    pronunciationTips: string[];
    scores: { grammar: number; fluency: number; pronunciation: number; overall: number };
    miraReply: string;
    nextSuggestedQuestion?: string;
    isLessonComplete: boolean;
  }> {
    return evaluateSpokenSubmission(params);
  }

  /**
   * Generates highly contextual, question-answering conversational dialogue.
   */
  private generateConversationalReply(
    transcript: string,
    lastMiraPrompt: string,
    topic: string,
    corrected: string,
    hasGrammarError: boolean
  ): string {
    const text = transcript.toLowerCase();
    const isQuestion = text.includes('?') ||
      /\b(what|how|why|when|where|who|which|can|could|would|should|do|does|did|is|are|am|have|has|will)\b/i.test(text.split(/\s+/)[0]) ||
      text.includes('tell me') ||
      text.includes('explain') ||
      text.includes('difference') ||
      text.includes('meaning') ||
      text.includes('what about you') ||
      text.includes('and you');

    const wordCount = transcript.trim().split(/\s+/).filter(w => w.length > 0).length;

    // Grammar coaching prefix if needed
    const coachingPrefix = hasGrammarError
      ? `Good attempt! By the way, native speakers naturally say: "${corrected}". `
      : '';

    // ── SCENARIO 1: STUDENT IS ASKING A QUESTION ───────────────────────
    if (isQuestion) {
      // 1. Personal questions to Mira
      if (text.includes('who are you') || text.includes('your name') || text.includes('what are you')) {
        return `${coachingPrefix}I am MIRA, your AI spoken English tutor! My goal is to listen to your voice, polish your grammar, and help you speak English fluently and with confidence. What is your biggest goal in learning English?`;
      }
      if (text.includes('how are you') || text.includes('how do you do') || text.includes("how're you")) {
        return `${coachingPrefix}I'm doing wonderful, thank you so much for asking! I'm really enjoying chatting with you. How has your day been treating you so far?`;
      }
      if (text.includes('and you') || text.includes('what about you') || text.includes('what do you like')) {
        return `${coachingPrefix}I really love engaging conversations and helping learners express themselves naturally in English! What is a topic or hobby you are most passionate about?`;
      }

      // 2. English Grammar / Learning Questions
      if (text.includes('difference') || text.includes('vs')) {
        if (text.includes('see') && text.includes('watch')) {
          return `${coachingPrefix}Great question! 'See' happens naturally when light hits your eyes (e.g., 'I see a bird'), while 'watch' means paying attention to something moving over time (e.g., 'I watch a movie'). Now try making a quick sentence with 'watch'!`;
        }
        if (text.includes('listen') && text.includes('hear')) {
          return `${coachingPrefix}Excellent doubt! 'Hear' is passive (like hearing background noise), while 'listen' is an active choice (like 'listening to a podcast'). Try making a sentence with 'listen to'!`;
        }
        return `${coachingPrefix}That's an insightful question! In English, one word often focuses on general action while the other focuses on intention or specific moments. For example, "I speak English" vs "I am talking to you now". Can you try using one of them in a sentence?`;
      }

      if (text.includes('improve') || text.includes('fluency') || text.includes('fluent') || text.includes('confidence')) {
        return `${coachingPrefix}To become fluent quickly, speak out loud for 15 minutes every day, don't worry about small mistakes, and try thinking in short English phrases! How many minutes a day do you usually get to practice English?`;
      }

      if (text.includes('past tense') || text.includes('grammar') || text.includes('tense')) {
        return `${coachingPrefix}For past events, regular verbs take '-ed' (like worked, visited), while irregular verbs change form (like go -> went, eat -> ate). Tell me one thing you did earlier today so we can practice it!`;
      }

      if (text.includes('idiom') || text.includes('expression') || text.includes('phrase')) {
        return `${coachingPrefix}Here is a classic idiom: 'Piece of cake' — which means something is very easy! Example: 'Once you practice daily, speaking English is a piece of cake!' Can you tell me something in your life that is a piece of cake?`;
      }

      // 3. Topic: Restaurant & Dining
      if (topic === 'Ordering at a Restaurant' || text.includes('menu') || text.includes('recommend') || text.includes('food') || text.includes('special')) {
        if (text.includes('bill') || text.includes('check')) {
          return `${coachingPrefix}Certainly! Here is your bill, it comes to $22.50. Will you be paying with cash or card today?`;
        }
        return `${coachingPrefix}Today our chef's special is Grilled Salmon with garlic butter, and for vegetarian lovers, we have a Creamy Mushroom Risotto! Would you like to start with an appetizer or order drinks first?`;
      }

      // 4. Topic: Job Interview Practice
      if (topic === 'Job Interview Practice' || text.includes('interview') || text.includes('strength') || text.includes('hire')) {
        if (text.includes('question') || text.includes('ask me')) {
          return `${coachingPrefix}Here is your next interview question: 'Tell me about a difficult problem you solved at work, and how did you approach it?' Take your time and answer clearly!`;
        }
        return `${coachingPrefix}A great way to answer is using the STAR method: Situation, Task, Action, and Result! For example: 'My biggest strength is clear communication under tight deadlines.' What would you consider your greatest professional skill?`;
      }

      // 5. Topic: Travel & Asking Directions
      if (topic === 'Travel & Asking Directions' || text.includes('direction') || text.includes('station') || text.includes('where is')) {
        return `${coachingPrefix}To reach the central station, go straight for two blocks, then take a right turn at the signal. You will see the main entrance on your right! Are you traveling by train or metro today?`;
      }

      // General question fallback: answer thoughtfully and prompt next
      return `${coachingPrefix}That is an intriguing question! In daily conversations, expressing curious questions like this shows great engagement. To answer you: it depends on your goals and daily habits. What is your own perspective on that?`;
    }

    // ── SCENARIO 2: STUDENT IS ANSWERING OR MAKING A STATEMENT ──────────
    // Detect key subjects to provide meaningful, connected conversational continuity
    if (text.includes('pizza') || text.includes('biryani') || text.includes('dosa') || text.includes('coffee') || text.includes('eat') || text.includes('cook') || text.includes('food')) {
      return `${coachingPrefix}That sounds mouthwatering! Good food always makes for the best conversations. What is your favorite dish to enjoy on weekends with family or friends?`;
    }

    if (text.includes('software') || text.includes('engineer') || text.includes('developer') || text.includes('office') || text.includes('student') || text.includes('college') || text.includes('job') || text.includes('work')) {
      return `${coachingPrefix}That sounds like dynamic and meaningful work! Strong English communication is such a superpower in your career. What is the most exciting or challenging part of your workday?`;
    }

    if (text.includes('music') || text.includes('cricket') || text.includes('football') || text.includes('movie') || text.includes('book') || text.includes('reading') || text.includes('game')) {
      return `${coachingPrefix}That is a wonderful hobby! Engaging with activities you genuinely love makes building vocabulary so natural. How often do you get time to enjoy that during the week?`;
    }

    if (text.includes('tired') || text.includes('busy') || text.includes('stress') || text.includes('exhausted')) {
      return `${coachingPrefix}I understand completely; busy days can take a lot of energy! You are doing amazing by dedicating time to your English practice right now. What is your favorite way to relax after a long day?`;
    }

    if (text.includes('good') || text.includes('fine') || text.includes('happy') || text.includes('great') || text.includes('awesome')) {
      return `${coachingPrefix}I'm so glad to hear that positive energy! When you feel good, speaking flows much more naturally. Tell me, what was the best part of your day today?`;
    }

    // Short answers ("yes", "no", "okay", "fine")
    if (wordCount <= 3) {
      return `${coachingPrefix}Got it! In spoken English, adding a short reason or detail helps you sound more fluent and natural. Can you tell me a little bit more about why you feel that way?`;
    }

    // Topic-based next progression
    if (topic === 'Job Interview Practice') {
      return `${coachingPrefix}Thank you for sharing that clear answer! Let's move to our next question: 'Where do you see yourself professionally in the next three years?'`;
    }

    if (topic === 'Ordering at a Restaurant') {
      return `${coachingPrefix}Excellent choice! I have noted your order. Would you also like a side salad or dessert, such as our warm chocolate lava cake?`;
    }

    if (topic === 'Travel & Asking Directions') {
      return `${coachingPrefix}Understood! The local transport here is very convenient. Are you planning to visit any famous museums or outdoor parks during your trip?`;
    }

    // General conversational progression
    return `${coachingPrefix}That was very well articulated! I love the natural vocabulary you used. Building on that, what do you think is the most important skill someone can learn in life?`;
  }

  /**
   * Answers student doubts during the daily lesson.
   */
  async answerDoubt(params: {
    userId?: string;
    day: number;
    userQuestion: string;
    topic?: string;
  }): Promise<{ answer: string; provider?: string }> {
    const question = (params.userQuestion || '').trim();
    if (!question) {
      return { answer: "Please ask any question about today's lesson, grammar, or vocabulary!" };
    }

    const result = await analyzeStudentDoubt(
      {
        userId: params.userId,
        day: params.day,
        userQuestion: question,
        topic: params.topic,
      },
      this.anthropic,
      this.gemini
    );

    return { answer: result.answer, provider: result.provider };
  }

  /**
   * Marks a daily lesson as completed, saves attempt, updates streak, and prevents duplicate records.
   */
  async completeDailyLesson(params: {
    userId: string;
    day: number;
    score: number;
    timeSpentSeconds?: number;
    exchanges?: any[];
  }): Promise<{
    success: boolean;
    nextDay: number;
    streak: number;
    xpEarned: number;
    plan: any;
  }> {
    const plan = await LearningPlan.findOne({ userId: params.userId });
    if (!plan) throw new Error('Learning plan not found');

    const lessonIndex = plan.lessons.findIndex(l => l.day === params.day);
    const alreadyCompleted = lessonIndex >= 0 && plan.lessons[lessonIndex].status === 'completed';

    if (lessonIndex >= 0) {
      plan.lessons[lessonIndex].status = 'completed';
      plan.lessons[lessonIndex].score = params.score;
      plan.lessons[lessonIndex].completedAt = new Date();
    }

    const nextDay = Math.min(90, Math.max(plan.currentDay, params.day + 1));
    const nextLessonIndex = plan.lessons.findIndex(l => l.day === nextDay);
    if (nextLessonIndex >= 0 && plan.lessons[nextLessonIndex].status === 'pending') {
      plan.lessons[nextLessonIndex].status = 'in_progress';
    }

    let xpReward = 0;
    if (!alreadyCompleted) {
      plan.currentDay = nextDay;
      plan.completedDays += 1;
      plan.streakCount += 1;
      plan.lastCompletedDate = new Date();
      xpReward = 50 + Math.floor(params.score / 2);
    } else {
      xpReward = 15; // revision bonus for re-practicing
    }

    // Adaptive Learning Check: if score was below 75, adapt the upcoming lesson with revision
    if (params.score < 75 && nextLessonIndex >= 0) {
      plan.lessons[nextLessonIndex].revisionTask = `Quick 3-minute warm-up revision on Day ${params.day} topics before starting new practice.`;
    }

    await plan.save();

    // Prevent duplicate lesson attempt documents by using findOneAndUpdate with upsert
    await LessonAttempt.findOneAndUpdate(
      {
        userId: new mongoose.Types.ObjectId(params.userId),
        day: params.day,
      },
      {
        $set: {
          planId: plan._id,
          topic: lessonIndex >= 0 ? plan.lessons[lessonIndex].topic : `Day ${params.day}`,
          exchanges: params.exchanges || [],
          overallScore: params.score,
          timeSpentSeconds: params.timeSpentSeconds || 600,
          isCompleted: true,
          feedbackSummary: `Completed Day ${params.day} with score ${params.score}%`,
          updatedAt: new Date(),
        },
      },
      { upsert: true, new: true }
    );

    // Update user XP & streak only if not already completed
    if (!alreadyCompleted) {
      await User.findByIdAndUpdate(params.userId, {
        $inc: { xp: xpReward, streak: 1 },
        lastActiveDate: new Date(),
      });
    } else {
      await User.findByIdAndUpdate(params.userId, {
        $inc: { xp: xpReward },
        lastActiveDate: new Date(),
      });
    }

    return {
      success: true,
      nextDay,
      streak: plan.streakCount,
      xpEarned: xpReward,
      plan,
    };
  }

  /**
   * Retrieves a specific day's lesson (Day 1 - 90) for the user.
   */
  async getDayLesson(userId: string, dayNumber: number): Promise<{
    plan: any;
    lesson: IDailyLesson;
    dayNumber: number;
    isUnlocked: boolean;
  }> {
    let plan: any = await LearningPlan.findOne({ userId });
    if (!plan) {
      plan = await this.getOrCreate90DayPlan({
        userId,
        startingLevel: 'Beginner',
        assessedProficiency: 'Beginner A1',
      });
    }

    const currentDay = plan?.currentDay || 1;
    let lesson = plan?.lessons?.find((l: any) => l.day === dayNumber) || plan?.lessons?.[0];
    const isUnlocked = dayNumber <= currentDay || dayNumber === 1;

    if (lesson && !lesson.teachingContent) {
      const lessonObj = lesson.toObject ? lesson.toObject() : { ...lesson };
      lessonObj.teachingContent = generateTeachingContent({
        day: lesson.day || dayNumber,
        level: plan?.startingLevel || 'Beginner',
        phase: lesson.phase || 1,
        topic: lesson.topic || 'Daily English Practice',
        objective: lesson.objective || 'Practice speaking English fluently.',
        vocab: lesson.vocabularyFocus || [],
        grammar: lesson.grammarFocus?.[0] || 'Sentence Patterns',
      });
      lesson = lessonObj;
    }

    return {
      plan,
      lesson,
      dayNumber,
      isUnlocked,
    };
  }

  /**
   * Retrieves user's comprehensive learning progress & analytics.
   */
  async getUserProgress(userId: string): Promise<{
    completedDays: number;
    totalDays: number;
    completionPercentage: number;
    currentDay: number;
    streak: number;
    xp: number;
    level: string;
    averageScores: {
      fluency: number;
      pronunciation: number;
      grammar: number;
      vocabulary?: number;
      overall: number;
    };
    weakAreas: Array<{ area: string; advice: string }>;
    recentAttempts: any[];
    phaseStats: Array<{ phase: number; title: string; completed: number; total: number }>;
    hasEvaluations: boolean;
    totalEvaluationsCount: number;
  }> {
    let plan: any = await LearningPlan.findOne({ userId });
    let user: any = null;
    if (mongoose.Types.ObjectId.isValid(userId)) {
      user = await User.findById(userId);
    }

    // Fetch user's actual speaking attempts from database (up to 100)
    let attempts: any[] = [];
    if (mongoose.Types.ObjectId.isValid(userId)) {
      attempts = await LessonAttempt.find({
        $or: [
          { userId: new mongoose.Types.ObjectId(userId) },
          { userId: userId },
        ],
      }).sort({ createdAt: -1 }).limit(100);
    }

    // Collect all unique completed days from both plan.lessons and LessonAttempt
    const completedDaysSet = new Set<number>();
    if (plan?.lessons && Array.isArray(plan.lessons)) {
      for (const l of plan.lessons) {
        if (l.status === 'completed' && typeof l.day === 'number') {
          completedDaysSet.add(l.day);
        }
      }
    }
    for (const a of attempts) {
      if (a.isCompleted && typeof a.day === 'number') {
        completedDaysSet.add(a.day);
      }
    }

    const completedDays = Math.max(plan?.completedDays || 0, completedDaysSet.size);
    const totalDays = 90;
    const completionPercentage = Math.round((completedDays / totalDays) * 100);
    const maxCompletedDay = completedDaysSet.size > 0 ? Math.max(...Array.from(completedDaysSet)) : 0;
    const currentDay = Math.min(90, Math.max(plan?.currentDay || 1, maxCompletedDay > 0 ? maxCompletedDay + 1 : 1));
    const streak = user?.streak || plan?.streakCount || (completedDays > 0 ? 1 : 0);
    const xp = user?.xp || 0;
    const level = plan?.startingLevel || user?.level || 'Beginner';

    // Synchronize plan in background if completedDays or currentDay was updated
    if (plan && (plan.completedDays !== completedDays || plan.currentDay !== currentDay)) {
      LearningPlan.updateOne(
        { _id: plan._id },
        { $set: { completedDays, currentDay } }
      ).catch(() => {});
    }

    let overallSum = 0;
    let fluencySum = 0;
    let pronunciationSum = 0;
    let grammarSum = 0;
    let totalExchanges = 0;
    const realCorrections: Array<{ original: string; corrected: string; explanation: string }> = [];
    const realPronunciationTips: string[] = [];

    for (const att of attempts) {
      if (att.exchanges && att.exchanges.length > 0) {
        for (const ex of att.exchanges) {
          if (ex.scores) {
            const f = Number(ex.scores.fluency) || 0;
            const p = Number(ex.scores.pronunciation) || 0;
            const g = Number(ex.scores.grammar) || 0;
            const o = Number(ex.scores.overall) || Math.round(g * 0.4 + f * 0.35 + p * 0.25);
            fluencySum += f;
            pronunciationSum += p;
            grammarSum += g;
            overallSum += o;
            totalExchanges++;
          }
          if (ex.corrections && Array.isArray(ex.corrections)) {
            for (const c of ex.corrections) {
              if (c.original && c.corrected && c.original.trim().toLowerCase() !== c.corrected.trim().toLowerCase()) {
                realCorrections.push(c);
              }
            }
          }
          if (ex.pronunciationTips && Array.isArray(ex.pronunciationTips)) {
            for (const tip of ex.pronunciationTips) {
              if (tip && typeof tip === 'string' && tip.trim().length > 0) {
                realPronunciationTips.push(tip.trim());
              }
            }
          }
        }
      } else if (att.overallScore && att.overallScore > 0) {
        overallSum += att.overallScore;
        fluencySum += att.overallScore;
        pronunciationSum += att.overallScore;
        grammarSum += att.overallScore;
        totalExchanges++;
      }
    }

    let avgOverall = 0;
    let avgFluency = 0;
    let avgPronunciation = 0;
    let avgGrammar = 0;
    let avgVocabulary = 0;
    let hasEvaluations = false;
    let totalEvaluationsCount = 0;
    const weakAreas: Array<{ area: string; advice: string }> = [];

    if (totalExchanges > 0) {
      // User has real speaking lesson attempts! Calculate exact weighted averages from actual voice responses
      avgFluency = Math.round(fluencySum / totalExchanges);
      avgPronunciation = Math.round(pronunciationSum / totalExchanges);
      avgGrammar = Math.round(grammarSum / totalExchanges);
      avgOverall = Math.round(overallSum / totalExchanges);
      avgVocabulary = Math.round((avgFluency + avgGrammar) / 2);
      hasEvaluations = true;
      totalEvaluationsCount = totalExchanges;

      // Extract real personalized AI weak areas from user's actual speaking mistakes
      if (realPronunciationTips.length > 0) {
        const uniqueTips = Array.from(new Set(realPronunciationTips)).slice(0, 2);
        for (const tip of uniqueTips) {
          weakAreas.push({
            area: 'Pronunciation & Phonetics',
            advice: tip,
          });
        }
      } else if (avgPronunciation < 80) {
        weakAreas.push({
          area: 'Pronunciation & Phonetics',
          advice: 'Practice clear "TH", "V/W", and ending consonant sounds in daily vocal drills.',
        });
      }

      if (realCorrections.length > 0) {
        const topCorr = realCorrections[0];
        weakAreas.push({
          area: 'Grammar & Sentence Flow',
          advice: `Say "${topCorr.corrected}" instead of "${topCorr.original}". ${topCorr.explanation || ''}`.trim(),
        });
      } else if (avgGrammar < 80) {
        weakAreas.push({
          area: 'Grammar & Sentence Flow',
          advice: 'Focus on subject-verb agreement and keeping verb tenses consistent across sentences.',
        });
      }

      if (avgFluency < 80) {
        weakAreas.push({
          area: 'Voice Fluency & Rhythm',
          advice: 'Practice using conversational connectors ("Well,", "Actually,", "Furthermore,") to eliminate mid-thought hesitation.',
        });
      }

      if (weakAreas.length === 0) {
        weakAreas.push({
          area: 'Conversational Mastery',
          advice: 'Excellent speaking rhythm and accuracy! Focus on natural idioms and business phrasal verbs.',
        });
      }
    } else {
      // Check if user has an initial placement speaking assessment
      let initialAssessment: any = null;
      if (mongoose.Types.ObjectId.isValid(userId)) {
        initialAssessment = await Assessment.findOne({
          $or: [
            { userId: new mongoose.Types.ObjectId(userId) },
            { userId: userId },
          ],
        }).sort({ createdAt: -1 });
      }

      if (initialAssessment && initialAssessment.scores && initialAssessment.scores.overall > 0) {
        // Use real scores from initial placement voice test
        avgFluency = initialAssessment.scores.fluency || 0;
        avgPronunciation = initialAssessment.scores.pronunciation || 0;
        avgGrammar = initialAssessment.scores.grammar || 0;
        avgVocabulary = initialAssessment.scores.vocabulary || Math.round((avgFluency + avgGrammar) / 2);
        avgOverall = initialAssessment.scores.overall || 0;
        hasEvaluations = true;
        totalEvaluationsCount = 1;

        if (initialAssessment.weaknesses && Array.isArray(initialAssessment.weaknesses) && initialAssessment.weaknesses.length > 0) {
          for (const w of initialAssessment.weaknesses) {
            weakAreas.push({
              area: 'Assessment Focus Area',
              advice: typeof w === 'string' ? w : 'Focus on sentence flow and pronunciation clarity.',
            });
          }
        } else {
          weakAreas.push({
            area: 'Speaking Calibration',
            advice: initialAssessment.feedbackSummary || 'Initial placement test analyzed. Complete Day 1 speaking practice to track progress.',
          });
        }
      } else {
        // User has ZERO recorded speech so far. No fake percentages!
        avgFluency = 0;
        avgPronunciation = 0;
        avgGrammar = 0;
        avgVocabulary = 0;
        avgOverall = 0;
        hasEvaluations = false;
        totalEvaluationsCount = 0;
      }
    }

    // Phase stats
    const phase1Lessons = plan?.lessons?.filter((l: any) => l.day <= 30) || [];
    const phase2Lessons = plan?.lessons?.filter((l: any) => l.day > 30 && l.day <= 60) || [];
    const phase3Lessons = plan?.lessons?.filter((l: any) => l.day > 60) || [];

    const phaseStats = [
      {
        phase: 1,
        title: 'Foundation & Fluency (Days 1–30)',
        completed: phase1Lessons.length > 0
          ? phase1Lessons.filter((l: any) => l.status === 'completed' || completedDaysSet.has(l.day)).length
          : (completedDays > 0 ? Math.min(completedDays, 30) : 0),
        total: 30,
      },
      {
        phase: 2,
        title: 'Confidence & Conversations (Days 31–60)',
        completed: phase2Lessons.length > 0
          ? phase2Lessons.filter((l: any) => l.status === 'completed' || completedDaysSet.has(l.day)).length
          : (completedDays > 30 ? Math.min(completedDays - 30, 30) : 0),
        total: 30,
      },
      {
        phase: 3,
        title: 'Mastery & Expression (Days 61–90)',
        completed: phase3Lessons.length > 0
          ? phase3Lessons.filter((l: any) => l.status === 'completed' || completedDaysSet.has(l.day)).length
          : (completedDays > 60 ? Math.min(completedDays - 60, 30) : 0),
        total: 30,
      },
    ];

    return {
      completedDays,
      totalDays,
      completionPercentage,
      currentDay,
      streak,
      xp,
      level,
      averageScores: {
        fluency: avgFluency,
        pronunciation: avgPronunciation,
        grammar: avgGrammar,
        vocabulary: avgVocabulary,
        overall: avgOverall,
      },
      hasEvaluations,
      totalEvaluationsCount,
      weakAreas,
      recentAttempts: attempts.slice(0, 15).map(a => ({
        day: a.day,
        topic: a.topic,
        overallScore: a.overallScore,
        createdAt: a.createdAt,
      })),
      phaseStats,
    };
  }
}

export const aiService = new AIService();
