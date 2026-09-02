import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { sendNotification } from '../lib/notifications';

const router = Router();

// GET /admin/config — persisted platform settings
router.get('/config', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  const rows = await prisma.adminConfig.findMany();
  res.json(Object.fromEntries(rows.map(row => [row.key, row.value])));
});

// PATCH /admin/config — update persisted platform settings
router.patch('/config', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const allowed = ['maintenanceMode', 'minimumAppVersion', 'supportEmail', 'termsUrl', 'trialPeriodDays'];
  const entries = Object.entries(req.body as Record<string, unknown>).filter(([key]) => allowed.includes(key));
  await prisma.$transaction(entries.map(([key, value]) => prisma.adminConfig.upsert({
    where: { key },
    create: { key, value: value as any, updatedBy: req.user!.userId },
    update: { value: value as any, updatedBy: req.user!.userId },
  })));
  res.json({ message: 'Settings saved' });
});

/**
 * GET /admin/stats — Platform-wide overview & growth metrics
 */
router.get('/stats', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  try {
    const [totalBusinesses, totalCustomers, totalPunches, totalRedemptions] = await Promise.all([
      prisma.businessProfile.count(),
      prisma.user.count({ where: { role: 'CUSTOMER' } }),
      prisma.punchTransaction.count(),
      prisma.redemption.count(),
    ]);

    // Growth chart mock/aggregated timeline
    const growthData = [
      { month: 'Jan', signups: 42, punches: 180 },
      { month: 'Feb', signups: 88, punches: 410 },
      { month: 'Mar', signups: 145, punches: 890 },
      { month: 'Apr', signups: 210, punches: 1420 },
      { month: 'May', signups: 290, punches: 2150 },
      { month: 'Jun', signups: 380, punches: 3200 },
    ];

    // Recent platform activity
    const recentActivity = await prisma.activityLog.findMany({
      include: { user: { select: { email: true, role: true } } },
      orderBy: { createdAt: 'desc' },
      take: 15,
    });

    res.json({
      stats: {
        totalBusinesses,
        totalCustomers,
        totalPunches,
        totalRedemptions,
      },
      growthData,
      recentActivity: recentActivity.map(a => ({
        id: a.id,
        userEmail: a.user.email,
        role: a.user.role,
        action: a.action,
        metadata: a.metadata,
        timestamp: a.createdAt,
      })),
    });
  } catch (error) {
    console.error('Admin stats error:', error);
    res.status(500).json({ error: 'Failed to load admin stats' });
  }
});

/**
 * GET /admin/businesses — List all registered businesses with status
 */
router.get('/businesses', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const { status, search } = req.query;
  const where: Record<string, unknown> = {};

  if (status && status !== 'ALL') {
    where.status = status;
  }
  if (search) {
    where.OR = [
      { name: { contains: String(search), mode: 'insensitive' } },
      { category: { contains: String(search), mode: 'insensitive' } },
    ];
  }

  const businesses = await prisma.businessProfile.findMany({
    where,
    include: {
      user: { select: { email: true, publicId: true, createdAt: true, phone: true } },
      loyaltyCards: { select: { id: true, title: true, isActive: true } },
      _count: { select: { loyaltyCards: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  res.json(businesses);
});

/**
 * PUT /admin/businesses/:id/status — Activate or Suspend a business
 */
router.put('/businesses/:id/status', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const { status } = req.body;
  if (!['APPROVED', 'SUSPENDED'].includes(status)) {
    res.status(400).json({ error: 'Invalid business status' });
    return;
  }

  const business = await prisma.businessProfile.update({
    where: { id: String(req.params.id) },
    data: { status },
    include: { user: true },
  });

  await prisma.activityLog.create({
    data: {
      userId: req.user!.userId,
      action: 'ADMIN_BUSINESS_STATUS_UPDATED',
      metadata: { businessId: business.id, businessName: business.name, newStatus: status },
    },
  });

  // Notify business owner
  await sendNotification({
    userId: business.userId,
    title: `Business Profile ${status === 'APPROVED' ? 'Approved! 🎉' : status}`,
    body: `Your business profile "${business.name}" has been marked as ${status}.`,
  });

  res.json({ message: `Business status updated to ${status}`, business });
});

/**
 * GET /admin/customers — List all customer accounts
 */
router.get('/customers', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const { search } = req.query;
  const where: Record<string, unknown> = { role: 'CUSTOMER' };

  if (search) {
    where.email = { contains: String(search), mode: 'insensitive' };
  }

  const customers = await prisma.user.findMany({
    where,
    select: {
      id: true,
      publicId: true,
      email: true,
      phone: true,
      isBlocked: true,
      createdAt: true,
      customerCards: {
        select: {
          id: true,
          punchCount: true,
          isCompleted: true,
          card: { select: { title: true } },
        },
      },
      _count: { select: { customerCards: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  res.json(customers);
});

// GET /admin/customers/:id — customer detail for the admin portal
router.get('/customers/:id', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const customer = await prisma.user.findFirst({
    where: { id: String(req.params.id), role: 'CUSTOMER' },
    select: {
      id: true, publicId: true, email: true, name: true, phone: true, isBlocked: true, createdAt: true,
      customerCards: {
        select: { id: true, punchCount: true, isCompleted: true, card: { select: { title: true, business: { select: { name: true } } } } },
      },
    },
  });
  if (!customer) { res.status(404).json({ error: 'Customer not found' }); return; }
  res.json({ customer });
});

router.get('/notification-targets', requireAuth, requireRole('ADMIN'), async (_req, res) => {
  const [customers, businesses] = await Promise.all([
    prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true, publicId: true, email: true, name: true, createdAt: true } }),
    prisma.businessProfile.findMany({ select: { userId: true, name: true, createdAt: true, user: { select: { email: true, publicId: true } } } }),
  ]);
  res.json({ customers, businesses });
});

/**
 * POST /admin/customers/:id/toggle-block — Suspend or Unsuspend customer account
 */
router.post('/customers/:id/toggle-block', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const user = await prisma.user.findUnique({ where: { id: String(req.params.id) } });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  if (user.role !== 'CUSTOMER') { res.status(400).json({ error: 'Only customer accounts can be suspended here' }); return; }

  const updated = await prisma.user.update({
    where: { id: user.id },
    data: { isBlocked: !user.isBlocked },
  });

  await prisma.activityLog.create({
    data: {
      userId: req.user!.userId,
      action: updated.isBlocked ? 'ADMIN_BLOCKED_USER' : 'ADMIN_UNBLOCKED_USER',
      metadata: { targetUserId: user.id, targetEmail: user.email },
    },
  });

  res.json({
    message: updated.isBlocked ? 'Customer account suspended.' : 'Customer account activated.',
    isBlocked: updated.isBlocked,
  });
});

// Announcement Schema
const AnnouncementSchema = z.object({
  title: z.string().min(3),
  body: z.string().min(5),
  targetType: z.enum(['ALL', 'BUSINESSES', 'CUSTOMERS']),
});

/**
 * GET /admin/announcements — List announcement history
 */
router.get('/announcements', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  const notifications = await prisma.notification.findMany({
    orderBy: { createdAt: 'desc' },
    take: 30,
  });
  res.json(notifications);
});

/**
 * POST /admin/announcements — Compose and send platform-wide announcement
 */
router.post('/announcements', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const parsed = AnnouncementSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const { title, body, targetType } = parsed.data;

  const notification = await prisma.notification.create({
    data: {
      title,
      body,
      targetType,
      createdBy: req.user!.userId,
      sentAt: new Date(),
    },
  });

  // Broadcast notification
  await sendNotification({
    targetRole: targetType === 'CUSTOMERS' ? 'CUSTOMER' : targetType === 'BUSINESSES' ? 'BUSINESS' : 'ALL',
    title,
    body,
  });

  res.status(201).json({ message: 'Announcement sent successfully! 📢', notification });
});

export default router;
