import bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import prisma from '../utils/db';
import { signToken } from '../utils/jwt';

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID ?? '';
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET ?? '';

const googleClient = new OAuth2Client(
    GOOGLE_CLIENT_ID,
    GOOGLE_CLIENT_SECRET,
    'postmessage' // Usado habitualmente por Fluter/Web plugins
);

const safeUserSelect = {
    id: true,
    email: true,
    name: true,
    role: true,
    pairingCode: true,
    partnerId: true,
    googleId: true,
    createdAt: true,
} as const;

export class AuthService {
    static async register(email: string, password: string, name: string) {
        const existing = await prisma.user.findUnique({ where: { email } });
        if (existing) throw new Error('Este correo ya está registrado');

        const passwordHash = await bcrypt.hash(password, 12);
        const user = await prisma.user.create({
            data: { email, name, passwordHash },
            select: safeUserSelect,
        });

        const token = signToken({ userId: user.id, email: user.email, role: user.role });
        return { user, token };
    }

    static async login(email: string, password: string) {
        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) throw new Error('No existe una cuenta con ese correo. ¿Quieres registrarte?');
        if (!user.passwordHash) throw new Error('Esta cuenta fue creada con Google. Usa el botón de Google para iniciar sesión.');

        const isValid = await bcrypt.compare(password, user.passwordHash);
        if (!isValid) throw new Error('Contraseña incorrecta.');

        const { passwordHash: _, ...safeUser } = user;
        const token = signToken({ userId: user.id, email: user.email, role: user.role });
        return { user: safeUser, token };
    }

    static async loginWithGoogle(idToken?: string, serverAuthCode?: string) {
        if (!GOOGLE_CLIENT_ID) throw new Error('Google OAuth no configurado en el servidor');

        let finalIdToken = idToken;

        // Exchange serverAuthCode for Tokens if we don't have idToken
        // Typically happens on Flutter Web
        if (!finalIdToken && serverAuthCode) {
            if (!GOOGLE_CLIENT_SECRET) throw new Error('Google Oauth Client Secret no configuro');

            try {
                const { tokens } = await googleClient.getToken(serverAuthCode);
                finalIdToken = tokens.id_token || undefined;
            } catch (e) {
                console.error("Error exchanging code:", e);
                throw new Error('Error al validar el código de autenticación con Google');
            }
        }

        if (!finalIdToken) throw new Error('No se pudo resolver el ID Token de Google');

        let payload;
        try {
            const ticket = await googleClient.verifyIdToken({
                idToken: finalIdToken,
                audience: GOOGLE_CLIENT_ID,
            });
            payload = ticket.getPayload();
        } catch (e) {
            console.error("Error verifying ID Token:", e);
        }

        if (!payload || !payload.email) throw new Error('Token de Google inválido');

        const { email, name = 'Usuario', sub: googleId } = payload;

        let user = await prisma.user.findFirst({
            where: { OR: [{ googleId }, { email }] },
        });

        if (user) {
            if (!user.googleId) {
                user = await prisma.user.update({ where: { id: user.id }, data: { googleId } });
            }
        } else {
            user = await prisma.user.create({ data: { email, name, googleId } });
        }

        const token = signToken({ userId: user.id, email: user.email, role: user.role });
        const { passwordHash: _pw, ...safeUser } = user;
        return { user: safeUser, token };
    }

    static async getProfile(userId: string) {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: safeUserSelect,
        });
        if (!user) throw new Error('Usuario no encontrado');
        return user;
    }
}
