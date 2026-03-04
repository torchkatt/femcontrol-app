import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import { AuthRequest } from '../middleware/auth.middleware';

export const register = async (req: Request, res: Response) => {
    try {
        const { email, password, name, role } = req.body;
        if (!email || !password || !name) {
            res.status(400).json({ success: false, message: 'Email, contraseña y nombre son requeridos' });
            return;
        }
        const validRole = role === 'PARTNER' ? 'PARTNER' : 'PRIMARY';
        const result = await AuthService.register(email, password, name, validRole);
        res.status(201).json({ success: true, data: result });
    } catch (error: any) {
        const isDuplicate = error.message?.includes('ya está registrado');
        res.status(isDuplicate ? 409 : 400).json({ success: false, message: error.message });
    }
};

export const login = async (req: Request, res: Response) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            res.status(400).json({ success: false, message: 'Email y contraseña son requeridos' });
            return;
        }
        const result = await AuthService.login(email, password);
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(401).json({ success: false, message: error.message });
    }
};

export const googleLogin = async (req: Request, res: Response) => {
    try {
        const { idToken, serverAuthCode } = req.body;
        if (!idToken && !serverAuthCode) {
            res.status(400).json({ success: false, message: 'Se requiere idToken o serverAuthCode de Google' });
            return;
        }
        const result = await AuthService.loginWithGoogle(idToken, serverAuthCode);
        res.json({ success: true, data: result });
    } catch (error: any) {
        res.status(401).json({ success: false, message: error.message });
    }
};

export const getProfile = async (req: AuthRequest, res: Response) => {
    try {
        const profile = await AuthService.getProfile(req.user!.userId);
        res.json({ success: true, data: profile });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
};
