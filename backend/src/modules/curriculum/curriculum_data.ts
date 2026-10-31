export interface RawThemeItem {
  day: number;
  phase: number;
  topic: string;
  objective: string;
  vocab: string[];
  grammar: string;
  activities: string[];
  miraQuestions: string[];
  revisionTask?: string;
}

// ── 1. BEGINNER CURRICULUM (90 DAYS) ─────────────────────────────────
// Focus: Basic vocabulary, sentence formation, grammar fundamentals, self-introduction, daily routines, simple conversations.
export const beginnerSyllabusThemes: RawThemeItem[] = [
  // Phase 1 (Days 1–30): Foundation & Daily Routines
  {
    day: 1, phase: 1,
    topic: 'Self-Introduction & Greetings',
    objective: 'Introduce yourself with your name, hometown, and profession using simple present tense.',
    vocab: ['Name', 'Hometown', 'Student', 'Work'],
    grammar: 'Present Simple of Be (I am / You are)',
    activities: ['Greeting Mira and saying your name', 'Sharing where you live and your job', 'Practicing clear greeting pronunciation'],
    miraQuestions: [
      'Hello! Welcome to Voxora. What is your name and where are you from?',
      'Nice to meet you! What do you do for work or study?',
      'What are your favorite hobbies or what do you like to do on weekends?',
      'Why do you want to learn English, and what is your dream speaking goal?',
      'Can you say one full sentence: "I am practicing English every day to speak fluently and confidently"?',
    ],
  },
  {
    day: 2, phase: 1,
    topic: 'Family & Close People',
    objective: 'Talk about your family members and relationships with possessive words.',
    vocab: ['Parents', 'Siblings', 'Brother', 'Sister'],
    grammar: 'Possessive adjectives (My, His, Her)',
    activities: ['Naming family members', 'Describing how many siblings you have', 'Simple sentence drill'],
    miraQuestions: [
      'Tell me about your family. How many people are in your family?',
      'Do you have any brothers or sisters?',
      'Say: "My family lives in..." and complete the sentence.',
    ],
  },
  {
    day: 3, phase: 1,
    topic: 'Daily Morning Routine',
    objective: 'Describe what you do every morning from waking up to breakfast.',
    vocab: ['Wake up', 'Brush', 'Breakfast', 'Coffee'],
    grammar: 'Present Simple for habits (I wake up at 7 AM)',
    activities: ['Describing your wake-up time', 'Listing morning tasks in sequence', 'Time phrases practice'],
    miraQuestions: [
      'What time do you usually wake up on weekdays?',
      'What do you like to eat or drink for breakfast?',
      'Say a sentence with "always" or "usually" about your morning.',
    ],
  },
  {
    day: 4, phase: 1,
    topic: 'Numbers & Telling the Time',
    objective: 'Ask and tell the time accurately in spoken English.',
    vocab: ['Quarter past', 'Half past', 'Midnight', 'Noon'],
    grammar: 'Preposition of time (At 8:00 AM, In the morning)',
    activities: ['Reading clock times aloud', 'Stating your work or study hours', 'Answering "What time is it?"'],
    miraQuestions: [
      'What time do you usually start your work or daily routine?',
      'If a meeting is at 2:30 PM, how do you say that naturally?',
      'Practice saying: "I will meet you at half past six."',
    ],
  },
  {
    day: 5, phase: 1,
    topic: 'Phase 1 Warm-up & Review (Days 1–4)',
    objective: 'Synthesize greetings, family, morning routines, and telling time without hesitation.',
    vocab: ['Routine', 'Schedule', 'Family', 'Introduction'],
    grammar: 'Present Simple synthesis',
    activities: ['1-minute continuous self-introduction', 'Reviewing mistakes from days 1 to 4', 'Fluency check'],
    miraQuestions: [
      'Can you introduce yourself and tell me about your daily morning in 3 sentences?',
      'What is your favorite time of the day and why?',
      'Repeat after me with steady rhythm: "Every morning I wake up ready to practice English."',
    ],
    revisionTask: 'Review greetings and morning routine words before recording.',
  },
  {
    day: 6, phase: 1,
    topic: 'Favorite Foods & Beverages',
    objective: 'Express food likes, dislikes, and daily meals.',
    vocab: ['Delicious', 'Spicy', 'Sweet', 'Vegetables'],
    grammar: 'Expressing likes (I like / I do not like)',
    activities: ['Naming favorite dishes', 'Describing taste and flavors', 'Ordering food simulation'],
    miraQuestions: [
      'What is your all-time favorite food to eat?',
      'Do you prefer sweet snacks or spicy food?',
      'Say: "I really enjoy eating..." and describe why.',
    ],
  },
  {
    day: 7, phase: 1,
    topic: 'Describing Your Home & Living Space',
    objective: 'Describe your room, house, and favorite spaces with prepositions of place.',
    vocab: ['Balcony', 'Kitchen', 'Bedroom', 'Cozy'],
    grammar: 'There is / There are + Prepositions (In, On, Next to)',
    activities: ['Describing items in your room', 'Using "There is" and "There are"', 'Spatial words drill'],
    miraQuestions: [
      'Can you describe your room or favorite place in your home?',
      'What is one thing on your desk or table right now?',
      'Say: "There is a window in my room with a nice view."',
    ],
  },
  {
    day: 8, phase: 1,
    topic: 'Colors, Clothing & Everyday Style',
    objective: 'Describe what you and others are wearing today.',
    vocab: ['Casual', 'Jacket', 'Comfortable', 'Sneakers'],
    grammar: 'Present Continuous for clothing (I am wearing)',
    activities: ['Describing your outfit today', 'Talking about clothes for different seasons', 'Color adjectives'],
    miraQuestions: [
      'What clothes are you wearing today?',
      'Do you prefer formal clothes or casual clothes?',
      'Practice: "Today I am wearing a comfortable blue shirt."',
    ],
  },
  {
    day: 9, phase: 1,
    topic: 'Days of the Week & Month Seasons',
    objective: 'Talk about plans for specific days of the week and seasons.',
    vocab: ['Weekend', 'Autumn', 'Summer', 'Winter'],
    grammar: 'Prepositions on days and months (On Monday, In December)',
    activities: ['Listing weekly commitments', 'Describing your favorite season', 'Pronouncing days clearly'],
    miraQuestions: [
      'Which day of the week is your busiest day?',
      'What season of the year do you enjoy the most?',
      'Say: "On weekends, I like to relax with my family."',
    ],
  },
  {
    day: 10, phase: 1,
    topic: 'Shopping for Groceries & Items',
    objective: 'Ask prices, quantities, and interact politely at a grocery shop.',
    vocab: ['Price', 'Receipt', 'Discount', 'Fresh'],
    grammar: 'How much / How many',
    activities: ['Asking "How much is this?"', 'Listing items to purchase', 'Polite cashier exchanges'],
    miraQuestions: [
      'Imagine you are at a supermarket. Ask me the price of apples.',
      'How do you politely ask for the receipt?',
      'Practice saying: "Could you tell me how much this costs?"',
    ],
  },
  {
    day: 11, phase: 1,
    topic: 'Asking for Directions in the Street',
    objective: 'Ask for and give basic street directions using navigation words.',
    vocab: ['Crossroad', 'Turn left', 'Turn right', 'Opposite'],
    grammar: 'Imperatives & directional prepositions',
    activities: ['Asking where the nearest station or bank is', 'Following simple directions', 'Clear street guidance drill'],
    miraQuestions: [
      'How do you politely ask a stranger where the bus station is?',
      'If someone asks you for directions, how do you say "Turn right at the corner"?',
      'Say: "Excuse me, where is the nearest pharmacy?"',
    ],
  },
  {
    day: 12, phase: 1,
    topic: 'Hobbies & Free Time Activities',
    objective: 'Share what you enjoy doing in your spare time.',
    vocab: ['Reading', 'Gardening', 'Music', 'Drawing'],
    grammar: 'Enjoy / Love + Verb-ing (I enjoy listening)',
    activities: ['Sharing your top hobby', 'Explaining how long you have had this hobby', 'Expressing passion'],
    miraQuestions: [
      'What hobbies do you do when you have free time?',
      'Why do you enjoy this activity?',
      'Say: "In my free time, I really enjoy reading books."',
    ],
  },
  {
    day: 13, phase: 1,
    topic: 'Weather & Daily Temperatures',
    objective: 'Comment on the weather conditions today and express how you feel.',
    vocab: ['Sunny', 'Rainy', 'Cloudy', 'Humid'],
    grammar: 'It is + Adjective (It is raining outside)',
    activities: ['Describing today\'s weather', 'Small talk about rain or sunshine', 'Weather phrases drill'],
    miraQuestions: [
      'How is the weather outside in your city today?',
      'Do you prefer sunny days or rainy days?',
      'Say: "It looks like it might rain this afternoon."',
    ],
  },
  {
    day: 14, phase: 1,
    topic: 'Ordering Coffee & Snacks at a Cafe',
    objective: 'Order beverages, customize options, and pay with confidence.',
    vocab: ['Cappuccino', 'Takeaway', 'Sugar', 'Pastry'],
    grammar: 'Polite requests (Can I have / Could I please get)',
    activities: ['Ordering your favorite drink', 'Specifying hot or iced', 'Polite cafe roleplay'],
    miraQuestions: [
      'Welcome to the cafe! What drink can I get for you today?',
      'Would you like that for here or takeaway?',
      'Practice: "Could I please get an iced coffee with milk?"',
    ],
  },
  {
    day: 15, phase: 1,
    topic: 'Phase 1 Mid-Point Milestone & Spoken Fluency Drill',
    objective: 'Test spontaneous speaking across personal routines, shopping, food, and directions.',
    vocab: ['Milestone', 'Confidence', 'Pronunciation', 'Speaking'],
    grammar: 'Synthesis of present and polite forms',
    activities: ['2-minute continuous talk without long pauses', 'Speech rate measurement', 'Progress check'],
    miraQuestions: [
      'Congratulations on Day 15! Tell me: What has been the most helpful word you learned so far?',
      'Describe your typical weekend from Saturday morning to Sunday night in 3 sentences.',
      'Speak for 30 seconds about your goals with English speaking.',
    ],
    revisionTask: 'Day 15 Speaking Milestone: review your voice recordings and check fluency rhythm.',
  },
  // Continuing Days 16–30 for Beginner Phase 1
  ...Array.from({ length: 15 }, (_, i) => {
    const d = i + 16;
    const topics = [
      'Public Transport & City Travel', 'Visiting a Doctor & Basic Symptoms', 'Describing People & Appearances',
      'Supermarket Aisle Shopping', 'Childhood Memories & Hometown', 'My Best Friend', 'Local Celebrations & Festivals',
      'Describing Your City & Highlights', 'Phone Conversation Basics', 'Music & Favorite Songs', 'A Memorable Past Trip',
      'Likes vs Dislikes Comparison', 'Simple Sports & Exercise', 'Pets & Animals at Home', 'Phase 1 Graduation Review'
    ];
    const vocabs = [
      ['Ticket', 'Platform', 'Subway'], ['Fever', 'Headache', 'Medicine'], ['Tall', 'Kind', 'Friendly'],
      ['Cart', 'Produce', 'Bakery'], ['Childhood', 'School', 'Memory'], ['Loyal', 'Helpful', 'Friend'],
      ['Festival', 'Holiday', 'Gathering'], ['Monument', 'Traffic', 'Beautiful'], ['Hello', 'Hold on', 'Call back'],
      ['Rhythm', 'Song', 'Relaxing'], ['Journey', 'Scenery', 'Travel'], ['Prefer', 'Dislike', 'Favorite'],
      ['Walk', 'Jog', 'Fitness'], ['Dog', 'Cat', 'Playful'], ['Achievement', 'Fluency', 'Progress']
    ];
    return {
      day: d, phase: 1,
      topic: topics[i],
      objective: `Master basic spoken English expressions and vocabulary for ${topics[i].toLowerCase()}.`,
      vocab: vocabs[i],
      grammar: 'Basic sentence structure and conversational markers',
      activities: ['Word pronunciation drill', 'Answering Mira\'s questions', 'Sentence repetition'],
      miraQuestions: [
        `Today we explore "${topics[i]}". What first comes to your mind about this?`,
        `Can you share a simple sentence using one of today's key words?`,
        `Repeat clearly after me: "Speaking English every day makes me more confident."`,
      ],
      revisionTask: d % 5 === 0 ? 'Review recent vocabulary and record a 1-minute summary.' : undefined,
    };
  }),

  // Phase 2 (Days 31–60): Conversational English & Everyday Situations
  ...Array.from({ length: 30 }, (_, i) => {
    const d = i + 31;
    const topics = [
      'Job Roles & Everyday Work', 'A Typical Workday Schedule', 'Giving and Receiving Polite Help',
      'Making Simple Appointments', 'Expressing Simple Opinions', 'Agreeing and Disagreeing Gently',
      'Reporting a Problem with an Item', 'Asking Coworkers for Assistance', 'Describing a Useful Gadget',
      'Booking a Hotel Room by Phone', 'Dining at a Casual Restaurant', 'Airport Check-in and Bag Drop',
      'Asking for Recommendations in Town', 'Expressing Emotions & Moods', 'Talking About Tomorrow Plans',
      'Online Shopping & Delivery Inquiries', 'Talking About a Book or Short Story', 'Recycling & Green Habits',
      'Social Media & Daily Screen Time', 'Resolving Simple Misunderstandings', 'Describing a Dream Trip',
      'Simple Cooking & Recipe Steps', 'Exercise Habits & Health Goals', 'Introducing Someone at an Event',
      'Telling a Funny Short Anecdote', 'Describing Cultural Food Traditions', 'Basic Budgeting & Saving Words',
      'Describing Favorite Photos', 'Handling a Minor Emergency', 'Phase 2 Milestone Review & Speech Check'
    ];
    return {
      day: d, phase: 2,
      topic: topics[i],
      objective: `Expand conversational vocabulary, asking questions naturally, and speaking in full sentences about ${topics[i].toLowerCase()}.`,
      vocab: ['Express', 'Communicate', 'Sentence', 'Conversation'],
      grammar: 'Past Simple, Future with Going to, and Modal verbs (Can, Should)',
      activities: ['Roleplay dialogue with Mira', 'Short personal experience sharing', 'Pronunciation and intonation drill'],
      miraQuestions: [
        `Welcome to Day ${d}! Today our topic is "${topics[i]}". How do you handle this in your daily life?`,
        `Can you describe an example or situation related to this?`,
        `Try speaking for 20 seconds without long pauses. I am listening!`,
      ],
      revisionTask: d % 5 === 0 ? `Review Phase 2 lessons up to Day ${d} with a spoken summary.` : undefined,
    };
  }),

  // Phase 3 (Days 61–90): Confident Expression & Spontaneous Speaking
  ...Array.from({ length: 30 }, (_, i) => {
    const d = i + 61;
    const topics = [
      'Introducing Yourself Professionally', 'Answering "Tell Me About Yourself"', 'Describing Past Achievements',
      'Pitching a Simple Idea to Friends', 'Presenting a Short 1-Minute Update', 'Negotiating Minor Requests',
      'Discussing Pros and Cons of City Life', 'Talking About Smart Devices in Life', 'Impromptu 1-Minute Speaking',
      'Storytelling: A Turning Point in Life', 'Using Body Language & Eye Contact Tone', 'Natural Everyday Idioms',
      'Common Phrasal Verbs in Daily Talk', 'Differences in Tone (Polite vs Casual)', 'Active Listening & Echo Questions',
      'Giving Clear Step-by-step Instructions', 'Discussing Today\'s Good News', 'Life Lessons & What Inspires You',
      'Respectful Communication with Others', 'Handling Questions Calmly Under Pressure', 'Speaking with Warmth and Humor',
      'Discussing Movies and Story Themes', 'Participating in a Virtual Group Call', 'Saying Heartfelt Thanks & Praise',
      'Staying Calm When Speaking in Public', 'Motivating a Friend Who Feels Down', '2-Minute Non-stop Speech Challenge',
      'Reflecting on Your 90-Day Transformation', 'Final Practice: Fluency & Articulation', 'Day 90 Graduation Speaking Showcase'
    ];
    return {
      day: d, phase: 3,
      topic: topics[i],
      objective: `Speak spontaneously, use natural conversational rhythm, and articulate full ideas with confidence.`,
      vocab: ['Fluency', 'Spontaneous', 'Articulate', 'Confidence'],
      grammar: 'Compound sentences, connectors (Although, However, Therefore)',
      activities: ['Impromptu response with Mira', 'Accent and intonation polish', 'Continuous 1-to-2 minute speech drill'],
      miraQuestions: [
        `Day ${d}: "${topics[i]}". Give me your spontaneous response to this prompt.`,
        `How would you express your thoughts clearly to someone listening?`,
        `Let us test your spoken flow: repeat a complete sentence with natural stress.`,
      ],
      revisionTask: d % 5 === 0 ? `Milestone check for Day ${d}: record your best spontaneous answer.` : undefined,
    };
  }),
];

// ── 2. INTERMEDIATE CURRICULUM (90 DAYS) ─────────────────────────────
// Focus: Conversational fluency, storytelling, expressing opinions, explaining experiences, workplace communication, handling real-life situations.
export const intermediateSyllabusThemes: RawThemeItem[] = [
  ...Array.from({ length: 90 }, (_, i) => {
    const day = i + 1;
    const phase = day <= 30 ? 1 : day <= 60 ? 2 : 3;
    const intermediateTopics = [
      // Phase 1 (1–30): Fluency, Eliminating Mental Translation, Connectors & Storytelling
      'Eliminating Hesitation & Spoken Connectors', 'Narrating a Memorable Life Event', 'Describing Complex Emotions Accurately',
      'Polite Disagreement & Offering Alternatives', 'Explaining "Why" with Persuasive Logic', 'Storytelling: Building Suspense and Detail',
      'Workplace Small Talk with Senior Colleagues', 'Discussing Career Ambitions & Future Goals', 'Asking Probing Questions in Conversations',
      'Handling Uncomfortable Social Situations', 'Describing Cultural Traditions to Strangers', 'Comparing Two Products or Life Choices',
      'Giving Constructive Feedback Tactfully', 'Overcoming the Fear of Making Mistakes', 'Phase 1 Intermediate Fluency Check (Day 15)',
      'Explaining How Something Works Step-by-Step', 'Discussing Current Technology Trends', 'Telling an Anecdote with Dialogue & Humor',
      'Expressing Hypothetical Scenarios (If I had...)', 'Describing Personal Strengths with Evidence', 'Discussing Work-Life Balance Realities',
      'Active Listening: Summarizing What Others Said', 'Clarifying Misunderstandings Without Friction', 'Using Conversational Fillers Naturally',
      'Narrating a Failure and What You Learned', 'Debating: Remote Work vs Office Culture', 'Discussing Personal Finance & Smart Habits',
      'Explaining Creative Ideas with Metaphors', 'Reflecting on Personal Growth Over 5 Years', 'Phase 1 Review & 2-Minute Monologue Test',

      // Phase 2 (31–60): Workplace Communication & Real-life Negotiation
      'Leading a Project Status Standup Meeting', 'Pitching a New Feature or Solution', 'Handling Customer Complaints with Empathy',
      'Negotiating a Deadline Extension Professionally', 'Answering Unprepared Questions in Meetings', 'Writing vs Speaking: Adapting Your Tone',
      'Cross-Functional Team Collaboration Dialogues', 'Networking at an Industry Conference', 'Interview Mastery: The STAR Method Story',
      'Interview Mastery: Addressing Weaknesses Positively', 'Interview Mastery: Asking Smart Employer Questions', 'Expressing Dissent Diplomatically',
      'Delegating Tasks and Setting Clear Expectations', 'Giving a 3-Minute Compelling Presentation', 'Phase 2 Workplace Mid-Point Review (Day 45)',
      'Handling Technical Glitches on Client Calls', 'Crisis Management & Quick Decisions Under Pressure', 'Explaining Data, Charts, and Metrics',
      'Influencing Colleagues Without Formal Authority', 'Conflict Resolution Between Coworkers', 'Crafting an Elevator Pitch for Your Skillset',
      'Describing Market Trends and Customer Needs', 'Navigating Small Talk Before Formal Meetings', 'Summarizing Action Items and Ownership',
      'Receiving Critical Feedback with Professionalism', 'Asking for a Raise or Promotion Strategically', 'Managing Expectations with Difficult Clients',
      'Conducting an Informational Interview', 'Storytelling for Influence & Leadership', 'Phase 2 Graduation: Corporate Simulation Drill',

      // Phase 3 (61–90): Spontaneous Speaking & Nuanced Idioms
      'Thinking on Your Feet: The 60-Second Challenge', 'Everyday Idioms in Real Workplace Context', 'Separable vs Inseparable Phrasal Verbs',
      'Nuances of Sarcasm, Irony, and Humor', 'Speaking with Varied Pace, Pitch, and Tone', 'Debating: AI Automation & Human Workforce',
      'Debating: Climate Change Action & Economics', 'Nuances of British vs American Word Choices', 'Expressing Deep Gratitude and Loyalty',
      'Discussing Philosophical Dilemmas Smoothly', 'Answering Hostile or Tricky Questions', 'The Art of Tactful Interruptions in Meetings',
      'Explaining Complex Scientific or Tech Concepts', 'Storytelling: The Hero’s Journey Arc', 'Phase 3 Mastery Check: Impromptu Talk (Day 75)',
      'Speaking Without Any Mental Translation', 'Conversational Chemistry & Building Rapport', 'Persuasive Call-to-Action Closing Techniques',
      'Navigating Cross-Cultural Etiquette Differences', 'Speaking Clearly Under Stressful Conditions', 'Using Voice Cadence to Captivate Audiences',
      'Refining Pronunciation of Difficult Consonant Clusters', 'Defending an Unpopular Viewpoint with Grace', 'Describing the Psychology of Habits',
      'Spontaneous 3-Minute Monologue with Mira', 'Reflecting on Your 90-Day Spoken Journey', 'Overcoming Any Lingering Self-Doubt',
      'Final Assessment Simulation: Fluency & Range', 'Mastering Conversational Confidence Everywhere', 'Day 90 Intermediate Graduation: Fluent Speaker'
    ];

    return {
      day,
      phase,
      topic: intermediateTopics[i],
      objective: `Master fluent, natural English speech for ${intermediateTopics[i].toLowerCase()} without hesitation.`,
      vocab: ['Articulate', 'Perspective', 'Consequently', 'Furthermore'],
      grammar: 'Complex conditionals, passive voice, modal deduction, discourse markers',
      activities: ['Impromptu response with Mira', 'Spontaneous storytelling drill', 'Grammar correction & rhythm polish'],
      miraQuestions: [
        `Intermediate Day ${day}: "${intermediateTopics[i]}". How would you articulate your perspective on this?`,
        `Can you illustrate that with a real-life example or personal experience?`,
        `Synthesize your response in two fluent sentences using smooth connectors.`,
      ],
      revisionTask: day % 5 === 0 ? `Intermediate Milestone ${day}: review your pronunciation clarity and record an unscripted response.` : undefined,
    };
  }),
];

// ── 3. ADVANCED CURRICULUM (90 DAYS) ─────────────────────────────────
// Focus: Spontaneous speaking, professional communication, debates, persuasion, nuanced vocabulary, presentations, complex discussions.
export const advancedSyllabusThemes: RawThemeItem[] = [
  ...Array.from({ length: 90 }, (_, i) => {
    const day = i + 1;
    const phase = day <= 30 ? 1 : day <= 60 ? 2 : 3;
    const advancedTopics = [
      // Phase 1 (1–30): Executive Communication, Nuance & Impromptu Mastery
      'Executive Presence: The Psychology of Gravitas', 'Persuasive Rhetoric & Aristotle’s Triad', 'Eliminating Subtle Fillers and Vocal Fry',
      'Mastering Cadence, Pauses, and Vocal Resonance', 'Impromptu Speaking on Abstruse Philosophy', 'Reframing Tough Narratives with Precision',
      'Sophisticated Idiomatic Nuances in Leadership', 'Cross-Cultural Diplomatic Protocol in Speech', 'Debating: Ethics of Genetic Engineering',
      'Debating: Universal Basic Income & Economy', 'Storytelling with Emotional Catharsis', 'Articulating Strategic Vision to Teams',
      'The Art of Subtlety, Understatement & Wit', 'Synthesizing 10-Page Reports into 60 Seconds', 'Phase 1 Executive Benchmark Assessment (Day 15)',
      'Negotiating Multi-Stakeholder High-Stakes Deals', 'Handling Aggressive Counter-Arguments Gracefully', 'Vocal Inflection: Assertive vs Inquisitive',
      'Speaking in Extended Complex Syntax Without Pauses', 'The Linguistic Nuance of Concession & Rebuttal', 'Impromptu Defense of a Contrarian Idea',
      'Mastering High-Level Corporate Phrasal Verbs', 'Delivering Bad News with Unshakable Empathy', 'Executive Keynote Speech Opening Hooks',
      'Dissecting Media Narratives and Bias Critically', 'Advanced Idioms for Boardroom & C-Suite', 'Speaking with Precision: Choosing the Exact Word',
      'The Rhythm of Natural Spoken English Monologues', 'Humor, Irony, and Satire in High-Level Dialogue', 'Phase 1 Advanced Defense: 3-Minute Monologue',

      // Phase 2 (31–60): High-Stakes Debates, Crisis & Persuasive Mastery
      'Boardroom Presentations: Navigating Skepticism', 'Crisis Communication: Calming Market Panics', 'Salary & Equity Negotiation for Senior Roles',
      'Debating: Quantum Computing & Global Security', 'Debating: Free Speech in the Algorithmic Era', 'Handling Hostile Media & Press Interviews',
      'The Art of Non-Violent Assertive Confrontation', 'Storytelling: Metaphors That Drive Business Decisions', 'Keynote Speeches: Pacing and Crescendo',
      'Strategic Ambiguity vs Explicit Direction', 'Cross-Cultural Nuances in Executive Negotiations', 'Managing High-Conflict Personalities Calmly',
      'Deconstructing Logical Fallacies in Live Debates', 'Speaking with Intellectual Depth and Accessibility', 'Phase 2 High-Stakes Speech Trial (Day 45)',
      'Delivering Unrehearsed Acceptance & Toast Speeches', 'The Nuance of Tone in High-Stakes Email and Speech', 'Persuading Skeptical Investors in 2 Minutes',
      'Navigating Ambiguous and Incomplete Information', 'Mastering the Subjunctive and Inversion in Spoken English', 'Speaking in High-Velocity Fast Conversations',
      'Unpacking Cognitive Biases in Decision Discussions', 'Strategic Storytelling: Inspiring Action Under Uncertainty', 'Debating: Space Exploration vs Terrestrial Priorities',
      'Executive Empathy in Difficult Termination Discussions', 'Speaking with Unhurried Authority and Gravitas', 'Nuanced Lexicon: Replacing Generic Words with Power Verbs',
      'The Music of Speech: Articulation, Consonant Stress, and Breath Control', 'Impromptu 5-Minute Speech on an Unfamiliar Abstract Theme', 'Phase 2 Graduation: Boardroom Simulation Masterclass',

      // Phase 3 (61–90): Native-Like Spontaneity, Effortless Flow & Graduation
      'Total Spontaneous Fluency: Eliminating the Thinking Delay', 'Native-Level Conversational Flow and Collocations', 'Effortless Code-Switching for Different Audiences',
      'Speaking on Global Geopolitics with Measured Nuance', 'Debating: The Future of Consciousness & Sentience', 'Articulating the Essence of Wisdom and Human Experience',
      'Humor and Banter in Professional Peer Settings', 'Mastering Dramatic Pacing in Storytelling', 'Speaking with Poetic Imagery and Rhetorical Power',
      'The Art of Unshakable Calm Under Cross-Examination', 'Impromptu Critique of an Argument in Real Time', 'Executive Toast and Tribute Speeches That Resonate',
      'Nuanced Pronunciation: Connected Speech & Elision', 'Defending an Ethical Stance Against Groupthink', 'Phase 3 Master Milestone: Spontaneous Defense (Day 75)',
      'The Flow State: Speaking Without Monitoring Every Word', 'Articulating Complex Systems Architecture Eloquently', 'Persuading Hostile Audiences Through Common Ground',
      'Mastering Tone in Sensitive Geopolitical Exchanges', 'Speaking with Emotional Authenticity and Impact', 'Storytelling: The Arc of Personal Transformation',
      'The Nuances of Tone: Warmth, Gravitas, and Decisiveness', 'Impromptu Masterclass: Teaching a Hard Concept Simply', 'Debating: Human Longevity and Society',
      'Unscripted 5-Minute Monologue Marathon with Mira', 'Reflections on the Complete 90-Day Spoken Journey', 'The Lifetime Habit of Articulate English Communication',
      'Final Assessment Simulation: CEFR C2 Master Level', 'Spoken Mastery Showcase: Speech to the World', 'Day 90 Advanced Graduation: Voxora Fluent Master'
    ];

    return {
      day,
      phase,
      topic: advancedTopics[i],
      objective: `Demonstrate executive-level spoken mastery, nuanced vocabulary, and spontaneous eloquence on ${advancedTopics[i].toLowerCase()}.`,
      vocab: ['Gravitas', 'Eloquent', 'Articulate', 'Nuanced', 'Persuasive'],
      grammar: 'Inversion structures, subjunctive mood, cleft sentences, advanced discourse synthesis',
      activities: ['Impromptu executive monologue', 'Debate defense against Mira', 'Rhetorical cadence and phonetics polish'],
      miraQuestions: [
        `Advanced Day ${day}: "${advancedTopics[i]}". Present your structured impromptu perspective.`,
        `How would you substantiate your thesis against a sharp counter-argument?`,
        `Summarize your concluding thought using powerful, evocative vocabulary.`,
      ],
      revisionTask: day % 5 === 0 ? `Advanced Milestone ${day}: execute a 2-minute unscripted presentation on today's theme.` : undefined,
    };
  }),
];
