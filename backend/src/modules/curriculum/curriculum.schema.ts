import mongoose, { Document, Schema, Model } from 'mongoose';

export interface ICurriculum extends Document {
  id: string;
  level: string;
  title: string;
  description: string;
  totalWeeks: number;
  modules: Array<{
    title: string;
    description: string;
    lessons: Array<{
      title: string;
      type: string;
      duration: number;
      objectives: string[];
    }>;
  }>;
  createdAt: Date;
  updatedAt: Date;
}

const curriculumSchema = new Schema<ICurriculum>(
  {
    level: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    totalWeeks: {
      type: Number,
      default: 12,
    },
    modules: [
      {
        title: { type: String, required: true },
        description: { type: String, required: true },
        lessons: [
          {
            title: { type: String, required: true },
            type: { type: String, default: 'speaking' },
            duration: { type: Number, default: 15 },
            objectives: [{ type: String }],
          },
        ],
      },
    ],
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

export const Curriculum: Model<ICurriculum> = mongoose.model<ICurriculum>(
  'Curriculum',
  curriculumSchema
);
