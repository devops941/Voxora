import { build90DayCurriculum } from './curriculum_generator';
import { LearningPlan, ILearningPlan, IDailyLesson } from './plan.model';
import { User } from '../users/user.model';
import logger from '../../utils/logger';

export interface CurriculumResponse {
  level: string;
  totalDays: number;
  completedDays: number;
  currentDay: number;
  streakCount: number;
  lessons: IDailyLesson[];
}

export class CurriculumService {
  /**
   * Retrieves 90-day curriculum for the specified level or user's active plan.
   */
  async getCurriculum(userId?: string, levelParam?: string): Promise<CurriculumResponse> {
    let targetLevel: 'Beginner' | 'Intermediate' | 'Advanced' = 'Beginner';

    if (levelParam && ['Beginner', 'Intermediate', 'Advanced'].includes(levelParam)) {
      targetLevel = levelParam as 'Beginner' | 'Intermediate' | 'Advanced';
    } else if (userId) {
      const user = await User.findById(userId);
      if (user?.level && ['Beginner', 'Intermediate', 'Advanced'].includes(user.level)) {
        targetLevel = user.level as 'Beginner' | 'Intermediate' | 'Advanced';
      }
    }

    // If authenticated user exists, check for an existing LearningPlan in MongoDB
    if (userId) {
      let plan = await LearningPlan.findOne({ userId });

      // If level is specified and different, check if user switched track
      if (plan && levelParam && plan.startingLevel !== targetLevel) {
        // Build plan for requested track
        const newLessons = build90DayCurriculum({ level: targetLevel });
        return {
          level: targetLevel,
          totalDays: 90,
          completedDays: 0,
          currentDay: 1,
          streakCount: plan.streakCount,
          lessons: newLessons,
        };
      }

      if (!plan) {
        // Seed default 90-day plan for user
        const lessons = build90DayCurriculum({ level: targetLevel });
        plan = await LearningPlan.create({
          userId,
          startingLevel: targetLevel,
          assessedProficiency: `${targetLevel} Track`,
          totalDays: 90,
          currentDay: 1,
          completedDays: 0,
          streakCount: 0,
          lessons,
        });
        logger.info(`[CurriculumService] Created new 90-day plan in MongoDB for user ${userId} (${targetLevel})`);
      }

      return {
        level: plan.startingLevel,
        totalDays: plan.totalDays,
        completedDays: plan.completedDays,
        currentDay: plan.currentDay,
        streakCount: plan.streakCount,
        lessons: plan.lessons,
      };
    }

    // Public / unauthenticated curriculum preview
    const lessons = build90DayCurriculum({ level: targetLevel });
    return {
      level: targetLevel,
      totalDays: 90,
      completedDays: 0,
      currentDay: 1,
      streakCount: 0,
      lessons,
    };
  }
}

export const curriculumService = new CurriculumService();

