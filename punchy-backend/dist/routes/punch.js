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
const PunchSchema = zod_1.z.object({ identifier: zod_1.z.string().min(1) });
/**
 * POST /punch
 *
 * Called when a customer scans a QR code or taps an NFC tag.
 * Atomically validates the identifier, joins the card on first visit,
 * increments the punch count, and marks completion.
 */
router.post('/', auth_1.requireAuth, (0, auth_1.requireRole)('CUSTOMER'), async (req, res) => {
    const parsed = PunchSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const punchMethod = await prisma_1.default.punchMethod.findUnique({
        where: { identifier: parsed.data.identifier },
        include: { card: { include: { business: true } } },
    });
    if (!punchMethod?.isActive) {
        res.status(404).json({ error: 'Invalid or inactive punch identifier' });
        return;
    }
    if (!punchMethod.card.isActive) {
        res.status(400).json({ error: 'This loyalty card is no longer active' });
        return;
    }
    if (punchMethod.card.validUntil && new Date(punchMethod.card.validUntil) < new Date()) {
        res.status(400).json({ error: 'This loyalty card has expired' });
        return;
    }
    if (punchMethod.card.business.status !== 'APPROVED') {
        res.status(400).json({ error: 'This business is not currently active' });
        return;
    }
    const customerId = req.user.userId;
    const card = punchMethod.card;
    try {
        const result = await prisma_1.default.$transaction(async (tx) => {
            let customerCard = await tx.customerCard.findUnique({
                where: { customerId_cardId: { customerId, cardId: card.id } },
            });
            if (customerCard?.isCompleted)
                throw new Error('CARD_ALREADY_COMPLETED');
            const isFirstVisit = !customerCard;
            if (!customerCard) {
                customerCard = await tx.customerCard.create({ data: { customerId, cardId: card.id } });
            }
            const newCount = customerCard.punchCount + 1;
            const isNowComplete = newCount >= card.punchesRequired;
            const updated = await tx.customerCard.update({
                where: { id: customerCard.id },
                data: { punchCount: newCount, isCompleted: isNowComplete },
            });
            await tx.punchTransaction.create({
                data: { customerCardId: customerCard.id, punchMethodId: punchMethod.id, method: punchMethod.type },
            });
            await tx.activityLog.create({
                data: {
                    userId: customerId,
                    action: isFirstVisit ? 'CARD_JOINED_AND_PUNCHED' : 'PUNCH_RECORDED',
                    metadata: { cardId: card.id, businessId: card.businessId, punchCount: newCount, punchesRequired: card.punchesRequired, isCompleted: isNowComplete },
                },
            });
            return { updated, isFirstVisit, newCount, isNowComplete };
        });
        res.json({
            message: result.isNowComplete
                ? '🎉 Reward unlocked! Show this to redeem in-store.'
                : `Punch recorded! ${result.newCount}/${card.punchesRequired}`,
            punchCount: result.newCount,
            punchesRequired: card.punchesRequired,
            isCompleted: result.isNowComplete,
            isFirstVisit: result.isFirstVisit,
            customerCard: result.updated,
        });
    }
    catch (err) {
        if (err instanceof Error && err.message === 'CARD_ALREADY_COMPLETED') {
            res.status(400).json({ error: 'Card is already complete. Please redeem your reward first.' });
            return;
        }
        throw err;
    }
});
exports.default = router;
//# sourceMappingURL=punch.js.map