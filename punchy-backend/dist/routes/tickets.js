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
const TicketSchema = zod_1.z.object({
    subject: zod_1.z.string().min(5),
    body: zod_1.z.string().min(10),
});
// POST /tickets
router.post('/', auth_1.requireAuthAllowSuspended, async (req, res) => {
    const parsed = TicketSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const ticket = await prisma_1.default.supportTicket.create({
        data: { authorId: req.user.userId, ...parsed.data },
    });
    res.status(201).json(ticket);
});
// GET /tickets — admin sees all, others see their own
router.get('/', auth_1.requireAuth, async (req, res) => {
    const { status, page = '1', limit = '20' } = req.query;
    const skip = (Number(page) - 1) * Number(limit);
    const where = req.user.role === 'ADMIN' ? {} : { authorId: req.user.userId };
    if (status)
        where.status = status;
    const [tickets, total] = await Promise.all([
        prisma_1.default.supportTicket.findMany({
            where, skip, take: Number(limit),
            include: { author: { select: { email: true, role: true } } },
            orderBy: { createdAt: 'desc' },
        }),
        prisma_1.default.supportTicket.count({ where }),
    ]);
    res.json({ tickets, total });
});
// GET /tickets/:id
router.get('/:id', auth_1.requireAuth, async (req, res) => {
    const ticket = await prisma_1.default.supportTicket.findUnique({
        where: { id: String(req.params.id) },
        include: { author: { select: { email: true, role: true } }, resolver: { select: { email: true } } },
    });
    if (!ticket) {
        res.status(404).json({ error: 'Ticket not found' });
        return;
    }
    if (req.user.role !== 'ADMIN' && ticket.authorId !== req.user.userId) {
        res.status(403).json({ error: 'Forbidden' });
        return;
    }
    res.json(ticket);
});
// PATCH /tickets/:id — admin resolves/updates
router.patch('/:id', auth_1.requireAuth, (0, auth_1.requireRole)('ADMIN'), async (req, res) => {
    const { status } = req.body;
    if (!['OPEN', 'IN_PROGRESS', 'RESOLVED'].includes(status)) {
        res.status(400).json({ error: 'Invalid status' });
        return;
    }
    const updated = await prisma_1.default.supportTicket.update({
        where: { id: String(req.params.id) },
        data: {
            status,
            resolvedBy: status === 'RESOLVED' ? req.user.userId : undefined,
            resolvedAt: status === 'RESOLVED' ? new Date() : undefined,
        },
    });
    res.json(updated);
});
exports.default = router;
//# sourceMappingURL=tickets.js.map