"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const prisma_1 = __importDefault(require("../lib/prisma"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// GET /analytics/platform — admin only
router.get('/platform', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const days = parseInt(String(req.query.period ?? '30'));
    const since = new Date(Date.now() - days * 86400000);
    const [totalBusinesses, totalCustomers, totalPunches, totalRedemptions, newBusinesses, newCustomers, recentPunches] = await Promise.all([
        prisma_1.default.businessProfile.count(),
        prisma_1.default.user.count({ where: { role: 'CUSTOMER' } }),
        prisma_1.default.punchTransaction.count(),
        prisma_1.default.redemption.count(),
        prisma_1.default.businessProfile.count({ where: { createdAt: { gte: since } } }),
        prisma_1.default.user.count({ where: { role: 'CUSTOMER', createdAt: { gte: since } } }),
        prisma_1.default.punchTransaction.count({ where: { timestamp: { gte: since } } }),
    ]);
    // Top businesses by total punch count (aggregate via raw query for performance)
    const topBusinesses = await prisma_1.default.businessProfile.findMany({
        take: 5,
        select: {
            id: true, name: true, category: true, logo: true,
            loyaltyCards: {
                select: {
                    customerCards: {
                        select: { punchTransactions: { select: { id: true } } },
                    },
                },
            },
        },
    });
    res.json({
        totals: { totalBusinesses, totalCustomers, totalPunches, totalRedemptions },
        period: { days, newBusinesses, newCustomers, recentPunches },
        topBusinesses: topBusinesses
            .map(b => ({
            id: b.id, name: b.name, category: b.category, logo: b.logo,
            totalPunches: b.loyaltyCards.reduce((s, c) => s + c.customerCards.reduce((s2, cc) => s2 + cc.punchTransactions.length, 0), 0),
        }))
            .sort((a, b) => b.totalPunches - a.totalPunches),
    });
});
// GET /analytics/business/:businessId — owner or admin
router.get('/business/:businessId', auth_1.requireAuth, async (req, res) => {
    const businessId = String(req.params.businessId);
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: businessId } });
    if (!business) {
        res.status(404).json({ error: 'Business not found' });
        return;
    }
    const isOwner = req.user.role === 'BUSINESS' && business.userId === req.user.userId;
    if (!isOwner && req.user.role !== 'ADMIN') {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    const cards = await prisma_1.default.loyaltyCard.findMany({
        where: { businessId },
        include: {
            _count: { select: { customerCards: true } },
            customerCards: {
                select: {
                    customerId: true,
                    punchTransactions: { select: { id: true } },
                    redemptions: { select: { id: true } },
                },
            },
        },
    });
    const totalCustomers = new Set(cards.flatMap(c => c.customerCards.map(cc => cc.customerId))).size;
    const totalPunches = cards.reduce((s, c) => s + c.customerCards.reduce((s2, cc) => s2 + cc.punchTransactions.length, 0), 0);
    const totalRedemptions = cards.reduce((s, c) => s + c.customerCards.reduce((s2, cc) => s2 + cc.redemptions.length, 0), 0);
    const recentActivity = await prisma_1.default.activityLog.findMany({
        where: {
            metadata: { path: ['businessId'], equals: businessId },
            createdAt: { gte: new Date(Date.now() - 30 * 86400000) },
        },
        orderBy: { createdAt: 'desc' },
        take: 20,
        include: { user: { select: { email: true } } },
    });
    res.json({
        business: { id: business.id, name: business.name, status: business.status },
        totals: { totalCustomers, totalPunches, totalRedemptions },
        cards: cards.map(c => ({
            id: c.id, title: c.title,
            customers: c._count.customerCards,
            punches: c.customerCards.reduce((s, cc) => s + cc.punchTransactions.length, 0),
            redemptions: c.customerCards.reduce((s, cc) => s + cc.redemptions.length, 0),
        })),
        recentActivity,
    });
});
exports.default = router;
//# sourceMappingURL=analytics.js.map