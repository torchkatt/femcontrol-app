import { Router } from 'express';
import { pairPartner, getPartnerInfo, unlinkPartner } from '../controllers/couple.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.post('/pair', authenticate, pairPartner);
router.get('/partner', authenticate, getPartnerInfo);
router.delete('/unlink', authenticate, unlinkPartner);

export default router;
