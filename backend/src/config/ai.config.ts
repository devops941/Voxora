import Anthropic from '@anthropic-ai/sdk';
import { GoogleGenAI } from '@google/genai';
import config from './env';

export const anthropicClient = config.anthropicApiKey && !config.anthropicApiKey.includes('dummy')
  ? new Anthropic({
      apiKey: config.anthropicApiKey,
      timeout: 5000,
    })
  : null;

function buildGeminiClient(key: string): InstanceType<typeof GoogleGenAI> {
  // AQ... keys are the new Google AI Studio format — use Bearer auth instead of x-goog-api-key
  if (key.startsWith('AQ')) {
    return new GoogleGenAI({
      httpOptions: {
        headers: { 'Authorization': `Bearer ${key}` },
      },
    });
  }
  return new GoogleGenAI({ apiKey: key });
}

export const geminiClient = config.geminiApiKey && !config.geminiApiKey.includes('dummy')
  ? buildGeminiClient(config.geminiApiKey)
  : null;

export const CLAUDE_MODEL = config.anthropicModel || 'claude-3-5-haiku-20241022';
export const GEMINI_MODEL = config.geminiModel || 'gemini-2.5-flash';
export const DEFAULT_MODEL = CLAUDE_MODEL;

export const MAX_TOKENS = {
  chat: 1024,
  feedback: 2048,
  curriculum: 4096,
  assessment: 2048,
};

export default {
  anthropic: anthropicClient,
  gemini: geminiClient,
};
