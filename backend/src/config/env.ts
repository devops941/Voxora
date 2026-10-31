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
  geminiApiKey: string;
  geminiModel: string;
  groqApiKey: string;
  groqModel: string;
  nodeEnv: string;
  googleCloudApiKey: string;
  googleClientId: string;
  smtpHost: string;
  smtpPort: number;
  smtpSecure: boolean;
  smtpUser: string;
  smtpPass: string;
  smtpFrom: string;
  smtpTo: string;
  enableFinalAssessmentTestMode: boolean;
  devTestAccountEmail: string;
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
  anthropicApiKey: optionalEnv('ANTHROPIC_API_KEY', ''),
  anthropicModel: optionalEnv('ANTHROPIC_MODEL', 'claude-haiku-4-5-20251001'),
  geminiApiKey: optionalEnv('GEMINI_API_KEY', ''),
  geminiModel: optionalEnv('GEMINI_MODEL', 'gemini-2.5-flash'),
  groqApiKey: optionalEnv('GROQ_API_KEY', ''),
  groqModel: optionalEnv('GROQ_MODEL', 'llama-3.3-70b-versatile'),
  nodeEnv: optionalEnv('NODE_ENV', 'development'),
  googleCloudApiKey: optionalEnv('GOOGLE_CLOUD_API_KEY', ''),
  googleClientId: optionalEnv('GOOGLE_CLIENT_ID', ''),
  smtpHost: optionalEnv('SMTP_HOST', 'smtp.gmail.com'),
  smtpPort: parseInt(optionalEnv('SMTP_PORT', '465'), 10),
  smtpSecure: optionalEnv('SMTP_SECURE', 'true') === 'true',
  smtpUser: optionalEnv('SMTP_USER', ''),
  smtpPass: optionalEnv('SMTP_PASS', ''),
  smtpFrom: optionalEnv('SMTP_FROM', ''),
  smtpTo: optionalEnv('SMTP_TO', ''),
  enableFinalAssessmentTestMode: optionalEnv('ENABLE_FINAL_ASSESSMENT_TEST_MODE', 'false') === 'true',
  devTestAccountEmail: optionalEnv('DEV_TEST_ACCOUNT_EMAIL', ''),
};

export default config;
