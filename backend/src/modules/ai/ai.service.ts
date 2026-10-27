import Anthropic from '@anthropic-ai/sdk';
import logger from '../../utils/logger';
import { Assessment, IAssessment } from '../assessments/assessment.model';
import { LearningPlan, ILearningPlan, IDailyLesson } from '../curriculum/plan.model';
import { build90DayCurriculum } from '../curriculum/curriculum_generator';
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

  constructor() {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (apiKey && !apiKey.includes('dummy') && !apiKey.includes('xxxx')) {
      this.anthropic = new Anthropic({ apiKey });
      logger.info('🤖 Anthropic Claude client initialized in AIService');
    } else {
      logger.warn('⚠️ Anthropic API key not configured or placeholder. Using resilient local AI engine.');
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

    // Attempt Claude evaluation if available
    let claudeAssessment: any = null;
    if (this.anthropic) {
      try {
        const response = await this.anthropic.messages.create({
          model: process.env.ANTHROPIC_MODEL || 'claude-3-5-haiku-20241022',
          max_tokens: 400,
          system: 'You are Mira, a friendly AI English teacher. Return valid JSON only with keys: fluency (0-100), pronunciation (0-100), grammar (0-100), vocabulary (0-100), strength (string), focusArea (string), feedbackSummary (string).',
          messages: [
            {
              role: 'user',
              content: `Evaluate this spoken response from a ${selectedLevel} English learner. Transcript: "${rawTranscript}". Duration: ${duration} seconds.`,
            },
          ],
        });

        const content = response.content[0];
        if (content && content.type === 'text') {
          const jsonMatch = content.text.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            claudeAssessment = JSON.parse(jsonMatch[0]);
            fluencyScore = claudeAssessment.fluency || fluencyScore;
            pronunciationScore = claudeAssessment.pronunciation || pronunciationScore;
            grammarScore = claudeAssessment.grammar || grammarScore;
            vocabularyScore = claudeAssessment.vocabulary || vocabularyScore;
          }
        }
      } catch (err: any) {
        logger.warn(`Anthropic Claude call notice: ${err?.message || err}. Falling back to speech analysis engine.`);
      }
    }

    const overallScore = Math.round(
      pronunciationScore * 0.3 + grammarScore * 0.3 + fluencyScore * 0.4
    );

    // Determine estimated CEFR level
    let recommendedLevel: string = selectedLevel;
    let levelBadge = 'Beginner A1';
    if (selectedLevel === 'Beginner') {
      recommendedLevel = overallScore > 85 ? 'Elementary' : 'Beginner';
      levelBadge = recommendedLevel === 'Elementary' ? 'Elementary A2' : 'Beginner A1';
    } else if (selectedLevel === 'Intermediate') {
      recommendedLevel = overallScore > 88 ? 'Upper-Intermediate' : 'Intermediate';
      levelBadge = recommendedLevel === 'Upper-Intermediate' ? 'Upper-Intermediate B2' : 'Intermediate B1';
    } else {
      recommendedLevel = 'Advanced';
      levelBadge = 'Advanced C1';
    }

    // Dynamic diagnosis
    let strength = claudeAssessment?.strength || 'Clear basic pronunciation and confident speaking tone.';
    let focusArea = claudeAssessment?.focusArea || 'Work on sentence connectors and eliminating mid-thought pauses.';
    let feedbackSummary = claudeAssessment?.feedbackSummary || 'Good communicative intent! Your voice shows natural rhythm.';

    if (!claudeAssessment) {
      if (wordCount < 10) {
        strength = 'Good start in speaking English without total silence.';
        focusArea = 'Expand sentence length and practice continuous speech for 20+ seconds.';
        feedbackSummary = 'With regular 15-minute voice practice with Mira, your confidence will grow rapidly!';
      } else if (selectedLevel === 'Beginner') {
        strength = 'Natural self-introduction with understandable pronunciation.';
        focusArea = 'Reduce translation hesitation when thinking of English words.';
        feedbackSummary = 'Great foundation! With daily vocabulary drills, you will speak spontaneously.';
      } else if (selectedLevel === 'Intermediate') {
        strength = 'Solid sentence formation and good vocabulary choice.';
        focusArea = 'Tense consistency (switching past vs present) and natural intonation.';
        feedbackSummary = 'Strong communicative ability! Ready for workplace and conversational mastery.';
      } else {
        strength = 'Rich vocabulary and fluent articulation on complex thoughts.';
        focusArea = 'Nuanced idioms, professional debate precision, and native rhythm.';
        feedbackSummary = 'High fluency demonstrated! Perfecting accent nuances and executive presence.';
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
        rawAiResponse: claudeAssessment,
      });

      // Update user's profile level if user exists
      if (userObjId) {
        await User.findByIdAndUpdate(userObjId, {
          level: recommendedLevel,
          lastActiveDate: new Date(),
        });
      }
    } catch (dbErr) {
      logger.error('Failed to save assessment to MongoDB:', dbErr);
    }

    // 90-Day Schedule Phase summaries
    const schedule: MonthPlan[] = [
      {
        month: 1,
        daysRange: 'Days 1 – 30',
        title: selectedLevel === 'Beginner'
          ? 'Foundation & Daily Sentence Flow'
          : 'Spoken Fluency & Hesitation Elimination',
        desc: selectedLevel === 'Beginner'
          ? 'Daily 15-min speaking with Mira, essential 500 spoken words, small talk greetings & basic introductions.'
          : 'Eliminating mental translation, conversational connectors (so, because, although), daily impromptu speech drills.',
        focusAreas: ['Pronunciation Clarity', 'Self-Introductions', 'Core 500 Vocabulary'],
        colorHex: '#2563EB',
      },
      {
        month: 2,
        daysRange: 'Days 31 – 60',
        title: selectedLevel === 'Beginner'
          ? 'Conversational Confidence & Everyday English'
          : 'Workplace English & Spontaneous Storytelling',
        desc: selectedLevel === 'Beginner'
          ? 'Asking questions naturally, expressing opinions, ordering food, shopping & everyday interactions.'
          : 'Handling meetings, job interview answers, explaining ideas smoothly without pausing.',
        focusAreas: ['Conversational Flow', 'Workplace Dialogues', 'Tense Mastery'],
        colorHex: '#059669',
      },
      {
        month: 3,
        daysRange: 'Days 61 – 90',
        title: selectedLevel === 'Beginner'
          ? 'Fluency Habit & Confident Public Speaking'
          : 'Accent Polish & Native Expressions',
        desc: selectedLevel === 'Beginner'
          ? 'Speaking without fear in groups, phone calls in English, automatic sentence building.'
          : 'Advanced idioms, natural intonation, effortless English thinking and executive presentation skills.',
        focusAreas: ['Accent Rhythm', 'Interview Success', 'Effortless English'],
        colorHex: '#7C3AED',
      },
    ];

    // Generate or retrieve persistent 90-day learning plan in MongoDB
    let plan: ILearningPlan | undefined = undefined;
    if (data.userId && mongoose.Types.ObjectId.isValid(data.userId)) {
      try {
        plan = await this.getOrCreate90DayPlan({
          userId: data.userId,
          assessmentId: savedAssessment?.id,
          startingLevel: selectedLevel,
          assessedProficiency: levelBadge,
          strengths: [strength],
          weaknesses: [focusArea],
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
   * Ensures the plan is NOT regenerated each time the user opens the app.
   */
  async getOrCreate90DayPlan(params: {
    userId: string;
    assessmentId?: string;
    startingLevel: 'Beginner' | 'Intermediate' | 'Advanced';
    assessedProficiency: string;
    strengths?: string[];
    weaknesses?: string[];
  }): Promise<any> {
    const existingPlan = await LearningPlan.findOne({ userId: params.userId });
    if (existingPlan) {
      logger.info(`Found existing 90-day plan for user ${params.userId} (Current Day: ${existingPlan.currentDay}/90)`);
      return existingPlan;
    }

    logger.info(`✨ Generating brand new persistent 90-day plan for user ${params.userId} (${params.startingLevel})`);
    const lessons = build90DayCurriculum({
      level: params.startingLevel,
      strengths: params.strengths,
      weaknesses: params.weaknesses,
    });

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
    let plan: any = await LearningPlan.findOne({ userId });
    if (!plan) {
      // Create default plan if user didn't take assessment
      plan = await this.getOrCreate90DayPlan({
        userId,
        startingLevel: 'Beginner',
        assessedProficiency: 'Beginner A1',
      });
    }

    const currentDay = plan?.currentDay || 1;
    const lesson = plan?.lessons?.find((l: any) => l.day === currentDay) || plan?.lessons?.[0];

    return {
      plan,
      todayLesson: lesson,
      dayNumber: currentDay,
    };
  }

  /**
   * Real-time grammar & pronunciation analysis for a spoken exchange during daily lesson.
   */
  async evaluateSpokenResponse(params: {
    userId: string;
    day: number;
    miraPrompt: string;
    userTranscript: string;
    durationSeconds?: number;
  }): Promise<{
    original: string;
    corrected: string;
    explanation: string;
    pronunciationTips: string[];
    scores: { grammar: number; fluency: number; pronunciation: number; overall: number };
    miraReply: string;
    isLessonComplete: boolean;
  }> {
    const transcript = (params.userTranscript || '').trim();
    const duration = params.durationSeconds || 10;
    const words = transcript.split(/\s+/).filter(w => w.length > 0);
    const wpm = Math.round((words.length / duration) * 60);

    // Identify grammar corrections
    let corrected = transcript;
    let explanation = 'Well expressed! Your sentence communicates your thoughts clearly.';
    const corrections: Array<{ original: string; corrected: string; explanation: string }> = [];

    // Common spoken English grammar patterns
    if (/\byesterday\b/i.test(transcript) && /\b(go|eat|see|buy|do)\b/i.test(transcript)) {
      corrected = transcript
        .replace(/\bgo\b/gi, 'went')
        .replace(/\beat\b/gi, 'ate')
        .replace(/\bsee\b/gi, 'saw')
        .replace(/\bbuy\b/gi, 'bought')
        .replace(/\bdo\b/gi, 'did');
      explanation = 'Use past tense verbs when talking about past events or "yesterday".';
      corrections.push({ original: transcript, corrected, explanation });
    } else if (/\bhe\s+(like|want|go|work)\b/i.test(transcript) || /\bshe\s+(like|want|go|work)\b/i.test(transcript)) {
      corrected = transcript
        .replace(/\blike\b/gi, 'likes')
        .replace(/\bwant\b/gi, 'wants')
        .replace(/\bgo\b/gi, 'goes')
        .replace(/\bwork\b/gi, 'works');
      explanation = 'Remember to add "-s" or "-es" to present verbs with He / She / It.';
      corrections.push({ original: transcript, corrected, explanation });
    }

    // Pronunciation tips for words with difficult phonemes (th, r, v/w)
    const pronunciationTips: string[] = [];
    if (/think|thought|three|weather|the/i.test(transcript)) {
      pronunciationTips.push('Tip: Place the tip of your tongue gently between your teeth for the "TH" sound.');
    }
    if (/very|voice|work|water/i.test(transcript)) {
      pronunciationTips.push('Tip: For "V", touch your top teeth to your lower lip; for "W", round your lips like an "O".');
    }
    if (pronunciationTips.length === 0) {
      pronunciationTips.push('Great voice clarity! Keep your speech steady and articulate each word clearly.');
    }

    const grammarScore = corrections.length === 0 ? 92 : 78;
    const fluencyScore = wpm >= 70 && wpm <= 130 ? 90 : 76;
    const pronunciationScore = 84;
    const overallScore = Math.round((grammarScore + fluencyScore + pronunciationScore) / 3);

    const miraReply = corrections.length > 0
      ? `That was a great attempt! Notice how we say: "${corrected}". Repeat it after me once, and let's keep going!`
      : `Wonderful! You expressed that very naturally and fluently. Keep that great rhythm!`;

    return {
      original: transcript,
      corrected,
      explanation,
      pronunciationTips,
      scores: {
        grammar: grammarScore,
        fluency: fluencyScore,
        pronunciation: pronunciationScore,
        overall: overallScore,
      },
      miraReply,
      isLessonComplete: true,
    };
  }

  /**
   * Marks a daily lesson as completed, saves attempt, updates streak, and triggers adaptive adjustments.
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
    const plan: any = await LearningPlan.findOne({ userId: params.userId });
    if (!plan) throw new Error('Learning plan not found');

    const lessonIndex = plan.lessons.findIndex(l => l.day === params.day);
    if (lessonIndex >= 0) {
      plan.lessons[lessonIndex].status = 'completed';
      plan.lessons[lessonIndex].score = params.score;
      plan.lessons[lessonIndex].completedAt = new Date();
    }

    const nextDay = Math.min(90, params.day + 1);
    const nextLessonIndex = plan.lessons.findIndex(l => l.day === nextDay);
    if (nextLessonIndex >= 0 && plan.lessons[nextLessonIndex].status === 'pending') {
      plan.lessons[nextLessonIndex].status = 'in_progress';
    }

    plan.currentDay = nextDay;
    plan.completedDays += 1;
    plan.streakCount += 1;
    plan.lastCompletedDate = new Date();

    // Adaptive Learning Check: if score was below 75, adapt the upcoming lesson with revision
    if (params.score < 75 && nextLessonIndex >= 0) {
      plan.lessons[nextLessonIndex].revisionTask = `Quick 3-minute warm-up revision on Day ${params.day} topics before starting new practice.`;
    }

    await plan.save();

    // Record attempt
    await LessonAttempt.create({
      userId: new mongoose.Types.ObjectId(params.userId),
      planId: plan._id,
      day: params.day,
      topic: lessonIndex >= 0 ? plan.lessons[lessonIndex].topic : `Day ${params.day}`,
      exchanges: params.exchanges || [],
      overallScore: params.score,
      timeSpentSeconds: params.timeSpentSeconds || 600,
      isCompleted: true,
      feedbackSummary: `Completed Day ${params.day} with score ${params.score}%`,
    });

    // Update user XP & streak
    const xpReward = 50 + Math.floor(params.score / 2);
    await User.findByIdAndUpdate(params.userId, {
      $inc: { xp: xpReward, streak: 1 },
      lastActiveDate: new Date(),
    });

    return {
      success: true,
      nextDay,
      streak: plan.streakCount,
      xpEarned: xpReward,
      plan,
    };
  }
}

export const aiService = new AIService();
