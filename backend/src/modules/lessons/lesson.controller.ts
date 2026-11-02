import { Response, NextFunction } from 'express';
import { AuthRequest, AppError } from '../../types';
import { aiService } from '../ai/ai.service';
import { User } from '../users/user.model';
import { LearningPlan } from '../curriculum/plan.model';
import { CurriculumTemplate } from '../curriculum/curriculum_template.model';
import { build90DayCurriculum } from '../curriculum/curriculum_generator';
import { generateTeachingContent } from '../curriculum/teaching_content_generator';
import { LessonAttempt } from './lesson_attempt.model';
import mongoose from 'mongoose';

function enforceUserId(req: AuthRequest): string {
  if (!req.user?.id) {
    throw new AppError('Authentication required to access lesson resources', 401);
  }
  const specifiedId = req.query.userId || req.body?.userId;
  if (specifiedId && specifiedId !== req.user.id && req.user.role !== 'admin') {
    throw new AppError('Access denied: You can only access your own resources', 403);
  }
  return req.user.id;
}

export interface VocabularyCardItem {
  word: string;
  phonetic: string;
  partOfSpeech: string;
  meaning: string;
  tamilMeaning: string;
  exampleSentence: string;
  dailyTip: string;
}

// Level-tailored vocabulary database
const LEVEL_VOCABULARY: Record<string, VocabularyCardItem[]> = {
  Beginner: [
    {
      word: 'Articulate',
      phonetic: '/ɑːrˈtɪk.jə.lət/',
      partOfSpeech: 'Adjective • Clear Speech',
      meaning: 'Able to express thoughts and ideas clearly and fluently.',
      tamilMeaning: 'தெளிவாக பேசக்கூடிய',
      exampleSentence: 'She gave an articulate and confident answer in the interview.',
      dailyTip: 'Use when someone explains ideas simply and with clarity.',
    },
    {
      word: 'Hesitate',
      phonetic: '/ˈhez.ɪ.teɪt/',
      partOfSpeech: 'Verb • Fluency Booster',
      meaning: 'To pause or delay before speaking due to uncertainty.',
      tamilMeaning: 'தயங்குதல் / இடைநிறுத்தம்',
      exampleSentence: "Don't hesitate to speak English; making mistakes helps you learn!",
      dailyTip: 'Say "I won\'t hesitate" instead of saying "I am shy to speak".',
    },
    {
      word: 'Spontaneous',
      phonetic: '/spɒnˈteɪ.ni.əs/',
      partOfSpeech: 'Adjective • Natural Speech',
      meaning: 'Speaking naturally and easily without memorized scripts.',
      tamilMeaning: 'இயல்பான பேச்சு',
      exampleSentence: 'With daily speaking practice, your answers become spontaneous.',
      dailyTip: 'The goal of conversational English is spontaneous flow.',
    },
    {
      word: 'Wrap up',
      phonetic: '/ræp ʌp/',
      partOfSpeech: 'Phrasal Verb • Workplace',
      meaning: 'To bring a discussion, meeting, or activity to a finish.',
      tamilMeaning: 'நிறைவு செய்தல் / முடித்தல்',
      exampleSentence: "Let's wrap up our discussion and summarize the key action points.",
      dailyTip: 'Commonly used in corporate and client calls instead of "finish".',
    },
    {
      word: 'Get the hang of',
      phonetic: '/ɡet ðə hæŋ ʌv/',
      partOfSpeech: 'Idiom • Daily English',
      meaning: 'To master or understand how to speak something with practice.',
      tamilMeaning: 'பழகிக்கொள்ளுதல்',
      exampleSentence: "Don't worry! You will get the hang of English conversation quickly.",
      dailyTip: 'Say "I am getting the hang of it" when your fluency improves.',
    },
  ],
  Intermediate: [
    {
      word: 'Eloquent',
      phonetic: '/ˈel.ə.kwənt/',
      partOfSpeech: 'Adjective • Advanced',
      meaning: 'Expressing ideas in an elegant, fluent, and persuasive way.',
      tamilMeaning: 'நேர்த்தியான ஈர்க்கும் பேச்சு',
      exampleSentence: 'His eloquent presentation impressed everyone in the conference.',
      dailyTip: 'Top-tier word used to praise impressive communication.',
    },
    {
      word: 'Persuasive',
      phonetic: '/pərˈsweɪ.sɪv/',
      partOfSpeech: 'Adjective • Communication',
      meaning: 'Good at convincing others to agree with your viewpoint.',
      tamilMeaning: 'நம்ப வைக்கும் பேச்சுத்திறன்',
      exampleSentence: 'She made a persuasive argument during the team discussion.',
      dailyTip: 'Essential word for negotiation, presentations, and sales.',
    },
    {
      word: 'Cut to the chase',
      phonetic: '/kʌt tu ðə tʃeɪs/',
      partOfSpeech: 'Idiom • Direct Speaking',
      meaning: 'To get straight to the main point without wasting time.',
      tamilMeaning: 'நேரடியாக விஷயத்திற்கு வருதல்',
      exampleSentence: 'We have limited time, so let us cut to the chase.',
      dailyTip: 'Common workplace idiom used when time is short.',
    },
    {
      word: 'Elaborate',
      phonetic: '/iˈlæb.ə.reɪt/',
      partOfSpeech: 'Verb • Discussion',
      meaning: 'To explain or provide more detailed information on a topic.',
      tamilMeaning: 'விளக்கமாக கூறுதல்',
      exampleSentence: 'Could you please elaborate on your proposed project timeline?',
      dailyTip: 'Use in workplace meetings when asking for clarification.',
    },
    {
      word: 'Touch base',
      phonetic: '/tʌtʃ beɪs/',
      partOfSpeech: 'Idiom • Workplace',
      meaning: 'To briefly communicate or make contact with someone.',
      tamilMeaning: 'தொடர்பு கொள்ளுதல்',
      exampleSentence: "Let's touch base tomorrow morning regarding the client feedback.",
      dailyTip: 'Standard business English for a quick check-in.',
    },
  ],
  Advanced: [
    {
      word: 'Perspicacious',
      phonetic: '/ˌpɜː.spɪˈkeɪ.ʃəs/',
      partOfSpeech: 'Adjective • Executive',
      meaning: 'Having a keen insight and quick discernment in understanding complex issues.',
      tamilMeaning: 'கூர்மையான அறிவாற்றல் கொண்ட',
      exampleSentence: 'Her perspicacious analysis resolved the team conflict immediately.',
      dailyTip: 'Use in executive briefings to describe sharp intelligence.',
    },
    {
      word: 'Juxtaposition',
      phonetic: '/ˌdʒʌk.stə.pəˈzɪʃ.ən/',
      partOfSpeech: 'Noun • Rhetoric',
      meaning: 'Placing two contrasting ideas or elements side by side to emphasize comparison.',
      tamilMeaning: 'மாறுபட்ட விஷயங்களை ஒப்பிடுதல்',
      exampleSentence: 'The speech made brilliant use of juxtaposition between past and future.',
      dailyTip: 'Key term in professional speechwriting and leadership rhetoric.',
    },
    {
      word: 'Circumlocution',
      phonetic: '/ˌsɜː.kəm.ləˈkjuː.ʃən/',
      partOfSpeech: 'Noun • Speaking Precision',
      meaning: 'Using unnecessarily many words when a few direct words would be clearer.',
      tamilMeaning: 'சுற்றி வளைத்துப் பேசுதல்',
      exampleSentence: 'Avoid circumlocution when presenting concise executive summaries.',
      dailyTip: 'Aim for directness instead of circumlocution in board meetings.',
    },
    {
      word: 'Nuanced',
      phonetic: '/ˈnjuː.ɑːnst/',
      partOfSpeech: 'Adjective • Thought Leadership',
      meaning: 'Characterized by subtle shades of meaning or distinction.',
      tamilMeaning: 'நுட்பமான வேறுபாடுகள் கொண்ட',
      exampleSentence: 'The panel gave a nuanced perspective on cross-border leadership.',
      dailyTip: 'Highlight subtle, sophisticated arguments with this word.',
    },
  ],
};

function getPersonalizedVocabulary(
  level: string,
  todayLesson: any,
  completedDays: number
): VocabularyCardItem[] {
  const normLevel = ['Beginner', 'Intermediate', 'Advanced'].includes(level) ? level : 'Beginner';
  const baseWords = [...(LEVEL_VOCABULARY[normLevel] || LEVEL_VOCABULARY['Beginner'])];

  // If today's lesson has specific vocabulary, convert and prepend them
  if (todayLesson?.teachingContent?.vocabularyItems && Array.isArray(todayLesson.teachingContent.vocabularyItems)) {
    const lessonWords: VocabularyCardItem[] = todayLesson.teachingContent.vocabularyItems.map((vi: any) => ({
      word: vi.word || 'Vocabulary',
      phonetic: `/${(vi.word || '').toLowerCase()}/`,
      partOfSpeech: `${normLevel} • Day ${todayLesson.day || 1}`,
      meaning: vi.meaning || 'Daily speaking word',
      tamilMeaning: vi.tamilMeaning || 'அன்றாட சொல்',
      exampleSentence: vi.exampleSentence || `Practice saying "${vi.word}" in a sentence.`,
      dailyTip: `Featured in today's lesson on ${todayLesson.topic || 'English'}`,
    }));
    return [...lessonWords, ...baseWords].slice(0, 8);
  }

  // Rotate list according to completed days
  const offset = completedDays % baseWords.length;
  return [...baseWords.slice(offset), ...baseWords.slice(0, offset)];
}

export class LessonController {
  async getDashboard(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);

      const user = await User.findById(userId);
      const todayResult = await aiService.getTodayLesson(userId);
      const progress = await aiService.getUserProgress(userId);

      const plan = todayResult.plan;
      const todayLesson = todayResult.todayLesson;
      const currentDay = todayResult.dayNumber || 1;
      const completedDays = plan?.completedDays || 0;
      const currentLevel = user?.level || plan?.startingLevel || 'Beginner';

      // Phase identification
      const currentPhase = currentDay <= 30 ? 1 : currentDay <= 60 ? 2 : 3;
      const phaseTitle =
        currentPhase === 1
          ? 'Phase 1: Foundation & Daily Routines'
          : currentPhase === 2
          ? 'Phase 2: Fluency & Workplace Communication'
          : 'Phase 3: Mastery & Executive Cadence';

      // Personalized vocabulary from MongoDB / Lesson / Level
      const vocabularyOfDay = getPersonalizedVocabulary(currentLevel, todayLesson, completedDays);

      // Fetch real recent activity from MongoDB LessonAttempt
      let recentActivity: any[] = [];
      try {
        if (mongoose.Types.ObjectId.isValid(userId)) {
          const attempts = await LessonAttempt.find({
            userId: new mongoose.Types.ObjectId(userId),
          })
            .sort({ createdAt: -1 })
            .limit(5)
            .lean();

          recentActivity = attempts.map((att) => ({
            id: att._id.toString(),
            day: att.day,
            topic: att.topic,
            overallScore: att.overallScore,
            date: att.createdAt,
            timeSpentSeconds: att.timeSpentSeconds,
            isCompleted: att.isCompleted,
          }));
        }
      } catch (_) {}

      // Personalized suggestions based on actual progress
      const personalizedSuggestions: string[] = [];
      if (progress.weakAreas && progress.weakAreas.length > 0) {
        personalizedSuggestions.push(
          ...progress.weakAreas.map((w: any) =>
            typeof w === 'string' ? w : `${w.area}: ${w.advice}`
          )
        );
      } else {
        personalizedSuggestions.push(
          'Practice speaking every day for 15 minutes to establish continuous rhythm.',
          'Articulate word endings clearly and focus on natural sentence flow.',
          'Review the vocabulary cards and use each word in conversation today.'
        );
      }

      res.status(200).json({
        success: true,
        data: {
          user: {
            id: user?.id || userId,
            name: user?.name || 'Learner',
            email: user?.email || '',
            level: currentLevel,
            streak: user?.streak ?? plan?.streakCount ?? 0,
            xp: user?.xp ?? 0,
            coins: user?.xp ? Math.floor(user.xp / 10) : 0,
            avatarUrl: user?.avatarUrl || null,
            bio: user?.bio || '',
            location: user?.location || '',
          },
          currentDay,
          totalDays: plan?.totalDays || 90,
          completedDays,
          currentPhase,
          phaseTitle,
          streak: user?.streak ?? plan?.streakCount ?? 0,
          level: currentLevel,
          todayLesson,
          progress: {
            ...progress,
            completedDays,
            totalDays: 90,
            completionPercentage: Math.round((completedDays / 90) * 100),
          },
          vocabularyOfDay,
          recentActivity,
          personalizedSuggestions,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  async getTodayLesson(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);

      const result = await aiService.getTodayLesson(userId);
      res.status(200).json({
        success: true,
        data: {
          planId: result.plan.id,
          currentDay: result.dayNumber,
          totalDays: result.plan.totalDays,
          completedDays: result.plan.completedDays,
          streak: result.plan.streakCount,
          lesson: result.todayLesson,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  async evaluateResponse(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);
      const { day, miraQuestion, userTranscript, durationSeconds, topic } = req.body;

      if (!userTranscript) {
        res.status(400).json({ success: false, message: 'userTranscript is required' });
        return;
      }

      const result = await aiService.evaluateSpokenResponse({
        userId,
        day: Number(day) || 1,
        miraPrompt: miraQuestion || 'Tell me about today',
        userTranscript,
        durationSeconds: Number(durationSeconds) || 10,
        topic: topic || 'Casual Small Talk',
      });

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async askDoubt(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);
      const { day, userQuestion, topic } = req.body;

      if (!userQuestion) {
        res.status(400).json({ success: false, message: 'userQuestion is required' });
        return;
      }

      const result = await aiService.answerDoubt({
        userId,
        day: Number(day) || 1,
        userQuestion,
        topic,
      });

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async completeLesson(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);
      const { day, score, timeSpentSeconds, exchanges } = req.body;

      const result = await aiService.completeDailyLesson({
        userId,
        day: Number(day) || 1,
        score: Number(score) || 85,
        timeSpentSeconds: Number(timeSpentSeconds) || 600,
        exchanges: exchanges || [],
      });

      res.status(200).json({
        success: true,
        message: `Day ${day} successfully completed!`,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async getPlan(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);
      const requestedLevel = req.query.level as string | undefined;

      const userPlanResult = await aiService.getTodayLesson(userId);
      const activePlan = userPlanResult.plan;
      const activeLevel = activePlan?.startingLevel || 'Beginner';

      const planObj = activePlan ? (activePlan.toObject ? activePlan.toObject() : activePlan) : {};
      const lessons =
        planObj.lessons && planObj.lessons.length > 0
          ? planObj.lessons
          : build90DayCurriculum({ level: 'Beginner' });

      res.status(200).json({
        success: true,
        data: {
          ...planObj,
          startingLevel: requestedLevel || activeLevel,
          activeTrackLevel: activeLevel,
          isUserActivePlan: true,
          lessons,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  async setLevel(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);
      const { level } = req.body;
      if (!level || !['Beginner', 'Intermediate', 'Advanced'].includes(level)) {
        res.status(400).json({ success: false, message: 'Valid level (Beginner, Intermediate, Advanced) is required' });
        return;
      }

      // Update User profile level
      await User.findByIdAndUpdate(userId, { level });

      // Generate lessons for new level
      const lessons = build90DayCurriculum({ level });

      // Update or create user's 90-day learning plan in MongoDB
      const updatedPlan = await LearningPlan.findOneAndUpdate(
        { userId },
        {
          startingLevel: level,
          assessedProficiency: `${level} Track`,
          currentDay: 1,
          completedDays: 0,
          lessons,
        },
        { new: true, upsert: true }
      );

      res.status(200).json({
        success: true,
        message: `Successfully set active curriculum track to ${level}`,
        data: updatedPlan,
      });
    } catch (error) {
      next(error);
    }
  }

  async getDayLesson(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);
      const day = Number(req.params.day) || 1;
      const level = req.query.level as 'Beginner' | 'Intermediate' | 'Advanced' | undefined;

      // If level is passed and different from active plan, fetch template
      if (level && ['Beginner', 'Intermediate', 'Advanced'].includes(level)) {
        const template = await CurriculumTemplate.findOne({ level, day });
        if (template) {
          res.status(200).json({
            success: true,
            data: {
              plan: {
                startingLevel: level,
                currentDay: 1,
                totalDays: 90,
              },
              lesson: {
                day: template.day,
                phase: template.phase,
                topic: template.topic,
                objective: template.objective,
                difficulty: template.difficulty,
                targetSkills: template.targetSkills,
                vocabularyFocus: template.vocabularyFocus,
                grammarFocus: template.grammarFocus,
                speakingActivities: template.speakingActivities,
                miraQuestions: template.miraQuestions,
                expectedDurationMinutes: template.expectedDurationMinutes,
                teachingContent:
                  template.teachingContent ||
                  generateTeachingContent({
                    day: template.day,
                    level,
                    phase: template.phase,
                    topic: template.topic,
                    objective: template.objective,
                    vocab: template.vocabularyFocus,
                    grammar: template.grammarFocus?.[0] || 'Present Tense',
                  }),
                status: 'in_progress',
                score: 0,
              },
              dayNumber: day,
              isUnlocked: true,
            },
          });
          return;
        }
      }

      const result = await aiService.getDayLesson(userId, day);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async getProgress(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = enforceUserId(req);
      const progress = await aiService.getUserProgress(userId);
      res.status(200).json({
        success: true,
        data: progress,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const lessonController = new LessonController();
