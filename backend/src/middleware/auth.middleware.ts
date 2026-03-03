import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';

export interface AuthRequest extends Request {
    user?: { userId: string; email: string; role: string };
}

export const authenticate = (req: AuthRequest, res: Response, next: NextFunction): void => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ success: false, message: 'No autorizado' });
        return;
    }
    try {
        const token = authHeader.split(' ')[1]!;
        req.user = verifyToken(token);
        next();
    } catch {
        res.status(401).json({ success: false, message: 'Token inválido o expirado' });
    }
};
