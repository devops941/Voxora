import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IAssessmentQuestion {
  id: string;
  question: string;
  options: string[];
  correctAnswerIndex: number; // NEVER sent to client
  marks: number;
}

export interface IFinalAssessment extends Document {
  userId: mongoose.Types.ObjectId;
  level: 'Beginner' | 'Intermediate' | 'Advanced';
  questions: IAssessmentQuestion[];
  userAnswers: Map<string, number>;
  score: number;
  correctAnswers: number;
  status: 'in_progress' | 'pass' | 'fail';
  attemptNumber: number;
  isTestMode: boolean;
  submittedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const assessmentQuestionSchema = new Schema<IAssessmentQuestion>(
  {
    id: { type: String, required: true },
    question: { type: String, required: true },
    options: [{ type: String }],
    correctAnswerIndex: { type: Number, required: true, min: 0, max: 3 },
    marks: { type: Number, default: 4 },
  },
  { _id: false }
);

const finalAssessmentSchema = new Schema<IFinalAssessment>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    level: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced'],
      required: true,
    },
    questions: [assessmentQuestionSchema],
    userAnswers: {
      type: Map,
      of: Number,
      default: () => new Map(),
    },
    score: { type: Number, default: 0 },
    correctAnswers: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['in_progress', 'pass', 'fail'],
      default: 'in_progress',
    },
    attemptNumber: { type: Number, default: 1 },
    isTestMode: { type: Boolean, default: false },
    submittedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

finalAssessmentSchema.index({ userId: 1, level: 1 });
finalAssessmentSchema.index({ userId: 1, createdAt: -1 });

export const FinalAssessment: Model<IFinalAssessment> = mongoose.model<IFinalAssessment>(
  'FinalAssessment',
  finalAssessmentSchema
);
