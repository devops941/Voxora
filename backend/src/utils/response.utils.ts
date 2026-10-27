import { Response } from 'express';
import { ApiResponse } from '../types';

export function successResponse<T>(
  res: Response,
  data: T,
  message: string = 'Success',
  statusCode: number = 200
): Response {
  const response: ApiResponse<T> = {
    success: true,
    message,
    data,
  };
  return res.status(statusCode).json(response);
}

export function errorResponse(
  res: Response,
  message: string,
  statusCode: number = 500,
  errors?: Record<string, string>[]
): Response {
  const response: ApiResponse<null> = {
    success: false,
    message,
    data: null,
    ...(errors && { errors }),
  };
  return res.status(statusCode).json(response);
}

export function createdResponse<T>(res: Response, data: T, message: string = 'Created successfully'): Response {
  return successResponse(res, data, message, 201);
}

export function noContentResponse(res: Response): Response {
  return res.status(204).send();
}
