import { Router } from 'express';
import { finalAssessmentController } from './final_assessment.controller';
import { authMiddleware } from '../../middleware/auth.middleware';

const router = Router();

router.use(authMiddleware);

router.get('/eligibility', (req, res, next) => finalAssessmentController.checkEligibility(req, res, next));
router.post('/start', (req, res, next) => finalAssessmentController.startAssessment(req, res, next));
router.post('/submit', (req, res, next) => finalAssessmentController.submitAssessment(req, res, next));
router.get('/attempts', (req, res, next) => finalAssessmentController.getAttempts(req, res, next));

export default router;
