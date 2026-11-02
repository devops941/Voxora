import Anthropic from '@anthropic-ai/sdk';
import config from './env';

export const anthropicClient =
  config.anthropicApiKey &&
  !config.anthropicApiKey.includes('dummy') &&
  !config.anthropicApiKey.includes('xxxx')
    ? new Anthropic({
        apiKey: config.anthropicApiKey,
        timeout: config.claudeTimeoutMs || 8000,
      })
    : null;

export const CLAUDE_MODEL = config.anthropicModel || 'claude-3-5-haiku-20241022';
export const DEFAULT_MODEL = CLAUDE_MODEL;

export const MAX_TOKENS = {
  chat: 1024,
  feedback: 2048,
  curriculum: 4096,
  assessment: 2048,
};

export default {
  anthropic: anthropicClient,
};
