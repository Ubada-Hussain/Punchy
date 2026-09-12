import { PrismaClient } from '@prisma/client';

export class PunchService {
  constructor(private readonly db: PrismaClient) {}

  async record(customerId: string, identifier: string) {
    const punchMethod = await this.db.punchMethod.findUnique({
      where: { identifier },
      include: { card: { include: { business: true } } },
    });

    if (!punchMethod?.isActive) throw new PunchDomainError(404, 'Invalid or inactive punch identifier');
    if (!punchMethod.card.isActive) throw new PunchDomainError(400, 'This loyalty card is no longer active');
    if (punchMethod.card.validUntil && new Date(punchMethod.card.validUntil) < new Date()) {
      throw new PunchDomainError(400, 'This loyalty card has expired');
    }
    if (punchMethod.card.business.status !== 'APPROVED') {
      throw new PunchDomainError(400, 'This business is not currently active');
    }

    const card = punchMethod.card;
    try {
      const result = await this.db.$transaction(async (tx) => {
        let customerCard = await tx.customerCard.findUnique({
          where: { customerId_cardId: { customerId, cardId: card.id } },
        });
        if (customerCard?.isCompleted) throw new PunchDomainError(400, 'Card is already complete. Please redeem your reward first.');

        const isFirstVisit = !customerCard;
        if (!customerCard) customerCard = await tx.customerCard.create({ data: { customerId, cardId: card.id } });
        const newCount = customerCard.punchCount + 1;
        const isNowComplete = newCount >= card.punchesRequired;
        const updated = await tx.customerCard.update({
          where: { id: customerCard.id },
          data: { punchCount: newCount, isCompleted: isNowComplete },
        });
        await tx.punchTransaction.create({
          data: { customerCardId: customerCard.id, punchMethodId: punchMethod.id, method: punchMethod.type },
        });
        await tx.activityLog.create({
          data: {
            userId: customerId,
            action: isFirstVisit ? 'CARD_JOINED_AND_PUNCHED' : 'PUNCH_RECORDED',
            metadata: { cardId: card.id, businessId: card.businessId, punchCount: newCount, punchesRequired: card.punchesRequired, isCompleted: isNowComplete },
          },
        });
        return { updated, isFirstVisit, newCount, isNowComplete };
      });
      return { ...result, card };
    } catch (error) {
      if (error instanceof PunchDomainError) throw error;
      throw error;
    }
  }
}

export class PunchDomainError extends Error {
  constructor(readonly statusCode: number, message: string) { super(message); }
}
