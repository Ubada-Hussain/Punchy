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

  const business = await prisma.businessProfile.findUnique({ where: { id: businessId } });
  if (!business) { res.status(404).json({ error: 'Business not found' }); return; }

  const isOwner = req.user!.role === 'BUSINESS' && business.userId === req.user!.userId;
  if (!isOwner && req.user!.role !== 'ADMIN') { res.status(403).json({ error: 'Forbidden' }); return; }

  const cards = await prisma.loyaltyCard.findMany({
    where: { businessId },
    include: {
      _count: { select: { customerCards: true } },
      customerCards: {
        select: {
          customerId: true,
          punchTransactions: { select: { id: true } },
          redemptions: { select: { id: true } },
        },
      },
    },
  });

  const totalCustomers = new Set(cards.flatMap(c => c.customerCards.map(cc => cc.customerId))).size;
  const totalPunches = cards.reduce((s, c) => s + c.customerCards.reduce((s2, cc) => s2 + cc.punchTransactions.length, 0), 0);
  const totalRedemptions = cards.reduce((s, c) => s + c.customerCards.reduce((s2, cc) => s2 + cc.redemptions.length, 0), 0);

  const recentActivity = await prisma.activityLog.findMany({
    where: {
      metadata: { path: ['businessId'], equals: businessId },
      createdAt: { gte: new Date(Date.now() - 30 * 86_400_000) },
    },
    orderBy: { createdAt: 'desc' },
    take: 20,
    include: { user: { select: { email: true } } },
  });

  res.json({
    business: { id: business.id, name: business.name, status: business.status },
    totals: { totalCustomers, totalPunches, totalRedemptions },
    cards: cards.map(c => ({
      id: c.id, title: c.title,
      customers: c._count.customerCards,
      punches: c.customerCards.reduce((s, cc) => s + cc.punchTransactions.length, 0),
      redemptions: c.customerCards.reduce((s, cc) => s + cc.redemptions.length, 0),
    })),
    recentActivity,
  });
});

export default router;
