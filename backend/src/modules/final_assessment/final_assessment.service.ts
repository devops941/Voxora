import config from '../../config/env';
import { AppError } from '../../types';
import { User } from '../users/user.model';
import { LearningPlan } from '../curriculum/plan.model';
import { FinalAssessment, IAssessmentQuestion } from './final_assessment.model';
import { aiProviderManager } from '../../services/ai/AIProviderManager';

interface ClientQuestion {
  id: string;
  question: string;
  options: string[];
  marks: number;
}

interface SubmitResult {
  assessmentId: string;
  score: number;
  percentage: number;
  correctAnswers: number;
  totalQuestions: number;
  totalMarks: number;
  status: 'pass' | 'fail';
  level: string;
  isTestMode: boolean;
}

export class FinalAssessmentService {
  async checkEligibility(
    userId: string,
    level: string
  ): Promise<{ eligible: boolean; isTestMode: boolean; reason?: string }> {
    // ── TEST MODE (dev only, never in staging/production) ──────────────────
    if (config.enableFinalAssessmentTestMode) {
      if (config.nodeEnv !== 'development') {
        throw new AppError('Test mode is only available in development environment', 403);
      }
      const user = await User.findById(userId);
      if (!user) throw new AppError('User not found', 404);
      if (user.role !== 'admin' && user.email !== config.devTestAccountEmail) {
        throw new AppError('Test mode is restricted to authorized development accounts', 403);
      }
      return { eligible: true, isTestMode: true };
    }

    // ── NORMAL 90-DAY CHECK ─────────────────────
    const plan = await LearningPlan.findOne({ userId });
    if (!plan) {
      return {
        eligible: false,
        isTestMode: false,
        reason: 'No learning plan found. Complete your initial speech assessment first.',
      };
    }
    if (plan.completedDays < 90) {
      return {
        eligible: false,
        isTestMode: false,
        reason: `Complete all 90 days to unlock the Final Assessment (${plan.completedDays}/90 completed).`,
      };
    }
    return { eligible: true, isTestMode: false };
  }

  async generateQuestions(
    level: 'Beginner' | 'Intermediate' | 'Advanced'
  ): Promise<IAssessmentQuestion[]> {
    const response = await aiProviderManager.generateFinalAssessmentQuestions(level);
    return response.data;
  }

  async startAssessment(
    userId: string,
    level: 'Beginner' | 'Intermediate' | 'Advanced'
  ): Promise<{ assessmentId: string; questions: ClientQuestion[] }> {
    const { isTestMode } = await this.checkEligibility(userId, level);
    const attemptCount = await FinalAssessment.countDocuments({ userId, level });
    const questions = await this.generateQuestions(level);

    const doc = await FinalAssessment.create({
      userId,
      level,
      questions,
      userAnswers: new Map(),
      score: 0,
      correctAnswers: 0,
      status: 'in_progress',
      attemptNumber: attemptCount + 1,
      isTestMode,
    });

    // Never include correctAnswerIndex in client response
    const clientQuestions: ClientQuestion[] = doc.questions.map((q) => ({
      id: q.id,
      question: q.question,
      options: q.options,
      marks: q.marks,
    }));

    return { assessmentId: doc.id, questions: clientQuestions };
  }

  async submitAssessment(
    userId: string,
    assessmentId: string,
    answers: Record<string, number>
  ): Promise<SubmitResult> {
    const assessment = await FinalAssessment.findOne({ _id: assessmentId, userId });
    if (!assessment) throw new AppError('Assessment not found', 404);
    if (assessment.status !== 'in_progress') {
      throw new AppError('This assessment has already been submitted', 400);
    }

    let correctAnswers = 0;
    assessment.questions.forEach((q) => {
      if (answers[q.id] !== undefined && Number(answers[q.id]) === q.correctAnswerIndex) {
        correctAnswers++;
      }
    });

    const score = correctAnswers * 4; // 4 marks each → max 100
    const status: 'pass' | 'fail' = score >= 65 ? 'pass' : 'fail';

    const answersMap = new Map<string, number>();
    Object.entries(answers).forEach(([k, v]) => answersMap.set(k, Number(v)));

    assessment.userAnswers = answersMap;
    assessment.score = score;
    assessment.correctAnswers = correctAnswers;
    assessment.status = status;
    assessment.submittedAt = new Date();
    await assessment.save();

    return {
      assessmentId: assessment.id,
      score,
      percentage: score,
      correctAnswers,
      totalQuestions: 25,
      totalMarks: 100,
      status,
      level: assessment.level,
      isTestMode: assessment.isTestMode,
    };
  }

  async getAttempts(userId: string, level: string) {
    const filter: any = { userId };
    if (level && ['Beginner', 'Intermediate', 'Advanced'].includes(level)) {
      filter.level = level;
    }
    const attempts = await FinalAssessment.find(filter)
      .sort({ createdAt: -1 })
      .lean();

    return attempts.map((a) => ({
      id: a._id?.toString(),
      level: a.level,
      score: a.score,
      percentage: a.score,
      correctAnswers: a.correctAnswers,
      status: a.status,
      attemptNumber: a.attemptNumber,
      isTestMode: a.isTestMode,
      submittedAt: a.submittedAt,
    }));
  }
}

export const finalAssessmentService = new FinalAssessmentService();
