import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IAssessment extends Document {
  id: string;
  userId?: mongoose.Types.ObjectId;
  selectedStartingLevel: 'Beginner' | 'Intermediate' | 'Advanced';
  transcript: string;
  audioMetrics: {
    durationSeconds: number;
    wpm: number;
    wordCount: number;
  };
  scores: {
    fluency: number;
    pronunciation: number;
    grammar: number;
    vocabulary: number;
    overall: number;
  };
  strengths: string[];
  weaknesses: string[];
  estimatedProficiency: string;
  feedbackSummary: string;
  rawAiResponse?: any;
  createdAt: Date;
  updatedAt: Date;
}

const assessmentSchema = new Schema<IAssessment>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: false,
      index: true,
    },
    selectedStartingLevel: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced'],
      required: true,
    },
    transcript: {
      type: String,
      required: true,
      trim: true,
    },
    audioMetrics: {
      durationSeconds: { type: Number, default: 15 },
      wpm: { type: Number, default: 0 },
      wordCount: { type: Number, default: 0 },
    },
    scores: {
      fluency: { type: Number, default: 75 },
      pronunciation: { type: Number, default: 75 },
      grammar: { type: Number, default: 75 },
      vocabulary: { type: Number, default: 75 },
      overall: { type: Number, default: 75 },
    },
    strengths: [{ type: String }],
    weaknesses: [{ type: String }],
    estimatedProficiency: {
      type: String,
      default: 'Beginner A1',
    },
    feedbackSummary: {
      type: String,
      default: '',
    },
    rawAiResponse: {
      type: Schema.Types.Mixed,
      required: false,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret: Record<string, unknown>) => {
        ret['id'] = ret['_id']?.toString();
        if (ret['userId']) ret['user_id'] = ret['userId'].toString();
        delete ret['_id'];
        delete ret['__v'];
        return ret;
      },
    },
  }
);

export const Assessment: Model<IAssessment> = mongoose.model<IAssessment>(
  'Assessment',
  assessmentSchema
);
