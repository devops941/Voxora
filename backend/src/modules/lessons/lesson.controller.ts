import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../types';
import { aiService } from '../ai/ai.service';
import { verifyAccessToken } from '../../utils/jwt.utils';
import { User } from '../users/user.model';
import { LearningPlan } from '../curriculum/plan.model';
import { CurriculumTemplate } from '../curriculum/curriculum_template.model';
import { build90DayCurriculum } from '../curriculum/curriculum_generator';
import { generateTeachingContent } from '../curriculum/teaching_content_generator';

function extractUserId(req: any): string | undefined {
  if (req.user?.id) return req.user.id;
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = verifyAccessToken(authHeader.slice(7).trim());
      return decoded.id;
    } catch {
      // ignore
    }
  }
  return req.query.userId || req.body.userId;
}

export class LessonController {
  async getDashboard(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(400).json({ success: false, message: 'User ID or valid Authorization token is required' });
        return;
      }

      const user = await User.findById(userId);
      const todayResult = await aiService.getTodayLesson(userId);
      const progress = await aiService.getUserProgress(userId);

      const plan = todayResult.plan;
      const todayLesson = todayResult.todayLesson;

      res.status(200).json({
        success: true,
        data: {
          user: {
            id: user?.id || userId,
            name: user?.name || 'English Learner',
            email: user?.email || '',
            level: user?.level || plan?.startingLevel || 'Beginner',
            streak: user?.streak ?? plan?.streakCount ?? 0,
            xp: user?.xp ?? 0,
            coins: (user?.xp ? Math.floor(user.xp / 10) : 0),
            avatarUrl: user?.avatarUrl,
          },
          currentDay: todayResult.dayNumber || 1,
          totalDays: plan?.totalDays || 90,
          completedDays: plan?.completedDays || 0,
          streak: user?.streak ?? plan?.streakCount ?? 0,
          level: user?.level || plan?.startingLevel || 'Beginner',
          todayLesson: todayLesson,
          progress: progress,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  async getTodayLesson(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(400).json({ success: false, message: 'User ID or valid Authorization token is required' });
        return;
      }

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
      const userId = extractUserId(req) || 'anonymous';
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
      const userId = extractUserId(req) || 'anonymous';
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
      const userId = extractUserId(req);
      if (!userId) {
        res.status(400).json({ success: false, message: 'User ID or valid Authorization token is required' });
        return;
      }

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
      const userId = extractUserId(req);
      if (!userId) {
        res.status(400).json({ success: false, message: 'User ID is required' });
        return;
      }

      const requestedLevel = req.query.level as string | undefined;

      const userPlanResult = await aiService.getTodayLesson(userId);
      const activePlan = userPlanResult.plan;
      const activeLevel = activePlan?.startingLevel || 'Beginner';

      const planObj = activePlan ? (activePlan.toObject ? activePlan.toObject() : activePlan) : {};
      const lessons = planObj.lessons && planObj.lessons.length > 0
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
      const userId = extractUserId(req);
      if (!userId) {
        res.status(400).json({ success: false, message: 'User ID is required' });
        return;
      }

      const { level } = req.body;
      if (!level || !['Beginner', 'Intermediate', 'Advanced'].includes(level)) {
        res.status(400).json({ success: false, message: 'Valid level (Beginner, Intermediate, Advanced) is required' });
        return;
      }

      // Update User profile level
      await User.findByIdAndUpdate(userId, { level });

      // Generate lessons for new level
      const lessons = build90DayCurriculum({ level });

      // Update or create user's 90-day learning plan
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
      const userId = extractUserId(req);
      if (!userId) {
        res.status(400).json({ success: false, message: 'User ID is required' });
        return;
      }

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
                teachingContent: template.teachingContent || generateTeachingContent({
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
      const userId = extractUserId(req);
      if (!userId) {
        res.status(400).json({ success: false, message: 'User ID is required' });
        return;
      }

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
