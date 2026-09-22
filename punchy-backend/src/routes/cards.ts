import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

const CardSchema = z.object({
  title: z.string().min(2),
  punchesRequired: z.number().int().min(1).max(100).default(10),
  rewardDescription: z.string().min(5),
  validUntil: z.string().nullable().optional(),
  pricePerPunch: z.number().min(0).optional().default(0),
  currency: z.string().min(1).max(10).optional().default('PKR'),
  isActive: z.boolean().optional(),
  visualStyle: z.object({
    primaryColor: z.string().default('#FF6B35'),
    bgColor: z.string().default('#1a1a2e'),
    iconType: z.string().default('star'),
  }).optional(),
});

// GET /cards/business/:businessId
router.get('/business/:businessId', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const businessId = String(req.params.businessId);
  const business = await prisma.businessProfile.findUnique({ where: { id: businessId } });
  if (!business) { res.status(404).json({ error: 'Business not found' }); return; }

  const isOwner = req.user!.role === 'BUSINESS' && business.userId === req.user!.userId;
  const isAdmin = req.user!.role === 'ADMIN';

  const cards = await prisma.loyaltyCard.findMany({
    where: { businessId, ...(isOwner || isAdmin ? {} : { isActive: true }) },
    include: { punchMethods: { where: { isActive: true } }, _count: { select: { customerCards: true } } },
    orderBy: { createdAt: 'desc' },
  });
  res.json(cards);
});

// POST /cards/business/:businessId
router.post('/business/:businessId', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const businessId = String(req.params.businessId);
  const business = await prisma.businessProfile.findUnique({ where: { id: businessId } });
  if (!business || business.userId !== req.user!.userId) { res.status(403).json({ error: 'Forbidden' }); return; }

  // Check Single Active Card rule
  const existingCard = await prisma.loyaltyCard.findFirst({ where: { businessId } });
  if (existingCard) {
    res.status(400).json({ error: 'A business can only have one loyalty card. Edit the existing card to update or reactivate it.' });
    return;
  }

  const parsed = CardSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const card = await prisma.loyaltyCard.create({
    data: {
      businessId,
      title: parsed.data.title,
      punchesRequired: parsed.data.punchesRequired,
      rewardDescription: parsed.data.rewardDescription,
      validUntil: parsed.data.validUntil ? new Date(parsed.data.validUntil) : null,
      pricePerPunch: parsed.data.pricePerPunch,
      currency: parsed.data.currency,
      visualStyle: parsed.data.visualStyle ?? { primaryColor: '#FF6B35', bgColor: '#1a1a2e', iconType: 'star' },
    },
  });
  res.status(201).json(card);
});

// GET /cards/:id
router.get('/:id', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const id = String(req.params.id);
  const card = await prisma.loyaltyCard.findUnique({
    where: { id },
    include: {
      business: { select: { id: true, name: true, logo: true, status: true } },
      punchMethods: { where: { isActive: true } },
    },
  });
  if (!card) { res.status(404).json({ error: 'Card not found' }); return; }
  res.json(card);
});

// PATCH /cards/:id
router.patch('/:id', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const id = String(req.params.id);
  const card = await prisma.loyaltyCard.findUnique({ where: { id } });
  if (!card) { res.status(404).json({ error: 'Card not found' }); return; }

  // Verify ownership via business
  const business = await prisma.businessProfile.findUnique({ where: { id: card.businessId } });
  if (!business || business.userId !== req.user!.userId) { res.status(403).json({ error: 'Forbidden' }); return; }

  const parsed = CardSchema.partial().safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const updateData: Record<string, unknown> = { ...parsed.data };
  if (parsed.data.validUntil !== undefined) {
    updateData.validUntil = parsed.data.validUntil ? new Date(parsed.data.validUntil) : null;
  }
  const nextActive = parsed.data.isActive ?? card.isActive;
  const nextValidUntil = parsed.data.validUntil !== undefined
    ? (parsed.data.validUntil ? new Date(parsed.data.validUntil) : null)
    : card.validUntil;
  if (nextValidUntil && nextValidUntil <= new Date()) {
    res.status(400).json({ error: 'A card can only be reactivated with a future expiry date.' });
    return;
  }

  if (!card.isActive && nextValidUntil && nextValidUntil > new Date() && parsed.data.isActive === undefined) {
    updateData.isActive = true;
    updateData.reactivatedAt = new Date();
  }

  res.json(await prisma.loyaltyCard.update({ where: { id }, data: updateData }));
});

export default router;
