import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

const NotificationSchema = z.object({
  title: z.string().min(2),
  body: z.string().min(5),
  targetType: z.enum(['ALL', 'BUSINESSES', 'CUSTOMERS', 'USER']),
  targetId: z.string().optional(),
  scheduledAt: z.string().datetime().optional(),
});

// POST /notifications
router.post('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parsed = NotificationSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  if (req.user!.role !== 'ADMIN' && parsed.data.targetType !== 'CUSTOMERS') {
    res.status(403).json({ error: 'Business accounts can only target customers' }); return;
  }

  const notification = await prisma.notification.create({
    data: { ...parsed.data, createdBy: req.user!.userId, sentAt: parsed.data.scheduledAt ? undefined : new Date() },
  });
  res.status(201).json(notification);
});

// GET /notifications
router.get('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { page = '1', limit = '20' } = req.query;
  const skip = (Number(page) - 1) * Number(limit);
  let where: any = {};
  if (req.user!.role === 'ADMIN') {
    where = {};
  } else if (req.user!.role === 'CUSTOMER') {
    where = {
      OR: [
        { targetType: 'ALL' },
        { targetType: 'CUSTOMERS' },
        { targetType: 'USER', targetId: req.user!.userId },
      ],
    };
  } else if (req.user!.role === 'BUSINESS') {
    where = {
      OR: [
        { targetType: 'ALL' },
        { targetType: 'BUSINESSES' },
        { createdBy: req.user!.userId },
      ],
    };
  } else {
    where = { targetType: 'ALL' };
  }

  const [notifications, total] = await Promise.all([
    prisma.notification.findMany({
      where, skip, take: Number(limit),
      include: { creator: { select: { email: true, name: true, role: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.notification.count({ where }),
  ]);
  res.json({ notifications, total });
});

export default router;
