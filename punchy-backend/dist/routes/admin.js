"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const prisma_1 = __importDefault(require("../lib/prisma"));
const auth_1 = require("../middleware/auth");
const notifications_1 = require("../lib/notifications");
const router = (0, express_1.Router)();
// GET /admin/config — persisted platform settings
router.get('/config', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (_req, res) => {
    const rows = await prisma_1.default.adminConfig.findMany();
    res.json(Object.fromEntries(rows.map(row => [row.key, row.value])));
});
// PATCH /admin/config — update persisted platform settings
router.patch('/config', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const allowed = ['maintenanceMode', 'minimumAppVersion', 'supportEmail', 'termsUrl', 'trialPeriodDays'];
    const entries = Object.entries(req.body).filter(([key]) => allowed.includes(key));
    await prisma_1.default.$transaction(entries.map(([key, value]) => prisma_1.default.adminConfig.upsert({
        where: { key },
        create: { key, value: value, updatedBy: req.user.userId },
        update: { value: value, updatedBy: req.user.userId },
    })));
    res.json({ message: 'Settings saved' });
});
/**
 * GET /admin/stats — Platform-wide overview & growth metrics
 */
router.get('/stats', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (_req, res) => {
    try {
        const [totalBusinesses, totalCustomers, totalPunches, totalRedemptions] = await Promise.all([
            prisma_1.default.businessProfile.count(),
            prisma_1.default.user.count({ where: { role: 'CUSTOMER' } }),
            prisma_1.default.punchTransaction.count(),
            prisma_1.default.redemption.count(),
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
        const recentActivity = await prisma_1.default.activityLog.findMany({
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
    }
    catch (error) {
        console.error('Admin stats error:', error);
        res.status(500).json({ error: 'Failed to load admin stats' });
    }
});
/**
 * GET /admin/businesses — List all registered businesses with status
 */
router.get('/businesses', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const { status, search } = req.query;
    const where = {};
    if (status && status !== 'ALL') {
        where.status = status;
    }
    if (search) {
        where.OR = [
            { name: { contains: String(search), mode: 'insensitive' } },
            { category: { contains: String(search), mode: 'insensitive' } },
        ];
    }
    const businesses = await prisma_1.default.businessProfile.findMany({
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
router.put('/businesses/:id/status', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const { status } = req.body;
    if (!['APPROVED', 'SUSPENDED'].includes(status)) {
        res.status(400).json({ error: 'Invalid business status' });
        return;
    }
    const business = await prisma_1.default.businessProfile.update({
        where: { id: String(req.params.id) },
        data: { status },
        include: { user: true },
    });
    await prisma_1.default.activityLog.create({
        data: {
            userId: req.user.userId,
            action: 'ADMIN_BUSINESS_STATUS_UPDATED',
            metadata: { businessId: business.id, businessName: business.name, newStatus: status },
        },
    });
    // Notify business owner
    await (0, notifications_1.sendNotification)({
        userId: business.userId,
        title: `Business Profile ${status === 'APPROVED' ? 'Approved! 🎉' : status}`,
        body: `Your business profile "${business.name}" has been marked as ${status}.`,
    });
    res.json({ message: `Business status updated to ${status}`, business });
});
/**
 * GET /admin/customers — List all customer accounts
 */
router.get('/customers', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const { search } = req.query;
    const where = { role: 'CUSTOMER' };
    if (search) {
        where.email = { contains: String(search), mode: 'insensitive' };
    }
    const customers = await prisma_1.default.user.findMany({
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
router.get('/customers/:id', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const customer = await prisma_1.default.user.findFirst({
        where: { id: String(req.params.id), role: 'CUSTOMER' },
        select: {
            id: true, publicId: true, email: true, name: true, phone: true, isBlocked: true, createdAt: true,
            customerCards: {
                select: { id: true, punchCount: true, isCompleted: true, card: { select: { title: true, business: { select: { name: true } } } } },
            },
        },
    });
    if (!customer) {
        res.status(404).json({ error: 'Customer not found' });
        return;
    }
    res.json({ customer });
});
router.get('/notification-targets', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (_req, res) => {
    const [customers, businesses] = await Promise.all([
        prisma_1.default.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true, publicId: true, email: true, name: true, createdAt: true } }),
        prisma_1.default.businessProfile.findMany({ select: { userId: true, name: true, createdAt: true, user: { select: { email: true, publicId: true } } } }),
    ]);
    res.json({ customers, businesses });
});
/**
 * POST /admin/customers/:id/toggle-block — Suspend or Unsuspend customer account
 */
router.post('/customers/:id/toggle-block', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const user = await prisma_1.default.user.findUnique({ where: { id: String(req.params.id) } });
    if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
    }
    if (user.role !== 'CUSTOMER') {
        res.status(400).json({ error: 'Only customer accounts can be suspended here' });
        return;
    }
    const updated = await prisma_1.default.user.update({
        where: { id: user.id },
        data: { isBlocked: !user.isBlocked },
    });
    await prisma_1.default.activityLog.create({
        data: {
            userId: req.user.userId,
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
const AnnouncementSchema = zod_1.z.object({
    title: zod_1.z.string().min(3),
    body: zod_1.z.string().min(5),
    targetType: zod_1.z.enum(['ALL', 'BUSINESSES', 'CUSTOMERS']),
});
/**
 * GET /admin/announcements — List announcement history
 */
router.get('/announcements', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (_req, res) => {
    const notifications = await prisma_1.default.notification.findMany({
        orderBy: { createdAt: 'desc' },
        take: 30,
    });
    res.json(notifications);
});
/**
 * POST /admin/announcements — Compose and send platform-wide announcement
 */
router.post('/announcements', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const parsed = AnnouncementSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const { title, body, targetType } = parsed.data;
    const notification = await prisma_1.default.notification.create({
        data: {
            title,
            body,
            targetType,
            createdBy: req.user.userId,
            sentAt: new Date(),
        },
    });
    // Broadcast notification
    await (0, notifications_1.sendNotification)({
        targetRole: targetType === 'CUSTOMERS' ? 'CUSTOMER' : targetType === 'BUSINESSES' ? 'BUSINESS' : 'ALL',
        title,
        body,
    });
    res.status(201).json({ message: 'Announcement sent successfully! 📢', notification });
});
exports.default = router;
//# sourceMappingURL=admin.js.map