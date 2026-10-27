import jwt, { SignOptions, JwtPayload } from 'jsonwebtoken';
import config from '../config/env';

export interface TokenPayload {
  id: string;
  email: string;
  role: string;
}

export interface DecodedToken extends JwtPayload {
  id: string;
  email: string;
  role: string;
}

export function generateAccessToken(payload: TokenPayload): string {
  const options: SignOptions = {
    expiresIn: config.jwtExpiresIn as SignOptions['expiresIn'],
  };
  return jwt.sign(payload, config.jwtSecret, options);
}

export function generateRefreshToken(payload: TokenPayload): string {
  const options: SignOptions = {
    expiresIn: config.refreshTokenExpiresIn as SignOptions['expiresIn'],
  };
  return jwt.sign(payload, config.refreshTokenSecret, options);
}

export function verifyAccessToken(token: string): DecodedToken {
  const decoded = jwt.verify(token, config.jwtSecret);
  if (typeof decoded === 'string') {
    throw new Error('Invalid token payload');
  }
  return decoded as DecodedToken;
}

export function verifyRefreshToken(token: string): DecodedToken {
  const decoded = jwt.verify(token, config.refreshTokenSecret);
  if (typeof decoded === 'string') {
    throw new Error('Invalid refresh token payload');
  }
  return decoded as DecodedToken;
}
