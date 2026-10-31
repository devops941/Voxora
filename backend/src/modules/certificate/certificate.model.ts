import mongoose, { Document, Schema, Model } from 'mongoose';

export interface ICertificate extends Document {
  userId: mongoose.Types.ObjectId;
  finalAssessmentId: mongoose.Types.ObjectId;
  certificateId: string;
  fullName: string;
  email: string;
  level: 'Beginner' | 'Intermediate' | 'Advanced';
  score: number;
  percentage: number;
  completionDate: Date;
  isTestMode: boolean;
  pdfBuffer?: Buffer;
  createdAt: Date;
  updatedAt: Date;
}

const certificateSchema = new Schema<ICertificate>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    finalAssessmentId: { type: Schema.Types.ObjectId, ref: 'FinalAssessment', required: true },
    certificateId: { type: String, required: true, unique: true },
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    level: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced'],
      required: true,
    },
    score: { type: Number, required: true },
    percentage: { type: Number, required: true },
    completionDate: { type: Date, required: true },
    isTestMode: { type: Boolean, default: false },
    pdfBuffer: { type: Buffer, default: null },
  },
  { timestamps: true }
);

certificateSchema.index({ userId: 1 });

export const Certificate: Model<ICertificate> = mongoose.model<ICertificate>(
  'Certificate',
  certificateSchema
);
