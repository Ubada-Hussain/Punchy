import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { sendNotification } from '../lib/notifications';
import { clearMaintenanceCache } from '../middleware/maintenance';
import { parsePagination } from '../lib/pagination';

const router = Router();
const PermanentDeleteSchema = z.object({ confirmationKey: z.string().min(1) });
const SearchSchema = z.object({ q: z.string().trim().min(2).max(160) });
const ReportSchema = z.enum(['customers', 'subscriptions', 'payments', 'support', 'activity']);

function startOfMonth(monthOffset = 0): Date {
  const date = new Date();
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + monthOffset, 1));
}

function csvCell(value: unknown): string {
  const text = value == null ? '' : value instanceof Date ? value.toISOString() : String(value);
  return `"${text.replace(/"/g, '""')}"`;
}

function csv(rows: unknown[][]): string {
  return `\uFEFF${rows.map(row => row.map(csvCell).join(',')).join('\r\n')}\r\n`;
}

function hasValidDeletionKey(key: string): boolean {
  const expected = process.env.ADMIN_DELETION_KEY;
  return Boolean(expected) && key === expected;
}

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
  if (entries.some(([key]) => key === 'maintenanceMode')) clearMaintenanceCache();
  res.json({ message: 'Settings saved' });
});

// GET /admin/overview — one real-data source for the Admin dashboard.
router.get('/overview', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 86_400_000);
  const thirtyDaysAhead = new Date(now.getTime() + 30 * 86_400_000);
  const trendStart = startOfMonth(-5);
  const [
    totalCustomers, activeCustomers, suspendedCustomers, newCustomers,
    totalBusinesses, activeSubscriptions, trialSubscriptions, expiredSubscriptions,
    pendingPayments, approvedPayments, rejectedPayments, approvedRevenue,
    upcomingExpirations, openTickets, recentActions, customerDates, paymentRows,
    plans, countries,
  ] = await Promise.all([
    prisma.user.count({ where: { role: 'CUSTOMER' } }),
    prisma.user.count({ where: { role: 'CUSTOMER', isBlocked: false } }),
    prisma.user.count({ where: { role: 'CUSTOMER', isBlocked: true } }),
    prisma.user.count({ where: { role: 'CUSTOMER', createdAt: { gte: thirtyDaysAgo } } }),
    prisma.businessProfile.count(),
    prisma.businessSubscription.count({ where: { status: 'ACTIVE', endDate: { gt: now } } }),
    prisma.businessSubscription.count({ where: { status: 'TRIALING', endDate: { gt: now } } }),
    prisma.businessSubscription.count({ where: { OR: [{ status: 'EXPIRED' }, { endDate: { lte: now } }] } }),
    prisma.subscriptionPayment.count({ where: { status: 'PENDING' } }),
    prisma.subscriptionPayment.count({ where: { status: 'APPROVED' } }),
    prisma.subscriptionPayment.count({ where: { status: 'REJECTED' } }),
    prisma.subscriptionPayment.groupBy({ by: ['currency'], where: { status: 'APPROVED' }, _sum: { amount: true } }),
    prisma.businessSubscription.count({ where: { status: { in: ['ACTIVE', 'TRIALING'] }, endDate: { gt: now, lte: thirtyDaysAhead } } }),
    prisma.supportTicket.count({ where: { status: { in: ['OPEN', 'IN_PROGRESS'] } } }),
    prisma.activityLog.findMany({
      orderBy: { createdAt: 'desc' }, take: 10,
      select: { id: true, action: true, metadata: true, createdAt: true, user: { select: { email: true, role: true } } },
    }),
    prisma.user.findMany({ where: { role: 'CUSTOMER', createdAt: { gte: trendStart } }, select: { createdAt: true } }),
    prisma.subscriptionPayment.findMany({ where: { status: 'APPROVED', verifiedAt: { gte: trendStart } }, select: { amount: true, currency: true, verifiedAt: true } }),
    prisma.businessSubscription.groupBy({ by: ['plan'], _count: { _all: true } }),
    prisma.businessProfile.groupBy({ by: ['countryCode'], _count: { _all: true }, orderBy: { _count: { countryCode: 'desc' } }, take: 8 }),
  ]);

  const trend = Array.from({ length: 6 }, (_, index) => {
    const month = startOfMonth(index - 5);
    const next = new Date(Date.UTC(month.getUTCFullYear(), month.getUTCMonth() + 1, 1));
    return {
      key: month.toISOString().slice(0, 7),
      label: month.toLocaleDateString('en', { month: 'short', timeZone: 'UTC' }),
      customers: customerDates.filter(row => row.createdAt >= month && row.createdAt < next).length,
      revenue: paymentRows.filter(row => row.verifiedAt && row.verifiedAt >= month && row.verifiedAt < next).reduce((sum, row) => sum + row.amount, 0),
    };
  });

  res.json({
    generatedAt: now,
    customers: { total: totalCustomers, active: activeCustomers, new: newCustomers, suspended: suspendedCustomers },
    businesses: { total: totalBusinesses },
    subscriptions: { active: activeSubscriptions, trialing: trialSubscriptions, expired: expiredSubscriptions, upcomingExpirations },
    payments: { pending: pendingPayments, approved: approvedPayments, rejected: rejectedPayments, revenueByCurrency: approvedRevenue.map(row => ({ currency: row.currency, amount: row._sum.amount ?? 0 })) },
    support: { open: openTickets },
    trends: trend,
    distributions: {
      plans: plans.map(row => ({ label: row.plan, value: row._count._all })),
      countries: countries.map(row => ({ label: row.countryCode || 'Unknown', value: row._count._all })),
    },
    recentActions,
  });
});

// GET /admin/search — centralized identifier search across existing sources of truth.
router.get('/search', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const parsed = SearchSchema.safeParse(req.query);
  if (!parsed.success) { res.status(400).json({ error: 'Enter at least two characters.' }); return; }
  const q = parsed.data.q;
  const isObjectId = /^[a-f\d]{24}$/i.test(q);
  const [customers, businesses, payments, tickets] = await Promise.all([
    prisma.user.findMany({
      where: { role: 'CUSTOMER', OR: [
        { email: { contains: q, mode: 'insensitive' } }, { name: { contains: q, mode: 'insensitive' } },
        { phone: { contains: q, mode: 'insensitive' } }, { publicId: { contains: q, mode: 'insensitive' } },
      ] },
      select: { id: true, publicId: true, name: true, email: true, phone: true, isBlocked: true }, take: 6,
    }),
    prisma.businessProfile.findMany({
      where: { OR: [{ name: { contains: q, mode: 'insensitive' } }, { user: { is: { OR: [
        { email: { contains: q, mode: 'insensitive' } }, { phone: { contains: q, mode: 'insensitive' } }, { publicId: { contains: q, mode: 'insensitive' } },
      ] } } }] },
      select: { id: true, name: true, status: true, user: { select: { email: true, publicId: true } } }, take: 6,
    }),
    prisma.subscriptionPayment.findMany({
      where: { OR: [...(isObjectId ? [{ id: q }] : []), { transactionId: { contains: q, mode: 'insensitive' } }] },
      select: { id: true, transactionId: true, status: true, amount: true, currency: true, business: { select: { name: true } } }, take: 6,
    }),
    prisma.supportTicket.findMany({
      where: { OR: [...(isObjectId ? [{ id: q }] : []), { subject: { contains: q, mode: 'insensitive' } }, { author: { is: { email: { contains: q, mode: 'insensitive' } } } }] },
      select: { id: true, subject: true, status: true, author: { select: { email: true } } }, take: 6,
    }),
  ]);
  res.json({ customers, businesses, payments, tickets });
});

// GET /admin/audit — read-only view over the existing append-only ActivityLog source.
router.get('/audit', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const pagination = parsePagination(req.query);
  if (pagination.error) { res.status(400).json({ error: pagination.error }); return; }
  const search = String(req.query.search ?? '').trim();
  const where = search ? { OR: [
    { action: { contains: search, mode: 'insensitive' as const } },
    { user: { is: { email: { contains: search, mode: 'insensitive' as const } } } },
  ] } : {};
  const skip = (pagination.page - 1) * pagination.limit;
  const [events, total] = await Promise.all([
    prisma.activityLog.findMany({ where, skip, take: pagination.limit, orderBy: { createdAt: 'desc' }, include: { user: { select: { email: true, role: true } } } }),
    prisma.activityLog.count({ where }),
  ]);
  res.json({ events, total, page: pagination.page, limit: pagination.limit, totalPages: Math.ceil(total / pagination.limit) });
});

// GET /admin/operations — sanitized operational state only; no secrets or stack traces.
router.get('/operations', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  const started = Date.now();
  const [maintenance, scheduledNotifications, expiredSubscriptions] = await Promise.all([
    prisma.adminConfig.findUnique({ where: { key: 'maintenanceMode' } }),
    prisma.notification.count({ where: { sentAt: null, scheduledAt: { not: null } } }),
    prisma.businessSubscription.count({ where: { status: { in: ['ACTIVE', 'TRIALING'] }, endDate: { lte: new Date() } } }),
  ]);
  res.json({
    checkedAt: new Date(),
    services: [
      { name: 'API', status: 'healthy', detail: 'Request handling is operational' },
      { name: 'Database', status: 'healthy', detail: `${Date.now() - started} ms query latency` },
      { name: 'Scheduled notifications', status: 'healthy', detail: `${scheduledNotifications} queued` },
      { name: 'Subscription lifecycle', status: expiredSubscriptions ? 'attention' : 'healthy', detail: `${expiredSubscriptions} due for expiry processing` },
    ],
    maintenanceMode: maintenance?.value === true || maintenance?.value === 'true',
  });
});

// GET /admin/security — safe security posture summary from existing auth records.
router.get('/security', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  const now = new Date();
  const since = new Date(now.getTime() - 30 * 86_400_000);
  const [activeSessions, suspendedAccounts, passwordResetRequests, events] = await Promise.all([
    prisma.refreshToken.count({ where: { expiresAt: { gt: now } } }),
    prisma.user.count({ where: { isBlocked: true } }),
    prisma.passwordResetOtp.count({ where: { createdAt: { gte: since } } }),
    prisma.activityLog.findMany({
      where: { action: { in: ['ADMIN_BLOCKED_USER', 'ADMIN_UNBLOCKED_USER', 'ADMIN_BUSINESS_STATUS_UPDATED', 'PASSWORD_CHANGED', 'ACCOUNT_DELETE_REQUESTED'] } },
      orderBy: { createdAt: 'desc' }, take: 20, include: { user: { select: { email: true, role: true } } },
    }),
  ]);
  res.json({ activeSessions, suspendedAccounts, passwordResetRequests, events });
});

// GET /admin/reports/:report.csv — bounded exports backed by existing models.
router.get('/reports/:report.csv', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const parsed = ReportSchema.safeParse(req.params.report);
  if (!parsed.success) { res.status(404).json({ error: 'Unknown report' }); return; }
  let rows: unknown[][];
  if (parsed.data === 'customers') {
    const data = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, orderBy: { createdAt: 'desc' }, take: 5000, select: { publicId: true, name: true, email: true, phone: true, countryCode: true, isBlocked: true, createdAt: true } });
    rows = [['Customer ID', 'Name', 'Email', 'Phone', 'Country', 'Status', 'Registered'], ...data.map(row => [row.publicId, row.name, row.email, row.phone, row.countryCode, row.isBlocked ? 'SUSPENDED' : 'ACTIVE', row.createdAt])];
  } else if (parsed.data === 'subscriptions') {
    const data = await prisma.businessSubscription.findMany({ orderBy: { createdAt: 'desc' }, take: 5000, include: { business: { select: { name: true } } } });
    rows = [['Subscription ID', 'Business', 'Plan', 'Status', 'Price', 'Currency', 'Start', 'End'], ...data.map(row => [row.id, row.business.name, row.plan, row.status, row.price, row.currency, row.startDate, row.endDate])];
  } else if (parsed.data === 'payments') {
    const data = await prisma.subscriptionPayment.findMany({ orderBy: { createdAt: 'desc' }, take: 5000, include: { business: { select: { name: true } }, verifiedBy: { select: { email: true } } } });
    rows = [['Payment ID', 'Business', 'Transaction ID', 'Method', 'Plan', 'Amount', 'Currency', 'Status', 'Submitted', 'Reviewed by', 'Reviewed'], ...data.map(row => [row.id, row.business.name, row.transactionId, row.paymentMethodName, row.plan, row.amount, row.currency, row.status, row.createdAt, row.verifiedBy?.email, row.verifiedAt])];
  } else if (parsed.data === 'support') {
    const data = await prisma.supportTicket.findMany({ orderBy: { createdAt: 'desc' }, take: 5000, include: { author: { select: { email: true, role: true } }, resolver: { select: { email: true } } } });
    rows = [['Ticket ID', 'Customer', 'Role', 'Subject', 'Status', 'Created', 'Resolved', 'Resolved by'], ...data.map(row => [row.id, row.author.email, row.author.role, row.subject, row.status, row.createdAt, row.resolvedAt, row.resolver?.email])];
  } else {
    const data = await prisma.activityLog.findMany({ orderBy: { createdAt: 'desc' }, take: 5000, include: { user: { select: { email: true, role: true } } } });
    rows = [['Event ID', 'Actor', 'Role', 'Action', 'Timestamp', 'Metadata'], ...data.map(row => [row.id, row.user.email, row.user.role, row.action, row.createdAt, JSON.stringify(row.metadata)])];
  }
  await prisma.activityLog.create({ data: { userId: req.user!.userId, action: 'ADMIN_REPORT_EXPORTED', metadata: { report: parsed.data, rowCount: rows.length - 1 } } });
  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="punchy-${parsed.data}-${new Date().toISOString().slice(0, 10)}.csv"`);
  res.send(csv(rows));
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

  // Persist the direct notification so the business sees the same message in
  // its Punchy inbox as it receives through FCM.
  const businessNotification = await prisma.notification.create({
    data: {
      targetType: 'USER',
      targetId: business.userId,
      title: `Business Profile ${status === 'APPROVED' ? 'Approved! 🎉' : status}`,
      body: `Your business profile "${business.name}" has been marked as ${status}.`,
      createdBy: req.user!.userId,
      sentAt: new Date(),
    },
  });
  await sendNotification({
    userId: business.userId,
    title: businessNotification.title,
    body: businessNotification.body,
    data: { notificationId: businessNotification.id },
  });

  res.json({ message: `Business status updated to ${status}`, business });
});

/**
 * GET /admin/customers — List all customer accounts
 */
router.get('/customers', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const pagination = parsePagination(req.query);
  if (pagination.error) { res.status(400).json({ error: pagination.error }); return; }
  const { search, status, country } = req.query;
  const where: Record<string, unknown> = { role: 'CUSTOMER' };

  if (search) {
    const value = String(search).trim();
    where.OR = [
      { email: { contains: value, mode: 'insensitive' } },
      { name: { contains: value, mode: 'insensitive' } },
      { phone: { contains: value, mode: 'insensitive' } },
      { publicId: { contains: value, mode: 'insensitive' } },
    ];
  }
  if (status === 'ACTIVE') where.isBlocked = false;
  if (status === 'SUSPENDED') where.isBlocked = true;
  if (country) where.countryCode = String(country).toUpperCase();

  const [customers, total] = await Promise.all([
    prisma.user.findMany({
      where, skip: (pagination.page - 1) * pagination.limit, take: pagination.limit,
      select: {
        id: true, publicId: true, name: true, email: true, phone: true, countryCode: true,
        isBlocked: true, createdAt: true,
        customerCards: {
          select: { id: true, punchCount: true, isCompleted: true, card: { select: { title: true } } },
        },
        _count: { select: { customerCards: true } },
      },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.user.count({ where }),
  ]);

  res.json({ customers, total, page: pagination.page, limit: pagination.limit, totalPages: Math.ceil(total / pagination.limit) });
});

// GET /admin/customers/:id — customer detail for the admin portal
router.get('/customers/:id', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const customer = await prisma.user.findFirst({
    where: { id: String(req.params.id), role: 'CUSTOMER' },
    select: {
      id: true, publicId: true, email: true, name: true, phone: true, countryCode: true, isBlocked: true, createdAt: true, updatedAt: true,
      customerCards: {
        select: { id: true, punchCount: true, isCompleted: true, card: { select: { title: true, business: { select: { name: true } } } } },
      },
      supportTickets: { orderBy: { createdAt: 'desc' }, take: 10, select: { id: true, subject: true, status: true, createdAt: true, resolvedAt: true } },
      activityLogs: { orderBy: { createdAt: 'desc' }, take: 30, select: { id: true, action: true, metadata: true, createdAt: true } },
      refreshTokens: { where: { expiresAt: { gt: new Date() } }, select: { id: true, createdAt: true, expiresAt: true } },
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

// DELETE /admin/customers/:id — permanently remove a customer and their personal data.
router.delete('/customers/:id', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const parsed = PermanentDeleteSchema.safeParse(req.body);
  if (!parsed.success || !hasValidDeletionKey(parsed.data.confirmationKey)) {
    res.status(403).json({ error: 'The permanent deletion key is incorrect.' }); return;
  }
  const user = await prisma.user.findFirst({ where: { id: String(req.params.id), role: 'CUSTOMER' }, select: { id: true } });
  if (!user) { res.status(404).json({ error: 'Customer not found' }); return; }
  const customerCards = await prisma.customerCard.findMany({ where: { customerId: user.id }, select: { id: true } });
  const customerCardIds = customerCards.map((card) => card.id);
  await prisma.$transaction([
    ...(customerCardIds.length ? [prisma.punchTransaction.deleteMany({ where: { customerCardId: { in: customerCardIds } } }), prisma.redemption.deleteMany({ where: { customerCardId: { in: customerCardIds } } }), prisma.customerCard.deleteMany({ where: { customerId: user.id } })] : []),
    prisma.refreshToken.deleteMany({ where: { userId: user.id } }),
    prisma.activityLog.deleteMany({ where: { userId: user.id } }),
    prisma.notification.deleteMany({ where: { createdBy: user.id } }),
    prisma.supportTicket.deleteMany({ where: { authorId: user.id } }),
    prisma.supportTicket.updateMany({ where: { resolvedBy: user.id }, data: { resolvedBy: null } }),
    prisma.user.delete({ where: { id: user.id } }),
  ]);
  res.json({ message: 'Customer account permanently deleted.' });
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
