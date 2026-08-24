import { Router, Request, Response } from 'express';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

// GET /customer/cards — wallet
router.get('/cards', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const cards = await prisma.customerCard.findMany({
    where: { customerId: String(req.user!.userId) },
    include: {
      card: {
        include: {
          business: { select: { id: true, name: true, logo: true, category: true } },
          punchMethods: { where: { isActive: true }, select: { type: true } },
        },
      },
    },
    orderBy: { joinedAt: 'desc' },
  });
  res.json(cards);
});

// GET /customer/cards/:id — single card with punch history
router.get('/cards/:id', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const card = await prisma.customerCard.findFirst({
    where: { id: String(req.params.id), customerId: req.user!.userId },
    include: {
      card: { include: { business: { select: { id: true, name: true, logo: true, category: true } } } },
      punchTransactions: { orderBy: { timestamp: 'desc' }, take: 50 },
      redemptions: { orderBy: { redeemedAt: 'desc' } },
    },
  });
  if (!card) { res.status(404).json({ error: 'Card not found' }); return; }
  res.json(card);
});

// POST /customer/cards/:id/redeem
router.post('/cards/:id/redeem', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const customerCard = await prisma.customerCard.findFirst({
    where: { id: String(req.params.id), customerId: req.user!.userId },
  });
  if (!customerCard) { res.status(404).json({ error: 'Card not found' }); return; }
  if (!customerCard.isCompleted) { res.status(400).json({ error: 'Card is not yet complete' }); return; }

  const [redemption] = await prisma.$transaction([
    prisma.redemption.create({ data: { customerCardId: customerCard.id } }),
    prisma.customerCard.update({ where: { id: customerCard.id }, data: { punchCount: 0, isCompleted: false } }),
    prisma.activityLog.create({
      data: { userId: req.user!.userId, action: 'REWARD_REDEEMED', metadata: { customerCardId: customerCard.id, cardId: customerCard.cardId } },
    }),
  ]);

  res.json({ message: 'Reward redeemed! Enjoy! 🎉', redemption });
});

export default router;
