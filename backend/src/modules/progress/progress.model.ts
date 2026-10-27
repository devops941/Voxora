import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IUserLessonProgress extends Document {
  id: string;
  userId: mongoose.Types.ObjectId;
  lessonId: mongoose.Types.ObjectId;
  isCompleted: boolean;
  score: number;
  timeSpentMinutes: number;
  completedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const userLessonProgressSchema = new Schema<IUserLessonProgress>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    lessonId: {
      type: Schema.Types.ObjectId,
      ref: 'Lesson',
      required: true,
      index: true,
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    score: {
      type: Number,
      default: 0,
    },
    timeSpentMinutes: {
      type: Number,
      default: 0,
    },
    completedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret: Record<string, unknown>) => {
        ret['id'] = ret['_id']?.toString();
        ret['user_id'] = ret['userId']?.toString();
        ret['lesson_id'] = ret['lessonId']?.toString();
        ret['is_completed'] = ret['isCompleted'];
        ret['completed_at'] = ret['completedAt'];
        delete ret['_id'];
        delete ret['__v'];
        return ret;
      },
    },
  }
);

// Compound index to ensure 1 record per user per lesson
userLessonProgressSchema.index({ userId: 1, lessonId: 1 }, { unique: true });

export const UserLessonProgress: Model<IUserLessonProgress> =
  mongoose.model<IUserLessonProgress>('UserLessonProgress', userLessonProgressSchema);
