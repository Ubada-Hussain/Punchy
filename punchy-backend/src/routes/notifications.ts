import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { sendNotification } from '../lib/notifications';

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
  let targetId = parsed.data.targetId;
  if (parsed.data.targetType === 'USER' && targetId) {
    const candidates = [{ publicId: targetId } as any];
    if (/^[a-f0-9]{24}$/i.test(targetId)) candidates.unshift({ id: targetId } as any);
    const target = await prisma.user.findFirst({ where: { OR: candidates }, select: { id: true } });
    if (!target) { res.status(404).json({ error: 'Recipient not found for that ID' }); return; }
    targetId = target.id;
  }

  const notification = await prisma.notification.create({
    data: { ...parsed.data, targetId, createdBy: req.user!.userId, sentAt: parsed.data.scheduledAt ? undefined : new Date() },
  });
  await sendNotification({ userId: parsed.data.targetType === 'USER' ? targetId : undefined, targetRole: parsed.data.targetType === 'CUSTOMERS' ? 'CUSTOMER' : parsed.data.targetType === 'BUSINESSES' ? 'BUSINESS' : 'ALL', title: parsed.data.title, body: parsed.data.body });
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

router.delete('/:id', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const existing = await prisma.notification.findUnique({ where: { id: String(req.params.id) } });
  if (!existing) { res.status(404).json({ error: 'Notification not found' }); return; }
  const visibleToUser = existing.targetType === 'ALL' ||
    (existing.targetType === 'USER' && existing.targetId === req.user!.userId) ||
    (existing.targetType === 'CUSTOMERS' && req.user!.role === 'CUSTOMER') ||
    (existing.targetType === 'BUSINESSES' && req.user!.role === 'BUSINESS');
  if (req.user!.role !== 'ADMIN' && existing.createdBy !== req.user!.userId && !visibleToUser) {
    res.status(403).json({ error: 'Not allowed to delete this notification' }); return;
  }
  await prisma.notification.delete({ where: { id: existing.id } });
  res.json({ message: 'Notification deleted' });
});

export default router;
