import mongoose, { Document, Schema, Model } from 'mongoose';

export interface ICurriculumTemplate extends Document {
  id: string;
  level: 'Beginner' | 'Intermediate' | 'Advanced';
  day: number; // 1 to 90
  phase: number; // 1, 2, or 3
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
  revisionTask?: string | null;
  teachingContent?: any;
  createdAt: Date;
  updatedAt: Date;
}

const curriculumTemplateSchema = new Schema<ICurriculumTemplate>(
  {
    level: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced'],
      required: true,
      index: true,
    },
    day: {
      type: Number,
      required: true,
      min: 1,
      max: 90,
      index: true,
    },
    phase: {
      type: Number,
      required: true,
      min: 1,
      max: 3,
      default: 1,
    },
    topic: {
      type: String,
      required: true,
      trim: true,
    },
    objective: {
      type: String,
      required: true,
      trim: true,
    },
    targetSkills: [{ type: String }],
    difficulty: {
      type: String,
      enum: ['Beginner', 'Elementary', 'Intermediate', 'Upper-Intermediate', 'Advanced'],
      required: true,
      default: 'Beginner',
    },
    vocabularyFocus: [{ type: String }],
    grammarFocus: [{ type: String }],
    speakingActivities: [{ type: String }],
    miraQuestions: [{ type: String }],
    expectedDurationMinutes: {
      type: Number,
      default: 15,
    },
    evaluationCriteria: [{ type: String }],
    revisionTask: {
      type: String,
      default: null,
    },
    teachingContent: {
      type: Schema.Types.Mixed,
      default: null,
    },
  },
  {
    collection: 'curriculum_templates',
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

// Unique compound index: each level has exactly 90 days (1 to 90) -> Total 270 entries
curriculumTemplateSchema.index({ level: 1, day: 1 }, { unique: true });

export const CurriculumTemplate: Model<ICurriculumTemplate> = mongoose.model<ICurriculumTemplate>(
  'CurriculumTemplate',
  curriculumTemplateSchema
);
