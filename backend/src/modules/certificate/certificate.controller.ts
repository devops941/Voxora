import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../types';
import { verifyAccessToken } from '../../utils/jwt.utils';
import { certificateService } from './certificate.service';

function extractUserId(req: any): string | undefined {
  if (req.user?.id) return req.user.id;
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      return verifyAccessToken(authHeader.slice(7).trim()).id;
    } catch {
      // ignore
    }
  }
  return req.query.userId || req.body.userId;
}

export class CertificateController {
  async generateCertificate(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(401).json({ success: false, message: 'Unauthorized' });
        return;
      }
      const { assessmentId, fullName, email } = req.body;
      if (!assessmentId || !fullName || !email) {
        res.status(400).json({
          success: false,
          message: 'assessmentId, fullName, and email are required',
        });
        return;
      }
      const result = await certificateService.generateCertificate(
        userId,
        assessmentId,
        fullName.trim(),
        email.trim()
      );
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  async downloadCertificate(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        res.status(401).json({ success: false, message: 'Unauthorized' });
        return;
      }
      const { certificateId } = req.params;
      if (!certificateId) {
        res.status(400).json({ success: false, message: 'certificateId is required' });
        return;
      }
      const { buffer, filename, isTestMode } = await certificateService.downloadCertificate(
        certificateId,
        userId
      );
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      res.setHeader('Content-Length', buffer.length);
      if (isTestMode) res.setHeader('X-Test-Certificate', 'true');
      res.send(buffer);
    } catch (error) {
      next(error);
    }
  }
}

export const certificateController = new CertificateController();
