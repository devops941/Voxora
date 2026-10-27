import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IQuestion {
  id?: string;
  type: 'multiple_choice' | 'speaking' | 'fill_blank';
  prompt: string;
  options?: string[];
  correctAnswer?: string;
  audioUrl?: string;
  hint?: string;
  explanation?: string;
}

export interface ILesson extends Document {
  id: string;
  title: string;
  description: string;
  level: string;
  duration: number; // in minutes
  type: string; // vocabulary | grammar | speaking | listening
  order: number;
  xpReward: number;
  questions: IQuestion[];
  createdAt: Date;
  updatedAt: Date;
}

const questionSchema = new Schema<IQuestion>(
  {
    type: {
      type: String,
      enum: ['multiple_choice', 'speaking', 'fill_blank'],
      required: true,
    },
    prompt: {
      type: String,
      required: true,
    },
    options: [{ type: String }],
    correctAnswer: { type: String },
    audioUrl: { type: String },
    hint: { type: String },
    explanation: { type: String },
  },
  {
    _id: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret: Record<string, unknown>) => {
        ret['id'] = ret['_id']?.toString();
        ret['correct_answer'] = ret['correctAnswer'];
        ret['audio_url'] = ret['audioUrl'];
        delete ret['_id'];
        return ret;
      },
    },
  }
);

const lessonSchema = new Schema<ILesson>(
  {
    title: {
      type: String,
      required: [true, 'Lesson title is required'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Lesson description is required'],
      trim: true,
    },
    level: {
      type: String,
      enum: ['Beginner', 'Elementary', 'Intermediate', 'Upper-Intermediate', 'Advanced'],
      default: 'Beginner',
      index: true,
    },
    duration: {
      type: Number,
      default: 10,
    },
    type: {
      type: String,
      enum: ['vocabulary', 'grammar', 'speaking', 'listening'],
      default: 'speaking',
      index: true,
    },
    order: {
      type: Number,
      default: 1,
      index: true,
    },
    xpReward: {
      type: Number,
      default: 50,
    },
    questions: [questionSchema],
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret: Record<string, unknown>) => {
        ret['id'] = ret['_id']?.toString();
        delete ret['_id'];
        delete ret['__v'];
        return ret;
      },
    },
  }
);

export const Lesson: Model<ILesson> = mongoose.model<ILesson>('Lesson', lessonSchema);
