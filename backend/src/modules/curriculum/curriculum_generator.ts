import { IDailyLesson } from './plan.model';
import { generateTeachingContent } from './teaching_content_generator';
import {
  beginnerSyllabusThemes,
  intermediateSyllabusThemes,
  advancedSyllabusThemes,
  RawThemeItem,
} from './curriculum_data';

interface CurriculumContext {
  level: 'Beginner' | 'Intermediate' | 'Advanced';
  weaknesses?: string[];
  strengths?: string[];
}

export function build90DayCurriculum(context: CurriculumContext): IDailyLesson[] {
  const level = context.level || 'Beginner';
  let themes: RawThemeItem[];

  if (level === 'Intermediate') {
    themes = intermediateSyllabusThemes;
  } else if (level === 'Advanced') {
    themes = advancedSyllabusThemes;
  } else {
    themes = beginnerSyllabusThemes;
  }

  const lessons: IDailyLesson[] = [];

  for (let i = 0; i < 90; i++) {
    const dayNumber = i + 1;
    const theme = themes[i] || themes[themes.length - 1];
    const phase = theme.phase;

    let difficulty: 'Beginner' | 'Elementary' | 'Intermediate' | 'Upper-Intermediate' | 'Advanced' = 'Beginner';
    if (level === 'Beginner') {
      difficulty = phase === 1 ? 'Beginner' : phase === 2 ? 'Elementary' : 'Intermediate';
    } else if (level === 'Intermediate') {
      difficulty = phase === 1 ? 'Intermediate' : 'Upper-Intermediate';
    } else {
      difficulty = 'Advanced';
    }

    lessons.push({
      day: dayNumber,
      phase,
      topic: theme.topic,
      objective: theme.objective,
      targetSkills: [
        'Voice Fluency',
        'Pronunciation',
        'Sentence Construction',
        ...(level === 'Advanced' ? ['Executive Cadence', 'Rhetoric'] : []),
      ],
      difficulty,
      vocabularyFocus: theme.vocab,
      grammarFocus: [theme.grammar],
      speakingActivities: theme.activities,
      miraQuestions: theme.miraQuestions,
      expectedDurationMinutes: 15,
      evaluationCriteria: [
        'Spoken fluency without mid-thought pauses',
        'Clear pronunciation and phonetic stress',
        'Accurate contextual sentence construction',
      ],
      revisionTask: theme.revisionTask,
      teachingContent: generateTeachingContent({
        day: dayNumber,
        level,
        phase,
        topic: theme.topic,
        objective: theme.objective,
        vocab: theme.vocab,
        grammar: theme.grammar,
      }),
      status: dayNumber === 1 ? 'in_progress' : 'pending',
      score: 0,
    });
  }

  return lessons;
}
