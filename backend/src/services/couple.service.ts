import prisma from '../utils/db';

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

    static async unlinkPartner(userId: string) {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user || !user.partnerId) throw new Error('No tienes una pareja vinculada');

        await prisma.user.update({ where: { id: userId }, data: { partnerId: null } });
        await prisma.user.update({ where: { id: user.partnerId }, data: { partnerId: null } });
        return { message: 'Pareja desvinculada exitosamente' };
    }
}
