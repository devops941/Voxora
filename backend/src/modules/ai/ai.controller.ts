import { Request, Response, NextFunction } from 'express';
import { aiService } from './ai.service';
import { verifyAccessToken } from '../../utils/jwt.utils';

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
}

export const aiController = new AIController();
