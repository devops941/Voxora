import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../types';
import { curriculumService } from './curriculum.service';

export class CurriculumController {
  async getCurriculum(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      const level = req.query.level as string | undefined;

      const data = await curriculumService.getCurriculum(userId, level);

      res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const curriculumController = new CurriculumController();

