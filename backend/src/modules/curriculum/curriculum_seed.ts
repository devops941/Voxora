import logger from '../../utils/logger';
import { CurriculumTemplate } from './curriculum_template.model';
import {
  beginnerSyllabusThemes,
  intermediateSyllabusThemes,
  advancedSyllabusThemes,
  RawThemeItem,
} from './curriculum_data';

export async function seedCurriculumTemplates(): Promise<void> {
  try {
    const existingCount = await CurriculumTemplate.countDocuments();
    if (existingCount >= 270) {
      logger.info(`📚 Curriculum templates already seeded in MongoDB (${existingCount} entries).`);
      return;
    }

    logger.info(`🌱 Seeding 270 curriculum templates into MongoDB (90 Beginner, 90 Intermediate, 90 Advanced)...`);

    const prepareOps = (level: 'Beginner' | 'Intermediate' | 'Advanced', themes: RawThemeItem[]) => {
      return themes.map(t => {
        let difficulty: 'Beginner' | 'Elementary' | 'Intermediate' | 'Upper-Intermediate' | 'Advanced' = 'Beginner';
        if (level === 'Beginner') {
          difficulty = t.phase === 1 ? 'Beginner' : t.phase === 2 ? 'Elementary' : 'Intermediate';
        } else if (level === 'Intermediate') {
          difficulty = t.phase === 1 ? 'Intermediate' : 'Upper-Intermediate';
        } else {
          difficulty = 'Advanced';
        }

        return {
          updateOne: {
            filter: { level, day: t.day },
            update: {
              $set: {
                level,
                day: t.day,
                phase: t.phase,
                topic: t.topic,
                objective: t.objective,
                targetSkills: [
                  'Voice Fluency',
                  'Pronunciation',
                  'Sentence Construction',
                  ...(level === 'Advanced' ? ['Executive Cadence', 'Rhetoric'] : []),
                ],
                difficulty,
                vocabularyFocus: t.vocab,
                grammarFocus: [t.grammar],
                speakingActivities: t.activities,
                miraQuestions: t.miraQuestions,
                expectedDurationMinutes: 15,
                evaluationCriteria: [
                  'Spoken fluency without mid-thought pauses',
                  'Clear pronunciation and phonetic stress',
                  'Accurate contextual sentence construction',
                ],
                revisionTask: t.revisionTask || null,
              },
            },
            upsert: true,
          },
        };
      });
    };

    const beginnerOps = prepareOps('Beginner', beginnerSyllabusThemes);
    const intermediateOps = prepareOps('Intermediate', intermediateSyllabusThemes);
    const advancedOps = prepareOps('Advanced', advancedSyllabusThemes);

    const allOps = [...beginnerOps, ...intermediateOps, ...advancedOps];

    await CurriculumTemplate.bulkWrite(allOps);

    const totalNow = await CurriculumTemplate.countDocuments();
    logger.info(`✅ Successfully seeded ${totalNow} distinct curriculum templates in MongoDB!`);
  } catch (err) {
    logger.error('Failed to seed curriculum templates in MongoDB:', err);
  }
}
