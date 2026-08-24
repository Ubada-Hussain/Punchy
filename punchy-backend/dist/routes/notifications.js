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
    const notification = await prisma_1.default.notification.create({
        data: { ...parsed.data, createdBy: req.user.userId, sentAt: parsed.data.scheduledAt ? undefined : new Date() },
    });
    res.status(201).json(notification);
});
// GET /notifications
router.get('/', auth_1.requireAuth, async (req, res) => {
    const { page = '1', limit = '20' } = req.query;
    const skip = (Number(page) - 1) * Number(limit);
    const where = req.user.role === 'ADMIN' ? {} : { createdBy: req.user.userId };
    const [notifications, total] = await Promise.all([
        prisma_1.default.notification.findMany({
            where, skip, take: Number(limit),
            include: { creator: { select: { email: true, role: true } } },
            orderBy: { createdAt: 'desc' },
        }),
        prisma_1.default.notification.count({ where }),
    ]);
    res.json({ notifications, total });
});
exports.default = router;
//# sourceMappingURL=notifications.js.map