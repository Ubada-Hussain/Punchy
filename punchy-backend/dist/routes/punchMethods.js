"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const uuid_1 = require("uuid");
const prisma_1 = __importDefault(require("../lib/prisma"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
const MethodSchema = zod_1.z.object({
    type: zod_1.z.enum(['QR', 'NFC']),
    label: zod_1.z.string().optional(),
});
// GET /punch-methods — admin inventory for the admin portal
router.get('/', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (_req, res) => {
    const methods = await prisma_1.default.punchMethod.findMany({
        include: { card: { include: { business: { select: { name: true } } } } },
        orderBy: { createdAt: 'desc' },
    });
    res.json({ methods });
});
// POST /punch-methods/card/:cardId
router.post('/card/:cardId', auth_1.requireAuth, (0, auth_1.requireRole)('BUSINESS'), async (req, res) => {
    const cardId = String(req.params.cardId);
    const card = await prisma_1.default.loyaltyCard.findUnique({ where: { id: cardId } });
    if (!card) {
        res.status(404).json({ error: 'Card not found' });
        return;
    }
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: card.businessId } });
    if (!business || business.userId !== req.user.userId) {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    const parsed = MethodSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const method = await prisma_1.default.punchMethod.create({
        data: { cardId, type: parsed.data.type, identifier: (0, uuid_1.v4)(), label: parsed.data.label },
    });
    res.status(201).json(method);
});
// GET /punch-methods/card/:cardId
router.get('/card/:cardId', auth_1.requireAuth, async (req, res) => {
    const cardId = String(req.params.cardId);
    const card = await prisma_1.default.loyaltyCard.findUnique({ where: { id: cardId } });
    if (!card) {
        res.status(404).json({ error: 'Card not found' });
        return;
    }
    const business = await prisma_1.default.businessProfile.findUnique({ where: { id: card.businessId } });
    const isOwner = req.user.role === 'BUSINESS' && business?.userId === req.user.userId;
    if (!isOwner && req.user.role !== 'ADMIN') {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    res.json(await prisma_1.default.punchMethod.findMany({ where: { cardId }, orderBy: { createdAt: 'desc' } }));
});
// DELETE /punch-methods/:id — deactivate
router.delete('/:id', auth_1.requireAuth, (0, auth_1.requireRole)('BUSINESS'), async (req, res) => {
    const id = String(req.params.id);
    const method = await prisma_1.default.punchMethod.findUnique({ where: { id } });
    if (!method) {
        res.status(404).json({ error: 'Method not found' });
        return;
    }
    const card = await prisma_1.default.loyaltyCard.findUnique({ where: { id: method.cardId } });
    const business = card ? await prisma_1.default.businessProfile.findUnique({ where: { id: card.businessId } }) : null;
    if (!business || business.userId !== req.user.userId) {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    await prisma_1.default.punchMethod.update({ where: { id }, data: { isActive: false } });
    res.json({ message: 'Punch method deactivated' });
});
exports.default = router;
//# sourceMappingURL=punchMethods.js.map