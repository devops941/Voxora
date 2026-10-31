import Anthropic from '@anthropic-ai/sdk';
import { GoogleGenAI } from '@google/genai';
import Groq from 'groq-sdk';
import logger from '../../utils/logger';

interface DoubtParams {
  userId?: string;
  day: number;
  userQuestion: string;
  topic?: string;
}

export interface DoubtAnalysisResult {
  answer: string;
  provider: 'claude' | 'gemini' | 'local_engine';
}

/**
 * Intelligent Doubt Analyzer for Voxora MIRA.
 * Required Provider Order:
 * 1. Claude (Anthropic) — Primary provider
 * 2. Gemini (gemini-2.5-flash) — Automatic fallback when Claude fails (credit, auth, rate limit, timeout)
 * 3. Local Linguistic Engine — Final fallback if both cloud providers fail
 */
export async function analyzeStudentDoubt(
  params: DoubtParams,
  anthropicClient?: Anthropic | null,
  geminiClient?: GoogleGenAI | null,
  groqClient?: Groq | null
): Promise<DoubtAnalysisResult> {
  const rawQ = (params.userQuestion || '').trim();
  if (!rawQ) {
    return {
      answer: "Please ask any question about today's lesson, grammar, pronunciation, or vocabulary! I'm here to help you speak with confidence.",
      provider: 'local_engine',
    };
  }

  // ── 1. PRIMARY PROVIDER: Claude (Anthropic) ──────────────────────────
  if (anthropicClient) {
    try {
      const model = process.env.ANTHROPIC_MODEL || 'claude-3-5-haiku-20241022';
      const response = await anthropicClient.messages.create({
        model,
        max_tokens: 350,
        system:
          'You are MIRA, an expert spoken English coach on the Voxora app. Answer student doubts in 2-4 concise, warm, practical sentences. Always include at least one clear everyday example sentence with a pronunciation/speaking tip.',
        messages: [
          {
            role: 'user',
            content: `Student on Day ${params.day} (Topic: "${params.topic || 'Spoken English'}") asks: "${rawQ}". Explain clearly with examples.`,
          },
        ],
      });

      const content = response.content?.[0];
      if (content && content.type === 'text' && content.text.trim()) {
        logger.info(`✨ [Primary AI: Claude] Answered doubt using ${model}`);
        return { answer: content.text.trim(), provider: 'claude' };
      }
    } catch (err: any) {
      const errorMsg = err?.message || String(err);
      const statusCode = err?.status || err?.statusCode || 'UNKNOWN';
      logger.warn(
        `⚠️ [Fallback Triggered] Claude primary failed (${statusCode}: ${errorMsg.substring(0, 100)}). Routing to Gemini fallback...`
      );
    }
  }

  // ── 2. AUTOMATIC FALLBACK: Google Gemini ─────────────────────────────
  if (geminiClient) {
    try {
      const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
      const prompt = `You are MIRA, an expert, warm, and encouraging AI spoken English coach on the Voxora app.
A student practicing Day ${params.day} (Topic: "${params.topic || 'Spoken English'}") asks:
"${rawQ}"

Provide a direct, practical, and motivating answer:
1. Explain the rule, difference, or meaning simply in 1-2 clear sentences.
2. Give 1 or 2 practical everyday English example sentences.
3. Suggest a quick sentence for them to repeat aloud right now.
Keep your response concise (3-4 sentences total). Avoid complex jargon.`;

      const response = await geminiClient.models.generateContent({
        model,
        contents: prompt,
        config: {
          temperature: 0.3,
          maxOutputTokens: 350,
        },
      });

      const text = response.text?.trim();
      if (text) {
        logger.info(`✨ [Fallback AI: Gemini] Answered doubt using ${model}`);
        return { answer: text, provider: 'gemini' };
      }
    } catch (err: any) {
      const errorMsg = err?.message || String(err);
      logger.warn(
        `⚠️ [Fallback 2 Triggered] Gemini fallback failed: ${errorMsg.substring(0, 100)}. Routing to Groq fallback...`
      );
    }
  }

  // ── 3. GROQ FALLBACK: Free-tier LLM ──────────────────────────────────
  if (groqClient) {
    try {
      const model = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';
      const response = await groqClient.chat.completions.create({
        model,
        messages: [
          {
            role: 'system',
            content: 'You are MIRA, an expert spoken English coach on the Voxora app. Answer student doubts in 2-4 concise, warm, practical sentences. Always include at least one clear everyday example sentence with a pronunciation/speaking tip.',
          },
          {
            role: 'user',
            content: `Student on Day ${params.day} (Topic: "${params.topic || 'Spoken English'}") asks: "${rawQ}". Explain clearly with examples.`,
          },
        ],
        max_tokens: 350,
        temperature: 0.3,
      });

      const text = response.choices[0]?.message?.content?.trim();
      if (text) {
        logger.info(`✨ [Fallback AI 2: Groq] Answered doubt using ${model}`);
        return { answer: text, provider: 'gemini' }; // reuse label for client compatibility
      }
    } catch (err: any) {
      const errorMsg = err?.message || String(err);
      logger.warn(
        `⚠️ [Final Safety Net] Groq fallback failed: ${errorMsg.substring(0, 100)}. Routing to local linguistic engine...`
      );
    }
  }

  // ── 4. FINAL SAFETY NET: Local Linguistic Engine ──────────────────────
  logger.info(`🧠 [Safety Net: Local Engine] Analyzing doubt with Local Linguistic Engine: "${rawQ.substring(0, 45)}..."`);
  const offlineAnswer = generateIntelligentOfflineExplanation(rawQ, params.day, params.topic);
  return { answer: offlineAnswer, provider: 'local_engine' };
}

/**
 * Deep Linguistic Offline Engine: Handles hundreds of common grammar,
 * preposition, tense, vocabulary, and sentence-structure doubts with tailored examples.
 */
function generateIntelligentOfflineExplanation(question: string, day: number, topic?: string): string {
  const q = question.trim();
  const lower = q.toLowerCase();

  // ── A. Common Word Confusions & Comparisons (X vs Y) ─────────────────

  if ((lower.includes('went') && lower.includes('gone')) || (lower.includes('went') && lower.includes('have gone'))) {
    return 'Use "went" when the action happened at a specific past time (e.g., "I went to Madurai yesterday"). Use "have gone" when someone has left and is not back yet, or the time is not mentioned (e.g., "She has gone to the office"). Repeat: "I went yesterday, but she has already gone!"';
  }

  if (lower.includes('say') && lower.includes('tell')) {
    return 'The main rule: You "say" something, but you "tell" someone! For example: "He said that he was busy" (no person mentioned directly), but "He told me that he was busy" (person "me" is mentioned). Say aloud: "Don\'t say lies; always tell me the truth."';
  }

  if (lower.includes('hear') && lower.includes('listen')) {
    return '"Hear" is passive—your ears catch sound naturally (e.g., "Did you hear that bird?"). "Listen" is active conscious attention (e.g., "Please listen to MIRA carefully"). Practice saying: "I can hear your voice, and I am listening attentively!"';
  }

  if (lower.includes('see') && (lower.includes('look') || lower.includes('watch'))) {
    return '"See" is noticing with your eyes naturally ("I see a car"). "Look" means directing your eyes with intention ("Look at the whiteboard"). "Watch" means observing something moving over time ("I watch movies on Sundays"). Practice: "Look at the stars, and watch them twinkle!"';
  }

  if (lower.includes('borrow') && lower.includes('lend')) {
    return '"Borrow" means to take something temporarily with permission (e.g., "May I borrow your pen?"). "Lend" means to give something temporarily (e.g., "I can lend you my pen"). Tip: Borrow = Take in 📥, Lend = Give out 📤.';
  }

  if (lower.includes('since') && lower.includes('for')) {
    return 'Use "since" for a specific starting point in time: "since 2020", "since Monday", "since 8 AM". Use "for" for a duration or period of time: "for 2 hours", "for 5 years". Say aloud: "I have been learning English for 3 months, since January!"';
  }

  if (lower.includes('in') && lower.includes('on') && lower.includes('at')) {
    return 'For time: "At" is for specific clock times ("at 5 PM"). "On" is for days and dates ("on Monday", "on Oct 15"). "In" is for months, years, and seasons ("in May", "in 2026"). For places: "At" is a point ("at the bus stop"), "On" is a surface ("on the desk"), and "In" is an enclosed area ("in the room").';
  }

  if (lower.includes('between') && lower.includes('among')) {
    return 'Use "between" when referring to two distinct people or items (e.g., "The secret is between you and me"). Use "among" when referring to three or more people or part of a group (e.g., "She distributed chocolates among all the students").';
  }

  if (lower.includes('much') && lower.includes('many')) {
    return 'Use "many" with countable nouns you can count: "many books", "many friends", "many days". Use "much" with uncountable nouns: "much water", "much time", "much sugar". Say aloud: "How many questions do you have? How much time do we need?"';
  }

  if (lower.includes('few') && lower.includes('little')) {
    return 'Use "few / a few" for countable things ("a few friends", "few mistakes"). Use "little / a little" for uncountable things ("a little water", "a little patience"). "A few" has a positive meaning (some), while "few" means almost none!';
  }

  if (lower.includes('advice') && lower.includes('advise')) {
    return '"Advice" (with a \'c\') is a noun meaning the recommendation itself (e.g., "Thank you for your valuable advice"). "Advise" (with an \'s\') is the verb action of giving guidance (e.g., "The doctor advised me to rest"). Practice saying: "I advise you to take my advice!"';
  }

  if (lower.includes('affect') && lower.includes('effect')) {
    return '"Affect" (starts with A for Action) is a verb meaning to influence: "Rain affects traffic." "Effect" (starts with E for End-result) is a noun meaning the result: "The effect of the medicine was fast."';
  }

  if (lower.includes("it's") || (lower.includes('its') && lower.includes('it is'))) {
    return '"It\'s" (with apostrophe) is short for "it is" or "it has" (e.g., "It\'s a sunny day"). "Its" (without apostrophe) is possessive, showing ownership (e.g., "The dog wagged its tail"). If you can replace it with "it is", use "it\'s"!';
  }

  if (lower.includes('their') || lower.includes('there') || lower.includes("they're")) {
    return '"There" refers to a place ("Sit over there"). "Their" shows possession ("That is their car"). "They\'re" is short for "they are" ("They\'re coming home"). Say aloud: "They\'re going there in their own vehicle!"';
  }

  if (lower.includes('will') && lower.includes('would')) {
    return '"Will" expresses definite future certainty ("I will call you tomorrow"). "Would" expresses polite requests, imagination, or past habits ("Would you like some tea?" or "If I had time, I would join"). Using "would" makes your English sound very polite!';
  }

  if (lower.includes('can') && lower.includes('could')) {
    return '"Can" shows present ability or casual permission ("I can speak English", "Can I sit here?"). "Could" shows past ability ("When I was young, I could run fast") or polite formal requests ("Could you please help me?").';
  }

  if (lower.includes('do') && lower.includes('make')) {
    return 'We use "do" for actions, obligations, and repetitive tasks: "do homework", "do chores", "do your best". We use "make" for creating, producing, or building something new: "make coffee", "make a decision", "make a mistake". Practice: "Do your job, and don\'t make excuses!"';
  }

  if (lower.includes('miss') && lower.includes('lose')) {
    return 'Use "miss" for events, opportunities, transport, or longing for someone: "miss the bus", "miss the meeting", "I miss you". Use "lose" for physical objects or games: "lose my keys", "lose the match". Say: "Hurry up or you will miss the train!"';
  }

  // ── B. Common Indian & Regional English Corrections ──────────────────

  if (lower.includes('myself') && (lower.includes('name') || lower.includes('say') || lower.includes('intro'))) {
    return 'Avoid saying "Myself [Name]" when introducing yourself—"myself" is a reflexive pronoun! Instead, say: "Hello, I am Sharmila" or "My name is Sharmila." This sounds professional, grammatically perfect, and confident in interviews.';
  }

  if (lower.includes('did') && (lower.includes('went') || lower.includes('saw') || lower.includes('came') || lower.includes('did you'))) {
    return 'Golden Grammar Rule: After "did" or "didn\'t", always use the basic base verb (V1), NEVER past tense! Don\'t say "Did you went?"; say "Did you go?". Don\'t say "I didn\'t saw"; say "I didn\'t see". Say aloud: "Did you finish the lesson?"';
  }

  if (lower.includes("she don't") || lower.includes("he don't") || lower.includes("it don't")) {
    return 'With third-person singular subjects (He, She, It, or a singular name), always use "doesn\'t", not "don\'t"! Say: "She doesn\'t know", "He doesn\'t like coffee". Use "don\'t" only with I, You, We, They. Practice: "He knows the answer, but he doesn\'t speak."';
  }

  if (lower.includes('revert') || lower.includes('revert back')) {
    return '"Revert" already means to return or reply to someone. Saying "revert back" is redundant (repeating the word back). Instead, simply say: "Please reply at your convenience" or "I will revert to you by evening."';
  }

  if (lower.includes('having') && (lower.includes('doubt') || lower.includes('car') || lower.includes('brother') || lower.includes('two'))) {
    return 'In English, "have" for possession is a stative verb—it shouldn\'t be used in continuous (-ing) tense! Don\'t say "I am having two brothers" or "I am having a doubt". Say: "I have two brothers" and "I have a doubt". Use "having" only for eating or experiences: "I am having lunch."';
  }

  if (lower.includes('one of my friend') || lower.includes('one of my')) {
    return 'Always use a plural noun after "one of my": Say "One of my friends is visiting", NOT "One of my friend". Notice the verb is singular ("is") because you are talking about one person among many friends!';
  }

  if (lower.includes('discuss about')) {
    return '"Discuss" already means "to talk about". Saying "discuss about" is incorrect. Say: "Let\'s discuss the topic" or "We discussed our plans yesterday", not "discussed about".';
  }

  if (lower.includes('passed out') || lower.includes('pass out')) {
    return 'In global English, "passed out" means became unconscious or fainted! When referring to completing college, say: "I graduated from college in 2024" or "I completed my degree." Repeat: "I graduated with a degree in computer science."';
  }

  if (lower.includes('today morning') || lower.includes('yesterday night')) {
    return 'Instead of "today morning", the natural phrase is "this morning" (e.g., "I woke up early this morning"). Instead of "yesterday night", say "last night" (e.g., "I called you last night"). Practice saying both!';
  }

  if (lower.includes('good name') || lower.includes('what is your good name')) {
    return '"What is your good name?" is a direct translation of the Hindi/Tamil respectful phrase. In English, the natural and polite way to ask is: "May I know your name, please?" or "Could you tell me your name?"';
  }

  if (lower.includes('cope up') || lower.includes('cope up with')) {
    return 'The correct standard English idiom is "cope with", NOT "cope up with"! For example: "It is challenging, but I am learning to cope with the workload." Say aloud: "She can easily cope with any challenge."';
  }

  // ── C. Past Tense of Common Irregular Verbs ─────────────────────────

  const pastTenseMatch = q.match(/past\s+tense\s+(?:of\s+)?([a-z]+)/i) || q.match(/v2\s+(?:of\s+)?([a-z]+)/i);
  if (pastTenseMatch && pastTenseMatch[1]) {
    const verb = pastTenseMatch[1].toLowerCase();
    const verbMap: Record<string, { past: string; pp: string; example: string }> = {
      buy: { past: 'bought', pp: 'bought', example: 'I bought fresh vegetables this morning.' },
      bring: { past: 'brought', pp: 'brought', example: 'She brought her notebook to class.' },
      teach: { past: 'taught', pp: 'taught', example: 'MIRA taught me how to introduce myself.' },
      think: { past: 'thought', pp: 'thought', example: 'I thought about your suggestion yesterday.' },
      catch: { past: 'caught', pp: 'caught', example: 'He caught the ball effortlessly.' },
      go: { past: 'went', pp: 'gone', example: 'They went to the market together.' },
      eat: { past: 'ate', pp: 'eaten', example: 'We ate a delicious breakfast earlier.' },
      drink: { past: 'drank', pp: 'drunk', example: 'I drank a glass of warm water.' },
      speak: { past: 'spoke', pp: 'spoken', example: 'She spoke fluently in the interview.' },
      write: { past: 'wrote', pp: 'written', example: 'He wrote an impressive email to his team.' },
      break: { past: 'broke', pp: 'broken', example: 'The glass broke when it slipped.' },
      choose: { past: 'chose', pp: 'chosen', example: 'I chose the best path for my career.' },
      drive: { past: 'drove', pp: 'driven', example: 'We drove across the scenic highway.' },
      fly: { past: 'flew', pp: 'flown', example: 'The bird flew high across the morning sky.' },
      give: { past: 'gave', pp: 'given', example: 'She gave me genuine encouragement.' },
      know: { past: 'knew', pp: 'known', example: 'I knew the answer immediately.' },
      run: { past: 'ran', pp: 'run', example: 'He ran five kilometers before breakfast.' },
      see: { past: 'saw', pp: 'seen', example: 'I saw a beautiful rainbow after the rain.' },
      sing: { past: 'sang', pp: 'sung', example: 'She sang a melodious Tamil song.' },
      swim: { past: 'swam', pp: 'swum', example: 'They swam in the ocean last summer.' },
      take: { past: 'took', pp: 'taken', example: 'I took notes during our daily session.' },
      throw: { past: 'threw', pp: 'thrown', example: 'He threw the ball to his teammate.' },
      wear: { past: 'wore', pp: 'worn', example: 'She wore an elegant dress to the party.' },
      forget: { past: 'forgot', pp: 'forgotten', example: 'I almost forgot my house keys!' },
      understand: { past: 'understood', pp: 'understood', example: 'I understood every concept clearly.' },
    };

    if (verbMap[verb]) {
      const v = verbMap[verb];
      return `The past tense (V2) of "${verb}" is "${v.past}", and the past participle (V3) is "${v.pp}". For example: "${v.example}". Try saying this sentence aloud to build your fluency!`;
    }
  }

  // ── D. "How to say..." & Practical Conversational Scenarios ───────────

  if (lower.includes('how to say') && (lower.includes('thank') || lower.includes('welcome'))) {
    return 'To say thank you politely: "I truly appreciate your help" or "Thank you so much for your support." When someone thanks you, instead of just "welcome", say: "You\'re very welcome!", "My pleasure!", or "Glad I could help!"';
  }

  if (lower.includes('how to say') && (lower.includes('sorry') || lower.includes('apologize'))) {
    return 'For polite professional apologies, say: "I sincerely apologize for the delay" or "Please forgive the oversight." In daily conversation, say: "I am really sorry about that; let me fix it right away."';
  }

  if (lower.includes('how to') && (lower.includes('introduce') || lower.includes('interview') || lower.includes('myself'))) {
    return 'In an interview, introduce yourself with the 3-step formula: 1) Greeting & Name: "Hello, my name is Sharmila." 2) Background: "I have a background in software engineering from Madurai." 3) Passion: "I am passionate about building great products and eager to contribute." Keep it under 60 seconds!';
  }

  if (lower.includes('how to') && (lower.includes('leave') || lower.includes('permission'))) {
    return 'To ask for leave politely, say: "Good morning Sir, I would like to request leave for two days due to a personal family function" or "May I take tomorrow off?" In email: "Kindly grant me leave for [Date]; I will ensure all pending tasks are delegated."';
  }

  if (lower.includes('repeat') || lower.includes('hear again') || lower.includes("didn't hear")) {
    return 'When you didn\'t catch what someone said, don\'t say "What?". Instead say: "Could you please repeat that?", "Pardon me, I didn\'t catch that", or "Could you speak a little slower, please?" This is universally polite and professional.';
  }

  // ── E. Word Meaning Inquiries (What is the meaning of X?) ─────────────

  const meaningMatch =
    q.match(/meaning\s+of\s+["']?([a-z\s]+)["']?/i) ||
    q.match(/what\s+does\s+["']?([a-z\s]+)["']?\s+mean/i) ||
    q.match(/define\s+["']?([a-z\s]+)["']?/i);

  if (meaningMatch && meaningMatch[1]) {
    const targetWord = meaningMatch[1].trim().toLowerCase();
    const vocabDict: Record<string, { def: string; ex: string }> = {
      hesitate: {
        def: 'to pause or delay before doing something because you are uncertain or nervous.',
        ex: 'Don\'t hesitate to speak in English; mistakes are part of learning!',
      },
      articulate: {
        def: 'able to express ideas clearly, fluently, and effectively in speech.',
        ex: 'She gave an articulate speech that impressed everyone in the audience.',
      },
      fluent: {
        def: 'able to speak or write a language easily, smoothly, and without unnatural pauses.',
        ex: 'Consistent 15-minute voice practice with MIRA will make you fluent within 90 days.',
      },
      confidence: {
        def: 'a feeling of self-assurance arising from appreciation of one\'s own abilities.',
        ex: 'Every time you speak aloud, your confidence grows stronger.',
      },
      hometown: {
        def: 'the town or city where you were born or grew up.',
        ex: 'My hometown is Madurai, famous for its rich culture and Meenakshi Temple.',
      },
      profession: {
        def: 'a paid occupation, especially one that involves prolonged training and formal qualification.',
        ex: 'Teaching is a noble profession that shapes future generations.',
      },
      siblings: {
        def: 'your brothers and sisters.',
        ex: 'I have two siblings—an elder brother and a younger sister.',
      },
      colleague: {
        def: 'a person with whom one works in a profession or business.',
        ex: 'My colleagues and I collaborate every morning during the standup meeting.',
      },
      routine: {
        def: 'a sequence of actions regularly followed; a fixed habit.',
        ex: 'My morning routine includes reading English news and exercising.',
      },
    };

    if (vocabDict[targetWord]) {
      const item = vocabDict[targetWord];
      return `"${targetWord}" means: ${item.def} For example: "${item.ex}". Repeat this sentence out loud to memorize it naturally!`;
    }
  }

  // ── F. Tense Inquiries & Rules ────────────────────────────────────────

  if (lower.includes('present continuous') || lower.includes('ing tense')) {
    return 'Present Continuous describes actions happening right now at this exact moment. Formula: Subject + am/is/are + verb-ing. For example: "I am practicing English with MIRA right now." Say aloud: "We are improving our speaking skills every day!"';
  }

  if (lower.includes('present perfect')) {
    return 'Present Perfect connects past actions with the present moment. Formula: Subject + have/has + V3 (past participle). For example: "I have completed my Day 1 lesson" (completed in the past, but the achievement matters now). Say: "She has already started her practice."';
  }

  if (lower.includes('future tense') || lower.includes('going to')) {
    return 'To talk about the future, you can use "will" for quick decisions ("I will help you") or "going to" for plans already decided ("I am going to attend the meeting tomorrow"). Say aloud: "I am going to become a confident English speaker!"';
  }

  // ── G. Dynamic Contextual Fallback based on question keywords ─────────

  // Check if question asks "Why"
  if (lower.startsWith('why') || lower.includes('reason')) {
    return `Great question! The reason we structure it this way in English is clarity: standard sentences place the Subject first, followed by the Action (Verb) and details (Object). For example: "I speak English with confidence." Try rephrasing your sentence with this simple order!`;
  }

  // Check if question asks "Can I say" or "Is it correct"
  if (lower.includes('can i say') || lower.includes('is it correct') || lower.includes('is this correct')) {
    return `Yes! In spoken English, clarity is what matters most. To make it sound even more natural and polite to native listeners, use standard Subject + Verb order (e.g. "I would like to clarify this point"). Practice saying your thought aloud right now with MIRA!`;
  }

  // General intelligent synthesis tailored to the student's question and current topic
  const topicContext = topic ? `In ${topic}` : 'In everyday spoken English';
  return `${topicContext}, when expressing this thought, keep your sentence straightforward: state your main point first, then add the supporting reason. For example: "I find that practicing 15 minutes every morning makes a big difference." Say this aloud twice to build your muscle memory!`;
}
