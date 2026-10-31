import { Router } from 'express';
import { lessonController } from './lesson.controller';

const router = Router();

// Aggregated dashboard data (User profile, streak, today's lesson, 90-day progress)
router.get('/dashboard', (req, res, next) => lessonController.getDashboard(req, res, next));

// Retrieve today's scheduled lesson
router.get('/today', (req, res, next) => lessonController.getTodayLesson(req, res, next));

// Real-time voice exchange evaluation during lesson
router.post('/evaluate-response', (req, res, next) => lessonController.evaluateResponse(req, res, next));

// Ask doubts to MIRA during lesson
router.post('/ask-doubt', (req, res, next) => lessonController.askDoubt(req, res, next));

// Complete today's lesson and save attempt
router.post('/complete', (req, res, next) => lessonController.completeLesson(req, res, next));

// Get user's 90-day learning plan (optional ?level=Beginner|Intermediate|Advanced)
router.get('/plan', (req, res, next) => lessonController.getPlan(req, res, next));

// Switch user's active curriculum track level
router.post('/set-level', (req, res, next) => lessonController.setLevel(req, res, next));

// Retrieve a specific day's lesson (Day 1 - 90)
router.get('/day/:day', (req, res, next) => lessonController.getDayLesson(req, res, next));

// Get user's comprehensive learning progress & analytics
router.get('/progress', (req, res, next) => lessonController.getProgress(req, res, next));

export default router;
