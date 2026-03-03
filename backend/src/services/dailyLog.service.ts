import prisma from '../utils/db';

interface DailyLogInput {
    userId: string;
    logDate: string;
    flowLevel?: number;
    painLevel?: number;
    mood?: string[];
    symptoms?: string[];
    notes?: string;
}

export class DailyLogService {
    static async upsertLog(input: DailyLogInput) {
        const date = new Date(input.logDate);
        date.setUTCHours(0, 0, 0, 0);

        return prisma.dailyLog.upsert({
            where: { userId_logDate: { userId: input.userId, logDate: date } },
            update: {
                ...(input.flowLevel !== undefined && { flowLevel: input.flowLevel }),
                ...(input.painLevel !== undefined && { painLevel: input.painLevel }),
                ...(input.mood !== undefined && { mood: JSON.stringify(input.mood) }),
                ...(input.symptoms !== undefined && { symptoms: JSON.stringify(input.symptoms) }),
                ...(input.notes !== undefined && { notes: input.notes }),
            },
            create: {
                userId: input.userId,
                logDate: date,
                flowLevel: input.flowLevel ?? null,
                painLevel: input.painLevel ?? null,
                mood: input.mood ? JSON.stringify(input.mood) : null,
                symptoms: input.symptoms ? JSON.stringify(input.symptoms) : null,
                notes: input.notes ?? null,
            },
        });
    }

    static async getLogs(userId: string, limit = 60) {
        const logs = await prisma.dailyLog.findMany({
            where: { userId },
            orderBy: { logDate: 'desc' },
            take: limit,
        });
        return logs.map((log) => ({
            ...log,
            mood: log.mood ? JSON.parse(log.mood) : [],
            symptoms: log.symptoms ? JSON.parse(log.symptoms) : [],
        }));
    }

    static async getLogForDate(userId: string, date: string) {
        const d = new Date(date);
        d.setUTCHours(0, 0, 0, 0);
        const log = await prisma.dailyLog.findUnique({
            where: { userId_logDate: { userId, logDate: d } },
        });
        if (!log) return null;
        return {
            ...log,
            mood: log.mood ? JSON.parse(log.mood) : [],
            symptoms: log.symptoms ? JSON.parse(log.symptoms) : [],
        };
    }
}
