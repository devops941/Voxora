import { OAuth2Client } from 'google-auth-library';
import { User, IUser } from '../users/user.model';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../../utils/jwt.utils';
import { AppError } from '../../types';
import logger from '../../utils/logger';
import config from '../../config/env';
import { emailService } from '../../services/email.service';

const googleAuthClient = new OAuth2Client();

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
  email?: string;
  name?: string;
  googleId?: string;
  avatarUrl?: string | null;
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
    let verifiedAvatar = data.avatarUrl ? data.avatarUrl.trim() : undefined;

    // ── Official Google ID Token Verification ─────────────────────
    if (data.idToken && data.idToken.trim().length > 0) {
      try {
        const audiences = config.googleClientId
          ? config.googleClientId.split(',').map((s) => s.trim()).filter(Boolean)
          : undefined;

        const ticket = await googleAuthClient.verifyIdToken({
          idToken: data.idToken.trim(),
          audience: audiences && audiences.length > 0 ? audiences : undefined,
        });

        const payload = ticket.getPayload();
        if (!payload || !payload.email) {
          throw new AppError('Google ID token did not contain a verified email address', 401);
        }

        verifiedEmail = payload.email.toLowerCase();
        verifiedName = payload.name || payload.given_name || verifiedName || 'Google User';
        verifiedGoogleId = payload.sub || verifiedGoogleId;
        verifiedAvatar = payload.picture || verifiedAvatar;

        logger.info(`✅ Google ID token securely verified with google-auth-library for: ${verifiedEmail} (sub: ${verifiedGoogleId})`);
      } catch (err: any) {
        logger.error(`❌ Google ID token verification failed: ${err.message || err}`);
        throw new AppError(err.message || 'Invalid or expired Google ID token', 401);
      }
    }

    if (!verifiedEmail) {
      throw new AppError('Valid Google email or ID token is required', 400);
    }

    // ── Find existing user by googleId or email ───────────────────
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
      if (verifiedName && (!user.name || user.name === 'Google User')) {
        user.name = verifiedName;
        shouldSave = true;
      }
      if (shouldSave) {
        await user.save();
      }
      logger.info(`✅ Existing Google user authenticated: ${user.email} (ID: ${user._id})`);
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

  /**
   * Generates a 6-digit OTP and dispatches it via SMTP email for password reset.
   */
  async forgotPassword(rawEmail: string): Promise<{ success: boolean; message: string }> {
    const email = rawEmail.trim().toLowerCase();
    const user = await User.findOne({ email }).select('+resetPasswordOtp +resetPasswordExpires');

    if (!user) {
      logger.info(`Password reset requested for non-existent email: ${email}`);
      return {
        success: true,
        message: `If an account with ${email} exists, a 6-digit OTP has been sent.`,
      };
    }

    // Generate secure 6-digit numeric OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    user.resetPasswordOtp = otp;
    user.resetPasswordExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    await user.save();

    // Send styled OTP email via configured SMTP
    await emailService.sendPasswordResetOtpEmail(
      user.email,
      user.name || 'Voxora Learner',
      otp
    );

    logger.info(`🔐 Password reset 6-digit OTP generated and dispatched for user: ${user.email}`);

    return {
      success: true,
      message: `A 6-digit verification code has been sent to ${email}`,
    };
  }

  /**
   * Verifies that the submitted 6-digit OTP matches and is not expired.
   */
  async verifyOtp(rawEmail: string, rawOtp: string): Promise<{ success: boolean; message: string }> {
    const email = rawEmail.trim().toLowerCase();
    const otp = rawOtp.trim();

    if (!otp || otp.length < 4) {
      throw new AppError('Please enter a valid 6-digit OTP code', 400);
    }

    const user = await User.findOne({ email }).select('+resetPasswordOtp +resetPasswordExpires');
    if (!user || !user.resetPasswordOtp || !user.resetPasswordExpires) {
      throw new AppError('No active password reset request found for this email', 400);
    }

    if (user.resetPasswordExpires < new Date()) {
      throw new AppError('The verification code has expired. Please request a new one.', 400);
    }

    if (user.resetPasswordOtp !== otp) {
      throw new AppError('Incorrect verification code. Please check your email and try again.', 400);
    }

    logger.info(`✅ OTP verified successfully for user: ${email}`);

    return {
      success: true,
      message: 'Verification successful! You can now set a new password.',
    };
  }

  /**
   * Resets the user's password once the OTP has been verified.
   */
  async resetPassword(
    rawEmail: string,
    rawOtp: string,
    rawPassword: string
  ): Promise<{ success: boolean; message: string }> {
    const email = rawEmail.trim().toLowerCase();
    const otp = rawOtp.trim();
    const newPassword = rawPassword.trim();

    if (!newPassword || newPassword.length < 6) {
      throw new AppError('Password must be at least 6 characters long', 400);
    }

    const user = await User.findOne({ email }).select('+resetPasswordOtp +resetPasswordExpires +password');
    if (!user || !user.resetPasswordOtp || !user.resetPasswordExpires) {
      throw new AppError('Invalid or expired password reset session', 400);
    }

    if (user.resetPasswordExpires < new Date()) {
      throw new AppError('The verification code has expired. Please request a new one.', 400);
    }

    if (user.resetPasswordOtp !== otp) {
      throw new AppError('Invalid verification code', 400);
    }

    // Update password (pre-save hook will hash it with bcrypt)
    user.password = newPassword;
    user.resetPasswordOtp = null;
    user.resetPasswordExpires = null;
    await user.save();

    logger.info(`🎉 Password successfully updated for user: ${email}`);

    return {
      success: true,
      message: 'Password reset successfully! Please log in with your new password.',
    };
  }
}

export const authService = new AuthService();
