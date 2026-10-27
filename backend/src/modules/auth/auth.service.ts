import { User, IUser } from '../users/user.model';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../../utils/jwt.utils';
import { AppError } from '../../types';
import logger from '../../utils/logger';

export interface RegisterDTO {
  name: string;
  email: string;
  phone?: string;
  password?: string;
  level?: string;
}

export interface LoginDTO {
  email: string;
  password?: string;
}

export interface GoogleAuthDTO {
  email: string;
  name: string;
  googleId?: string;
  avatarUrl?: string;
  idToken?: string;
}

export interface AuthResult {
  user: IUser;
  access_token: string;
  refresh_token: string;
}

export class AuthService {
  async register(data: RegisterDTO): Promise<AuthResult> {
    const email = data.email.trim().toLowerCase();
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      throw new AppError('Email already in use', 409);
    }

    const user = await User.create({
      name: data.name.trim(),
      email,
      phone: data.phone?.trim() || null,
      password: data.password,
      level: data.level || 'Beginner',
    });

    const tokenPayload = {
      id: user._id.toString(),
      email: user.email,
      role: user.role,
    };

    const access_token = generateAccessToken(tokenPayload);
    const refresh_token = generateRefreshToken(tokenPayload);

    logger.info(`✅ New user registered in MongoDB: ${user.email} (ID: ${user._id})`);

    return {
      user,
      access_token,
      refresh_token,
    };
  }

  async login(data: LoginDTO): Promise<AuthResult> {
    const raw = (data.email || '').trim();
    const emailLower = raw.toLowerCase();
    const user = await User.findOne({
      $or: [
        { email: emailLower },
        { phone: raw },
      ],
    }).select('+password');
    if (!user) {
      throw new AppError('Invalid email or password', 401);
    }

    const isMatch = await user.comparePassword(data.password || '');
    if (!isMatch) {
      throw new AppError('Invalid email or password', 401);
    }

    const tokenPayload = {
      id: user._id.toString(),
      email: user.email,
      role: user.role,
    };

    const access_token = generateAccessToken(tokenPayload);
    const refresh_token = generateRefreshToken(tokenPayload);

    logger.info(`✅ User logged in: ${user.email}`);

    return {
      user,
      access_token,
      refresh_token,
    };
  }

  async googleLogin(data: GoogleAuthDTO): Promise<AuthResult> {
    let verifiedEmail = (data.email || '').trim().toLowerCase();
    let verifiedName = (data.name || '').trim();
    let verifiedGoogleId = data.googleId?.trim();
    let verifiedAvatar = data.avatarUrl?.trim();

    if (data.idToken) {
      try {
        const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${data.idToken}`);
        if (response.ok) {
          const payload = await response.json() as {
            email?: string;
            name?: string;
            sub?: string;
            picture?: string;
          };
          if (payload.email) verifiedEmail = payload.email.toLowerCase();
          if (payload.name) verifiedName = payload.name;
          if (payload.sub) verifiedGoogleId = payload.sub;
          if (payload.picture) verifiedAvatar = payload.picture;
          logger.info(`✅ Google idToken verified from Google OAuth API for: ${verifiedEmail}`);
        }
      } catch (err) {
        logger.warn(`⚠️ Google tokeninfo verification skipped or network unavailable: ${err}`);
      }
    }

    if (!verifiedEmail) {
      throw new AppError('Valid Google email is required', 400);
    }

    let user = await User.findOne({
      $or: [
        ...(verifiedGoogleId ? [{ googleId: verifiedGoogleId }] : []),
        { email: verifiedEmail },
      ],
    });

    if (user) {
      let shouldSave = false;
      if (verifiedGoogleId && !user.googleId) {
        user.googleId = verifiedGoogleId;
        shouldSave = true;
      }
      if (verifiedAvatar && !user.avatarUrl) {
        user.avatarUrl = verifiedAvatar;
        shouldSave = true;
      }
      if (!user.authProvider || user.authProvider !== 'google') {
        user.authProvider = 'google';
        shouldSave = true;
      }
      if (shouldSave) {
        await user.save();
      }
      logger.info(`✅ Google user authenticated: ${user.email} (ID: ${user._id})`);
    } else {
      user = await User.create({
        name: verifiedName || 'Google User',
        email: verifiedEmail,
        avatarUrl: verifiedAvatar || null,
        googleId: verifiedGoogleId || `google_${Date.now()}`,
        authProvider: 'google',
        level: 'Beginner',
      });
      logger.info(`✅ New user registered via Google in MongoDB: ${user.email} (ID: ${user._id})`);
    }

    const tokenPayload = {
      id: user._id.toString(),
      email: user.email,
      role: user.role,
    };

    const access_token = generateAccessToken(tokenPayload);
    const refresh_token = generateRefreshToken(tokenPayload);

    return {
      user,
      access_token,
      refresh_token,
    };
  }

  async refreshToken(token: string): Promise<{ access_token: string; refresh_token: string }> {
    const decoded = verifyRefreshToken(token);
    const user = await User.findById(decoded.id);
    if (!user) {
      throw new AppError('User not found', 401);
    }

    const tokenPayload = {
      id: user._id.toString(),
      email: user.email,
      role: user.role,
    };

    const access_token = generateAccessToken(tokenPayload);
    const refresh_token = generateRefreshToken(tokenPayload);

    return { access_token, refresh_token };
  }

  async getMe(userId: string): Promise<IUser> {
    const user = await User.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404);
    }
    return user;
  }
}

export const authService = new AuthService();
