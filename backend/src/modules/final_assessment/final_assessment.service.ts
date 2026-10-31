import { randomUUID } from 'crypto';
import config from '../../config/env';
import { AppError } from '../../types';
import { User } from '../users/user.model';
import { LearningPlan } from '../curriculum/plan.model';
import { FinalAssessment, IAssessmentQuestion } from './final_assessment.model';
import { anthropicClient, geminiClient, groqClient, CLAUDE_MODEL, GEMINI_MODEL, GROQ_MODEL, MAX_TOKENS } from '../../config/ai.config';
import {
  beginnerSyllabusThemes,
  intermediateSyllabusThemes,
  advancedSyllabusThemes,
} from '../curriculum/curriculum_data';

interface ClientQuestion {
  id: string;
  question: string;
  options: string[];
  marks: number;
}

interface SubmitResult {
  assessmentId: string;
  score: number;
  percentage: number;
  correctAnswers: number;
  totalQuestions: number;
  totalMarks: number;
  status: 'pass' | 'fail';
  level: string;
  isTestMode: boolean;
}

export class FinalAssessmentService {
  async checkEligibility(
    userId: string,
    level: string
  ): Promise<{ eligible: boolean; isTestMode: boolean; reason?: string }> {
    // ── TEST MODE (dev only, never in staging/production) ──────────────────
    if (config.enableFinalAssessmentTestMode) {
      if (config.nodeEnv !== 'development') {
        throw new AppError('Test mode is only available in development environment', 403);
      }
      const user = await User.findById(userId);
      if (!user) throw new AppError('User not found', 404);
      if (user.role !== 'admin' && user.email !== config.devTestAccountEmail) {
        throw new AppError('Test mode is restricted to authorized development accounts', 403);
      }
      return { eligible: true, isTestMode: true };
    }

    // ── NORMAL 90-DAY CHECK (day-lock logic untouched) ─────────────────────
    const plan = await LearningPlan.findOne({ userId });
    if (!plan) {
      return {
        eligible: false,
        isTestMode: false,
        reason: 'No learning plan found. Complete your initial speech assessment first.',
      };
    }
    if (plan.completedDays < 90) {
      return {
        eligible: false,
        isTestMode: false,
        reason: `Complete all 90 days to unlock the Final Assessment (${plan.completedDays}/90 completed).`,
      };
    }
    return { eligible: true, isTestMode: false };
  }

  async generateQuestions(
    level: 'Beginner' | 'Intermediate' | 'Advanced'
  ): Promise<IAssessmentQuestion[]> {
    const themes =
      level === 'Beginner'
        ? beginnerSyllabusThemes
        : level === 'Intermediate'
        ? intermediateSyllabusThemes
        : advancedSyllabusThemes;

    const topicsContext = themes
      .slice(0, 50)
      .map((t) => `- ${t.topic} | Grammar: ${t.grammar} | Vocab: ${t.vocab.slice(0, 4).join(', ')}`)
      .join('\n');

    const systemPrompt =
      'You are an expert English language assessment creator for a spoken English coaching app called Voxora. Generate clear, fair, and practical multiple choice questions.';

    const userPrompt = `Generate exactly 25 multiple choice questions for the ${level} level English speaking course.

Topics covered in this curriculum:
${topicsContext}

STRICT REQUIREMENTS:
- Exactly 25 questions total
- Each question has exactly 4 answer options
- correctAnswerIndex must be 0, 1, 2, or 3 (index into the options array)
- Questions must test: vocabulary usage, grammar correctness, speaking situations, and comprehension appropriate for ${level} level
- Make options plausible but with one clearly correct answer
- Return ONLY a valid JSON array with NO extra text, NO markdown, NO explanation

Required JSON format:
[{"id":"q1","question":"...","options":["...","...","...","..."],"correctAnswerIndex":0},{"id":"q2",...},...]`;

    // Try Claude first
    if (anthropicClient) {
      try {
        const response = await anthropicClient.messages.create({
          model: CLAUDE_MODEL,
          max_tokens: MAX_TOKENS.curriculum,
          system: systemPrompt,
          messages: [{ role: 'user', content: userPrompt }],
        });
        const text =
          response.content[0].type === 'text' ? response.content[0].text : '';
        const parsed = this.parseAndValidateQuestions(text);
        if (parsed) return parsed;
      } catch (err) {
        console.error('[FinalAssessment] Claude generation failed, trying Gemini:', err);
      }
    }

    // Gemini fallback
    if (geminiClient) {
      try {
        const response = await geminiClient.models.generateContent({
          model: GEMINI_MODEL,
          contents: [
            {
              role: 'user',
              parts: [{ text: `${systemPrompt}\n\n${userPrompt}` }],
            },
          ],
          config: { maxOutputTokens: MAX_TOKENS.curriculum },
        });
        const text = response.text ?? '';
        const parsed = this.parseAndValidateQuestions(text);
        if (parsed) return parsed;
      } catch (err) {
        console.error('[FinalAssessment] Gemini generation failed, trying Groq:', err);
      }
    }

    // Groq fallback (free tier, OpenAI-compatible)
    if (groqClient) {
      try {
        const response = await groqClient.chat.completions.create({
          model: GROQ_MODEL,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
          max_tokens: MAX_TOKENS.curriculum,
          temperature: 0.3,
        });
        const text = response.choices[0]?.message?.content ?? '';
        const parsed = this.parseAndValidateQuestions(text);
        if (parsed) return parsed;
      } catch (err) {
        console.error('[FinalAssessment] Groq generation failed:', err);
      }
    }

    // Test mode fallback: use sample questions when AI is unavailable
    if (config.enableFinalAssessmentTestMode && config.nodeEnv === 'development') {
      console.warn('[FinalAssessment] Using mock questions for test mode (AI unavailable)');
      return this.getMockQuestions(level);
    }

    throw new AppError(
      'Failed to generate assessment questions. Please check your AI API keys and try again.',
      500
    );
  }

  private getMockQuestions(level: string): IAssessmentQuestion[] {
    const beginnerQuestions = [
      { q: 'Which sentence is correct?', opts: ['She go to school.', 'She goes to school.', 'She going to school.', 'She gone to school.'], ans: 1 },
      { q: 'Choose the correct article: ___ apple a day keeps the doctor away.', opts: ['A', 'An', 'The', 'No article'], ans: 1 },
      { q: 'What is the plural of "child"?', opts: ['Childs', 'Childes', 'Children', 'Childrens'], ans: 2 },
      { q: 'Choose: She is ___ honest person.', opts: ['a', 'an', 'the', 'some'], ans: 1 },
      { q: 'Which is correct past tense of "go"?', opts: ['Goed', 'Goes', 'Went', 'Gone'], ans: 2 },
      { q: 'What does "hello" mean?', opts: ['Goodbye', 'A greeting', 'Thank you', 'Sorry'], ans: 1 },
      { q: 'Choose the correct word: I ___ a student.', opts: ['is', 'are', 'am', 'be'], ans: 2 },
      { q: '"Good morning" is said:', opts: ['At night', 'In the afternoon', 'In the morning', 'Any time'], ans: 2 },
      { q: 'Which word means the opposite of "big"?', opts: ['Large', 'Huge', 'Small', 'Tall'], ans: 2 },
      { q: 'Complete: "My name ___ Priya."', opts: ['is', 'are', 'am', 'be'], ans: 0 },
      { q: 'Which sentence asks a question?', opts: ['She is happy.', 'Is she happy?', 'She happy.', 'Happy she is.'], ans: 1 },
      { q: 'What is the color of the sky?', opts: ['Green', 'Red', 'Blue', 'Yellow'], ans: 2 },
      { q: 'Choose the correct word: They ___ friends.', opts: ['is', 'am', 'are', 'be'], ans: 2 },
      { q: '"Thank you" is a way to express:', opts: ['Anger', 'Gratitude', 'Sadness', 'Surprise'], ans: 1 },
      { q: 'Which word is a verb?', opts: ['Happy', 'Run', 'Beautiful', 'Quickly'], ans: 1 },
      { q: 'What does "big" mean?', opts: ['Small', 'Fast', 'Large', 'Cold'], ans: 2 },
      { q: 'Choose: I ___ to school every day.', opts: ['go', 'goes', 'going', 'went'], ans: 0 },
      { q: 'Which word describes a person?', opts: ['Run', 'Eat', 'Tall', 'Jump'], ans: 2 },
      { q: '"Excuse me" is used to:', opts: ['Say goodbye', 'Get attention politely', 'Say thank you', 'Start a fight'], ans: 1 },
      { q: 'What is the opposite of "hot"?', opts: ['Warm', 'Cool', 'Cold', 'Boiling'], ans: 2 },
      { q: 'Choose: She ___ milk every morning.', opts: ['drink', 'drinks', 'drank', 'drinking'], ans: 1 },
      { q: 'Which word is a noun?', opts: ['Quickly', 'Beautiful', 'Book', 'Run'], ans: 2 },
      { q: 'Complete: "I ___ from Chennai."', opts: ['is', 'are', 'am', 'be'], ans: 2 },
      { q: '"Sorry" means:', opts: ['I am happy', 'I made a mistake and feel bad', 'Good morning', 'Thank you'], ans: 1 },
      { q: 'Which number comes after 9?', opts: ['8', '11', '10', '7'], ans: 2 },
    ];

    const intermediateQuestions = [
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

    const advancedQuestions = [
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

    const questions = level === 'Beginner'
      ? beginnerQuestions
      : level === 'Intermediate'
      ? intermediateQuestions
      : advancedQuestions;

    return questions.map((item, i) => ({
      id: `q${i + 1}`,
      question: item.q,
      options: item.opts,
      correctAnswerIndex: item.ans,
      marks: 4,
    }));
  }

  private parseAndValidateQuestions(text: string): IAssessmentQuestion[] | null {
    try {
      const jsonMatch = text.match(/\[[\s\S]*\]/);
      if (!jsonMatch) return null;
      const arr = JSON.parse(jsonMatch[0]);
      if (!Array.isArray(arr) || arr.length !== 25) return null;

      const questions: IAssessmentQuestion[] = arr.map((q: any, i: number) => {
        if (!q.question || !Array.isArray(q.options) || q.options.length !== 4) {
          throw new Error(`Invalid question format at index ${i}`);
        }
        const ci = Number(q.correctAnswerIndex);
        if (isNaN(ci) || ci < 0 || ci > 3) {
          throw new Error(`Invalid correctAnswerIndex at index ${i}`);
        }
        return {
          id: q.id || `q${i + 1}`,
          question: String(q.question).trim(),
          options: q.options.map((o: any) => String(o).trim()),
          correctAnswerIndex: ci,
          marks: 4,
        };
      });
      return questions;
    } catch {
      return null;
    }
  }

  async startAssessment(
    userId: string,
    level: 'Beginner' | 'Intermediate' | 'Advanced'
  ): Promise<{ assessmentId: string; questions: ClientQuestion[] }> {
    const { isTestMode } = await this.checkEligibility(userId, level);
    const attemptCount = await FinalAssessment.countDocuments({ userId, level });
    const questions = await this.generateQuestions(level);

    const doc = await FinalAssessment.create({
      userId,
      level,
      questions,
      userAnswers: new Map(),
      score: 0,
      correctAnswers: 0,
      status: 'in_progress',
      attemptNumber: attemptCount + 1,
      isTestMode,
    });

    // Never include correctAnswerIndex in client response
    const clientQuestions: ClientQuestion[] = doc.questions.map((q) => ({
      id: q.id,
      question: q.question,
      options: q.options,
      marks: q.marks,
    }));

    return { assessmentId: doc.id, questions: clientQuestions };
  }

  async submitAssessment(
    userId: string,
    assessmentId: string,
    answers: Record<string, number>
  ): Promise<SubmitResult> {
    const assessment = await FinalAssessment.findOne({ _id: assessmentId, userId });
    if (!assessment) throw new AppError('Assessment not found', 404);
    if (assessment.status !== 'in_progress') {
      throw new AppError('This assessment has already been submitted', 400);
    }

    let correctAnswers = 0;
    assessment.questions.forEach((q) => {
      if (answers[q.id] !== undefined && Number(answers[q.id]) === q.correctAnswerIndex) {
        correctAnswers++;
      }
    });

    const score = correctAnswers * 4; // 4 marks each → max 100
    const status: 'pass' | 'fail' = score >= 65 ? 'pass' : 'fail';

    const answersMap = new Map<string, number>();
    Object.entries(answers).forEach(([k, v]) => answersMap.set(k, Number(v)));

    assessment.userAnswers = answersMap;
    assessment.score = score;
    assessment.correctAnswers = correctAnswers;
    assessment.status = status;
    assessment.submittedAt = new Date();
    await assessment.save();

    return {
      assessmentId: assessment.id,
      score,
      percentage: score,
      correctAnswers,
      totalQuestions: 25,
      totalMarks: 100,
      status,
      level: assessment.level,
      isTestMode: assessment.isTestMode,
    };
  }

  async getAttempts(userId: string, level: string) {
    const filter: any = { userId };
    if (level && ['Beginner', 'Intermediate', 'Advanced'].includes(level)) {
      filter.level = level;
    }
    const attempts = await FinalAssessment.find(filter)
      .sort({ createdAt: -1 })
      .lean();

    return attempts.map((a) => ({
      id: a._id?.toString(),
      level: a.level,
      score: a.score,
      percentage: a.score,
      correctAnswers: a.correctAnswers,
      status: a.status,
      attemptNumber: a.attemptNumber,
      isTestMode: a.isTestMode,
      submittedAt: a.submittedAt,
    }));
  }
}

export const finalAssessmentService = new FinalAssessmentService();
