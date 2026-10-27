import { Request, Response, NextFunction } from 'express';
import { Error as MongooseError } from 'mongoose';
import { AppError } from '../types';
import logger from '../utils/logger';

interface MongoError extends Error {
  code?: number;
  keyValue?: Record<string, unknown>;
}

interface ValidationErrorItem {
  message: string;
  path: string;
}

export function errorMiddleware(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  logger.error(`Error on ${req.method} ${req.path}:`, err);

  // AppError (operational errors)
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
    return;
  }

  // Mongoose ValidationError
  if (err instanceof MongooseError.ValidationError) {
    const errors: ValidationErrorItem[] = Object.values(err.errors).map((e) => ({
      message: e.message,
      path: e.path,
    }));
    res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors,
    });
    return;
  }

  // Mongoose CastError (invalid ObjectId)
  if (err instanceof MongooseError.CastError) {
    res.status(400).json({
      success: false,
      message: `Invalid value for field: ${err.path}`,
    });
    return;
  }

  // MongoDB Duplicate Key Error
  const mongoErr = err as MongoError;
  if (mongoErr.code === 11000 && mongoErr.keyValue) {
    const field = Object.keys(mongoErr.keyValue)[0];
    res.status(409).json({
      success: false,
      message: `A record with this ${field} already exists`,
    });
    return;
  }

  // JWT Errors
  if (err.name === 'JsonWebTokenError') {
    res.status(401).json({
      success: false,
      message: 'Invalid token',
    });
    return;
  }

  if (err.name === 'TokenExpiredError') {
    res.status(401).json({
      success: false,
      message: 'Token has expired',
    });
    return;
  }

  if (err.name === 'NotBeforeError') {
    res.status(401).json({
      success: false,
      message: 'Token not yet active',
    });
    return;
  }

  // ZodError (from validate middleware — should be caught there, but just in case)
  if (err.name === 'ZodError') {
    res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: JSON.parse(err.message),
    });
    return;
  }

  // Unknown / unhandled errors
  const isDevelopment = process.env['NODE_ENV'] === 'development';
  res.status(500).json({
    success: false,
    message: isDevelopment ? err.message : 'An unexpected error occurred',
    ...(isDevelopment && { stack: err.stack }),
  });
}

export function notFoundMiddleware(req: Request, _res: Response, next: NextFunction): void {
  next(new AppError(`Route not found: ${req.method} ${req.originalUrl}`, 404));
}
