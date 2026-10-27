import app from './app';
import config from './config/env';
import { connectDatabase, disconnectDatabase } from './config/database';
import logger from './utils/logger';

async function bootstrap(): Promise<void> {
  try {
    // Connect to MongoDB
    await connectDatabase();

    // Start Express server on all network interfaces
    const server = app.listen(config.port, '0.0.0.0', () => {
      logger.info(`🚀 Voxora Backend API running on http://localhost:${config.port}`);
      logger.info(`📦 MongoDB connected at: ${config.mongoUri}`);
      logger.info(`🩺 Health check available at: http://localhost:${config.port}/health`);
    });

    // Graceful shutdown handling
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
