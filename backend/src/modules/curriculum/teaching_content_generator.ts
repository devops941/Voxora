export interface IDialogueLine {
  speaker: string;
  english: string;
  tamil?: string;
  notes?: string;
}

export interface IVocabularyItem {
  word: string;
  meaning: string;
  tamilMeaning?: string;
  exampleSentence: string;
  tamilExample?: string;
}

export interface ICommonMistake {
  incorrect: string;
  correct: string;
  explanation: string;
  tamilExplanation?: string;
}

export interface ITeachingStep {
  stepNumber: number;
  title: string;
  explanation: string;
  practicalExample: string;
  tamilHint?: string;
}

export interface ITeachingContent {
  intro: {
    greeting: string;
    objective: string;
    whyLearnThis: string;
    tamilOverview?: string;
  };
  explanation: {
    concept: string;
    whenToUse: string;
    whyToUse: string;
    tamilNotes?: string;
  };
  stepByStepGuide: ITeachingStep[];
  realLifeScenario: {
    title: string;
    context: string;
    dialogue: IDialogueLine[];
  };
  vocabularyItems: IVocabularyItem[];
  grammarRules: {
    ruleName: string;
    explanation: string;
    formula?: string;
    examples: string[];
    tamilExplanation?: string;
  }[];
  commonMistakes: ICommonMistake[];
  recap: {
    summaryPoints: string[];
    comprehensionQuestion: string;
    suggestedAnswer: string;
  };
  spokenScript: string;
}

// English to Tamil dictionary for common vocabulary
const tamilVocabDict: Record<string, { meaning: string; exampleTamil: string }> = {
  name: { meaning: 'பெயர்', exampleTamil: 'என் பெயர் ஆனந்த்.' },
  hometown: { meaning: 'சொந்த ஊர்', exampleTamil: 'என் சொந்த ஊர் மதுரை.' },
  student: { meaning: 'மாணவர்', exampleTamil: 'நான் ஒரு கல்லூரி மாணவர்.' },
  work: { meaning: 'வேலை', exampleTamil: 'நான் ஒரு மென்பொருள் நிறுவனத்தில் வேலை செய்கிறேன்.' },
  family: { meaning: 'குடும்பம்', exampleTamil: 'என் குடும்பத்தில் நான்கு பேர் உள்ளனர்.' },
  parents: { meaning: 'பெற்றோர்', exampleTamil: 'என் பெற்றோருடன் நான் வசிக்கிறேன்.' },
  siblings: { meaning: 'உடன்பிறப்புகள்', exampleTamil: 'எனக்கு ஒரு தம்பி மற்றும் ஒரு தங்கை உள்ளனர்.' },
  breakfast: { meaning: 'காலை உணவு', exampleTamil: 'நான் தினமும் காலை 8 மணிக்கு காலை உணவு சாப்பிடுகிறேன்.' },
  coffee: { meaning: 'காபி', exampleTamil: 'எனக்கு சூடான காபி குடிக்க பிடிக்கும்.' },
  wake: { meaning: 'விழித்தெழு', exampleTamil: 'நான் காலை 6 மணிக்கு விழிக்கிறேன்.' },
  shopping: { meaning: 'பொருட்கள் வாங்குதல்', exampleTamil: 'நாங்கள் வார இறுதியில் கடைக்குச் செல்கிறோம்.' },
  price: { meaning: 'விலை', exampleTamil: 'இந்த சட்டையின் விலை என்ன?' },
  discount: { meaning: 'தள்ளுபடி', exampleTamil: 'இதற்கு ஏதேனும் தள்ளுபடி உண்டா?' },
  direction: { meaning: 'திசை / வழிகாட்டல்', exampleTamil: 'ரயில் நிலையத்திற்கு வழி சொல்ல முடியுமா?' },
  straight: { meaning: 'நேராக', exampleTamil: 'நேராகச் சென்று வலது பக்கம் திரும்புங்கள்.' },
  turn: { meaning: 'திரும்பு', exampleTamil: 'அடுத்த சிக்னலில் இடதுபுறம் திரும்புங்கள்.' },
  meeting: { meaning: 'கூட்டம் / ஆலோசனைக் கூட்டம்', exampleTamil: 'நாளை காலை எனக்கு ஒரு முக்கியமான மீட்டிங் உள்ளது.' },
  colleague: { meaning: 'சக ஊழியர்', exampleTamil: 'என் சக ஊழியர்கள் மிகவும் நட்பானவர்கள்.' },
  opinion: { meaning: 'கருத்து', exampleTamil: 'என் கருத்தில் இது ஒரு நல்ல திட்டம்.' },
  interview: { meaning: 'நேர்காணல்', exampleTamil: 'நான் நாளை வேலைக்கான நேர்காணலில் கலந்து கொள்கிறேன்.' },
  deadline: { meaning: 'கடைசி தேதி / காலக்கெடு', exampleTamil: 'திங்கட்கிழமைக்குள் இந்த வேலையை முடிக்க வேண்டும்.' },
  presentation: { meaning: 'விளக்கக்காட்சி', exampleTamil: 'வாடிக்கையாளருக்கு திட்டம் பற்றிய பிரசென்டேஷன் கொடுத்தேன்.' },
};

/**
 * Generates comprehensive, level-appropriate teaching content for any curriculum day.
 */
export function generateTeachingContent(params: {
  day: number;
  level: 'Beginner' | 'Intermediate' | 'Advanced';
  phase: number;
  topic: string;
  objective: string;
  vocab: string[];
  grammar: string;
}): ITeachingContent {
  const { day, level, phase, topic, objective, vocab, grammar } = params;
  const isBeginner = level === 'Beginner';
  const isIntermediate = level === 'Intermediate';

  // 1. Construct Vocabulary Items with Meanings & Tamil hints
  const vocabularyItems: IVocabularyItem[] = vocab.map((word) => {
    const key = word.toLowerCase().trim();
    const tamilData = tamilVocabDict[key] || {
      meaning: isBeginner ? 'முக்கியமான சொல்' : 'Key Term',
      exampleTamil: `"${word}" என்ற சொல்லை வாக்கியத்தில் பயன்படுத்துங்கள்.`,
    };

    let exampleSentence = `I often use "${word}" in daily English conversations.`;
    if (key.includes('name')) exampleSentence = 'My name is Sarah, and I am pleased to meet you.';
    else if (key.includes('work')) exampleSentence = 'I work diligently on new projects every day.';
    else if (key.includes('family')) exampleSentence = 'My family always gathers together for Sunday dinner.';
    else if (key.includes('meeting')) exampleSentence = 'Our team meeting is scheduled for 10:00 AM tomorrow.';
    else if (key.includes('price')) exampleSentence = 'Could you please tell me the price of this item?';
    else if (key.includes('turn')) exampleSentence = 'Turn left at the traffic light to reach the station.';
    else if (key.includes('deadline')) exampleSentence = 'We must submit our project before the deadline.';
    else if (key.includes('opinion')) exampleSentence = 'In my opinion, open communication solves most team problems.';
    else if (key.includes('presentation')) exampleSentence = 'She delivered an outstanding presentation to the executives.';

    return {
      word,
      meaning: `Used to describe or refer to ${word.toLowerCase()} in context of ${topic.toLowerCase()}.`,
      tamilMeaning: isBeginner ? tamilData.meaning : undefined,
      exampleSentence,
      tamilExample: isBeginner ? tamilData.exampleTamil : undefined,
    };
  });

  // 2. Construct Step-by-Step Practical Guide
  const stepByStepGuide: ITeachingStep[] = [
    {
      stepNumber: 1,
      title: 'Understand the Core Purpose',
      explanation: `Identify when you need to talk about ${topic}. Focus on speaking clearly rather than translating word-by-word.`,
      practicalExample: isBeginner
        ? `Start with simple subject + verb patterns: "I am...", "I have...", or "I do..."`
        : `Frame your opening thought with confidence: "Let me share my perspective on ${topic}."`,
      tamilHint: isBeginner ? 'முதலில் எளிய வாக்கியங்களை உருவாக்குங்கள்; கடினமான வார்த்தைகள் தேவையில்லை.' : undefined,
    },
    {
      stepNumber: 2,
      title: 'Apply the Grammar Formula',
      explanation: `Use "${grammar}" correctly. Pay attention to subject-verb agreement and natural word order.`,
      practicalExample: `Pattern to practice: [Subject] + [Verb form based on "${grammar}"] + [Object/Detail].`,
      tamilHint: isBeginner ? 'இலக்கண விதியை சரியாகப் பின்பற்றி வாக்கியத்தை நிறைவு செய்யுங்கள்.' : undefined,
    },
    {
      stepNumber: 3,
      title: 'Deliver with Natural Cadence',
      explanation: 'Take a calm breath, speak smoothly without rushing, and emphasize key nouns and action verbs.',
      practicalExample: `Speak this aloud: "When discussing ${topic}, I like to express myself clearly and naturally."`,
      tamilHint: isBeginner ? 'பயமின்றி, தெளிவாக, சத்தமாகப் பேசிப் பழகுங்கள்.' : undefined,
    },
  ];

  // 3. Construct Real-Life Scenario Dialogue
  const dialogueLines: IDialogueLine[] = [
    {
      speaker: 'MIRA (Tutor)',
      english: `Hello! Today we are practicing ${topic}. Tell me, how would you start when speaking about this?`,
      tamil: isBeginner ? `வணக்கம்! இன்று நாம் ${topic} பற்றிப் பழகுகிறோம். இதைப் பற்றி எப்படிப் பேசுவீர்கள்?` : undefined,
      notes: 'Warm opening with direct question',
    },
    {
      speaker: 'Learner',
      english: `I usually start by greeting warmly and stating my main point clearly. For example, "It is great to discuss ${topic} with you."`,
      tamil: isBeginner ? 'நான் பொதுவாக அன்புடன் வணக்கம் கூறி, எனது கருத்தை தெளிவாகச் சொல்வேன்.' : undefined,
      notes: 'Clear, polite response applying lesson concept',
    },
    {
      speaker: 'MIRA (Tutor)',
      english: `That is spot on! Adding a reason or specific example makes your English sound polished and natural. Let's keep practicing!`,
      tamil: isBeginner ? 'மிகச் சிறப்பு! ஒரு காரணம் அல்லது உதாரணம் சேர்த்தால் உங்கள் பேச்சு மிக இயல்பாக இருக்கும்.' : undefined,
      notes: 'Positive feedback with actionable speaking advice',
    },
  ];

  // 4. Grammar Rules & Common Mistakes
  const commonMistakes: ICommonMistake[] = [
    {
      incorrect: `Myself ${isBeginner ? 'Karthik' : 'working here'}...`,
      correct: `My name is ${isBeginner ? 'Karthik' : 'Alex, and I work here'}...`,
      explanation: 'Do not use reflexive pronoun "Myself" to introduce yourself. Use "I am..." or "My name is...".',
      tamilExplanation: isBeginner ? '"Myself" என்று ஆரம்பிக்காதீர்கள்; "My name is..." அல்லது "I am..." என்று கூறுங்கள்.' : undefined,
    },
    {
      incorrect: 'I am agree with your point.',
      correct: 'I agree with your point.',
      explanation: '"Agree" is a main verb, not an adjective. Say "I agree", never "I am agree".',
      tamilExplanation: isBeginner ? '"I am agree" என்பது தவறு; "I agree" என்று மட்டுமே கூற வேண்டும்.' : undefined,
    },
    {
      incorrect: 'He do not know the answer.',
      correct: 'He does not know the answer.',
      explanation: 'With third-person singular (He / She / It), use "does not", not "do not".',
      tamilExplanation: isBeginner ? 'He / She / It வரும்போது "does not" பயன்படுத்த வேண்டும்.' : undefined,
    },
  ];

  // 5. Spoken Lesson Script for MIRA Voice TTS
  const spokenScript = isBeginner
    ? `Welcome to Day ${day} of Voxora! I am your AI teacher, MIRA. Today, our lesson is: ${topic}. ${objective} In daily English, this topic is essential because it helps you communicate clearly with others. Let's start with our core vocabulary: ${vocab.slice(0, 3).join(', ')}. Remember our grammar rule: ${grammar}. Avoid common errors like saying "myself" instead of "my name is". Listen closely to our dialogue, and when you are ready, tap Phase 2 to practice speaking with me!`
    : `Hello and welcome to Day ${day} of your English mastery journey with Voxora. Today, we are focusing on ${topic}. Our primary objective is to ${objective.toLowerCase()} This will sharpen your workplace communication, fluency, and presence. Notice our target vocabulary: ${vocab.join(', ')}. Keep our grammar focus in mind: ${grammar}. Let's examine how professionals navigate this topic naturally, and then transition to Phase 2 for interactive spoken practice.`;

  return {
    intro: {
      greeting: `Welcome to Day ${day}! I am MIRA, your AI English tutor.`,
      objective,
      whyLearnThis: `Mastering "${topic}" gives you the confidence to speak fluently in daily life, work, and social conversations without hesitating.`,
      tamilOverview: isBeginner
        ? `இன்றைய பாடம் "${topic}". ஆங்கிலத்தில் சரளமாகவும் தயக்கமின்றியும் பேச இந்த பாடம் உங்களுக்கு பெரிதும் உதவும்.`
        : undefined,
    },
    explanation: {
      concept: `In this lesson, we break down how to express ideas regarding "${topic}" using natural sentence structures.`,
      whenToUse: `Use these expressions whenever you are meeting people, sharing ideas, or participating in conversations related to ${topic.toLowerCase()}.`,
      whyToUse: `Clear communication in this area shows professionalism, warmth, and strong spoken command of English.`,
      tamilNotes: isBeginner
        ? `நேரடியாக தமிழில் இருந்து ஆங்கிலத்திற்கு வார்த்தைக்கு வார்த்தை மொழிபெயர்க்காமல், இந்த எளிய வாக்கிய அமைப்புகளைப் பழகுங்கள்.`
        : undefined,
    },
    stepByStepGuide,
    realLifeScenario: {
      title: `Real-Life Dialogue: ${topic}`,
      context: `A natural conversation demonstrating how to apply today's topic in real life.`,
      dialogue: dialogueLines,
    },
    vocabularyItems,
    grammarRules: [
      {
        ruleName: grammar,
        explanation: `This structure ensures your sentences are grammatically accurate and easy for listeners to follow.`,
        formula: isBeginner ? 'Subject + Verb + Context / Object' : 'Opening Clause + Key Message + Supporting Detail',
        examples: [
          `Example 1: I practice speaking English every day.`,
          `Example 2: Clear communication makes conversations enjoyable.`,
        ],
        tamilExplanation: isBeginner
          ? 'வாக்கிய அமைப்பை எளிமையாக வைத்துக்கொண்டு, சரியான வினைச்சொல்லைப் (Verb) பயன்படுத்துங்கள்.'
          : undefined,
      },
    ],
    commonMistakes,
    recap: {
      summaryPoints: [
        `Use the core vocabulary words: ${vocab.slice(0, 4).join(', ')}.`,
        `Apply the grammar pattern: "${grammar}".`,
        `Speak out loud with confidence, clear tone, and steady pace.`,
      ],
      comprehensionQuestion: `How would you introduce or talk about "${topic}" in one full English sentence?`,
      suggestedAnswer: `I feel confident speaking about ${topic} in everyday conversations.`,
    },
    spokenScript,
  };
}
