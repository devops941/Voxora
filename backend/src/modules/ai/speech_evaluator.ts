import { LessonAttempt } from '../lessons/lesson_attempt.model';
import mongoose from 'mongoose';
import logger from '../../utils/logger';
import { aiProviderManager, SpeechEvaluationPayload } from '../../services/ai/AIProviderManager';

export interface SpeechEvaluationResult {
  caseType: string;
  original: string;
  corrected: string;
  explanation: string;
  pronunciationTips: string[];
  scores: {
    grammar: number;
    fluency: number;
    pronunciation: number;
    overall: number;
  };
  miraReply: string;
  nextSuggestedQuestion?: string;
  isLessonComplete: boolean;
  provider?: 'claude' | 'local_engine';
}

/**
 * Evaluates spoken submission using centralized AIProviderManager (Claude primary, Local Engine fallback).
 */
export async function evaluateSpokenSubmission(params: {
  userId?: string;
  day: number;
  miraPrompt: string;
  userTranscript: string;
  durationSeconds?: number;
  topic?: string;
  userLevel?: string;
}): Promise<SpeechEvaluationResult> {
  const transcript = (params.userTranscript || '').trim();
  const duration = Math.max(2, params.durationSeconds || 10);
  const topic = params.topic || 'Daily Spoken English';
  const miraPrompt = params.miraPrompt || 'Tell me your thoughts on today’s topic';

  const response = await aiProviderManager.evaluateSpeech({
    topic,
    day: params.day,
    miraPrompt,
    transcript,
    duration,
    userLevel: params.userLevel,
  });

  const evalData = response.data;

  // Persist attempt into MongoDB LessonAttempt asynchronously
  try {
    if (params.userId && mongoose.Types.ObjectId.isValid(params.userId) && evalData.caseType !== 'CASE_F_EMPTY_FAILED') {
      LessonAttempt.create({
        userId: new mongoose.Types.ObjectId(params.userId),
        day: params.day,
        topic,
        exchanges: [
          {
            miraPrompt,
            userAudioTranscript: transcript,
            durationSeconds: duration,
            corrections:
              evalData.corrected !== transcript
                ? [{ original: transcript, corrected: evalData.corrected, explanation: evalData.explanation }]
                : [],
            pronunciationTips: evalData.pronunciationTips,
            scores: evalData.scores,
          },
        ],
        overallScore: evalData.scores.overall,
        timeSpentSeconds: duration,
        isCompleted: true,
        feedbackSummary: evalData.explanation,
      }).catch((err) => logger.warn(`LessonAttempt save notice: ${err?.message || err}`));
    }
  } catch (_) {}

  return {
    ...evalData,
    provider: response.provider,
  };
}
