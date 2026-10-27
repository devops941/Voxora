import { Router } from 'express';
import { z } from 'zod';
import { aiController } from './ai.controller';
import { validate } from '../../middleware/validate.middleware';

const router = Router();

const assessSpeechSchema = z.object({
  transcript: z.string().min(1, 'Transcript is required'),
  selectedLevel: z.string().optional(),
  durationSeconds: z.number().optional(),
});

router.post('/assess-speech', validate(assessSpeechSchema), (req, res, next) =>
  aiController.assessSpeech(req, res, next)
);

export default router;
