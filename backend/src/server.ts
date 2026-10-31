import app from './app';
import config from './config/env';
import { connectDatabase, disconnectDatabase } from './config/database';
import { seedCurriculumTemplates } from './modules/curriculum/curriculum_seed';
import logger from './utils/logger';

// Vercel serverless: cache DB connection across warm invocations
let isDbConnected = false;

async function ensureDatabase(): Promise<void> {
  if (!isDbConnected) {
    await connectDatabase();
    await seedCurriculumTemplates();
    isDbConnected = true;
  }
}

// Vercel serverless export
if (process.env.VERCEL) {
  ensureDatabase().catch(err => logger.error('DB init failed:', err));
  module.exports = app;
} else {
  // Local / traditional server
  async function bootstrap(): Promise<void> {
    try {
      await connectDatabase();
      await seedCurriculumTemplates();

      const server = app.listen(config.port, '0.0.0.0', () => {
        logger.info(`🚀 Voxora Backend API running on http://localhost:${config.port}`);
        logger.info(`📦 MongoDB connected at: ${config.mongoUri}`);
        logger.info(`🩺 Health check available at: http://localhost:${config.port}/health`);
      });

      const shutdown = async (signal: string) => {
        logger.info(`${signal} signal received: closing HTTP server and database...`);
        server.close(async () => {
          logger.info('HTTP server closed');
          await disconnectDatabase();
          process.exit(0);
        });
      };

      process.on('SIGTERM', () => shutdown('SIGTERM'));
      process.on('SIGINT', () => shutdown('SIGINT'));
    } catch (error) {
      logger.error('Failed to start server:', error);
      process.exit(1);
    }
  }

  bootstrap();
}
