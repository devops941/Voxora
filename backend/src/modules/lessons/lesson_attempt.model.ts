import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IExchange {
  miraPrompt: string;
  userAudioTranscript: string;
  durationSeconds?: number;
  corrections: Array<{
    original: string;
    corrected: string;
    explanation: string;
  }>;
  pronunciationTips: string[];
  scores: {
    grammar: number;
    fluency: number;
    pronunciation: number;
    overall: number;
  };
}

export interface ILessonAttempt extends Document {
  id: string;
  userId: mongoose.Types.ObjectId;
  planId?: mongoose.Types.ObjectId;
  day: number;
  topic: string;
  exchanges: IExchange[];
  overallScore: number;
  timeSpentSeconds: number;
  isCompleted: boolean;
  feedbackSummary: string;
  createdAt: Date;
  updatedAt: Date;
}

const exchangeSchema = new Schema<IExchange>(
  {
    miraPrompt: { type: String, required: true },
    userAudioTranscript: { type: String, required: true },
    durationSeconds: { type: Number, default: 10 },
    corrections: [
      {
        original: { type: String, required: true },
        corrected: { type: String, required: true },
        explanation: { type: String, required: true },
      },
    ],
    pronunciationTips: [{ type: String }],
    scores: {
      grammar: { type: Number, default: 80 },
      fluency: { type: Number, default: 80 },
      pronunciation: { type: Number, default: 80 },
      overall: { type: Number, default: 80 },
    },
  },
  { _id: true }
);

const lessonAttemptSchema = new Schema<ILessonAttempt>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    planId: {
      type: Schema.Types.ObjectId,
      ref: 'LearningPlan',
      required: false,
    },
    day: {
      type: Number,
      required: true,
    },
    topic: {
      type: String,
      required: true,
    },
    exchanges: [exchangeSchema],
    overallScore: {
      type: Number,
      default: 0,
    },
    timeSpentSeconds: {
      type: Number,
      default: 0,
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    feedbackSummary: {
      type: String,
      default: '',
    },
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

lessonAttemptSchema.index({ userId: 1, day: 1 });

export const LessonAttempt: Model<ILessonAttempt> = mongoose.model<ILessonAttempt>(
  'LessonAttempt',
  lessonAttemptSchema
);
