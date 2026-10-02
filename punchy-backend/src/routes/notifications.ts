import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { sendNotification } from '../lib/notifications';
import { parsePagination } from '../lib/pagination';
import {
  markNotificationsRead,
  notificationInboxWhere,
  unreadNotificationCount,
} from '../lib/notificationInbox';

const router = Router();

const NotificationSchema = z.object({
  title: z.string().min(2),
  body: z.string().min(5),
  targetType: z.enum(['ALL', 'BUSINESSES', 'CUSTOMERS', 'USER']),
  targetId: z.string().optional(),
  scheduledAt: z.string().datetime().optional(),
});
const MarkReadSchema = z.object({ readThrough: z.string().datetime() });

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

  let connectedCustomerIds: string[] = [];
  if (req.user!.role === 'BUSINESS' && parsed.data.targetType === 'CUSTOMERS') {
    const biz = await prisma.businessProfile.findUnique({
      where: { userId: req.user!.userId },
      include: { loyaltyCards: { select: { id: true } } },
    });
    if (!biz) {
      res.status(404).json({ error: 'Business profile not found' });
      return;
    }
    const cardIds = biz.loyaltyCards.map((c) => c.id);
    const customerCards = await prisma.customerCard.findMany({
      where: { cardId: { in: cardIds } },
      select: { customerId: true },
    });
    connectedCustomerIds = Array.from(new Set(customerCards.map((c) => c.customerId)));
  }

  const notification = await prisma.notification.create({
    data: { ...parsed.data, targetId, createdBy: req.user!.userId, sentAt: parsed.data.scheduledAt ? undefined : new Date() },
  });
  if (!parsed.data.scheduledAt) {
    if (req.user!.role === 'BUSINESS' && parsed.data.targetType === 'CUSTOMERS') {
      // Send push notification exclusively to customers who joined this business's cards
      await sendNotification({ userIds: connectedCustomerIds, title: parsed.data.title, body: parsed.data.body });
    } else {
      await sendNotification({
        userId: parsed.data.targetType === 'USER' ? targetId : undefined,
        targetRole: parsed.data.targetType === 'CUSTOMERS' ? 'CUSTOMER' : parsed.data.targetType === 'BUSINESSES' ? 'BUSINESS' : 'ALL',
        title: parsed.data.title,
        body: parsed.data.body,
      });
    }
  }
  res.status(201).json(notification);
});

// GET /notifications
router.get('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const pagination = parsePagination(req.query);
  if (pagination.error) { res.status(400).json({ error: pagination.error }); return; }
  const { page, limit } = pagination;
  const skip = (page - 1) * limit;
  const asOf = new Date();
  const where = await notificationInboxWhere(req.user!.userId, req.user!.role);

  const [notifications, total, unreadCount] = await Promise.all([
    prisma.notification.findMany({
      where: { AND: [where, { createdAt: { lte: asOf } }] }, skip, take: Number(limit),
      include: { creator: { select: { email: true, name: true, role: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.notification.count({ where }),
    unreadNotificationCount(req.user!.userId, req.user!.role),
  ]);
  res.json({ notifications, total, unreadCount, asOf: asOf.toISOString(), page, limit, totalPages: Math.ceil(total / limit) });
});

router.get('/unread-count', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const unreadCount = await unreadNotificationCount(req.user!.userId, req.user!.role);
  res.json({ unreadCount });
});

router.post('/read', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parsed = MarkReadSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'A valid readThrough timestamp is required.' }); return; }
  await markNotificationsRead(req.user!.userId, new Date(parsed.data.readThrough));
  res.json({ unreadCount: 0 });
});

// Clear this user's visible inbox in one operation. Notifications are shared
// records, so a per-user marker prevents one recipient deleting them for all.
router.delete('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const where = await notificationInboxWhere(req.user!.userId, req.user!.role);
  const deletedCount = await prisma.notification.count({ where });
  if (deletedCount > 0) {
    await prisma.activityLog.create({
      data: {
        userId: req.user!.userId,
        action: 'NOTIFICATIONS_CLEARED',
        metadata: { deletedCount },
      },
    });
  }
  res.json({ message: 'Notifications cleared', deletedCount });
});

router.delete('/:id', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const where = await notificationInboxWhere(req.user!.userId, req.user!.role);
  const existing = await prisma.notification.findFirst({
    where: { AND: [where, { id: String(req.params.id) }] },
  });
  if (!existing) { res.status(404).json({ error: 'Notification not found' }); return; }

  if (req.user!.role === 'ADMIN' && existing.createdBy === req.user!.userId) {
    await prisma.notification.delete({ where: { id: existing.id } });
  } else {
    await prisma.activityLog.create({
      data: {
        userId: req.user!.userId,
        action: 'NOTIFICATION_DELETED',
        metadata: { notificationId: existing.id },
      },
    });
  }
  res.json({ message: 'Notification deleted' });
});

export default router;
