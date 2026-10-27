import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import mongoose from 'mongoose';
import { errorMiddleware, notFoundMiddleware } from './middleware/error.middleware';
import authRoutes from './modules/auth/auth.routes';
import userRoutes from './modules/users/user.routes';
import aiRoutes from './modules/ai/ai.routes';
import lessonRoutes from './modules/lessons/lesson.routes';

const app: Application = express();

// Security & utility middlewares
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Health check endpoints
app.get('/health', (_req: Request, res: Response) => {
  const dbState = mongoose.connection.readyState;
  const dbStatus = dbState === 1 ? 'connected' : dbState === 2 ? 'connecting' : 'disconnected';
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    database: {
      type: 'MongoDB',
      status: dbStatus,
    },
  });
});

app.get('/api/v1/health', (_req: Request, res: Response) => {
  const dbState = mongoose.connection.readyState;
  const dbStatus = dbState === 1 ? 'connected' : dbState === 2 ? 'connecting' : 'disconnected';
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    database: {
      type: 'MongoDB',
      status: dbStatus,
    },
  });
});

// ── API Routes (support both /api/v1 and root paths) ──
app.use('/api/v1/auth', authRoutes);
app.use('/auth', authRoutes);

app.use('/api/v1/users', userRoutes);
app.use('/users', userRoutes);

app.use('/api/v1/ai', aiRoutes);
app.use('/ai', aiRoutes);

app.use('/api/v1/lessons', lessonRoutes);
app.use('/lessons', lessonRoutes);

// ── 404 & Error Handling ────────────────────────────
app.use(notFoundMiddleware);
app.use(errorMiddleware);

export default app;
