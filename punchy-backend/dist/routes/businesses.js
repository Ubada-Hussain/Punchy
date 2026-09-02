"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const prisma_1 = __importDefault(require("../lib/prisma"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
const BusinessUpsertSchema = zod_1.z.object({
    name: zod_1.z.string().min(2),
    category: zod_1.z.string(),
    description: zod_1.z.string().optional(),
    website: zod_1.z.string().url().optional(),
    logo: zod_1.z.string().optional(),
    locations: zod_1.z.array(zod_1.z.object({ address: zod_1.z.string(), lat: zod_1.z.number().optional(), lng: zod_1.z.number().optional() })).optional(),
});
// GET /businesses — admin: all businesses with pagination + filters
router.get('/', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const { search, status, page = '1', limit = '20' } = req.query;
    const skip = (Number(page) - 1) * Number(limit);
    const where = {};
    if (status)
        where.status = status;
    if (search)
        where.OR = [
            { name: { contains: String(search), mode: 'insensitive' } },
            { category: { contains: String(search), mode: 'insensitive' } },
        ];
    const [businesses, total] = await Promise.all([
        prisma_1.default.businessProfile.findMany({
            where, skip, take: Number(limit),
            include: { user: { select: { email: true, publicId: true, createdAt: true } }, _count: { select: { loyaltyCards: true } } },
            orderBy: { createdAt: 'desc' },
        }),
        prisma_1.default.businessProfile.count({ where }),
    ]);
    res.json({ businesses, total, page: Number(page), limit: Number(limit) });
});
// POST /businesses — business user creates their profile
router.post('/', auth_1.requireAuth, (0, auth_1.requireRole)('BUSINESS'), async (req, res) => {
    if (await prisma_1.default.businessProfile.findUnique({ where: { userId: req.user.userId } })) {
        res.status(409).json({ error: 'Profile already exists — use PATCH to update' });
        return;
    }
    const parsed = BusinessUpsertSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const business = await prisma_1.default.businessProfile.create({
        data: { userId: req.user.userId, ...parsed.data, locations: parsed.data.locations ?? [], status: 'APPROVED' },
    });
    res.status(201).json(business);
});
// GET /businesses/me — own business profile
router.get('/me', auth_1.requireAuth, (0, auth_1.requireRole)('BUSINESS'), async (req, res) => {
    const business = await prisma_1.default.businessProfile.findUnique({
        where: { userId: req.user.userId },
        include: { loyaltyCards: { include: { punchMethods: true, _count: { select: { customerCards: true } } } } },
    });
    if (!business) {
        res.status(404).json({ error: 'No business profile found' });
        return;
    }
    res.json(business);
});
// GET /businesses/:id
router.get('/:id', auth_1.requireAuth, async (req, res) => {
    const business = await prisma_1.default.businessProfile.findUnique({
        where: { id: String(req.params.id) },
        include: {
            user: { select: { email: true, phone: true } },
            loyaltyCards: { include: { punchMethods: true, _count: { select: { customerCards: true } } } },
        },
    });
    if (!business) {
        res.status(404).json({ error: 'Business not found' });
        return;
    }
    const isOwner = req.user.role === 'BUSINESS' && business.userId === req.user.userId;
    const isAdmin = req.user.role === 'ADMIN';
    if (!isOwner && !isAdmin && business.status !== 'APPROVED') {
        res.status(404).json({ error: 'Business not found' });
        return;
    }
    res.json(business);
});
// PATCH /businesses/:id — owner or admin
router.patch('/:id', auth_1.requireAuth, async (req, res) => {
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: String(req.params.id) } });
    if (!business) {
        res.status(404).json({ error: 'Business not found' });
        return;
    }
    const isOwner = req.user.role === 'BUSINESS' && business.userId === req.user.userId;
    if (!isOwner && req.user.role !== 'ADMIN') {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    const parsed = BusinessUpsertSchema.partial().safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    res.json(await prisma_1.default.businessProfile.update({ where: { id: String(req.params.id) }, data: parsed.data }));
});
// POST /businesses/:id/suspend
router.post('/:id/suspend', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const b = await prisma_1.default.businessProfile.findUnique({ where: { id: String(req.params.id) } });
    if (!b) {
        res.status(404).json({ error: 'Business not found' });
        return;
    }
    res.json(await prisma_1.default.businessProfile.update({ where: { id: String(req.params.id) }, data: { status: 'SUSPENDED' } }));
});
// POST /businesses/:id/unban — only an admin can restore a suspended business
router.post('/:id/unban', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const b = await prisma_1.default.businessProfile.findUnique({ where: { id: String(req.params.id) } });
    if (!b) {
        res.status(404).json({ error: 'Business not found' });
        return;
    }
    res.json(await prisma_1.default.businessProfile.update({ where: { id: String(req.params.id) }, data: { status: 'APPROVED' } }));
});
exports.default = router;
//# sourceMappingURL=businesses.js.map