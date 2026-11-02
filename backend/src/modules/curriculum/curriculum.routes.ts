import { Router } from 'express';
import { curriculumController } from './curriculum.controller';
import { optionalAuthMiddleware } from '../../middleware/auth.middleware';

const router = Router();

// GET /api/v1/curriculum?level=Beginner|Intermediate|Advanced
router.get('/', optionalAuthMiddleware, (req, res, next) =>
  curriculumController.getCurriculum(req, res, next)
);

export default router;

