import prisma from '../utils/db';

function calculatePhase(day: number): string {
    if (day <= 5) return 'menstrual';
    if (day <= 13) return 'folicular';
    if (day <= 16) return 'ovulacion';
    return 'lutea';
}

export class CoupleService {
    static async pairPartner(userId: string, pairingCode: string) {
        // Find partner by pairing code
        const partner = await prisma.user.findUnique({ where: { pairingCode } });
        if (!partner) throw new Error('Código de vinculación inválido');
        if (partner.id === userId) throw new Error('No puedes vincularte contigo mismo');
        if (partner.partnerId) throw new Error('Esta persona ya tiene una pareja vinculada');

        const currentUser = await prisma.user.findUnique({ where: { id: userId } });
        if (!currentUser) throw new Error('Usuario no encontrado');
        if (currentUser.partnerId) throw new Error('Ya tienes una pareja vinculada');

        // Link both users to each other
        await prisma.user.update({ where: { id: userId }, data: { partnerId: partner.id } });
        await prisma.user.update({ where: { id: partner.id }, data: { partnerId: userId } });

        return { message: 'Pareja vinculada exitosamente', partnerId: partner.id, partnerName: partner.name };
    }

    static async getPartnerInfo(userId: string) {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                partner: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        cycles: { orderBy: { startDate: 'desc' }, take: 1 },
                    },
                },
            },
        });
        if (!user || !user.partner) throw new Error('No tienes una pareja vinculada');
        return user.partner;
    }

    static async getPartnerCycleStatus(userId: string) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                partner: {
                    include: {
                        cycles: {
                            where: { endDate: null },
                            orderBy: { startDate: 'desc' },
                            take: 1,
                        },
                        dailyLogs: {
                            where: { logDate: { gte: today, lt: tomorrow } },
                            take: 1,
                        },
                    },
                },
            },
        });
        if (!user?.partner) throw new Error('No tienes una pareja vinculada');

        const { partner } = user;
        const cycle = partner.cycles[0];
        if (!cycle) {
            return { partnerName: partner.name, hasActiveCycle: false };
        }

        const MS_PER_DAY = 1000 * 60 * 60 * 24;
        const startDate = new Date(cycle.startDate);
        startDate.setHours(0, 0, 0, 0);
        const currentDay = Math.max(1, Math.floor((today.getTime() - startDate.getTime()) / MS_PER_DAY) + 1);
        const phase = calculatePhase(currentDay);
        const daysUntilPeriod = Math.max(0, cycle.expectedLength - currentDay);

        const todayLog = partner.dailyLogs[0] ?? null;

        return {
            partnerName: partner.name,
            hasActiveCycle: true,
            currentDay,
            expectedLength: cycle.expectedLength,
            phase,
            daysUntilPeriod,
            todayLog,
        };
    }

    static async createLogForPartner(
        userId: string,
        logDate: string,
        flowLevel?: number,
        painLevel?: number,
        mood?: string[],
        symptoms?: string[],
        notes?: string,
    ) {
        const user = await prisma.user.findUnique({ where: { id: userId }, select: { partnerId: true } });
        if (!user?.partnerId) throw new Error('No tienes una pareja vinculada');

        const date = new Date(logDate);
        date.setHours(0, 0, 0, 0);

        const moodJson = mood ? JSON.stringify(mood) : undefined;
        const symptomsJson = symptoms ? JSON.stringify(symptoms) : undefined;

        await prisma.dailyLog.upsert({
            where: { userId_logDate: { userId: user.partnerId, logDate: date } },
            create: {
                userId: user.partnerId,
                logDate: date,
                flowLevel: flowLevel ?? null,
                painLevel: painLevel ?? null,
                mood: moodJson ?? null,
                symptoms: symptomsJson ?? null,
                notes: notes ?? null,
            },
            update: {
                ...(flowLevel !== undefined && { flowLevel }),
                ...(painLevel !== undefined && { painLevel }),
                ...(moodJson !== undefined && { mood: moodJson }),
                ...(symptomsJson !== undefined && { symptoms: symptomsJson }),
                ...(notes !== undefined && { notes }),
            },
        });

        return { message: 'Registro guardado exitosamente' };
    }

    static async unlinkPartner(userId: string) {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user || !user.partnerId) throw new Error('No tienes una pareja vinculada');

        await prisma.user.update({ where: { id: userId }, data: { partnerId: null } });
        await prisma.user.update({ where: { id: user.partnerId }, data: { partnerId: null } });
        return { message: 'Pareja desvinculada exitosamente' };
    }
}
