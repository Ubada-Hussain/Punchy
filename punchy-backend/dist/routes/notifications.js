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
const NotificationSchema = zod_1.z.object({
    title: zod_1.z.string().min(2),
    body: zod_1.z.string().min(5),
    targetType: zod_1.z.enum(['ALL', 'BUSINESSES', 'CUSTOMERS', 'USER']),
    targetId: zod_1.z.string().optional(),
    scheduledAt: zod_1.z.string().datetime().optional(),
});
// POST /notifications
router.post('/', auth_1.requireAuth, async (req, res) => {
    const parsed = NotificationSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    if (req.user.role !== 'ADMIN' && parsed.data.targetType !== 'CUSTOMERS') {
        res.status(403).json({ error: 'Business accounts can only target customers' });
        return;
    }
    let targetId = parsed.data.targetId;
    if (parsed.data.targetType === 'USER' && targetId) {
        const candidates = [{ publicId: targetId }];
        if (/^[a-f0-9]{24}$/i.test(targetId))
            candidates.unshift({ id: targetId });
        const target = await prisma_1.default.user.findFirst({ where: { OR: candidates }, select: { id: true } });
        if (!target) {
            res.status(404).json({ error: 'Recipient not found for that ID' });
            return;
        }
        targetId = target.id;
    }
    const notification = await prisma_1.default.notification.create({
        data: { ...parsed.data, targetId, createdBy: req.user.userId, sentAt: parsed.data.scheduledAt ? undefined : new Date() },
    });
    await (0, notifications_1.sendNotification)({ userId: parsed.data.targetType === 'USER' ? targetId : undefined, targetRole: parsed.data.targetType === 'CUSTOMERS' ? 'CUSTOMER' : parsed.data.targetType === 'BUSINESSES' ? 'BUSINESS' : 'ALL', title: parsed.data.title, body: parsed.data.body });
    res.status(201).json(notification);
});
// GET /notifications
router.get('/', auth_1.requireAuth, async (req, res) => {
    const { page = '1', limit = '20' } = req.query;
    const skip = (Number(page) - 1) * Number(limit);
    let where = {};
    if (req.user.role === 'ADMIN') {
        where = {};
    }
    else if (req.user.role === 'CUSTOMER') {
        where = {
            OR: [
                { targetType: 'ALL' },
                { targetType: 'CUSTOMERS' },
                { targetType: 'USER', targetId: req.user.userId },
            ],
        };
    }
    else if (req.user.role === 'BUSINESS') {
        where = {
            OR: [
                { targetType: 'ALL' },
                { targetType: 'BUSINESSES' },
                { createdBy: req.user.userId },
            ],
        };
    }
    else {
        where = { targetType: 'ALL' };
    }
    const [notifications, total] = await Promise.all([
        prisma_1.default.notification.findMany({
            where, skip, take: Number(limit),
            include: { creator: { select: { email: true, name: true, role: true } } },
            orderBy: { createdAt: 'desc' },
        }),
        prisma_1.default.notification.count({ where }),
    ]);
    res.json({ notifications, total });
});
router.delete('/:id', auth_1.requireAuth, async (req, res) => {
    const existing = await prisma_1.default.notification.findUnique({ where: { id: String(req.params.id) } });
    if (!existing) {
        res.status(404).json({ error: 'Notification not found' });
        return;
    }
    const visibleToUser = existing.targetType === 'ALL' ||
        (existing.targetType === 'USER' && existing.targetId === req.user.userId) ||
        (existing.targetType === 'CUSTOMERS' && req.user.role === 'CUSTOMER') ||
        (existing.targetType === 'BUSINESSES' && req.user.role === 'BUSINESS');
    if (req.user.role !== 'ADMIN' && existing.createdBy !== req.user.userId && !visibleToUser) {
        res.status(403).json({ error: 'Not allowed to delete this notification' });
        return;
    }
    await prisma_1.default.notification.delete({ where: { id: existing.id } });
    res.json({ message: 'Notification deleted' });
});
exports.default = router;
//# sourceMappingURL=notifications.js.map