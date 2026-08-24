"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const uuid_1 = require("uuid");
const prisma_1 = __importDefault(require("../lib/prisma"));
const jwt_1 = require("../lib/jwt");
const router = (0, express_1.Router)();
const RegisterSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(8),
    role: zod_1.z.enum(['BUSINESS', 'CUSTOMER']),
    phone: zod_1.z.string().optional(),
});
const LoginSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string(),
});
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;
router.post('/register', async (req, res) => {
    const parsed = RegisterSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const { email, password, role, phone } = parsed.data;
    if (await prisma_1.default.user.findUnique({ where: { email } })) {
        res.status(409).json({ error: 'Email already registered' });
        return;
    }
    const passwordHash = await bcryptjs_1.default.hash(password, 12);
    const user = await prisma_1.default.user.create({
        data: { email, passwordHash, role, phone },
        select: { id: true, email: true, role: true, createdAt: true },
    });
    const tokenPayload = { userId: user.id, email: user.email, role: user.role };
    const accessToken = (0, jwt_1.signAccessToken)(tokenPayload);
    const refreshToken = (0, jwt_1.signRefreshToken)(tokenPayload);
    await prisma_1.default.refreshToken.create({
        data: { id: (0, uuid_1.v4)(), token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
    });
    res.status(201).json({ user, accessToken, refreshToken });
});
router.post('/login', async (req, res) => {
    const parsed = LoginSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const { email, password } = parsed.data;
    const user = await prisma_1.default.user.findUnique({ where: { email } });
    if (!user || !(await bcryptjs_1.default.compare(password, user.passwordHash))) {
        res.status(401).json({ error: 'Invalid credentials' });
        return;
    }
    if (user.isBlocked) {
        res.status(403).json({ error: 'Account is blocked' });
        return;
    }
    const tokenPayload = { userId: user.id, email: user.email, role: user.role };
    const accessToken = (0, jwt_1.signAccessToken)(tokenPayload);
    const refreshToken = (0, jwt_1.signRefreshToken)(tokenPayload);
    await prisma_1.default.refreshToken.create({
        data: { id: (0, uuid_1.v4)(), token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
    });
    res.json({ user: { id: user.id, email: user.email, role: user.role }, accessToken, refreshToken });
});
router.post('/refresh', async (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken) {
        res.status(400).json({ error: 'Missing refreshToken' });
        return;
    }
    let payload;
    try {
        payload = (0, jwt_1.verifyRefreshToken)(refreshToken);
    }
    catch {
        res.status(401).json({ error: 'Invalid refresh token' });
        return;
    }
    const stored = await prisma_1.default.refreshToken.findUnique({ where: { token: refreshToken } });
    if (!stored || stored.expiresAt < new Date()) {
        res.status(401).json({ error: 'Refresh token expired' });
        return;
    }
    // Rotate
    await prisma_1.default.refreshToken.delete({ where: { token: refreshToken } });
    const tokenPayload = { userId: payload.userId, email: payload.email, role: payload.role };
    const newAccess = (0, jwt_1.signAccessToken)(tokenPayload);
    const newRefresh = (0, jwt_1.signRefreshToken)(tokenPayload);
    await prisma_1.default.refreshToken.create({
        data: { id: (0, uuid_1.v4)(), token: newRefresh, userId: payload.userId, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
    });
    res.json({ accessToken: newAccess, refreshToken: newRefresh });
});
router.post('/logout', async (req, res) => {
    const { refreshToken } = req.body;
    if (refreshToken)
        await prisma_1.default.refreshToken.deleteMany({ where: { token: refreshToken } });
    res.json({ message: 'Logged out' });
});
exports.default = router;
//# sourceMappingURL=auth.js.map