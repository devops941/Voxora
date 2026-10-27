import { Router } from 'express';
import { lessonController } from './lesson.controller';

const router = Router();

// Retrieve today's scheduled lesson
router.get('/today', (req, res, next) => lessonController.getTodayLesson(req, res, next));

// Real-time voice exchange evaluation during lesson
router.post('/evaluate-response', (req, res, next) => lessonController.evaluateResponse(req, res, next));

// Complete today's lesson and save attempt
router.post('/complete', (req, res, next) => lessonController.completeLesson(req, res, next));

// Get user's 90-day learning plan
router.get('/plan', (req, res, next) => lessonController.getPlan(req, res, next));

export default router;
