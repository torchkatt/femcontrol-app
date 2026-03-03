import { Response } from 'express';
import { DailyLogService } from '../services/dailyLog.service';
import { AuthRequest } from '../middleware/auth.middleware';

export const upsertLog = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const { logDate, flowLevel, painLevel, mood, symptoms, notes } = req.body;
        if (!logDate) {
            res.status(400).json({ success: false, message: 'La fecha de registro es requerida' });
            return;
        }
        const log = await DailyLogService.upsertLog({ userId, logDate, flowLevel, painLevel, mood, symptoms, notes });
        res.status(200).json({ success: true, data: log });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getLogs = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const limit = req.query.limit ? Number(req.query.limit) : 60;
        const logs = await DailyLogService.getLogs(userId, limit);
        res.json({ success: true, data: logs });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getLogForDate = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const date = req.params.date as string;
        const log = await DailyLogService.getLogForDate(userId, date);
        res.json({ success: true, data: log });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};
