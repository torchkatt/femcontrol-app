import { Router } from 'express';
import { upsertLog, getLogs, getLogForDate } from '../controllers/dailyLog.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.get('/', authenticate, getLogs);
router.post('/', authenticate, upsertLog);
router.get('/:date', authenticate, getLogForDate);

export default router;
