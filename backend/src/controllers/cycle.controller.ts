import { Request, Response } from 'express';
import { CycleService } from '../services/cycle.service';

export const getCurrentCycle = async (req: Request, res: Response) => {
    try {
        const userId = req.params.userId as string;
        const status = await CycleService.getCurrentCycleStatus(userId);
        res.json({ success: true, data: status });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
};
