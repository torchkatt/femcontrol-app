import { Response } from 'express';
import { CoupleService } from '../services/couple.service';
import { AuthRequest } from '../middleware/auth.middleware';

export const pairPartner = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const { pairingCode } = req.body;
        if (!pairingCode) {
            res.status(400).json({ success: false, message: 'El código de vinculación es requerido' });
            return;
        }
        const result = await CoupleService.pairPartner(userId, pairingCode);
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const getPartnerInfo = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const partner = await CoupleService.getPartnerInfo(userId);
        res.json({ success: true, data: partner });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
};

export const unlinkPartner = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const result = await CoupleService.unlinkPartner(userId);
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};
