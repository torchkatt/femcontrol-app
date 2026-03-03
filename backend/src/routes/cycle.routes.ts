import { Router } from 'express';
import { Response } from 'express';
import { CycleService } from '../services/cycle.service';
import { authenticate, AuthRequest } from '../middleware/auth.middleware';

const router = Router();

router.get('/current', authenticate, async (req: AuthRequest, res: Response) => {
    try {
        const status = await CycleService.getCurrentCycleStatus(req.user!.userId);
        res.json({ success: true, data: status });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
});

router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
    try {
        const { startDate, expectedLength } = req.body;
        if (!startDate) {
            res.status(400).json({ success: false, message: 'La fecha de inicio es requerida' });
            return;
        }
        const cycle = await CycleService.startCycle(req.user!.userId, startDate, expectedLength);
        res.status(201).json({ success: true, data: cycle });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
});

router.get('/history', authenticate, async (req: AuthRequest, res: Response) => {
    try {
        const cycles = await CycleService.getCycleHistory(req.user!.userId);
        res.json({ success: true, data: cycles });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
});

export default router;
