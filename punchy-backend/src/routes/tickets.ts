import { createHash } from 'node:crypto';
import { Prisma } from '@prisma/client';
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireAuthAllowSuspended, requireRole } from '../middleware/auth';
import { parsePagination } from '../lib/pagination';

const router = Router();

const TicketSchema = z.object({
  subject: z.string().trim().min(5).max(160),
  body: z.string().trim().min(10).max(5000),
  clientRequestId: z.string().trim().min(8).max(128).optional(),
});

export function supportTicketDedupeKey(
  authorId: string,
  subject: string,
  body: string,
  clientRequestId?: string,
  now = Date.now(),
): string {
  const requestIdentity = clientRequestId
    ? `client:${clientRequestId}`
    : `minute:${Math.floor(now / 60_000)}:${subject.toLowerCase()}:${body}`;
  return createHash('sha256')
    .update(`${authorId}\u0000${requestIdentity}`)
    .digest('hex');
}

// POST /tickets
router.post('/', requireAuthAllowSuspended, async (req: Request, res: Response): Promise<void> => {
  const parsed = TicketSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const { clientRequestId, subject, body } = parsed.data;
  const dedupeKey = supportTicketDedupeKey(req.user!.userId, subject, body, clientRequestId);
  const existing = await prisma.supportTicket.findUnique({ where: { dedupeKey } });
  if (existing) { res.status(200).json(existing); return; }

  try {
    const ticket = await prisma.supportTicket.create({
      data: { authorId: req.user!.userId, subject, body, dedupeKey },
    });
    res.status(201).json(ticket);
  } catch (error) {
    // Two identical requests can pass the read at the same time. The unique
    // database key is the final guard and both callers receive the same ticket.
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      const duplicate = await prisma.supportTicket.findUnique({ where: { dedupeKey } });
      if (duplicate) { res.status(200).json(duplicate); return; }
    }
    throw error;
  }
});

// GET /tickets — admin sees all, others see their own
router.get('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { status } = req.query;
  const pagination = parsePagination(req.query);
  if (pagination.error) { res.status(400).json({ error: pagination.error }); return; }
  const { page, limit } = pagination;
  const skip = (page - 1) * limit;
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
  res.json({ tickets, total, page, limit, totalPages: Math.ceil(total / limit) });
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
