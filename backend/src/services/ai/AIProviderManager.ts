import Anthropic from '@anthropic-ai/sdk';
import config from '../../config/env';
import logger from '../../utils/logger';
import { IAssessmentQuestion } from '../../modules/final_assessment/final_assessment.model';
import {
  beginnerSyllabusThemes,
  intermediateSyllabusThemes,
  advancedSyllabusThemes,
} from '../../modules/curriculum/curriculum_data';

export interface AIResponse<T> {
  success: boolean;
  data: T;
  provider: 'claude' | 'local_engine';
  latencyMs: number;
  model?: string;
  note?: string;
}

export interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export interface ChatResult {
  message: string;
  suggestedReplies: string[];
}

export interface FeedbackBreakdown {
  grammar: { score: number; feedback: string };
  pronunciation: { score: number; tips: string[] };
  fluency: { score: number; wpm: number; observation: string };
  vocabulary: { score: number; suggestedWords: string[] };
  sentenceFormation: { score: number; advice: string };
  overallScore: number;
  strengths: string[];
  weaknesses: string[];
  suggestions: string[];
}

export interface SpeechEvaluationPayload {
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
}

export interface DoubtAnswer {
  answer: string;
  relatedTips?: string[];
}

export interface InitialSpeechAssessment {
  scores: {
    fluency: number;
    pronunciation: number;
    grammar: number;
    vocabulary: number;
    overall: number;
  };
  recommendedLevel: 'Beginner' | 'Intermediate' | 'Advanced';
  levelBadge: string;
  wpm: number;
  wordCount: number;
  diagnosis: {
    strength: string;
    focusArea: string;
    feedbackSummary: string;
  };
}

type ProviderStatus = 'healthy' | 'degraded' | 'cooling_down';

export class AIProviderManager {
  private client: Anthropic | null = null;
  private modelName: string;
  private status: ProviderStatus = 'healthy';
  private lastFailureTime = 0;
  private consecutiveFailures = 0;
  private readonly cooldownMs: number;
  private readonly timeoutMs: number;
  private lastErrorMessage = '';

  constructor() {
    this.modelName = config.anthropicModel || 'claude-3-5-haiku-20241022';
    this.cooldownMs = config.claudeCooldownMs || 60000;
    this.timeoutMs = config.claudeTimeoutMs || 8000;
    this.initClient();
  }

  private initClient(): void {
    const key = config.anthropicApiKey || process.env.ANTHROPIC_API_KEY || '';
    if (key && key.trim().length > 10 && !key.includes('dummy') && !key.includes('xxxx')) {
      try {
        this.client = new Anthropic({
          apiKey: key.trim(),
          timeout: this.timeoutMs,
        });
        this.status = 'healthy';
        logger.info(`🤖 [AIProviderManager] Primary provider Claude initialized (Model: ${this.modelName})`);
      } catch (err: any) {
        logger.warn(`[AIProviderManager] Claude client initialization error: ${err?.message || err}`);
        this.client = null;
        this.status = 'degraded';
      }
    } else {
      logger.warn('⚠️ [AIProviderManager] Anthropic API key not provided or placeholder. Operating in Local Engine fallback mode.');
      this.client = null;
      this.status = 'degraded';
    }
  }

  /**
   * Evaluates if Claude is ready to be attempted or is currently within cooling down window.
   */
  private isClaudeAvailable(): boolean {
    if (!this.client) return false;

    if (this.status === 'cooling_down') {
      const elapsed = Date.now() - this.lastFailureTime;
      if (elapsed >= this.cooldownMs) {
        logger.info(
          `🔄 [AIProviderManager] Claude cooldown window elapsed (${Math.round(elapsed / 1000)}s). Attempting automatic recovery to Claude Primary...`
        );
        // Do not permanently switch: test probe on this next request
        return true;
      }
      return false;
    }

    return true;
  }

  /**
   * Categorizes errors to distinguish billing/quota limits from transient network issues.
   */
  private isBillingOrQuotaError(err: any): boolean {
    const status = err?.status || err?.statusCode || 0;
    const msg = (err?.message || '').toLowerCase();
    const type = (err?.error?.type || '').toLowerCase();

    return (
      status === 402 ||
      (status === 400 && (msg.includes('credit') || msg.includes('balance') || msg.includes('billing') || type.includes('credit'))) ||
      status === 429 ||
      msg.includes('rate limit') ||
      msg.includes('quota') ||
      msg.includes('insufficient_quota') ||
      msg.includes('exhausted')
    );
  }

  /**
   * Registers a Claude failure, updates health metrics, and activates cooldown.
   */
  private handleClaudeFailure(err: any): void {
    this.consecutiveFailures++;
    this.lastFailureTime = Date.now();
    this.lastErrorMessage = err?.message || String(err);
    this.status = 'cooling_down';

    const isBilling = this.isBillingOrQuotaError(err);
    const category = isBilling ? 'BILLING/QUOTA LIMIT EXHAUSTED' : 'SERVICE/NETWORK ERROR';

    logger.warn(
      `⚠️ [AIProviderManager: Fallback Triggered] Claude Primary failed [${category}]: ${this.lastErrorMessage.substring(0, 160)}. Switching to Local Engine fallback for ${Math.round(this.cooldownMs / 1000)}s.`
    );
  }

  /**
   * Registers successful Claude response, resetting failure tracking and recovering primary status.
   */
  private handleClaudeSuccess(): void {
    if (this.status === 'cooling_down' || this.consecutiveFailures > 0) {
      logger.info(
        `✅ [AIProviderManager: Claude Recovered] Claude primary responded successfully! Consecutive failure count reset. Claude restored as PRIMARY.`
      );
    }
    this.status = 'healthy';
    this.consecutiveFailures = 0;
    this.lastErrorMessage = '';
  }

  /**
   * Internal helper to execute a Claude completion with automatic retry for transient errors.
   */
  private async executeClaude(
    systemPrompt: string,
    messages: Array<{ role: 'user' | 'assistant'; content: string }>,
    maxTokens = 1024,
    temperature = 0.3
  ): Promise<string> {
    if (!this.client) {
      throw new Error('Claude client is not initialized');
    }

    let attempts = 0;
    const maxAttempts = 2; // 1 initial + 1 retry for transient errors
    let lastErr: any;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        const response = await this.client.messages.create({
          model: this.modelName,
          max_tokens: maxTokens,
          temperature,
          system: systemPrompt,
          messages,
        });

        const block = response.content?.[0];
        if (block && block.type === 'text') {
          this.handleClaudeSuccess();
          return block.text.trim();
        }
        throw new Error('Claude returned an empty response block');
      } catch (err: any) {
        lastErr = err;
        // Do not retry on billing or auth errors
        if (this.isBillingOrQuotaError(err) || err?.status === 401 || err?.status === 403) {
          break;
        }
        if (attempts < maxAttempts) {
          logger.info(`[AIProviderManager] Retrying transient Claude error in 500ms...`);
          await new Promise((res) => setTimeout(res, 500));
        }
      }
    }

    this.handleClaudeFailure(lastErr);
    throw lastErr;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. AI CHAT (Conversational spoken English practice)
  // ═════════════════════════════════════════════════════════════════════════

  async chat(params: {
    message: string;
    context?: Array<{ role: 'user' | 'assistant'; content: string }>;
    level?: string;
  }): Promise<AIResponse<ChatResult>> {
    const startTime = Date.now();
    const rawMessage = (params.message || '').trim();
    const level = params.level || 'Beginner';

    if (!rawMessage) {
      return {
        success: true,
        data: {
          message: "Hello! I am MIRA, your AI English coach. Speak to me about your day, practice conversation, or ask any question!",
          suggestedReplies: ["How can I introduce myself?", "Can we practice everyday greetings?", "Tell me about today's lesson"],
        },
        provider: 'local_engine',
        latencyMs: Date.now() - startTime,
      };
    }

    // Try Claude Primary
    if (this.isClaudeAvailable()) {
      try {
        const systemPrompt = `You are MIRA, an encouraging, friendly, and expert AI spoken English coach on the Voxora app.
The learner's level is ${level}.
GUIDELINES:
1. Reply in 2-4 conversational, natural, and warm sentences.
2. If the student made a grammar or wording slip, gently show the natural spoken version without making them feel bad.
3. Keep the conversation going by asking an open-ended follow-up question.
4. Conclude with 2 short suggested reply options formatted as:
[SUGGESTIONS]
- Suggestion 1
- Suggestion 2`;

        const messages: Array<{ role: 'user' | 'assistant'; content: string }> = [
          ...(params.context || []).slice(-6),
          { role: 'user', content: rawMessage },
        ];

        const rawReply = await this.executeClaude(systemPrompt, messages, 400, 0.4);

        let replyText = rawReply;
        const suggestedReplies: string[] = [];

        if (rawReply.includes('[SUGGESTIONS]')) {
          const parts = rawReply.split('[SUGGESTIONS]');
          replyText = parts[0].trim();
          const lines = parts[1].split('\n').map((l) => l.replace(/^[-*•0-9.]\s*/, '').trim()).filter(Boolean);
          suggestedReplies.push(...lines.slice(0, 3));
        }

        if (suggestedReplies.length === 0) {
          suggestedReplies.push("Tell me more about that", "Can you give me an example?", "What should I say next?");
        }

        logger.info(`✨ [AI Provider: Claude (Primary)] Generated chat response in ${Date.now() - startTime}ms`);
        return {
          success: true,
          data: { message: replyText, suggestedReplies },
          provider: 'claude',
          model: this.modelName,
          latencyMs: Date.now() - startTime,
        };
      } catch (claudeErr: any) {
        logger.warn(`Routing chat request to Local Engine fallback...`);
      }
    }

    // Fallback: Local Linguistic Engine
    logger.info(`🧠 [AI Provider: Local Engine (Fallback)] Generating local chat response`);
    const localData = this.generateLocalChatResponse(rawMessage, level);
    return {
      success: true,
      data: localData,
      provider: 'local_engine',
      latencyMs: Date.now() - startTime,
      note: 'Processed via intelligent local conversation engine (Claude primary cooling down)',
    };
  }

  private generateLocalChatResponse(message: string, level: string): ChatResult {
    const lower = message.toLowerCase().trim();

    // Check common conversation starters
    if (lower.includes('hello') || lower.includes('hi') || lower.includes('hey')) {
      return {
        message: "Hello there! I'm MIRA, your AI English coach. I'm excited to practice English with you today! How was your day so far?",
        suggestedReplies: [
          "My day was great, thank you!",
          "I had a busy workday today.",
          "I want to practice my self-introduction.",
        ],
      };
    }

    if (lower.includes('how are you')) {
      return {
        message: "I am feeling wonderful and ready to help you practice! How about you? How are you feeling today?",
        suggestedReplies: [
          "I am feeling happy and energetic!",
          "A little tired, but eager to learn English.",
          "Could you teach me some workplace vocabulary?",
        ],
      };
    }

    if (lower.includes('introduce') || lower.includes('name is') || lower.includes('from')) {
      return {
        message: "It is wonderful to meet you! Introducing yourself with confidence is the most valuable speaking skill. What are your favorite hobbies or goals?",
        suggestedReplies: [
          "I enjoy reading and listening to music.",
          "I want to speak fluently in job interviews.",
          "I like traveling to new cities.",
        ],
      };
    }

    if (lower.includes('weather')) {
      return {
        message: "Talking about the weather is classic English small talk! Is it sunny, pleasant, or rainy where you are right now?",
        suggestedReplies: [
          "It is quite sunny and warm here.",
          "It's raining cats and dogs today!",
          "The weather is very pleasant this evening.",
        ],
      };
    }

    // Default supportive conversational response
    return {
      message: `That's very interesting! Practicing spoken English every day like this builds natural fluency. Can you tell me a little bit more about that?`,
      suggestedReplies: [
        "Sure, let me elaborate on that.",
        "Could you check if my grammar was correct?",
        "What is another way to say that naturally?",
      ],
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. DETAILED AI FEEDBACK (Full diagnostic breakdown)
  // ═════════════════════════════════════════════════════════════════════════

  async getFeedback(params: {
    transcript: string;
    question?: string;
    topic?: string;
    day?: number;
    durationSeconds?: number;
  }): Promise<AIResponse<FeedbackBreakdown>> {
    const startTime = Date.now();
    const transcript = (params.transcript || '').trim();
    const duration = Math.max(3, params.durationSeconds || 10);
    const words = transcript.split(/\s+/).filter(Boolean);
    const wpm = Math.round((words.length / duration) * 60);

    if (this.isClaudeAvailable()) {
      try {
        const systemPrompt = `You are MIRA, a Senior Spoken English Evaluator on Voxora.
Evaluate the user's spoken English response.
Return ONLY a valid JSON object with NO surrounding markdown or text:
{
  "grammar": { "score": 85, "feedback": "Clear explanation" },
  "pronunciation": { "score": 88, "tips": ["Tip 1", "Tip 2"] },
  "fluency": { "score": 80, "wpm": ${wpm}, "observation": "Natural pacing with minimal pauses" },
  "vocabulary": { "score": 82, "suggestedWords": ["word1", "word2"] },
  "sentenceFormation": { "score": 85, "advice": "Strong subject-verb alignment" },
  "overallScore": 84,
  "strengths": ["Clear pronunciation", "Good vocabulary"],
  "weaknesses": ["Preposition usage in time phrases"],
  "suggestions": ["Practice linking words smoothly"]
}`;

        const userPrompt = `Topic: "${params.topic || 'Spoken English'}"
Question: "${params.question || 'Speaking Practice'}"
Student Transcript: "${transcript}"
Duration: ${duration} seconds (${wpm} WPM).`;

        const reply = await this.executeClaude(
          systemPrompt,
          [{ role: 'user', content: userPrompt }],
          1200,
          0.2
        );

        const jsonMatch = reply.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0]);
          if (parsed.grammar && parsed.pronunciation && parsed.overallScore) {
            logger.info(`✨ [AI Provider: Claude (Primary)] Generated personalized feedback in ${Date.now() - startTime}ms`);
            return {
              success: true,
              data: parsed,
              provider: 'claude',
              model: this.modelName,
              latencyMs: Date.now() - startTime,
            };
          }
        }
      } catch (err: any) {
        logger.warn(`Routing feedback request to Local Engine fallback...`);
      }
    }

    // Fallback: Local Linguistic Engine
    logger.info(`🧠 [AI Provider: Local Engine (Fallback)] Generating local feedback evaluation`);
    const localFeedback = this.generateLocalFeedback(transcript, wpm, params.topic);
    return {
      success: true,
      data: localFeedback,
      provider: 'local_engine',
      latencyMs: Date.now() - startTime,
      note: 'Generated via intelligent linguistic heuristics (Claude primary cooling down)',
    };
  }

  private generateLocalFeedback(transcript: string, wpm: number, topic?: string): FeedbackBreakdown {
    const words = transcript.split(/\s+/).filter(Boolean);
    const count = words.length;

    // Rule-based heuristic scoring
    let fluencyScore = 80;
    if (wpm >= 90 && wpm <= 140) fluencyScore = 90;
    else if (wpm < 60) fluencyScore = Math.max(50, 60 + count);
    else if (wpm > 170) fluencyScore = 75;

    let grammarScore = 82;
    const lower = transcript.toLowerCase();
    const mistakes: string[] = [];

    if (lower.includes('did went') || lower.includes('did saw') || lower.includes("didn't came")) {
      grammarScore -= 12;
      mistakes.push("Remember: use base verb after 'did' (e.g. 'did go', not 'did went')");
    }
    if (lower.includes('myself ')) {
      grammarScore -= 8;
      mistakes.push("Say 'I am [Name]' or 'My name is...' instead of 'Myself [Name]'");
    }
    if (lower.includes('is have') || lower.includes('are have')) {
      grammarScore -= 10;
      mistakes.push("Avoid combining 'is/are' with 'have'");
    }

    let vocabScore = 78;
    const advancedVocab = ['confident', 'perspective', 'articulate', 'essential', 'challenge', 'progress', 'fluent'];
    const usedAdvanced = words.filter((w) => advancedVocab.includes(w.toLowerCase()));
    vocabScore += Math.min(15, usedAdvanced.length * 5);

    const pronScore = count > 5 ? 85 : 70;
    const sentenceScore = count >= 6 ? 84 : 68;
    const overallScore = Math.round((fluencyScore + grammarScore + pronScore + vocabScore + sentenceScore) / 5);

    return {
      grammar: {
        score: grammarScore,
        feedback: mistakes.length > 0 ? mistakes[0] : 'Solid grammatical structure and tense consistency.',
      },
      pronunciation: {
        score: pronScore,
        tips: [
          'Articulate ending consonants clearly (e.g. -ed, -s, -t).',
          'Maintain steady breath control between spoken clauses.',
        ],
      },
      fluency: {
        score: fluencyScore,
        wpm,
        observation:
          wpm >= 85 && wpm <= 135
            ? 'Optimal conversational pace with natural flow.'
            : wpm < 85
            ? 'A bit slow; practice speaking with continuous rhythm without mid-sentence pauses.'
            : 'Fast pace; slow down slightly to give every syllable clarity.',
      },
      vocabulary: {
        score: vocabScore,
        suggestedWords: ['Articulate', 'Spontaneous', 'Persuasive', 'Consistent'],
      },
      sentenceFormation: {
        score: sentenceScore,
        advice: count >= 6 ? 'Good subject-verb-object arrangement.' : 'Try expanding your ideas into complete multi-clause sentences.',
      },
      overallScore,
      strengths: [
        count > 5 ? 'Expressive sentence length' : 'Good vocal attempt',
        fluencyScore >= 80 ? 'Steady conversational cadence' : 'Clear speech effort',
      ],
      weaknesses: mistakes.length > 0 ? mistakes : ['Varied transitional connectors (e.g. however, furthermore)'],
      suggestions: [
        'Practice reading English sentences aloud for 5 minutes daily.',
        'Record and listen back to your pronunciation of multi-syllable words.',
      ],
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. VOICE LESSON SPEECH EVALUATION (During interactive speaking practice)
  // ═════════════════════════════════════════════════════════════════════════

  async evaluateSpeech(params: {
    topic: string;
    day: number;
    miraPrompt: string;
    transcript: string;
    duration: number;
    userLevel?: string;
  }): Promise<AIResponse<SpeechEvaluationPayload>> {
    const startTime = Date.now();
    const transcript = (params.transcript || '').trim();
    const duration = Math.max(2, params.duration || 10);
    const words = transcript.split(/\s+/).filter(Boolean);
    const wpm = Math.round((words.length / duration) * 60);

    // Empty or inaudible guard
    if (words.length === 0 || transcript.toLowerCase() === '[inaudible]') {
      return {
        success: true,
        data: {
          caseType: 'CASE_F_EMPTY_FAILED',
          original: transcript,
          corrected: '',
          explanation: 'No clear spoken words were detected by the microphone.',
          pronunciationTips: ['Hold your phone closer and speak in a clear, audible tone.'],
          scores: { grammar: 0, fluency: 0, pronunciation: 0, overall: 0 },
          miraReply: "I couldn't hear your voice clearly. Tap the microphone and speak your thoughts aloud to MIRA!",
          nextSuggestedQuestion: params.miraPrompt,
          isLessonComplete: false,
        },
        provider: 'local_engine',
        latencyMs: Date.now() - startTime,
      };
    }

    if (this.isClaudeAvailable()) {
      try {
        const prompt = `You are MIRA, the AI spoken English coach on the Voxora app.
A learner on Day ${params.day} (Topic: "${params.topic}") was asked:
Question: "${params.miraPrompt}"
Learner's spoken response:
"${transcript}"
Pacing: ${wpm} WPM over ${duration} seconds.

Evaluate the response objectively. Return ONLY a valid JSON object:
{
  "caseType": "CASE_A_CORRECT",
  "original": "${transcript.replace(/"/g, '\\"')}",
  "corrected": "<grammatically correct and natural version>",
  "explanation": "<1-2 sentence precise explanation or praise>",
  "pronunciationTips": ["<1 actionable pronunciation/articulation tip>"],
  "scores": {
    "grammar": 88,
    "fluency": 86,
    "pronunciation": 88,
    "overall": 87
  },
  "miraReply": "<2 warm, encouraging conversational sentences from MIRA to the student responding to their answer and asking a follow-up>",
  "isLessonComplete": true
}`;

        const reply = await this.executeClaude(
          'You are an expert spoken English coach. Evaluate the speech objectively and return strictly JSON.',
          [{ role: 'user', content: prompt }],
          600,
          0.2
        );

        const match = reply.match(/\{[\s\S]*\}/);
        if (match) {
          const parsed = JSON.parse(match[0]);
          if (parsed.scores && parsed.miraReply) {
            logger.info(`✨ [AI Provider: Claude (Primary)] Evaluated spoken response in ${Date.now() - startTime}ms`);
            return {
              success: true,
              data: {
                caseType: parsed.caseType || 'CASE_A_CORRECT',
                original: transcript,
                corrected: parsed.corrected || transcript,
                explanation: parsed.explanation || 'Great articulation!',
                pronunciationTips: Array.isArray(parsed.pronunciationTips) && parsed.pronunciationTips.length > 0
                  ? parsed.pronunciationTips
                  : ['Speak with steady pacing and articulate word endings clearly.'],
                scores: {
                  grammar: Math.min(98, Math.max(45, Math.round(parsed.scores.grammar || 85))),
                  fluency: Math.min(98, Math.max(45, Math.round(parsed.scores.fluency || 85))),
                  pronunciation: Math.min(98, Math.max(45, Math.round(parsed.scores.pronunciation || 85))),
                  overall: Math.min(98, Math.max(45, Math.round(parsed.scores.overall || 85))),
                },
                miraReply: parsed.miraReply,
                isLessonComplete: true,
              },
              provider: 'claude',
              model: this.modelName,
              latencyMs: Date.now() - startTime,
            };
          }
        }
      } catch (err: any) {
        logger.warn(`Routing speech evaluation to Local Engine fallback...`);
      }
    }

    // Local Engine Fallback (Rich rule-based evaluator)
    logger.info(`🧠 [AI Provider: Local Engine (Fallback)] Running local speech evaluation`);
    const localResult = this.generateLocalSpeechEvaluation(params.topic, params.day, params.miraPrompt, transcript, duration, wpm);
    return {
      success: true,
      data: localResult,
      provider: 'local_engine',
      latencyMs: Date.now() - startTime,
    };
  }

  private generateLocalSpeechEvaluation(
    topic: string,
    day: number,
    miraPrompt: string,
    transcript: string,
    duration: number,
    wpm: number
  ): SpeechEvaluationPayload {
    const words = transcript.split(/\s+/).filter(Boolean);
    const count = words.length;

    let grammarScore = 85;
    let fluencyScore = wpm >= 80 && wpm <= 140 ? 90 : Math.max(55, 75);
    let pronScore = 85;
    let corrected = transcript;
    let explanation = 'Well articulated and clearly communicated!';

    // Basic heuristic corrections
    const lower = transcript.toLowerCase();
    if (lower.includes('i am come from')) {
      corrected = transcript.replace(/i am come from/i, 'I come from');
      explanation = "Say 'I come from' instead of 'I am come from'.";
      grammarScore -= 10;
    } else if (lower.includes('myself ')) {
      corrected = transcript.replace(/myself /i, 'I am ');
      explanation = "Introduce yourself with 'I am...' or 'My name is...'";
      grammarScore -= 8;
    }

    const overall = Math.round((grammarScore + fluencyScore + pronScore) / 3);

    return {
      caseType: grammarScore < 80 ? 'CASE_B_GRAMMAR_MISTAKE' : 'CASE_A_CORRECT',
      original: transcript,
      corrected,
      explanation,
      pronunciationTips: [
        'Maintain an open throat posture and articulate vowels distinctly.',
        'Keep a calm, steady rhythm without rushing syllables.',
      ],
      scores: {
        grammar: grammarScore,
        fluency: fluencyScore,
        pronunciation: pronScore,
        overall,
      },
      miraReply: `Wonderful attempt! You expressed your thoughts on "${topic}" with genuine effort. With daily practice, your speaking cadence will become completely natural!`,
      isLessonComplete: true,
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. STUDENT DOUBT RESOLUTION (Questions asked to MIRA)
  // ═════════════════════════════════════════════════════════════════════════

  async answerDoubt(params: {
    userQuestion: string;
    day: number;
    topic?: string;
  }): Promise<AIResponse<DoubtAnswer>> {
    const startTime = Date.now();
    const rawQ = (params.userQuestion || '').trim();

    if (!rawQ) {
      return {
        success: true,
        data: {
          answer: "Please ask any question about today's lesson, grammar, pronunciation, or vocabulary! I'm here to help you speak with confidence.",
        },
        provider: 'local_engine',
        latencyMs: Date.now() - startTime,
      };
    }

    if (this.isClaudeAvailable()) {
      try {
        const systemPrompt =
          'You are MIRA, an expert spoken English coach on the Voxora app. Answer student doubts in 2-4 concise, warm, practical sentences. Always include at least one clear everyday example sentence with a speaking tip.';
        const userPrompt = `Student on Day ${params.day} (Topic: "${params.topic || 'Spoken English'}") asks: "${rawQ}". Explain clearly with examples.`;

        const reply = await this.executeClaude(
          systemPrompt,
          [{ role: 'user', content: userPrompt }],
          350,
          0.3
        );

        if (reply && reply.trim()) {
          logger.info(`✨ [AI Provider: Claude (Primary)] Answered doubt in ${Date.now() - startTime}ms`);
          return {
            success: true,
            data: { answer: reply.trim() },
            provider: 'claude',
            model: this.modelName,
            latencyMs: Date.now() - startTime,
          };
        }
      } catch (err: any) {
        logger.warn(`Routing doubt analysis to Local Engine fallback...`);
      }
    }

    // Local Engine Fallback (Deep linguistic offline rules)
    logger.info(`🧠 [AI Provider: Local Engine (Fallback)] Answering doubt with Local Linguistic Engine`);
    const offlineExplanation = this.generateLocalDoubtAnswer(rawQ, params.day, params.topic);
    return {
      success: true,
      data: { answer: offlineExplanation },
      provider: 'local_engine',
      latencyMs: Date.now() - startTime,
    };
  }

  private generateLocalDoubtAnswer(question: string, day: number, topic?: string): string {
    const lower = question.toLowerCase();

    if (lower.includes('say') && lower.includes('tell')) {
      return 'The main rule: You "say" something, but you "tell" someone! For example: "He said that he was busy", but "He told me that he was busy". Practice: "Don\'t say lies; always tell me the truth."';
    }
    if (lower.includes('went') && (lower.includes('gone') || lower.includes('have gone'))) {
      return 'Use "went" when the action happened at a specific past time ("I went yesterday"). Use "have gone" when someone has left and is not back yet ("She has gone to the office"). Repeat: "I went yesterday, but she has already gone!"';
    }
    if (lower.includes('hear') && lower.includes('listen')) {
      return '"Hear" is passive—your ears catch sound naturally ("Did you hear that?"). "Listen" is active conscious attention ("Listen to MIRA carefully"). Practice: "I can hear you, and I am listening attentively!"';
    }
    if (lower.includes('since') && lower.includes('for')) {
      return 'Use "since" for a specific starting point in time: "since 2020", "since Monday". Use "for" for a duration or period of time: "for 2 hours", "for 5 years". Say aloud: "I have been learning English for 3 months, since January!"';
    }
    if (lower.includes('in') && lower.includes('on') && lower.includes('at')) {
      return 'For time: "At" is for clock times ("at 5 PM"), "On" is for days/dates ("on Monday"), "In" is for months/years ("in May", "in 2026"). For places: "At" is a point, "On" is a surface, and "In" is an enclosed area.';
    }
    if (lower.includes('did') && (lower.includes('went') || lower.includes('saw') || lower.includes('came'))) {
      return 'Golden Rule: After "did" or "didn\'t", always use the base verb (V1)! Never say "Did you went?", say "Did you go?". Never say "I didn\'t saw", say "I didn\'t see".';
    }

    return `In English, clarity and natural pacing matter most. For "${question}", focus on keeping your sentences simple, subject-verb aligned, and practicing the phrase aloud two to three times!`;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 5. FINAL ASSESSMENT QUESTIONS GENERATION (Exactly 25 questions per level)
  // ═════════════════════════════════════════════════════════════════════════

  async generateFinalAssessmentQuestions(
    level: 'Beginner' | 'Intermediate' | 'Advanced'
  ): Promise<AIResponse<IAssessmentQuestion[]>> {
    const startTime = Date.now();

    if (this.isClaudeAvailable()) {
      try {
        const themes =
          level === 'Beginner'
            ? beginnerSyllabusThemes
            : level === 'Intermediate'
            ? intermediateSyllabusThemes
            : advancedSyllabusThemes;

        const topicsContext = themes
          .slice(0, 40)
          .map((t) => `- ${t.topic} | Grammar: ${t.grammar} | Vocab: ${t.vocab.slice(0, 3).join(', ')}`)
          .join('\n');

        const systemPrompt =
          'You are an expert English language assessment creator for Voxora. Generate clear, practical multiple choice questions testing spoken English competence.';

        const userPrompt = `Generate exactly 25 multiple choice questions for the ${level} level English speaking course.
Topics covered:
${topicsContext}

STRICT REQUIREMENTS:
- Exactly 25 questions
- Each question has exactly 4 options
- correctAnswerIndex must be 0, 1, 2, or 3
- Return ONLY a valid JSON array with NO markdown, NO backticks:
[
  { "id": "q1", "question": "...", "options": ["A", "B", "C", "D"], "correctAnswerIndex": 1, "marks": 4 }
]`;

        const reply = await this.executeClaude(
          systemPrompt,
          [{ role: 'user', content: userPrompt }],
          3500,
          0.3
        );

        const match = reply.match(/\[[\s\S]*\]/);
        if (match) {
          const parsed = JSON.parse(match[0]);
          if (Array.isArray(parsed) && parsed.length === 25) {
            const formatted: IAssessmentQuestion[] = parsed.map((q, i) => ({
              id: q.id || `q${i + 1}`,
              question: String(q.question).trim(),
              options: q.options.map((o: any) => String(o).trim()),
              correctAnswerIndex: Number(q.correctAnswerIndex),
              marks: 4,
            }));

            logger.info(`✨ [AI Provider: Claude (Primary)] Generated 25 fresh final assessment questions for ${level}`);
            return {
              success: true,
              data: formatted,
              provider: 'claude',
              model: this.modelName,
              latencyMs: Date.now() - startTime,
            };
          }
        }
      } catch (err: any) {
        logger.warn(`Routing final assessment generation to Local Engine fallback...`);
      }
    }

    // Local Engine Fallback (Vetted 25 questions per level)
    logger.info(`🧠 [AI Provider: Local Engine (Fallback)] Loading 25 curated assessment questions for ${level}`);
    const localQuestions = this.getLocalAssessmentQuestions(level);
    return {
      success: true,
      data: localQuestions,
      provider: 'local_engine',
      latencyMs: Date.now() - startTime,
    };
  }

  private getLocalAssessmentQuestions(level: 'Beginner' | 'Intermediate' | 'Advanced'): IAssessmentQuestion[] {
    const beginnerList = [
      { q: 'Which is the correct greeting in the morning?', opts: ['Good evening', 'Good night', 'Good morning', 'Goodbye'], ans: 2 },
      { q: 'How do you introduce yourself professionally?', opts: ['Myself is Alex', 'My name is Alex', 'I Alex', 'Me is Alex'], ans: 1 },
      { q: 'Choose the correct sentence:', opts: ['I am lives in Chennai.', 'I live in Chennai.', 'I living in Chennai.', 'I lives in Chennai.'], ans: 1 },
      { q: 'What is the opposite of "fluent"?', opts: ['Confident', 'Hesitant', 'Fast', 'Clear'], ans: 1 },
      { q: 'Which word describes a family member?', opts: ['Colleague', 'Sibling', 'Stranger', 'Neighbor'], ans: 1 },
      { q: 'Complete: "She ___ to the office every morning."', opts: ['go', 'goes', 'going', 'gone'], ans: 1 },
      { q: 'What is the correct way to ask for the time?', opts: ['What is the time?', 'Time what is?', 'Where is time?', 'Who is the time?'], ans: 0 },
      { q: 'Which word means having no doubts or fear when speaking?', opts: ['Nervous', 'Confident', 'Silent', 'Afraid'], ans: 1 },
      { q: 'Complete: "They ___ watching a movie."', opts: ['is', 'are', 'am', 'be'], ans: 1 },
      { q: 'Which sentence is in the past tense?', opts: ['I walk to work.', 'I will walk to work.', 'I walked to work.', 'I am walking.'], ans: 2 },
      { q: 'What do you say when you leave someone?', opts: ['Hello', 'Goodbye', 'Welcome', 'Please'], ans: 1 },
      { q: 'Choose: "He does not ___ coffee."', opts: ['likes', 'like', 'liked', 'liking'], ans: 1 },
      { q: 'Which phrase is used when asking for help politely?', opts: ['Help me now!', 'Could you please help me?', 'You must help!', 'Give help.'], ans: 1 },
      { q: '"I have a question" is used to:', opts: ['Ask something', 'Say goodbye', 'Apologize', 'Introduce a friend'], ans: 0 },
      { q: 'Which day comes after Tuesday?', opts: ['Monday', 'Wednesday', 'Thursday', 'Friday'], ans: 1 },
      { q: 'Choose the correct article: "She is ___ engineer."', opts: ['a', 'an', 'the', 'no article'], ans: 1 },
      { q: 'Complete: "We ___ hungry."', opts: ['am', 'is', 'are', 'be'], ans: 2 },
      { q: 'Which word is a food item?', opts: ['Laptop', 'Breakfast', 'Pencil', 'Desk'], ans: 1 },
      { q: 'What does "daily routine" mean?', opts: ['Things you do once a year', 'Things you do every day', 'Things you never do', 'A weekend trip'], ans: 1 },
      { q: 'Complete: "He ___ a car."', opts: ['have', 'has', 'having', 'is have'], ans: 1 },
      { q: 'Which sentence expresses gratitude?', opts: ['Excuse me', 'Thank you very much', 'Where is it?', 'No problem'], ans: 1 },
      { q: 'Choose: "Yesterday, I ___ my friend."', opts: ['meet', 'met', 'meeting', 'meets'], ans: 1 },
      { q: 'What do you say when entering a shop politely?', opts: ['Hello, I am looking for...', 'Give me that!', 'Why are you here?', 'Stop talking.'], ans: 0 },
      { q: '"Sorry" means:', opts: ['I am happy', 'I made a mistake and feel bad', 'Good morning', 'Thank you'], ans: 1 },
      { q: 'Which number comes after 9?', opts: ['8', '11', '10', '7'], ans: 2 },
    ];

    const intermediateList = [
      { q: '"Could you please repeat that?" is used to:', opts: ['End a conversation', 'Ask for clarification', 'Give an opinion', 'Introduce yourself'], ans: 1 },
      { q: 'Which word is a synonym for "confident"?', opts: ['Nervous', 'Shy', 'Assured', 'Confused'], ans: 2 },
      { q: 'Complete: "I ___ studying English for two years."', opts: ['am', 'was', 'have been', 'will be'], ans: 2 },
      { q: 'Which phrase is used to politely disagree?', opts: ['I totally agree!', "That is wrong!", 'I see your point, but...', 'You are right.'], ans: 2 },
      { q: '"Wrap up" means:', opts: ['Open something', 'Finish or conclude', 'Start a meeting', 'Take a break'], ans: 1 },
      { q: 'Which sentence uses the present perfect correctly?', opts: ['I have went to London.', 'I have gone to London.', 'I has gone to London.', 'I have go to London.'], ans: 1 },
      { q: 'Choose the right preposition: She is good ___ speaking English.', opts: ['in', 'on', 'at', 'by'], ans: 2 },
      { q: 'Which is correct? "Neither of the students ___ prepared."', opts: ['are', 'were', 'was', 'is'], ans: 2 },
      { q: 'Choose: "He suggested ___ to the doctor."', opts: ['go', 'going', 'to going', 'gone'], ans: 1 },
      { q: '"Cut to the chase" means:', opts: ['Run faster', 'Get to the main point', 'Chase someone', 'Stop talking'], ans: 1 },
      { q: 'Which is a formal way to start an email?', opts: ['Hey!', 'Sup!', 'Dear Sir/Madam,', 'Yo,'], ans: 2 },
      { q: '"Could I take a message?" is said when:', opts: ['Starting a call', 'Ending a call', 'The person is unavailable', 'Answering a question'], ans: 2 },
      { q: 'Choose the best response to "How are you?"', opts: ['I am fine, thank you!', 'I am a student.', 'Yes, please.', 'Never mind.'], ans: 0 },
      { q: 'Which tense is used for habits?', opts: ['Past simple', 'Present simple', 'Future tense', 'Past perfect'], ans: 1 },
      { q: '"Get the hang of" means:', opts: ['Hold tightly', 'Learn to do something well', 'Give up', 'Start over'], ans: 1 },
      { q: 'Choose: "By the time she arrived, he ___ left."', opts: ['has', 'have', 'had', 'was'], ans: 2 },
      { q: 'Which word means to convince someone?', opts: ['Hesitate', 'Persuade', 'Articulate', 'Elaborate'], ans: 1 },
      { q: '"Spontaneous" speech means:', opts: ['Memorized speech', 'Natural and unplanned speech', 'Slow speech', 'Loud speech'], ans: 1 },
      { q: 'Choose the conditional: "If it rains, I ___ stay home."', opts: ['will', 'would', 'should', 'shall'], ans: 0 },
      { q: 'Which is passive voice?', opts: ['She wrote the letter.', 'The letter was written by her.', 'She is writing.', 'She writes letters.'], ans: 1 },
      { q: '"I look forward to hearing from you" is used in:', opts: ['Casual text', 'Formal emails', 'Greeting cards', 'Social media'], ans: 1 },
      { q: 'Choose: "Neither the manager nor the employees ___ happy."', opts: ['is', 'are', 'was', 'were'], ans: 1 },
      { q: 'What does "elaborate" mean?', opts: ['Simplify', 'Explain in detail', 'Argue', 'Interrupt'], ans: 1 },
      { q: 'Which conjunction shows contrast?', opts: ['And', 'Because', 'Although', 'Since'], ans: 2 },
      { q: '"Touch base" in a workplace means:', opts: ['Physical contact', 'Brief check-in or update', 'Argue with someone', 'Start a project'], ans: 1 },
    ];

    const advancedList = [
      { q: '"Eloquent" means:', opts: ['Speaking poorly', 'Speaking clearly and persuasively', 'Speaking very fast', 'Speaking in a whisper'], ans: 1 },
      { q: 'What does "articulate" mean as an adjective?', opts: ['Speaks quickly', 'Expresses ideas clearly and fluently', 'Speaks quietly', 'Speaks formally'], ans: 1 },
      { q: 'Choose the subjunctive: "I wish she ___ here."', opts: ['is', 'are', 'was', 'were'], ans: 3 },
      { q: '"Perspicacious" means:', opts: ['Tired', 'Having sharp mental perception', 'Overly emotional', 'Physically strong'], ans: 1 },
      { q: 'Which sentence uses inversion correctly?', opts: ['Never I have seen such skill.', 'Never have I seen such skill.', 'I have never seen such skill.', 'Such skill never I have seen.'], ans: 1 },
      { q: '"Obfuscate" means:', opts: ['To clarify', 'To make unclear or confusing', 'To emphasize', 'To summarize'], ans: 1 },
      { q: 'Choose the correct form: "Had she known, she ___ come."', opts: ['would', 'would have', 'will have', 'should'], ans: 1 },
      { q: '"Juxtaposition" in speech means:', opts: ['Repeating ideas', 'Placing contrasting ideas side by side', 'Using simple vocabulary', 'Avoiding detail'], ans: 1 },
      { q: 'Which rhetorical device repeats a word at the start of clauses?', opts: ['Metaphor', 'Simile', 'Anaphora', 'Hyperbole'], ans: 2 },
      { q: '"Circumlocution" means:', opts: ['Direct speech', 'Using many words when fewer would do', 'Silent communication', 'Formal writing'], ans: 1 },
      { q: 'Choose the correct gerund/infinitive: "She avoided ___ eye contact."', opts: ['make', 'to make', 'making', 'made'], ans: 2 },
      { q: '"Pragmatic competence" in language refers to:', opts: ['Grammar accuracy', 'Vocabulary size', 'Ability to use language appropriately in context', 'Pronunciation clarity'], ans: 2 },
      { q: 'Which is an example of hedging language?', opts: ['It definitely is true.', 'It seems that this might be true.', 'This is false.', 'Clearly this is correct.'], ans: 1 },
      { q: '"Nuanced" argument means:', opts: ['Simple and direct', 'Showing subtle distinctions', 'Emotional and passionate', 'Brief and vague'], ans: 1 },
      { q: 'Choose: "The data ___ inconclusive." (formal academic)', opts: ['is', 'are', 'was', 'were'], ans: 1 },
      { q: '"Vernacular" means:', opts: ['Formal written language', 'The everyday language of ordinary people', 'Technical jargon', 'Ancient vocabulary'], ans: 1 },
      { q: 'Which discourse marker signals a conclusion?', opts: ['Furthermore', 'However', 'Therefore', 'Nevertheless'], ans: 2 },
      { q: '"Mitigate" means:', opts: ['To worsen', 'To make less severe', 'To ignore', 'To celebrate'], ans: 1 },
      { q: 'Choose correct reported speech: She said "I will come." →', opts: ['She said she will come.', 'She said she would come.', 'She said she comes.', 'She said she had come.'], ans: 1 },
      { q: '"Tenacious" means:', opts: ['Easily giving up', 'Holding firmly to something', 'Speaking softly', 'Being confused'], ans: 1 },
      { q: 'Which sentence has a dangling modifier?', opts: ['Running fast, he won the race.', 'Running fast, the race was won.', 'He won the race by running fast.', 'The race was won by him.'], ans: 1 },
      { q: '"Paradigm shift" means:', opts: ['Small improvement', 'Fundamental change in approach', 'Statistical analysis', 'Team meeting'], ans: 1 },
      { q: 'Choose the most formal synonym of "show":', opts: ['Display', 'Demonstrate', 'Exhibit', 'Manifest'], ans: 3 },
      { q: '"Cognitive dissonance" in communication means:', opts: ['Clear thinking', 'Mental discomfort from conflicting beliefs', 'Excellent memory', 'Rapid speech'], ans: 1 },
      { q: 'Which advanced connector shows unexpected result?', opts: ['Moreover', 'Consequently', 'Nevertheless', 'Similarly'], ans: 2 },
    ];

    const source = level === 'Beginner' ? beginnerList : level === 'Intermediate' ? intermediateList : advancedList;
    return source.map((item, i) => ({
      id: `q${i + 1}`,
      question: item.q,
      options: item.opts,
      correctAnswerIndex: item.ans,
      marks: 4,
    }));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 6. HEALTH & STATUS
  // ═════════════════════════════════════════════════════════════════════════

  getStatus(): {
    primaryProvider: string;
    model: string;
    status: ProviderStatus;
    consecutiveFailures: number;
    lastFailureTime: number;
    cooldownRemainingMs: number;
    lastError: string;
  } {
    const elapsed = Date.now() - this.lastFailureTime;
    const cooldownRemaining = this.status === 'cooling_down' ? Math.max(0, this.cooldownMs - elapsed) : 0;

    return {
      primaryProvider: 'Claude (Anthropic)',
      model: this.modelName,
      status: this.status,
      consecutiveFailures: this.consecutiveFailures,
      lastFailureTime: this.lastFailureTime,
      cooldownRemainingMs: cooldownRemaining,
      lastError: this.lastErrorMessage,
    };
  }
}

export const aiProviderManager = new AIProviderManager();

