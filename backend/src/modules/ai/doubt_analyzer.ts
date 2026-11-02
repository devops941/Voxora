import { aiProviderManager } from '../../services/ai/AIProviderManager';

interface DoubtParams {
  userId?: string;
  day: number;
  userQuestion: string;
  topic?: string;
}

export interface DoubtAnalysisResult {
  answer: string;
  provider: 'claude' | 'local_engine';
}

/**
 * Intelligent Doubt Analyzer for Voxora MIRA.
 * Provider Hierarchy:
 * 1. Claude (Anthropic) — Primary provider
 * 2. Local Linguistic Engine — Fallback provider
 */
export async function analyzeStudentDoubt(
  params: DoubtParams
): Promise<DoubtAnalysisResult> {
  const result = await aiProviderManager.answerDoubt({
    userQuestion: params.userQuestion,
    day: params.day,
    topic: params.topic,
  });

  return {
    answer: result.data.answer,
    provider: result.provider,
  };
}
