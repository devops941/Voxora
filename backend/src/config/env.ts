import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

interface Config {
  port: number;
  mongoUri: string;
  jwtSecret: string;
  jwtExpiresIn: string;
  refreshTokenSecret: string;
  refreshTokenExpiresIn: string;
  anthropicApiKey: string;
  anthropicModel: string;
  nodeEnv: string;
  googleCloudApiKey: string;
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function optionalEnv(name: string, defaultValue: string): string {
  const value = process.env[name];
  return value && value.trim() !== '' ? value.trim() : defaultValue;
}

const config: Config = {
  port: parseInt(optionalEnv('PORT', '3000'), 10),
  mongoUri: requireEnv('MONGO_URI'),
  jwtSecret: requireEnv('JWT_SECRET'),
  jwtExpiresIn: optionalEnv('JWT_EXPIRES_IN', '7d'),
  refreshTokenSecret: requireEnv('REFRESH_TOKEN_SECRET'),
  refreshTokenExpiresIn: optionalEnv('REFRESH_TOKEN_EXPIRES_IN', '30d'),
  anthropicApiKey: requireEnv('ANTHROPIC_API_KEY'),
  anthropicModel: optionalEnv('ANTHROPIC_MODEL', 'claude-haiku-4-5-20251001'),
  nodeEnv: optionalEnv('NODE_ENV', 'development'),
  googleCloudApiKey: optionalEnv('GOOGLE_CLOUD_API_KEY', ''),
};

export default config;
