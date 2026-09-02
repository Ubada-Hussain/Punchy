"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const prisma_1 = __importDefault(require("../lib/prisma"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// GET /customer/cards — wallet
router.get('/cards', auth_1.requireAuth, (0, auth_1.requireRole)('CUSTOMER'), async (req, res) => {
    const cards = await prisma_1.default.customerCard.findMany({
        where: { customerId: String(req.user.userId) },
        include: {
            card: {
                include: {
                    business: { select: { id: true, name: true, logo: true, category: true, locations: true } },
                    punchMethods: { where: { isActive: true }, select: { type: true } },
                },
            },
        },
        orderBy: { joinedAt: 'desc' },
    });
    res.json(cards);
});
// GET /customer/cards/:id — single card with punch history
router.get('/cards/:id', auth_1.requireAuth, (0, auth_1.requireRole)('CUSTOMER'), async (req, res) => {
    const card = await prisma_1.default.customerCard.findFirst({
        where: { id: String(req.params.id), customerId: req.user.userId },
        include: {
            card: { include: { business: { select: { id: true, name: true, logo: true, category: true, locations: true } } } },
            punchTransactions: { orderBy: { timestamp: 'desc' }, take: 50 },
            redemptions: { orderBy: { redeemedAt: 'desc' } },
        },
    });
    if (!card) {
        res.status(404).json({ error: 'Card not found' });
        return;
    }
    res.json(card);
});
// POST /customer/cards/:id/redeem
router.post('/cards/:id/redeem', auth_1.requireAuth, (0, auth_1.requireRole)('CUSTOMER'), async (req, res) => {
    const customerCard = await prisma_1.default.customerCard.findFirst({
        where: { id: String(req.params.id), customerId: req.user.userId },
    });
    if (!customerCard) {
        res.status(404).json({ error: 'Card not found' });
        return;
    }
    if (!customerCard.isCompleted) {
        res.status(400).json({ error: 'Card is not yet complete' });
        return;
    }
    const [redemption] = await prisma_1.default.$transaction([
        prisma_1.default.redemption.create({ data: { customerCardId: customerCard.id } }),
        prisma_1.default.customerCard.update({ where: { id: customerCard.id }, data: { punchCount: 0, isCompleted: false } }),
        prisma_1.default.activityLog.create({
            data: { userId: req.user.userId, action: 'REWARD_REDEEMED', metadata: { customerCardId: customerCard.id, cardId: customerCard.cardId } },
        }),
    ]);
    res.json({ message: 'Reward redeemed! Enjoy! 🎉', redemption });
});
// GET /customer/explore — browse available businesses & loyalty cards
router.get('/explore', auth_1.requireAuth, async (req, res) => {
    const { category, search } = req.query;
    const where = {
        status: 'APPROVED',
    };
    if (category && category !== 'All') {
        where.category = { contains: String(category), mode: 'insensitive' };
    }
    if (search) {
        where.OR = [
            { name: { contains: String(search), mode: 'insensitive' } },
            { category: { contains: String(search), mode: 'insensitive' } },
            { description: { contains: String(search), mode: 'insensitive' } },
        ];
    }
    const businesses = await prisma_1.default.businessProfile.findMany({
        where,
        include: {
            loyaltyCards: {
                where: { isActive: true },
                include: {
                    punchMethods: { where: { isActive: true } },
                    _count: { select: { customerCards: true } },
                },
            },
        },
        orderBy: { createdAt: 'desc' },
    });
    res.json(businesses);
});
// POST /customer/cards/join — join card without scan
router.post('/cards/join', auth_1.requireAuth, (0, auth_1.requireRole)('CUSTOMER'), async (req, res) => {
    const { cardId } = req.body;
    if (!cardId) {
        res.status(400).json({ error: 'cardId is required' });
        return;
    }
    const card = await prisma_1.default.loyaltyCard.findUnique({
        where: { id: String(cardId) },
        include: { business: true },
    });
    if (!card || !card.isActive) {
        res.status(404).json({ error: 'Card not found or inactive' });
        return;
    }
    if (card.validUntil && new Date(card.validUntil) < new Date()) {
        res.status(400).json({ error: 'This loyalty card has expired and cannot be added.' });
        return;
    }
    const customerId = req.user.userId;
    const existing = await prisma_1.default.customerCard.findUnique({
        where: { customerId_cardId: { customerId, cardId: card.id } },
    });
    if (existing) {
        res.json({ message: 'Card is already in your wallet', customerCard: existing });
        return;
    }
    const created = await prisma_1.default.customerCard.create({
        data: {
            customerId,
            cardId: card.id,
            punchCount: 0,
        },
    });
    await prisma_1.default.activityLog.create({
        data: {
            userId: customerId,
            action: 'CARD_JOINED_FROM_EXPLORE',
            metadata: { cardId: card.id, cardTitle: card.title, businessName: card.business.name },
        },
    });
    res.status(201).json({ message: 'Card added to your wallet! 🎉', customerCard: created });
});
exports.default = router;
//# sourceMappingURL=customer.js.map