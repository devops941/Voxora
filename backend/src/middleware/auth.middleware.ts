import { Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt.utils';
import { AppError, AuthRequest } from '../types';

export function authMiddleware(req: AuthRequest, _res: Response, next: NextFunction): void {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      throw new AppError('Authorization header is missing', 401);
    }

    if (!authHeader.startsWith('Bearer ')) {
      throw new AppError('Authorization header must use Bearer scheme', 401);
    }

    const token = authHeader.slice(7).trim();

    if (!token) {
      throw new AppError('Bearer token is missing', 401);
    }

    const decoded = verifyAccessToken(token);

    req.user = {
      id: decoded.id,
      email: decoded.email,
      role: decoded.role,
    };

    next();
  } catch (error) {
    if (error instanceof AppError) {
      next(error);
      return;
    }

    const err = error as Error;
    if (err.name === 'JsonWebTokenError') {
      next(new AppError('Invalid token', 401));
    } else if (err.name === 'TokenExpiredError') {
      next(new AppError('Token has expired', 401));
    } else if (err.name === 'NotBeforeError') {
      next(new AppError('Token not yet valid', 401));
    } else {
      next(new AppError('Authentication failed', 401));
    }
  }
}

export function requireRole(...roles: string[]) {
  return (req: AuthRequest, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      next(new AppError('Authentication required', 401));
      return;
    }
    if (!roles.includes(req.user.role)) {
      next(new AppError('Insufficient permissions', 403));
      return;
    }
    next();
  };
}
