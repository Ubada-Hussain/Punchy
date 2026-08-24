"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const prisma_1 = __importDefault(require("../lib/prisma"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// GET /admin/users — all users
router.get('/users', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const { role, search, page = '1', limit = '20' } = req.query;
    const skip = (Number(page) - 1) * Number(limit);
    const where = {};
    if (role)
        where.role = role;
    if (search)
        where.email = { contains: String(search), mode: 'insensitive' };
    const [users, total] = await Promise.all([
        prisma_1.default.user.findMany({
            where, skip, take: Number(limit),
            select: { id: true, email: true, phone: true, role: true, isBlocked: true, createdAt: true, businessProfile: { select: { name: true, status: true } } },
            orderBy: { createdAt: 'desc' },
        }),
        prisma_1.default.user.count({ where }),
    ]);
    res.json({ users, total });
});
// GET /admin/users/:id — detail with activity
router.get('/users/:id', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const user = await prisma_1.default.user.findUnique({
        where: { id: String(req.params.id) },
        select: {
            id: true, email: true, phone: true, role: true, isBlocked: true, createdAt: true,
            businessProfile: true,
            customerCards: { include: { card: { include: { business: { select: { name: true } } } } } },
            activityLogs: { orderBy: { createdAt: 'desc' }, take: 30 },
        },
    });
    if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
    }
    res.json(user);
});
// POST /admin/users/:id/block
router.post('/users/:id/block', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    res.json(await prisma_1.default.user.update({ where: { id: String(req.params.id) }, data: { isBlocked: true } }));
});
// POST /admin/users/:id/unblock
router.post('/users/:id/unblock', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    res.json(await prisma_1.default.user.update({ where: { id: String(req.params.id) }, data: { isBlocked: false } }));
});
// GET /admin/config
router.get('/config', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (_req, res) => {
    const config = await prisma_1.default.adminConfig.findMany();
    res.json(Object.fromEntries(config.map(c => [c.key, c.value])));
});
// PUT /admin/config/:key
router.put('/config/:key', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const { value } = req.body;
    if (value === undefined) {
        res.status(400).json({ error: 'Missing value' });
        return;
    }
    const key = String(req.params.key);
    const config = await prisma_1.default.adminConfig.upsert({
        where: { key },
        update: { value, updatedBy: req.user.userId },
        create: { key, value, updatedBy: req.user.userId },
    });
    res.json(config);
});
exports.default = router;
//# sourceMappingURL=admin.js.map