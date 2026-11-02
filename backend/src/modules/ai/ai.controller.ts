import { Request, Response, NextFunction } from 'express';
import { aiService } from './ai.service';
import { aiProviderManager } from '../../services/ai/AIProviderManager';
import { LessonAttempt } from '../lessons/lesson_attempt.model';
import { Assessment } from '../assessments/assessment.model';
import { build90DayCurriculum } from '../curriculum/curriculum_generator';
import { verifyAccessToken } from '../../utils/jwt.utils';
import { AuthRequest } from '../../types';
import mongoose from 'mongoose';

function extractUserId(req: Request): string | undefined {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = verifyAccessToken(authHeader.slice(7).trim());
      return decoded.id;
    } catch {
      // ignore
    }
  }
  return (req.body && req.body.userId) || (req.query && (req.query.userId as string));
}

export class AIController {
  /**
   * Assesses user's initial speech submission and schedules 90-day plan.
   */
  async assessSpeech(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { transcript, selectedLevel, durationSeconds } = req.body;
      const userId = extractUserId(req);

      const result = await aiService.assessSpeech({
        transcript,
        selectedLevel,
        durationSeconds: Number(durationSeconds) || 15,
        userId,
      });

      res.status(200).json({
        success: true,
        message: 'Speech analyzed and 90-day plan scheduled',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Conversational AI Chat with MIRA using AIProviderManager.
   * POST /api/v1/ai/chat
   */
  async chat(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { message, context, level } = req.body;
      const response = await aiProviderManager.chat({
        message: message || '',
        context: Array.isArray(context) ? context : [],
        level: level || 'Beginner',
      });

      res.status(200).json({
        success: response.success,
        data: response.data,
        message: response.data.message,
        suggestedReplies: response.data.suggestedReplies,
        provider: response.provider,
        latencyMs: response.latencyMs,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Detailed diagnostic AI Feedback using AIProviderManager.
   * POST /api/v1/ai/feedback
   */
  async getFeedback(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { transcript, question, topic, day, durationSeconds } = req.body;

      if (!transcript || typeof transcript !== 'string') {
        res.status(400).json({ success: false, message: 'Valid transcript string is required' });
        return;
      }

      const response = await aiProviderManager.getFeedback({
        transcript,
        question,
        topic,
        day: day ? Number(day) : undefined,
        durationSeconds: durationSeconds ? Number(durationSeconds) : undefined,
      });

      res.status(200).json({
        success: response.success,
        data: response.data,
        provider: response.provider,
        latencyMs: response.latencyMs,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetches user's feedback history from MongoDB lesson attempts and speech assessments.
   * GET /api/v1/ai/feedback/history
   */
  async getFeedbackHistory(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id || extractUserId(req);
      if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
        res.status(200).json({ success: true, data: [] });
        return;
      }

      const attempts = await LessonAttempt.find({
        userId: new mongoose.Types.ObjectId(userId),
        isCompleted: true,
      })
        .sort({ createdAt: -1 })
        .limit(15)
        .lean();

      const history = attempts.map((att) => ({
        id: att._id.toString(),
        day: att.day,
        topic: att.topic,
        overallScore: att.overallScore,
        date: att.createdAt,
        summary: att.feedbackSummary,
        exchangesCount: att.exchanges?.length || 0,
        scores: att.exchanges?.[0]?.scores || {
          grammar: att.overallScore,
          fluency: att.overallScore,
          pronunciation: att.overallScore,
          overall: att.overallScore,
        },
        pronunciationTips: att.exchanges?.[0]?.pronunciationTips || [],
      }));

      res.status(200).json({
        success: true,
        data: history,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Returns a tailored 90-day curriculum preview for a specific level.
   * POST /api/v1/ai/curriculum
   */
  async getCurriculum(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const level = (req.body.level || 'Beginner') as 'Beginner' | 'Intermediate' | 'Advanced';
      const lessons = build90DayCurriculum({ level });

      res.status(200).json({
        success: true,
        data: {
          level,
          totalDays: 90,
          lessons,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Returns current AI Provider status (Claude Primary, Local Fallback, Cooldown).
   * GET /api/v1/ai/status
   */
  async getStatus(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const status = aiProviderManager.getStatus();
      res.status(200).json({
        success: true,
        data: status,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const aiController = new AIController();
