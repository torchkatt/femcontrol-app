import { Response } from 'express';
import { CoupleService } from '../services/couple.service';
import { AuthRequest } from '../middleware/auth.middleware';

export const pairPartner = async (req: AuthRequest, res: Response) => {
    try {
        const { pairingCode } = req.body;
        if (!pairingCode) {
            res.status(400).json({ success: false, message: 'El código de vinculación es requerido' });
            return;
        }
        const result = await CoupleService.pairPartner(req.user!.userId, pairingCode);
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const getPartnerInfo = async (req: AuthRequest, res: Response) => {
    try {
        const partner = await CoupleService.getPartnerInfo(req.user!.userId);
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
        const result = await CoupleService.unlinkPartner(req.user!.userId);
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const getSharingSettings = async (req: AuthRequest, res: Response) => {
    try {
        const settings = await CoupleService.getSharingSettings(req.user!.userId);
        res.json({ success: true, data: settings });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const updateSharingSettings = async (req: AuthRequest, res: Response) => {
    try {
        const { fertileWindow, symptoms } = req.body;
        const updated = await CoupleService.updateSharingSettings(req.user!.userId, {
            ...(fertileWindow !== undefined && { fertileWindow }),
            ...(symptoms !== undefined && { symptoms }),
        });
        res.json({ success: true, data: updated });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};
