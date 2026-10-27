import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../types';
import { aiService } from '../ai/ai.service';
import { verifyAccessToken } from '../../utils/jwt.utils';

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
      const { day, miraQuestion, userTranscript, durationSeconds } = req.body;

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

      const result = await aiService.getTodayLesson(userId);
      res.status(200).json({
        success: true,
        data: result.plan,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const lessonController = new LessonController();
