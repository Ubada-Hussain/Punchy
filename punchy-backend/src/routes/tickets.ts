import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireAuthAllowSuspended, requireRole } from '../middleware/auth';

const router = Router();

const TicketSchema = z.object({
  subject: z.string().min(5),
  body: z.string().min(10),
});

// POST /tickets
router.post('/', requireAuthAllowSuspended, async (req: Request, res: Response): Promise<void> => {
  const parsed = TicketSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const ticket = await prisma.supportTicket.create({
    data: { authorId: req.user!.userId, ...parsed.data },
  });
  res.status(201).json(ticket);
});

// GET /tickets — admin sees all, others see their own
router.get('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { status, page = '1', limit = '20' } = req.query;
  const skip = (Number(page) - 1) * Number(limit);
  const where: Record<string, unknown> = req.user!.role === 'ADMIN' ? {} : { authorId: req.user!.userId };
  if (status) where.status = status;

  const [tickets, total] = await Promise.all([
    prisma.supportTicket.findMany({
      where, skip, take: Number(limit),
      include: { author: { select: { email: true, role: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.supportTicket.count({ where }),
  ]);
  res.json({ tickets, total });
});

// GET /tickets/:id
router.get('/:id', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const ticket = await prisma.supportTicket.findUnique({
    where: { id: String(req.params.id) },
    include: { author: { select: { email: true, role: true } }, resolver: { select: { email: true } } },
  });
  if (!ticket) { res.status(404).json({ error: 'Ticket not found' }); return; }
  if (req.user!.role !== 'ADMIN' && ticket.authorId !== req.user!.userId) {
    res.status(403).json({ error: 'Forbidden' }); return;
  }
  res.json(ticket);
});

// PATCH /tickets/:id — admin resolves/updates
router.patch('/:id', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const { status } = req.body;
  if (!['OPEN', 'IN_PROGRESS', 'RESOLVED'].includes(status)) {
    res.status(400).json({ error: 'Invalid status' }); return;
  }
  const updated = await prisma.supportTicket.update({
    where: { id: String(req.params.id) },
    data: {
      status,
      resolvedBy: status === 'RESOLVED' ? req.user!.userId : undefined,
      resolvedAt: status === 'RESOLVED' ? new Date() : undefined,
    },
  });
  res.json(updated);
});

export default router;
