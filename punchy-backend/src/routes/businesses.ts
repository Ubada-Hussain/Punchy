import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { parsePagination } from '../lib/pagination';

const router = Router();

const PermanentDeleteSchema = z.object({ confirmationKey: z.string().min(1) });

function hasValidDeletionKey(key: string): boolean {
  const expected = process.env.ADMIN_DELETION_KEY;
  return Boolean(expected) && key === expected;
}

const BusinessUpsertSchema = z.object({
  name: z.string().min(2),
  category: z.string(),
  description: z.string().optional(),
  website: z.string().url().optional(),
  logo: z.string().optional(),
  locations: z.array(z.object({ address: z.string(), lat: z.number().optional(), lng: z.number().optional() })).optional(),
});

// GET /businesses — admin: all businesses with pagination + filters
router.get('/', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const { search, status } = req.query;
  const pagination = parsePagination(req.query);
  if (pagination.error) { res.status(400).json({ error: pagination.error }); return; }
  const { page, limit } = pagination;
  const skip = (page - 1) * limit;
  const where: Record<string, unknown> = {};
  if (status) where.status = status;
  if (search) where.OR = [
    { name: { contains: String(search), mode: 'insensitive' } },
    { category: { contains: String(search), mode: 'insensitive' } },
  ];

  const [businesses, total] = await Promise.all([
    prisma.businessProfile.findMany({
      where, skip, take: Number(limit),
      include: { user: { select: { email: true, phone: true, publicId: true, createdAt: true } }, _count: { select: { loyaltyCards: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.businessProfile.count({ where }),
  ]);

  res.json({ businesses, total, page, limit, totalPages: Math.ceil(total / limit) });
});

// POST /businesses — business user creates their profile
router.post('/', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  if (await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } })) {
    res.status(409).json({ error: 'Profile already exists — use PATCH to update' }); return;
  }
  const parsed = BusinessUpsertSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const business = await prisma.businessProfile.create({
    data: { userId: req.user!.userId, ...parsed.data, locations: parsed.data.locations ?? [], status: 'APPROVED' },
  });
  res.status(201).json(business);
});

// GET /businesses/me — own business profile
router.get('/me', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({
    where: { userId: req.user!.userId },
    include: { loyaltyCards: { include: { punchMethods: true, _count: { select: { customerCards: true } } } } },
  });
  if (!business) { res.status(404).json({ error: 'No business profile found' }); return; }
  res.json(business);
});

// GET /businesses/:id
router.get('/:id', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({
    where: { id: String(req.params.id) },
    include: {
      user: { select: { email: true, phone: true } },
      loyaltyCards: { include: { punchMethods: true, _count: { select: { customerCards: true } } } },
    },
  });
  if (!business) { res.status(404).json({ error: 'Business not found' }); return; }

  const isOwner = req.user!.role === 'BUSINESS' && business.userId === req.user!.userId;
  const isAdmin = req.user!.role === 'ADMIN';
  if (!isOwner && !isAdmin && business.status !== 'APPROVED') {
    res.status(404).json({ error: 'Business not found' }); return;
  }
  res.json(business);
});

// PATCH /businesses/:id — owner or admin
router.patch('/:id', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { id: String(req.params.id) } });
  if (!business) { res.status(404).json({ error: 'Business not found' }); return; }

  const isOwner = req.user!.role === 'BUSINESS' && business.userId === req.user!.userId;
  if (!isOwner && req.user!.role !== 'ADMIN') { res.status(403).json({ error: 'Forbidden' }); return; }

  const parsed = BusinessUpsertSchema.partial().safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  res.json(await prisma.businessProfile.update({ where: { id: String(req.params.id) }, data: parsed.data }));
});

// POST /businesses/:id/suspend
router.post('/:id/suspend', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const b = await prisma.businessProfile.findUnique({ where: { id: String(req.params.id) } });
  if (!b) { res.status(404).json({ error: 'Business not found' }); return; }
  res.json(await prisma.businessProfile.update({ where: { id: String(req.params.id) }, data: { status: 'SUSPENDED' } }));
});

// POST /businesses/:id/unban — only an admin can restore a suspended business
router.post('/:id/unban', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const b = await prisma.businessProfile.findUnique({ where: { id: String(req.params.id) } });
  if (!b) { res.status(404).json({ error: 'Business not found' }); return; }
  res.json(await prisma.businessProfile.update({ where: { id: String(req.params.id) }, data: { status: 'APPROVED' } }));
});

// DELETE /businesses/:id — permanently remove a business, its owner, staff, cards and related activity.
router.delete('/:id', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const parsed = PermanentDeleteSchema.safeParse(req.body);
  if (!parsed.success || !hasValidDeletionKey(parsed.data.confirmationKey)) {
    res.status(403).json({ error: 'The permanent deletion key is incorrect.' }); return;
  }

  const business = await prisma.businessProfile.findUnique({
    where: { id: String(req.params.id) },
    select: { id: true, userId: true, staffMembers: { select: { id: true } }, loyaltyCards: { select: { id: true, punchMethods: { select: { id: true } } } } },
  });
  if (!business) { res.status(404).json({ error: 'Business not found' }); return; }

  const userIds = [business.userId, ...business.staffMembers.map((staff) => staff.id)];
  const cardIds = business.loyaltyCards.map((card) => card.id);
  const methodIds = business.loyaltyCards.flatMap((card) => card.punchMethods.map((method) => method.id));
  const customerCards = cardIds.length ? await prisma.customerCard.findMany({ where: { cardId: { in: cardIds } }, select: { id: true } }) : [];
  const customerCardIds = customerCards.map((card) => card.id);

  await prisma.$transaction([
    ...(customerCardIds.length ? [prisma.punchTransaction.deleteMany({ where: { customerCardId: { in: customerCardIds } } }), prisma.redemption.deleteMany({ where: { customerCardId: { in: customerCardIds } } })] : []),
    ...(methodIds.length ? [prisma.punchTransaction.deleteMany({ where: { punchMethodId: { in: methodIds } } })] : []),
    ...(cardIds.length ? [prisma.customerCard.deleteMany({ where: { cardId: { in: cardIds } } }), prisma.punchMethod.deleteMany({ where: { cardId: { in: cardIds } } }), prisma.loyaltyCard.deleteMany({ where: { businessId: business.id } })] : []),
    prisma.refreshToken.deleteMany({ where: { userId: { in: userIds } } }),
    prisma.activityLog.deleteMany({ where: { userId: { in: userIds } } }),
    prisma.notification.deleteMany({ where: { createdBy: { in: userIds } } }),
    prisma.supportTicket.deleteMany({ where: { authorId: { in: userIds } } }),
    prisma.supportTicket.updateMany({ where: { resolvedBy: { in: userIds } }, data: { resolvedBy: null } }),
    prisma.businessProfile.delete({ where: { id: business.id } }),
    prisma.user.deleteMany({ where: { id: { in: userIds } } }),
  ]);
  res.json({ message: 'Business account permanently deleted.' });
});

export default router;
