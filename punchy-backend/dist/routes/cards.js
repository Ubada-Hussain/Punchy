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
const CardSchema = zod_1.z.object({
    title: zod_1.z.string().min(2),
    punchesRequired: zod_1.z.number().int().min(1).max(100).default(10),
    rewardDescription: zod_1.z.string().min(5),
    validUntil: zod_1.z.string().nullable().optional(),
    visualStyle: zod_1.z.object({
        primaryColor: zod_1.z.string().default('#FF6B35'),
        bgColor: zod_1.z.string().default('#1a1a2e'),
        iconType: zod_1.z.string().default('star'),
    }).optional(),
});
// GET /cards/business/:businessId
router.get('/business/:businessId', auth_1.requireAuth, async (req, res) => {
    const businessId = String(req.params.businessId);
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: businessId } });
    if (!business) {
        res.status(404).json({ error: 'Business not found' });
        return;
    }
    const isOwner = req.user.role === 'BUSINESS' && business.userId === req.user.userId;
    const isAdmin = req.user.role === 'ADMIN';
    const cards = await prisma_1.default.loyaltyCard.findMany({
        where: { businessId, ...(isOwner || isAdmin ? {} : { isActive: true }) },
        include: { punchMethods: { where: { isActive: true } }, _count: { select: { customerCards: true } } },
        orderBy: { createdAt: 'desc' },
    });
    res.json(cards);
});
// POST /cards/business/:businessId
router.post('/business/:businessId', auth_1.requireAuth, (0, auth_1.requireRole)('BUSINESS'), async (req, res) => {
    const businessId = String(req.params.businessId);
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: businessId } });
    if (!business || business.userId !== req.user.userId) {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    // Check Single Active Card rule
    const existingCard = await prisma_1.default.loyaltyCard.findFirst({ where: { businessId } });
    if (existingCard) {
        res.status(400).json({ error: 'A business can only have one active loyalty card at a time. Please delete your existing card before creating a new one.' });
        return;
    }
    const parsed = CardSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const card = await prisma_1.default.loyaltyCard.create({
        data: {
            businessId,
            title: parsed.data.title,
            punchesRequired: parsed.data.punchesRequired,
            rewardDescription: parsed.data.rewardDescription,
            validUntil: parsed.data.validUntil ? new Date(parsed.data.validUntil) : null,
            visualStyle: parsed.data.visualStyle ?? { primaryColor: '#FF6B35', bgColor: '#1a1a2e', iconType: 'star' },
        },
    });
    res.status(201).json(card);
});
// GET /cards/:id
router.get('/:id', auth_1.requireAuth, async (req, res) => {
    const id = String(req.params.id);
    const card = await prisma_1.default.loyaltyCard.findUnique({
        where: { id },
        include: {
            business: { select: { id: true, name: true, logo: true, status: true } },
            punchMethods: { where: { isActive: true } },
        },
    });
    if (!card) {
        res.status(404).json({ error: 'Card not found' });
        return;
    }
    res.json(card);
});
// PATCH /cards/:id
router.patch('/:id', auth_1.requireAuth, (0, auth_1.requireRole)('BUSINESS'), async (req, res) => {
    const id = String(req.params.id);
    const card = await prisma_1.default.loyaltyCard.findUnique({ where: { id } });
    if (!card) {
        res.status(404).json({ error: 'Card not found' });
        return;
    }
    // Verify ownership via business
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: card.businessId } });
    if (!business || business.userId !== req.user.userId) {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    const parsed = CardSchema.partial().safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const updateData = { ...parsed.data };
    if (parsed.data.validUntil !== undefined) {
        updateData.validUntil = parsed.data.validUntil ? new Date(parsed.data.validUntil) : null;
    }
    res.json(await prisma_1.default.loyaltyCard.update({ where: { id }, data: updateData }));
});
// DELETE /cards/:id
router.delete('/:id', auth_1.requireAuth, (0, auth_1.requireRole)('BUSINESS'), async (req, res) => {
    const id = String(req.params.id);
    const card = await prisma_1.default.loyaltyCard.findUnique({ where: { id } });
    if (!card) {
        res.status(404).json({ error: 'Card not found' });
        return;
    }
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: card.businessId } });
    if (!business || business.userId !== req.user.userId) {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    await prisma_1.default.punchMethod.deleteMany({ where: { cardId: id } });
    await prisma_1.default.customerCard.deleteMany({ where: { cardId: id } });
    await prisma_1.default.loyaltyCard.delete({ where: { id } });
    res.json({ message: 'Loyalty card deleted successfully' });
});
exports.default = router;
//# sourceMappingURL=cards.js.map