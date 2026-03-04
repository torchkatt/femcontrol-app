import { Router } from 'express';
import { pairPartner, getPartnerInfo, unlinkPartner, getPartnerCycleStatus, createLogForPartner, getSharingSettings, updateSharingSettings } from '../controllers/couple.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.post('/pair', authenticate, pairPartner);
router.get('/partner', authenticate, getPartnerInfo);
router.get('/partner/cycle', authenticate, getPartnerCycleStatus);
router.post('/partner/log', authenticate, createLogForPartner);
router.delete('/unlink', authenticate, unlinkPartner);
router.get('/sharing', authenticate, getSharingSettings);
router.put('/sharing', authenticate, updateSharingSettings);

export default router;
