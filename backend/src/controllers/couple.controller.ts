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

export const getPartnerCycleStatus = async (req: AuthRequest, res: Response) => {
    try {
        const result = await CoupleService.getPartnerCycleStatus(req.user!.userId);
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
};

export const createLogForPartner = async (req: AuthRequest, res: Response) => {
    try {
        const { logDate, flowLevel, painLevel, mood, symptoms, notes } = req.body;
        if (!logDate) {
            res.status(400).json({ success: false, message: 'logDate es requerido' });
            return;
        }
        const result = await CoupleService.createLogForPartner(
            req.user!.userId, logDate, flowLevel, painLevel, mood, symptoms, notes,
        );
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
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
