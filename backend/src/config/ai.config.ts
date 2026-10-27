import Anthropic from '@anthropic-ai/sdk';
import config from './env';

const anthropicClient = new Anthropic({
  apiKey: config.anthropicApiKey,
  defaultHeaders: {
    'anthropic-beta': 'prompt-caching-2024-07-31',
  },
});

export const DEFAULT_MODEL = config.anthropicModel || 'claude-haiku-4-5-20251001';

export const MAX_TOKENS = {
  chat: 1024,
  feedback: 2048,
  curriculum: 4096,
  assessment: 2048,
};

export default anthropicClient;
