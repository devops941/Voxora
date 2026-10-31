import mongoose, { Document, Schema, Model } from 'mongoose';
import bcrypt from 'bcryptjs';

export interface IUser extends Document {
  id: string;
  name: string;
  email: string;
  phone?: string;
  password?: string;
  avatarUrl?: string;
  bio?: string;
  location?: string;
  level: string;
  role: 'student' | 'admin';
  authProvider?: 'local' | 'google';
  googleId?: string;
  xp: number;
  streak: number;
  dailyGoalMinutes: number;
  lastActiveDate?: Date;
  resetPasswordOtp?: string | null;
  resetPasswordExpires?: Date | null;
  comparePassword(candidatePassword: string): Promise<boolean>;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    phone: {
      type: String,
      default: null,
      trim: true,
    },
    password: {
      type: String,
      required: false,
      minlength: [6, 'Password must be at least 6 characters'],
      select: false,
    },
    avatarUrl: {
      type: String,
      default: null,
    },
    bio: {
      type: String,
      default: 'Better English • Bigger Dreams',
      trim: true,
    },
    location: {
      type: String,
      default: 'Madurai, India',
      trim: true,
    },
    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
    },
    googleId: {
      type: String,
      default: null,
      sparse: true,
    },
    level: {
      type: String,
      enum: ['Beginner', 'Elementary', 'Intermediate', 'Upper-Intermediate', 'Advanced'],
      default: 'Beginner',
    },
    role: {
      type: String,
      enum: ['student', 'admin'],
      default: 'student',
    },
    xp: {
      type: Number,
      default: 0,
    },
    streak: {
      type: Number,
      default: 0,
    },
    dailyGoalMinutes: {
      type: Number,
      default: 20,
    },
    lastActiveDate: {
      type: Date,
      default: null,
    },
    resetPasswordOtp: {
      type: String,
      default: null,
      select: false,
    },
    resetPasswordExpires: {
      type: Date,
      default: null,
      select: false,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret: Record<string, unknown>) => {
        ret['id'] = ret['_id']?.toString();
        ret['avatar_url'] = ret['avatarUrl'];
        ret['bio'] = ret['bio'] || 'Better English • Bigger Dreams';
        ret['location'] = ret['location'] || 'Madurai, India';
        ret['phone_number'] = ret['phone'];
        ret['auth_provider'] = ret['authProvider'] || 'local';
        ret['google_id'] = ret['googleId'];
        ret['created_at'] = ret['createdAt'];
        delete ret['_id'];
        delete ret['__v'];
        delete ret['password'];
        return ret;
      },
    },
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password') || !this.password) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Method to verify password
userSchema.methods.comparePassword = async function (candidatePassword: string): Promise<boolean> {
  if (!this.password) return false;
  return bcrypt.compare(candidatePassword, this.password);
};

export const User: Model<IUser> = mongoose.model<IUser>('User', userSchema);
