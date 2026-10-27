import { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service';
import { AuthRequest } from '../../types';

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, phone, password, level } = req.body;
      const result = await authService.register({ name, email, phone, password, level });

      const userJson = result.user.toJSON();
      res.status(201).json({
        success: true,
        message: 'Account created successfully',
        data: {
          user: userJson,
          access_token: result.access_token,
          refresh_token: result.refresh_token,
        },
        user: userJson,
        access_token: result.access_token,
        refresh_token: result.refresh_token,
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body;
      const result = await authService.login({ email, password });

      const userJson = result.user.toJSON();
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: userJson,
          access_token: result.access_token,
          refresh_token: result.refresh_token,
        },
        user: userJson,
        access_token: result.access_token,
        refresh_token: result.refresh_token,
      });
    } catch (error) {
      next(error);
    }
  }

  async googleLogin(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, name, googleId, avatarUrl, idToken } = req.body;
      const result = await authService.googleLogin({ email, name, googleId, avatarUrl, idToken });

      const userJson = result.user.toJSON();
      res.status(200).json({
        success: true,
        message: 'Google login successful',
        data: {
          user: userJson,
          access_token: result.access_token,
          refresh_token: result.refresh_token,
        },
        user: userJson,
        access_token: result.access_token,
        refresh_token: result.refresh_token,
      });
    } catch (error) {
      next(error);
    }
  }

  async refreshToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refresh_token } = req.body;
      const result = await authService.refreshToken(refresh_token);

      res.status(200).json({
        success: true,
        message: 'Token refreshed',
        data: result,
        access_token: result.access_token,
        refresh_token: result.refresh_token,
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(_req: Request, res: Response): Promise<void> {
    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  }

  async forgotPassword(req: Request, res: Response): Promise<void> {
    const { email } = req.body;
    res.status(200).json({
      success: true,
      message: `Password reset instructions sent to ${email}`,
    });
  }

  async getMe(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await authService.getMe(req.user!.id);
      const userJson = user.toJSON();
      res.status(200).json({
        success: true,
        data: userJson,
        ...userJson,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
