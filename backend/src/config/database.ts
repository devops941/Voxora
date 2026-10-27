import mongoose from 'mongoose';
import config from './env';
import logger from '../utils/logger';

const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 5000;

async function connectWithRetry(attempt: number = 1): Promise<void> {
  try {
    logger.info(`MongoDB connection attempt ${attempt}/${MAX_RETRIES}...`);
    await mongoose.connect(config.mongoUri, {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    });
    logger.info('MongoDB connected successfully');

    mongoose.connection.on('disconnected', () => {
      logger.warn('MongoDB disconnected. Attempting to reconnect...');
    });

    mongoose.connection.on('reconnected', () => {
      logger.info('MongoDB reconnected successfully');
    });

    mongoose.connection.on('error', (err) => {
      logger.error('MongoDB connection error:', err);
    });
  } catch (error) {
    logger.error(`MongoDB connection attempt ${attempt} failed:`, error);
    if (attempt < MAX_RETRIES) {
      logger.info(`Retrying in ${RETRY_DELAY_MS / 1000} seconds...`);
      await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY_MS));
      return connectWithRetry(attempt + 1);
    }
    throw new Error(
      `Failed to connect to MongoDB after ${MAX_RETRIES} attempts: ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

export async function connectDatabase(): Promise<void> {
  await connectWithRetry();
}

export async function disconnectDatabase(): Promise<void> {
  await mongoose.disconnect();
  logger.info('MongoDB disconnected gracefully');
}
