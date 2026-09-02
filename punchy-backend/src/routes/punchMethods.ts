import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

const MethodSchema = z.object({
  type: z.enum(['QR', 'NFC']),
  label: z.string().optional(),
});

// GET /punch-methods — admin inventory for the admin portal
router.get('/', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  const methods = await prisma.punchMethod.findMany({
    include: { card: { include: { business: { select: { name: true } } } } },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ methods });
});

// POST /punch-methods/card/:cardId
router.post('/card/:cardId', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const cardId = String(req.params.cardId);
  const card = await prisma.loyaltyCard.findUnique({ where: { id: cardId } });
  if (!card) { res.status(404).json({ error: 'Card not found' }); return; }
  const business = await prisma.businessProfile.findUnique({ where: { id: card.businessId } });
  if (!business || business.userId !== req.user!.userId) { res.status(403).json({ error: 'Forbidden' }); return; }

  const parsed = MethodSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const method = await prisma.punchMethod.create({
    data: { cardId, type: parsed.data.type, identifier: uuid(), label: parsed.data.label },
  });
  res.status(201).json(method);
});

// GET /punch-methods/card/:cardId
router.get('/card/:cardId', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const cardId = String(req.params.cardId);
  const card = await prisma.loyaltyCard.findUnique({ where: { id: cardId } });
  if (!card) { res.status(404).json({ error: 'Card not found' }); return; }
  const business = await prisma.businessProfile.findUnique({ where: { id: card.businessId } });

  const isOwner = req.user!.role === 'BUSINESS' && business?.userId === req.user!.userId;
  if (!isOwner && req.user!.role !== 'ADMIN') { res.status(403).json({ error: 'Forbidden' }); return; }

  res.json(await prisma.punchMethod.findMany({ where: { cardId }, orderBy: { createdAt: 'desc' } }));
});

// DELETE /punch-methods/:id — deactivate
router.delete('/:id', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const id = String(req.params.id);
  const method = await prisma.punchMethod.findUnique({ where: { id } });
  if (!method) { res.status(404).json({ error: 'Method not found' }); return; }
  const card = await prisma.loyaltyCard.findUnique({ where: { id: method.cardId } });
  const business = card ? await prisma.businessProfile.findUnique({ where: { id: card.businessId } }) : null;
  if (!business || business.userId !== req.user!.userId) { res.status(403).json({ error: 'Forbidden' }); return; }
  await prisma.punchMethod.update({ where: { id }, data: { isActive: false } });
  res.json({ message: 'Punch method deactivated' });
});

export default router;
