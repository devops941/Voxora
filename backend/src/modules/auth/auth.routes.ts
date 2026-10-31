import { Router } from 'express';
import { z } from 'zod';
import { authController } from './auth.controller';
import { validate } from '../../middleware/validate.middleware';
import { authMiddleware } from '../../middleware/auth.middleware';

const router = Router();

const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Please enter a valid email address'),
  phone: z.string().optional(),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  level: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().min(1, 'Email or mobile number is required'),
  password: z.string().min(1, 'Password is required'),
});

const googleAuthSchema = z
  .object({
    email: z.string().email('Please enter a valid Google email address').optional(),
    name: z.string().optional(),
    googleId: z.string().optional(),
    avatarUrl: z.string().optional().nullable(),
    idToken: z.string().optional(),
  })
  .refine((data) => (data.idToken && data.idToken.trim().length > 0) || (data.email && data.email.trim().length > 0), {
    message: 'Google idToken or valid email is required',
  });

router.post('/register', validate(registerSchema), (req, res, next) =>
  authController.register(req, res, next)
);

router.post('/login', validate(loginSchema), (req, res, next) =>
  authController.login(req, res, next)
);

router.post('/google', validate(googleAuthSchema), (req, res, next) =>
  authController.googleLogin(req, res, next)
);

router.post('/refresh', (req, res, next) =>
  authController.refreshToken(req, res, next)
);

router.post('/logout', (req, res) =>
  authController.logout(req, res)
);

router.post('/forgot-password', (req, res, next) =>
  authController.forgotPassword(req, res, next)
);

router.post('/verify-otp', (req, res, next) =>
  authController.verifyOtp(req, res, next)
);

router.post('/reset-password', (req, res, next) =>
  authController.resetPassword(req, res, next)
);

router.get('/me', authMiddleware, (req, res, next) =>
  authController.getMe(req, res, next)
);

export default router;
