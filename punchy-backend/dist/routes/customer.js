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
                    business: { select: { id: true, name: true, logo: true, category: true } },
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
            card: { include: { business: { select: { id: true, name: true, logo: true, category: true } } } },
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
exports.default = router;
//# sourceMappingURL=customer.js.map