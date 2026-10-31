import { Router } from 'express';
import { certificateController } from './certificate.controller';
import { authMiddleware } from '../../middleware/auth.middleware';

const router = Router();

router.use(authMiddleware);

router.post('/', (req, res, next) => certificateController.generateCertificate(req, res, next));
router.get('/download/:certificateId', (req, res, next) => certificateController.downloadCertificate(req, res, next));

export default router;
