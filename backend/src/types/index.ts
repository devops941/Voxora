import { Request } from 'express';

// ─── User Roles ───────────────────────────────────────────────────────────────

export enum UserRole {
  STUDENT = 'student',
  ADMIN = 'admin',
}

// ─── Proficiency Levels ───────────────────────────────────────────────────────

export enum ProficiencyLevel {
  BEGINNER = 'beginner',
  ELEMENTARY = 'elementary',
  INTERMEDIATE = 'intermediate',
  UPPER_INTERMEDIATE = 'upper-intermediate',
  ADVANCED = 'advanced',
}

// ─── Auth Request ─────────────────────────────────────────────────────────────

export interface AuthUser {
  id: string;
  email: string;
  role: string;
}

export interface AuthRequest extends Request {
  user?: AuthUser;
}

// ─── API Response ─────────────────────────────────────────────────────────────

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T | null;
  errors?: Record<string, string>[];
}

// ─── App Error ────────────────────────────────────────────────────────────────

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number = 500, isOperational: boolean = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, AppError.prototype);
    Error.captureStackTrace(this, this.constructor);
  }
}

// ─── Conversation History ─────────────────────────────────────────────────────

export interface ConversationMessage {
  role: 'user' | 'assistant';
  content: string;
}

// ─── AI Feedback ─────────────────────────────────────────────────────────────

export interface FeedbackResult {
  score: number;
  pronunciation: {
    score: number;
    issues: string[];
    strengths: string[];
  };
  grammar: {
    score: number;
    corrections: Array<{ original: string; corrected: string; explanation: string }>;
  };
  fluency: {
    score: number;
    wordsPerMinute?: number;
    pausePattern?: string;
  };
  suggestions: string[];
  encouragement: string;
}

// ─── Curriculum Types ─────────────────────────────────────────────────────────

export interface LessonOutline {
  title: string;
  type: string;
  duration: number;
  objectives: string[];
}

export interface ModuleOutline {
  title: string;
  description: string;
  lessons: LessonOutline[];
}

export interface CurriculumOutline {
  level: string;
  title: string;
  description: string;
  totalWeeks: number;
  modules: ModuleOutline[];
}
