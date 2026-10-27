import { IDailyLesson } from './plan.model';

interface CurriculumContext {
  level: 'Beginner' | 'Intermediate' | 'Advanced';
  weaknesses?: string[];
  strengths?: string[];
}

export function build90DayCurriculum(context: CurriculumContext): IDailyLesson[] {
  const level = context.level || 'Beginner';
  const lessons: IDailyLesson[] = [];

  // 90 Curated Themes based on CEFR progression
  const beginnerThemes = [
    // Phase 1 (Days 1-30): Foundation & Daily Routines
    { topic: 'Self-Introduction & Origins', vocab: ['Hometown', 'Profession', 'Hobbies'], grammar: 'Present Simple (I am / I live)' },
    { topic: 'Family & Close Friends', vocab: ['Siblings', 'Parent', 'Colleague'], grammar: 'Possessive adjectives (My / Their)' },
    { topic: 'Daily Morning Routine', vocab: ['Wake up', 'Commute', 'Breakfast'], grammar: 'Adverbs of frequency (Always, Usually)' },
    { topic: 'Favorite Foods & Eating Out', vocab: ['Delicious', 'Order', 'Spicy'], grammar: 'Countable & uncountable nouns' },
    { topic: 'Describing Your Home & Room', vocab: ['Balcony', 'Cozy', 'Neighborhood'], grammar: 'Prepositions of place (In, On, Near)' },
    { topic: 'Telling Time & Daily Schedules', vocab: ['Quarter past', 'Schedule', 'Midnight'], grammar: 'Time expressions (At 7 AM, In July)' },
    { topic: 'Weather & Seasons', vocab: ['Breezy', 'Forecast', 'Humid'], grammar: 'Adjectives of condition' },
    { topic: 'Shopping & Basic Bargaining', vocab: ['Discount', 'Receipt', 'Affordable'], grammar: 'How much / How many' },
    { topic: 'Asking for Directions', vocab: ['Crossroad', 'Opposite', 'Turn left'], grammar: 'Imperatives & directional prepositions' },
    { topic: 'Hobbies & Free Time Fun', vocab: ['Photography', 'Gardening', 'Unwind'], grammar: 'Verb + -ing (I enjoy reading)' },
    { topic: 'Weekend Plans', vocab: ['Barbecue', 'Excursion', 'Relax'], grammar: 'Going to / Will for future' },
    { topic: 'Describing Clothes & Style', vocab: ['Casual', 'Formal', 'Comfortable'], grammar: 'Present Continuous for wear' },
    { topic: 'Favorite Movies & TV Shows', vocab: ['Actor', 'Plot', 'Suspenseful'], grammar: 'Expressing likes & dislikes' },
    { topic: 'Ordering Coffee & Food at a Cafe', vocab: ['Espresso', 'Takeaway', 'Pastry'], grammar: 'Polite requests (Could I have...)' },
    { topic: 'Public Transport & Traveling in City', vocab: ['Platform', 'Fare', 'Subway'], grammar: 'Modal verbs of movement' },
    { topic: 'Health & Visiting a Doctor', vocab: ['Headache', 'Prescription', 'Rest'], grammar: 'Expressing symptoms (I have a...)' },
    { topic: 'Describing People & Appearances', vocab: ['Tall', 'Outgoing', 'Curly hair'], grammar: 'Look like vs Be like' },
    { topic: 'At the Grocery Supermarket', vocab: ['Aisle', 'Checkout', 'Fresh produce'], grammar: 'Quantifiers (A few, A little)' },
    { topic: 'Childhood Memories', vocab: ['Nostalgic', 'Primary school', 'Playground'], grammar: 'Past Simple (Used to)' },
    { topic: 'My Best Friend & Why They Matter', vocab: ['Trustworthy', 'Supportive', 'Bond'], grammar: 'Relative clauses (Who / Which)' },
    { topic: 'Celebrations & Festivals', vocab: ['Gathering', 'Fireworks', 'Tradition'], grammar: 'Past celebrations (We celebrated)' },
    { topic: 'Describing Your City & Highlights', vocab: ['Monument', 'Lively', 'Traffic'], grammar: 'Comparatives (Bigger than...)' },
    { topic: 'Phone Conversations & Etiquette', vocab: ['Hold on', 'Voicemail', 'Call back'], grammar: 'Telephone phrases' },
    { topic: 'Music & Emotions', vocab: ['Melody', 'Rhythm', 'Uplifting'], grammar: 'Sensory verbs (Sounds like...)' },
    { topic: 'A Memorable Holiday Trip', vocab: ['Souvenir', 'Scenery', 'Flight'], grammar: 'Past Continuous (While traveling...)' },
    { topic: 'Expressing Likes, Dislikes & Preferences', vocab: ['Prefer', 'Can’t stand', 'Fond of'], grammar: 'Would rather / Prefer to' },
    { topic: 'Sports & Keeping Fit', vocab: ['Gym', 'Stamina', 'Workout'], grammar: 'Play vs Do vs Go sports' },
    { topic: 'Animals & Pets', vocab: ['Playful', 'Loyal', 'Adopt'], grammar: 'Adjectives of character' },
    { topic: 'Technology & Everyday Apps', vocab: ['Download', 'Notification', 'Browse'], grammar: 'Present Perfect for tech usage' },
    { topic: 'Phase 1 Review & Confident Speaking Test', vocab: ['Milestone', 'Achievement', 'Fluency'], grammar: 'Synthesis of tenses' },

    // Phase 2 (Days 31-60): Conversational English & Workplace
    { topic: 'Job Roles & Responsibilities', vocab: ['Collaborate', 'Deadline', 'Supervise'], grammar: 'Present Simple for profession' },
    { topic: 'A Typical Workday Schedule', vocab: ['Prioritize', 'Meeting', 'Task'], grammar: 'Sequence linkers (First, Then, Finally)' },
    { topic: 'Giving and Receiving Feedback', vocab: ['Constructive', 'Improvement', 'Praise'], grammar: 'Softening language (Could be better)' },
    { topic: 'Making Professional Appointments', vocab: ['Convenient', 'Reschedule', 'Confirm'], grammar: 'Modal verbs of arrangement' },
    { topic: 'Expressing Opinions in a Group', vocab: ['In my view', 'From my standpoint', 'Persist'], grammar: 'Opinion signposts' },
    { topic: 'Agreeing and Respectfully Disagreeing', vocab: ['Concur', 'Differ', 'Valid point'], grammar: 'Polite disagreement formulas' },
    { topic: 'Handling Complaints Politely', vocab: ['Apologize', 'Rectify', 'Inconvenience'], grammar: 'Conditionals (If you could...)' },
    { topic: 'Explaining a Problem & Requesting Help', vocab: ['Glitch', 'Assistance', 'Urgent'], grammar: 'Can you lend a hand...' },
    { topic: 'Describing a Product or Service', vocab: ['Feature', 'Benefit', 'Cost-effective'], grammar: 'Superlatives (The most reliable)' },
    { topic: 'Booking a Hotel Room & Inquiries', vocab: ['Amenities', 'Reservation', 'Complimentary'], grammar: 'Indirect questions (Could you tell me...)' },
    { topic: 'Dining at a Fine Restaurant', vocab: ['Appetizer', 'Cuisine', 'Chef’s special'], grammar: 'Formal restaurant expressions' },
    { topic: 'At the Airport & Security Check', vocab: ['Boarding pass', 'Luggage', 'Terminal'], grammar: 'Airport directives' },
    { topic: 'Asking for Recommendations in a New City', vocab: ['Hidden gem', 'Attraction', 'Locals'], grammar: 'Recommend + -ing' },
    { topic: 'Describing Feelings & Emotions', vocab: ['Overwhelmed', 'Delighted', 'Anxious'], grammar: 'Adjectives ending in -ed vs -ing' },
    { topic: 'Talking About Future Career Goals', vocab: ['Ambition', 'Promotion', 'Skillset'], grammar: 'Future plans (Hope to / Plan to)' },
    { topic: 'Online Shopping & Returns', vocab: ['Tracking number', 'Refund', 'Defective'], grammar: 'Conditional (If it doesn’t arrive...)' },
    { topic: 'Talking About Books & Articles', vocab: ['Author', 'Insight', 'Inspiring'], grammar: 'Summarizing main ideas' },
    { topic: 'Environmental Awareness & Green Habits', vocab: ['Recycle', 'Renewable', 'Footprint'], grammar: 'Should / Ought to' },
    { topic: 'Social Media Habits & Digital Life', vocab: ['Influencer', 'Algorithm', 'Scroll'], grammar: 'Gerunds as subjects' },
    { topic: 'Solving Everyday Conflicts', vocab: ['Compromise', 'Misunderstanding', 'Mediate'], grammar: 'I understand, but...' },
    { topic: 'Describing a Dream Destination', vocab: ['Breathtaking', 'Exotic', 'Bucket list'], grammar: 'Second conditional (If I went to...)' },
    { topic: 'Cooking & Explaining a Recipe', vocab: ['Ingredients', 'Simmer', 'Garnish'], grammar: 'Imperatives & cooking verbs' },
    { topic: 'Fitness Goals & Healthy Habits', vocab: ['Nutrition', 'Endurance', 'Balanced'], grammar: 'Advice modals' },
    { topic: 'Networking & Icebreakers at Events', vocab: ['Connect', 'Industry', 'Mutual contact'], grammar: 'Small talk openers' },
    { topic: 'Telling a Humorous Story', vocab: ['Hilarious', 'Unexpected', 'Punched'], grammar: 'Narrative past tenses' },
    { topic: 'Describing Cultural Traditions', vocab: ['Heritage', 'Ritual', 'Ancestral'], grammar: 'Passive voice (Is celebrated)' },
    { topic: 'Money Management & Saving Tips', vocab: ['Budget', 'Investment', 'Expense'], grammar: 'Expressing advice' },
    { topic: 'Discussing Art, Music & Creativity', vocab: ['Expression', 'Abstract', 'Masterpiece'], grammar: 'Expressing artistic nuance' },
    { topic: 'Handling an Emergency Situation', vocab: ['First aid', 'Paramedic', 'Safety precaution'], grammar: 'Urgent imperatives' },
    { topic: 'Phase 2 Milestone Review & Fluency Check', vocab: ['Spontaneity', 'Confidence', 'Clarity'], grammar: 'Intermediate fluency synthesis' },

    // Phase 3 (Days 61-90): Advanced Spoken Mastery & Spontaneity
    { topic: 'Job Interview: Pitching Yourself', vocab: ['Expertise', 'Accomplishment', 'Asset'], grammar: 'Present Perfect Continuous' },
    { topic: 'Job Interview: Handling Behavioral Questions', vocab: ['Situation', 'Action', 'Outcome'], grammar: 'STAR method narration' },
    { topic: 'Job Interview: Strengths & Weaknesses', vocab: ['Self-awareness', 'Vulnerable', 'Growth'], grammar: 'Reframing negatives positively' },
    { topic: 'Pitching an Idea to a Team', vocab: ['Proposal', 'Stakeholder', 'ROI'], grammar: 'Persuasive language' },
    { topic: 'Delivering a Short Presentation', vocab: ['Slide', 'Transition', 'Takeaway'], grammar: 'Signposting (Moving to my next point...)' },
    { topic: 'Negotiating a Better Deal or Salary', vocab: ['Counteroffer', 'Terms', 'Flexibility'], grammar: 'Conditional negotiation phrases' },
    { topic: 'Debating Pro vs Con: Remote Work', vocab: ['Flexibility', 'Burnout', 'Productivity'], grammar: 'Contrasting linkers (Whereas, While)' },
    { topic: 'Debating: Artificial Intelligence in Society', vocab: ['Automation', 'Ethics', 'Disruption'], grammar: 'Hypothetical structures' },
    { topic: 'Impromptu Speaking on Unfamiliar Topics', vocab: ['Spontaneous', 'On the fly', 'Elaborate'], grammar: 'Filler phrases for thinking time' },
    { topic: 'Storytelling with Emotional Resonance', vocab: ['Climax', 'Turning point', 'Epiphany'], grammar: 'Dramatic narrative pacing' },
    { topic: 'Nuances of Body Language & Tone', vocab: ['Intonation', 'Eye contact', 'Inflection'], grammar: 'Stress and cadence' },
    { topic: 'Everyday Idioms in Natural Speech', vocab: ['Bite the bullet', 'Break a leg', 'Piece of cake'], grammar: 'Idiom contextual integration' },
    { topic: 'Phrasal Verbs for Casual Conversation', vocab: ['Figure out', 'Look up to', 'Call off'], grammar: 'Separable vs inseparable' },
    { topic: 'American vs British English Nuances', vocab: ['Apartment/Flat', 'Elevator/Lift', 'Accent'], grammar: 'Dialect variations' },
    { topic: 'Active Listening & Showing Empathy', vocab: ['Acknowledge', 'Validate', 'Compassion'], grammar: 'Echo questions (Did you really?)' },
    { topic: 'Giving Clear Instructions & Demonstrations', vocab: ['Step-by-step', 'Ensure', 'Caution'], grammar: 'Sequential instructional cues' },
    { topic: 'Discussing Global News & Trends', vocab: ['Current affairs', 'Headline', 'Perspective'], grammar: 'Reported speech (He claimed that...)' },
    { topic: 'Philosophy & Life Lessons', vocab: ['Wisdom', 'Perspective', 'Resilience'], grammar: 'Third conditional (Had I known...)' },
    { topic: 'Cross-Cultural Communication Nuances', vocab: ['Stereotype', 'Cultural norm', 'Adaptability'], grammar: 'Modal deduction (Must have been...)' },
    { topic: 'Speaking Politely in Awkward Situations', vocab: ['Tactful', 'Discretion', 'Diplomatic'], grammar: 'Subjunctive & polite softening' },
    { topic: 'Handling Critical Q&A Confidently', vocab: ['Clarification', 'Rebuttal', 'Address'], grammar: 'Answering under pressure' },
    { topic: 'Speaking with Humor & Wit', vocab: ['Sarcasm', 'Playful', 'Punchline'], grammar: 'Timing and lighthearted tone' },
    { topic: 'Discussing Books, Films & Deep Themes', vocab: ['Symbolism', 'Protagonist', 'Underlying theme'], grammar: 'Critical analysis structures' },
    { topic: 'Leading a Virtual Video Call', vocab: ['Unmute', 'Screen share', 'Agenda'], grammar: 'Conference facilitation phrases' },
    { topic: 'Expressing Gratitude & Appreciation Deeply', vocab: ['Indebted', 'Heartfelt', 'Value your effort'], grammar: 'Formal thank-you formulas' },
    { topic: 'Crisis Communication & Staying Calm', vocab: ['Composure', 'Urgent', 'Protocol'], grammar: 'Decisive imperative speech' },
    { topic: 'Inspiring Others & Motivational Speech', vocab: ['Vision', 'Empower', 'Perseverance'], grammar: 'Rhetorical questions' },
    { topic: 'Spontaneous 2-Minute Speech Marathon', vocab: ['Unprepared', 'Coherence', 'Flow'], grammar: 'Sustained monologue connectors' },
    { topic: 'The 90-Day Transformation Journey', vocab: ['Metamorphosis', 'Progress', 'Self-assurance'], grammar: 'Reflective past to present' },
    { topic: 'Graduation Day: Fluent Speech with Mira', vocab: ['Mastery', 'Articulate', 'Native-like confidence'], grammar: 'Complete spoken fluency' },
  ];

  // Adjust difficulty and vocabulary according to selected level
  for (let i = 0; i < 90; i++) {
    const dayNumber = i + 1;
    const theme = beginnerThemes[i];
    const phase = dayNumber <= 30 ? 1 : dayNumber <= 60 ? 2 : 3;

    let difficulty: 'Beginner' | 'Elementary' | 'Intermediate' | 'Upper-Intermediate' | 'Advanced' = 'Beginner';
    if (level === 'Beginner') {
      difficulty = phase === 1 ? 'Beginner' : phase === 2 ? 'Elementary' : 'Intermediate';
    } else if (level === 'Intermediate') {
      difficulty = phase === 1 ? 'Intermediate' : phase === 2 ? 'Upper-Intermediate' : 'Upper-Intermediate';
    } else {
      difficulty = phase === 1 ? 'Upper-Intermediate' : 'Advanced';
    }

    // Mira's questions tailored to day's topic
    const miraQuestions = [
      `Hi there! Today we are exploring "${theme.topic}". To start off, how would you describe your experience with this?`,
      `That's great! Can you give me a specific real-life example using words like "${theme.vocab[0]}" or "${theme.vocab[1]}"?`,
      `Well said! Finally, try saying a full sentence focusing on ${theme.grammar}. Take your time, I am listening!`,
    ];

    lessons.push({
      day: dayNumber,
      phase,
      topic: theme.topic,
      objective: `Master speaking naturally about ${theme.topic.toLowerCase()} using clear pronunciation and correct ${theme.grammar}.`,
      targetSkills: ['Voice Fluency', 'Pronunciation', 'Sentence Construction'],
      difficulty,
      vocabularyFocus: theme.vocab,
      grammarFocus: [theme.grammar],
      speakingActivities: [
        'Warm-up response with Mira',
        'Vocabulary usage in context',
        'Sentence repetition and pronunciation drill',
      ],
      miraQuestions,
      expectedDurationMinutes: 15,
      evaluationCriteria: [
        'Fluency without long hesitation (>60 WPM)',
        'Accurate usage of target vocabulary',
        'Clear sentence structure and natural intonation',
      ],
      revisionTask: dayNumber % 5 === 0 ? 'Review mistakes from the last 4 days and record a 1-minute summary.' : undefined,
      status: dayNumber === 1 ? 'in_progress' : 'pending',
      score: 0,
    });
  }

  return lessons;
}
