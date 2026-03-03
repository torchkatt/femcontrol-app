import prisma from '../utils/db';

export class CycleService {
    static async getCurrentCycleStatus(userId: string) {
        const activeCycle = await prisma.cycle.findFirst({
            where: { userId },
            orderBy: { startDate: 'desc' },
        });

        if (!activeCycle) return null;

        const today = new Date();
        today.setUTCHours(0, 0, 0, 0);
        const start = new Date(activeCycle.startDate);
        start.setUTCHours(0, 0, 0, 0);

        const cycleDay = Math.floor((today.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;
        const nextPeriodDate = new Date(start);
        nextPeriodDate.setDate(nextPeriodDate.getDate() + activeCycle.expectedLength);

        // Determine phase
        let phase = 'menstrual';
        if (cycleDay > 5 && cycleDay <= 13) phase = 'folicular';
        else if (cycleDay >= 14 && cycleDay <= 16) phase = 'ovulacion';
        else if (cycleDay > 16) phase = 'lutea';

        return {
            cycleId: activeCycle.id,
            currentDay: Math.max(1, cycleDay),
            expectedLength: activeCycle.expectedLength,
            startDate: activeCycle.startDate,
            nextPeriodDate,
            phase,
            daysUntilNextPeriod: Math.max(0, activeCycle.expectedLength - cycleDay),
        };
    }

    static async startCycle(userId: string, startDate: string, expectedLength = 28) {
        const date = new Date(startDate);
        date.setUTCHours(0, 0, 0, 0);

        // Close previous cycle
        const lastCycle = await prisma.cycle.findFirst({
            where: { userId, endDate: null },
            orderBy: { startDate: 'desc' },
        });
        if (lastCycle) {
            await prisma.cycle.update({ where: { id: lastCycle.id }, data: { endDate: date } });
        }

        return prisma.cycle.create({
            data: { userId, startDate: date, expectedLength },
        });
    }

    static async getCycleHistory(userId: string) {
        return prisma.cycle.findMany({
            where: { userId },
            orderBy: { startDate: 'desc' },
        });
    }
}
