import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import { AuthRequest } from '../../types';
import { User } from './user.model';
import { aiService } from '../ai/ai.service';

const router = Router();

// GET /api/v1/users/me
router.get('/me', authMiddleware, async (req: AuthRequest, res, next) => {
  try {
    const user = await User.findById(req.user!.id);
    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }
    const userJson = user.toJSON();
    res.status(200).json({
      success: true,
      data: userJson,
      ...userJson,
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/users/me
router.patch('/me', authMiddleware, async (req: AuthRequest, res, next) => {
  try {
    const { name, level, avatar_url, bio, location } = req.body;
    const updates: Record<string, unknown> = {};
    if (name) updates.name = name;
    if (level) updates.level = level;
    if (avatar_url !== undefined) updates.avatarUrl = avatar_url;
    if (bio !== undefined) updates.bio = bio;
    if (location !== undefined) updates.location = location;

    const user = await User.findByIdAndUpdate(req.user!.id, updates, { new: true });
    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }

    if (level && ['Beginner', 'Intermediate', 'Advanced'].includes(level)) {
      try {
        await aiService.getOrCreate90DayPlan({
          userId: req.user!.id,
          startingLevel: level as 'Beginner' | 'Intermediate' | 'Advanced',
          assessedProficiency: `${level} Level`,
          forceUpdate: true,
        });
      } catch (planErr) {
        // Silently continue if plan sync fails
      }
    }

    const userJson = user.toJSON();
    res.status(200).json({
      success: true,
      data: userJson,
      ...userJson,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
