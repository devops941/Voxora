import { Router } from 'express';
import { z } from 'zod';
import { aiController } from './ai.controller';
import { validate } from '../../middleware/validate.middleware';
import { optionalAuthMiddleware } from '../../middleware/auth.middleware';

const router = Router();

const assessSpeechSchema = z.object({
  transcript: z.string().min(1, 'Transcript is required'),
  selectedLevel: z.string().optional(),
  durationSeconds: z.number().optional(),
  userId: z.string().optional(),
});

// POST /api/v1/ai/assess-speech
router.post('/assess-speech', validate(assessSpeechSchema), (req, res, next) =>
  aiController.assessSpeech(req, res, next)
);

// POST /api/v1/ai/chat
router.post('/chat', (req, res, next) =>
  aiController.chat(req, res, next)
);

// POST /api/v1/ai/feedback
router.post('/feedback', (req, res, next) =>
  aiController.getFeedback(req, res, next)
);

// GET /api/v1/ai/feedback/history
router.get('/feedback/history', optionalAuthMiddleware, (req, res, next) =>
  aiController.getFeedbackHistory(req, res, next)
);

// POST /api/v1/ai/curriculum
router.post('/curriculum', (req, res, next) =>
  aiController.getCurriculum(req, res, next)
);

// GET /api/v1/ai/status
router.get('/status', (req, res, next) =>
  aiController.getStatus(req, res, next)
);

export default router;
