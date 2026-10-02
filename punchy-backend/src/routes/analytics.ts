import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

// GET /analytics/platform — admin only
router.get('/platform', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const days = parseInt(String(req.query.period ?? '30'));
  const since = new Date(Date.now() - days * 86_400_000);

  const [totalBusinesses, totalCustomers, totalPunches, totalRedemptions, newBusinesses, newCustomers, recentPunches] =
    await Promise.all([
      prisma.businessProfile.count(),
      prisma.user.count({ where: { role: 'CUSTOMER' } }),
      prisma.punchTransaction.count(),
      prisma.redemption.count(),
      prisma.businessProfile.count({ where: { createdAt: { gte: since } } }),
      prisma.user.count({ where: { role: 'CUSTOMER', createdAt: { gte: since } } }),
      prisma.punchTransaction.count({ where: { timestamp: { gte: since } } }),
    ]);

  // Top businesses by total punch count (aggregate via raw query for performance)
  const topBusinesses = await prisma.businessProfile.findMany({
    take: 5,
    select: {
      id: true, name: true, category: true, logo: true,
      loyaltyCards: {
        select: {
          customerCards: {
            select: { punchTransactions: { select: { id: true } } },
          },
        },
      },
    },
  });

  res.json({
    totals: { totalBusinesses, totalCustomers, totalPunches, totalRedemptions },
    period: { days, newBusinesses, newCustomers, recentPunches },
    topBusinesses: topBusinesses
      .map(b => ({
        id: b.id, name: b.name, category: b.category, logo: b.logo,
        totalPunches: b.loyaltyCards.reduce(
          (s, c) => s + c.customerCards.reduce((s2, cc) => s2 + cc.punchTransactions.length, 0), 0
        ),
      }))
      .sort((a, b) => b.totalPunches - a.totalPunches),
  });
});

// GET /analytics/business/:businessId — owner or admin
router.get('/business/:businessId', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const businessId = String(req.params.businessId);

  const business = await prisma.businessProfile.findUnique({
    where: { id: businessId },
    select: { id: true, userId: true, name: true, status: true },
  });
  if (!business) { res.status(404).json({ error: 'Business not found' }); return; }

  const isOwner = req.user!.role === 'BUSINESS' && business.userId === req.user!.userId;
  if (!isOwner && req.user!.role !== 'ADMIN') { res.status(403).json({ error: 'Forbidden' }); return; }

  const cards = await prisma.loyaltyCard.findMany({
    where: { businessId },
    select: { id: true, title: true },
  });
  const cardIds = cards.map((card) => card.id);
  const [customerCards, recentActivity] = await Promise.all([
    prisma.customerCard.findMany({
      where: { cardId: { in: cardIds } },
      select: { id: true, customerId: true, cardId: true },
    }),
    prisma.activityLog.findMany({
      where: {
        metadata: { path: ['businessId'], equals: businessId },
        createdAt: { gte: new Date(Date.now() - 30 * 86_400_000) },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
      select: {
        id: true, action: true, metadata: true, createdAt: true,
        user: { select: { email: true } },
      },
    }),
  ]);
  const customerCardIds = customerCards.map((card) => card.id);
  const [punchCounts, redemptionCounts] = await Promise.all([
    prisma.punchTransaction.groupBy({
      by: ['customerCardId'],
      where: { customerCardId: { in: customerCardIds } },
      _count: { _all: true },
    }),
    prisma.redemption.groupBy({
      by: ['customerCardId'],
      where: { customerCardId: { in: customerCardIds } },
      _count: { _all: true },
    }),
  ]);
  const punchesByCustomerCard = new Map(punchCounts.map((row) => [row.customerCardId, row._count._all]));
  const redemptionsByCustomerCard = new Map(redemptionCounts.map((row) => [row.customerCardId, row._count._all]));
  const customersByCard = new Map<string, number>();
  const punchesByCard = new Map<string, number>();
  const redemptionsByCard = new Map<string, number>();
  const uniqueCustomers = new Set<string>();
  for (const customerCard of customerCards) {
    uniqueCustomers.add(customerCard.customerId);
    customersByCard.set(customerCard.cardId, (customersByCard.get(customerCard.cardId) ?? 0) + 1);
    punchesByCard.set(customerCard.cardId, (punchesByCard.get(customerCard.cardId) ?? 0) + (punchesByCustomerCard.get(customerCard.id) ?? 0));
    redemptionsByCard.set(customerCard.cardId, (redemptionsByCard.get(customerCard.cardId) ?? 0) + (redemptionsByCustomerCard.get(customerCard.id) ?? 0));
  }
  const totalCustomers = uniqueCustomers.size;
  const totalPunches = [...punchesByCard.values()].reduce((sum, count) => sum + count, 0);
  const totalRedemptions = [...redemptionsByCard.values()].reduce((sum, count) => sum + count, 0);

  res.json({
    business: { id: business.id, name: business.name, status: business.status },
    totals: { totalCustomers, totalPunches, totalRedemptions },
    cards: cards.map((card) => ({
      id: card.id,
      title: card.title,
      customers: customersByCard.get(card.id) ?? 0,
      punches: punchesByCard.get(card.id) ?? 0,
      redemptions: redemptionsByCard.get(card.id) ?? 0,
    })),
    recentActivity,
  });
});

export default router;
