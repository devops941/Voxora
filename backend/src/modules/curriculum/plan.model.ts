import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IDailyLesson {
  day: number; // 1 to 90
  phase: number; // 1 (Foundation), 2 (Fluency), 3 (Mastery)
  topic: string;
  objective: string;
  targetSkills: string[];
  difficulty: 'Beginner' | 'Elementary' | 'Intermediate' | 'Upper-Intermediate' | 'Advanced';
  vocabularyFocus: string[];
  grammarFocus: string[];
  speakingActivities: string[];
  miraQuestions: string[];
  expectedDurationMinutes: number;
  evaluationCriteria: string[];
  revisionTask?: string;
  teachingContent?: any;
  status: 'pending' | 'in_progress' | 'completed';
  score?: number;
  completedAt?: Date;
  learnerNotes?: string;
}

export interface ILearningPlan extends Document {
  id: string;
  userId: mongoose.Types.ObjectId;
  assessmentId?: mongoose.Types.ObjectId;
  startingLevel: 'Beginner' | 'Intermediate' | 'Advanced';
  assessedProficiency: string;
  totalDays: number; // 90
  currentDay: number; // 1 to 90
  completedDays: number;
  streakCount: number;
  lastCompletedDate?: Date;
  lessons: IDailyLesson[];
  createdAt: Date;
  updatedAt: Date;
}

const dailyLessonSchema = new Schema<IDailyLesson>(
  {
    day: { type: Number, required: true },
    phase: { type: Number, required: true, default: 1 },
    topic: { type: String, required: true },
    objective: { type: String, required: true },
    targetSkills: [{ type: String }],
    difficulty: {
      type: String,
      enum: ['Beginner', 'Elementary', 'Intermediate', 'Upper-Intermediate', 'Advanced'],
      default: 'Beginner',
    },
    vocabularyFocus: [{ type: String }],
    grammarFocus: [{ type: String }],
    speakingActivities: [{ type: String }],
    miraQuestions: [{ type: String }],
    expectedDurationMinutes: { type: Number, default: 15 },
    evaluationCriteria: [{ type: String }],
    revisionTask: { type: String, default: '' },
    status: {
      type: String,
      enum: ['pending', 'in_progress', 'completed'],
      default: 'pending',
    },
    score: { type: Number, default: 0 },
    completedAt: { type: Date, default: null },
    learnerNotes: { type: String, default: '' },
    teachingContent: { type: Schema.Types.Mixed, default: null },
  },
  { _id: true }
);

const learningPlanSchema = new Schema<ILearningPlan>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    assessmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Assessment',
      required: false,
    },
    startingLevel: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced'],
      required: true,
      default: 'Beginner',
    },
    assessedProficiency: {
      type: String,
      default: 'Beginner A1',
    },
    totalDays: {
      type: Number,
      default: 90,
    },
    currentDay: {
      type: Number,
      default: 1,
    },
    completedDays: {
      type: Number,
      default: 0,
    },
    streakCount: {
      type: Number,
      default: 0,
    },
    lastCompletedDate: {
      type: Date,
      default: null,
    },
    lessons: [dailyLessonSchema],
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret: Record<string, unknown>) => {
        ret['id'] = ret['_id']?.toString();
        ret['user_id'] = ret['userId']?.toString();
        delete ret['_id'];
        delete ret['__v'];
        return ret;
      },
    },
  }
);

export const LearningPlan: Model<ILearningPlan> = mongoose.model<ILearningPlan>(
  'LearningPlan',
  learningPlanSchema
);
