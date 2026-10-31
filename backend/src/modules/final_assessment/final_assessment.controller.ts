import { Response, NextFunction } from 'express';
import { Types as MongooseTypes } from 'mongoose';
import { AuthRequest } from '../../types';
import { verifyAccessToken } from '../../utils/jwt.utils';
import { finalAssessmentService } from './final_assessment.service';

function extractUserId(req: any): string | undefined {
  if (req.user?.id) return req.user.id;
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      return verifyAccessToken(authHeader.slice(7).trim()).id;
    } catch {
      // ignore
    }
  }
  return req.query.userId || req.body.userId;
}

const VALID_LEVELS = ['Beginner', 'Intermediate', 'Advanced'] as const;

export class FinalAssessmentController {
  async checkEligibility(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(401).json({ success: false, message: 'Unauthorized' });
        return;
      }
      const level = req.query.level as string;
      if (!level || !VALID_LEVELS.includes(level as any)) {
        res.status(400).json({ success: false, message: 'Valid level required: Beginner, Intermediate, or Advanced' });
        return;
      }
      const result = await finalAssessmentService.checkEligibility(userId, level);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  async startAssessment(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(401).json({ success: false, message: 'Unauthorized' });
        return;
      }
      const { level } = req.body;
      if (!level || !VALID_LEVELS.includes(level)) {
        res.status(400).json({ success: false, message: 'Valid level required: Beginner, Intermediate, or Advanced' });
        return;
      }
      const result = await finalAssessmentService.startAssessment(userId, level);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  async submitAssessment(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(401).json({ success: false, message: 'Unauthorized' });
        return;
      }
      const { assessmentId, answers } = req.body;
      if (!assessmentId || !answers || typeof answers !== 'object') {
        res.status(400).json({ success: false, message: 'assessmentId and answers object required' });
        return;
      }
      if (!MongooseTypes.ObjectId.isValid(assessmentId)) {
        res.status(400).json({ success: false, message: 'Invalid assessment ID' });
        return;
      }
      const result = await finalAssessmentService.submitAssessment(userId, assessmentId, answers);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  async getAttempts(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(401).json({ success: false, message: 'Unauthorized' });
        return;
      }
      const level = (req.query.level as string) || '';
      const attempts = await finalAssessmentService.getAttempts(userId, level);
      res.status(200).json({ success: true, data: attempts });
    } catch (error) {
      next(error);
    }
  }
}

export const finalAssessmentController = new FinalAssessmentController();
