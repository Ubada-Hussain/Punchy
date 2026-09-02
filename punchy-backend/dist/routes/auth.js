"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const uuid_1 = require("uuid");
const crypto_1 = __importDefault(require("crypto"));
const prisma_1 = __importDefault(require("../lib/prisma"));
const jwt_1 = require("../lib/jwt");
const email_1 = require("../lib/email");
const auth_1 = require("../middleware/auth");
const google_auth_library_1 = require("google-auth-library");
const router = (0, express_1.Router)();
const RegisterSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(8),
    role: zod_1.z.enum(['BUSINESS', 'CUSTOMER']),
    name: zod_1.z.string().optional(),
    phone: zod_1.z.string().optional(),
});
const LoginSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string(),
});
const ForgotPasswordSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
});
const ResetPasswordSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    otp: zod_1.z.string().regex(/^\d{6}$/),
    password: zod_1.z.string().min(8),
});
const ProfileUpdateSchema = zod_1.z.object({
    name: zod_1.z.string().min(1).optional(),
    phone: zod_1.z.string().optional(),
});
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const PASSWORD_RESET_TTL_MS = 10 * 60 * 1000;
const PASSWORD_RESET_MAX_ATTEMPTS = 5;
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '919748165158-eg03lb2d2dvbglej5vq3suvl12nfsp6e.apps.googleusercontent.com';
const googleClient = new google_auth_library_1.OAuth2Client(GOOGLE_CLIENT_ID);
async function uniquePublicId() {
    for (;;) {
        const value = String(crypto_1.default.randomInt(100000, 1000000));
        if (!(await prisma_1.default.user.findUnique({ where: { publicId: value } })))
            return value;
    }
}
router.post('/google', async (req, res) => {
    const token = typeof req.body?.idToken === 'string' ? req.body.idToken : '';
    if (!token) {
        res.status(400).json({ error: 'Google ID token is required' });
        return;
    }
    try {
        const ticket = await googleClient.verifyIdToken({ idToken: token, audience: GOOGLE_CLIENT_ID });
        const payload = ticket.getPayload();
        if (!payload?.email || payload.email_verified !== true) {
            res.status(401).json({ error: 'Google account email is not verified' });
            return;
        }
        let user = await prisma_1.default.user.findUnique({ where: { email: payload.email }, include: { businessProfile: true, staffBusiness: true } });
        if (!user) {
            user = await prisma_1.default.user.create({ data: { email: payload.email, publicId: await uniquePublicId(), name: payload.name || payload.email.split('@')[0], passwordHash: await bcryptjs_1.default.hash((0, uuid_1.v4)(), 12), role: 'CUSTOMER' }, include: { businessProfile: true, staffBusiness: true } });
        }
        const isBusinessSuspended = user.role === 'BUSINESS' && user.businessProfile?.status === 'SUSPENDED';
        const isStaffBusinessSuspended = user.role === 'STAFF' && user.staffBusiness?.status === 'SUSPENDED';
        if (user.isBlocked || isBusinessSuspended || isStaffBusinessSuspended) {
            const tokenPayload = { userId: user.id, email: user.email, role: user.role };
            const accessToken = (0, jwt_1.signAccessToken)(tokenPayload);
            const refreshToken = (0, jwt_1.signRefreshToken)(tokenPayload);
            await prisma_1.default.refreshToken.create({ data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) } });
            res.json({ user: { id: user.id, publicId: user.publicId, email: user.email, name: user.name || user.email.split('@')[0], role: user.role, phone: user.phone, isBlocked: user.isBlocked, isSuspended: true, isStaffActive: user.isStaffActive, businessId: user.businessId, businessName: user.staffBusiness?.name ?? user.businessProfile?.name, createdAt: user.createdAt }, accessToken, refreshToken });
            return;
        }
        const tokenPayload = { userId: user.id, email: user.email, role: user.role };
        const accessToken = (0, jwt_1.signAccessToken)(tokenPayload);
        const refreshToken = (0, jwt_1.signRefreshToken)(tokenPayload);
        await prisma_1.default.refreshToken.create({ data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) } });
        res.json({ user: { id: user.id, publicId: user.publicId, email: user.email, name: user.name || user.email.split('@')[0], role: user.role, phone: user.phone, isBlocked: user.isBlocked, isSuspended: false, isStaffActive: user.isStaffActive, businessId: user.businessId, businessName: user.staffBusiness?.name ?? user.businessProfile?.name, createdAt: user.createdAt }, accessToken, refreshToken });
    }
    catch (e) {
        console.error('Google authentication failed:', e);
        res.status(401).json({ error: 'Invalid Google sign-in token' });
    }
});
router.post('/register', async (req, res) => {
    const parsed = RegisterSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const { email, password, role, name, phone } = parsed.data;
    if (await prisma_1.default.user.findUnique({ where: { email } })) {
        res.status(409).json({ error: 'Email already registered' });
        return;
    }
    const passwordHash = await bcryptjs_1.default.hash(password, 12);
    const user = await prisma_1.default.user.create({
        data: { email, publicId: await uniquePublicId(), passwordHash, role, name: name || email.split('@')[0], phone },
        select: { id: true, publicId: true, email: true, name: true, role: true, phone: true, createdAt: true },
    });
    // If new business, automatically create default business profile
    if (user.role === 'BUSINESS') {
        await prisma_1.default.businessProfile.create({
            data: {
                userId: user.id,
                name: name || 'My Business',
                category: 'Cafe & Retail',
                status: 'APPROVED',
            },
        });
    }
    const tokenPayload = { userId: user.id, email: user.email, role: user.role };
    const accessToken = (0, jwt_1.signAccessToken)(tokenPayload);
    const refreshToken = (0, jwt_1.signRefreshToken)(tokenPayload);
    await prisma_1.default.refreshToken.create({
        data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
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
    const user = await prisma_1.default.user.findUnique({
        where: { email },
        include: {
            businessProfile: true,
            staffBusiness: true,
        },
    });
    if (!user || !(await bcryptjs_1.default.compare(password, user.passwordHash))) {
        res.status(401).json({ error: 'Invalid credentials' });
        return;
    }
    const isBusinessSuspended = user.role === 'BUSINESS' && user.businessProfile?.status === 'SUSPENDED';
    const isStaffBusinessSuspended = user.role === 'STAFF' && user.staffBusiness?.status === 'SUSPENDED';
    const isSuspended = user.isBlocked || isBusinessSuspended || isStaffBusinessSuspended;
    if (isSuspended) {
        const tokenPayload = { userId: user.id, email: user.email, role: user.role };
        const accessToken = (0, jwt_1.signAccessToken)(tokenPayload);
        const refreshToken = (0, jwt_1.signRefreshToken)(tokenPayload);
        await prisma_1.default.refreshToken.create({ data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) } });
        res.json({ user: { id: user.id, publicId: user.publicId, email: user.email, name: user.name || user.email.split('@')[0], role: user.role, phone: user.phone, isBlocked: user.isBlocked, isSuspended: true, isStaffActive: user.isStaffActive, businessId: user.businessId, businessName: user.staffBusiness?.name ?? user.businessProfile?.name, createdAt: user.createdAt }, accessToken, refreshToken });
        return;
    }
    const tokenPayload = { userId: user.id, email: user.email, role: user.role };
    const accessToken = (0, jwt_1.signAccessToken)(tokenPayload);
    const refreshToken = (0, jwt_1.signRefreshToken)(tokenPayload);
    await prisma_1.default.refreshToken.create({
        data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
    });
    res.json({
        user: {
            id: user.id,
            email: user.email,
            name: user.name || user.email.split('@')[0],
            role: user.role,
            phone: user.phone,
            isBlocked: user.isBlocked,
            isSuspended: false,
            isStaffActive: user.isStaffActive,
            businessId: user.businessId,
            businessName: user.staffBusiness?.name ?? user.businessProfile?.name,
            createdAt: user.createdAt,
        },
        accessToken,
        refreshToken,
    });
});
router.post('/device-token', auth_1.requireAuth, async (req, res) => {
    const token = typeof req.body?.token === 'string' ? req.body.token.trim() : '';
    if (!token || token.length < 20) {
        res.status(400).json({ error: 'Valid device token is required' });
        return;
    }
    await prisma_1.default.user.update({ where: { id: req.user.userId }, data: { fcmTokens: { push: token } } });
    res.json({ message: 'Device registered for notifications' });
});
router.post('/forgot-password', async (req, res) => {
    const parsed = ForgotPasswordSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const email = parsed.data.email.toLowerCase();
    const user = await prisma_1.default.user.findUnique({ where: { email }, select: { id: true, isBlocked: true } });
    if (!user || user.isBlocked) {
        res.json({ message: 'If that email exists, a password reset code has been sent.' });
        return;
    }
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHash = await bcryptjs_1.default.hash(otp, 12);
    await prisma_1.default.passwordResetOtp.deleteMany({
        where: {
            email,
            expiresAt: { gt: new Date() },
        },
    });
    await prisma_1.default.passwordResetOtp.create({
        data: {
            email,
            otpHash,
            expiresAt: new Date(Date.now() + PASSWORD_RESET_TTL_MS),
        },
    });
    try {
        await (0, email_1.sendOtpEmail)({ to: email, otp, type: 'PASSWORD_RESET' });
        res.json({ message: 'If that email exists, a password reset code has been sent.' });
    }
    catch (error) {
        console.error('Password reset email error:', error);
        // Even if external email fails, we return message to avoid email enumeration, but with clear status if dev
        res.json({ message: 'If that email exists, a password reset code has been sent.' });
    }
});
router.post('/reset-password', async (req, res) => {
    const parsed = ResetPasswordSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const email = parsed.data.email.toLowerCase();
    const reset = await prisma_1.default.passwordResetOtp.findFirst({
        where: {
            email,
            expiresAt: { gt: new Date() },
        },
        orderBy: { createdAt: 'desc' },
    });
    if (!reset || reset.consumedAt != null || reset.attempts >= PASSWORD_RESET_MAX_ATTEMPTS) {
        res.status(400).json({ error: 'Invalid or expired reset code.' });
        return;
    }
    const isValid = await bcryptjs_1.default.compare(parsed.data.otp, reset.otpHash);
    if (!isValid) {
        await prisma_1.default.passwordResetOtp.update({
            where: { id: reset.id },
            data: { attempts: { increment: 1 } },
        });
        res.status(400).json({ error: 'Invalid or expired reset code.' });
        return;
    }
    const user = await prisma_1.default.user.findUnique({ where: { email }, select: { id: true, isBlocked: true } });
    if (!user || user.isBlocked) {
        res.status(400).json({ error: 'Invalid or expired reset code.' });
        return;
    }
    await prisma_1.default.$transaction([
        prisma_1.default.user.update({
            where: { id: user.id },
            data: { passwordHash: await bcryptjs_1.default.hash(parsed.data.password, 12) },
        }),
        prisma_1.default.passwordResetOtp.update({
            where: { id: reset.id },
            data: { consumedAt: new Date() },
        }),
        prisma_1.default.refreshToken.deleteMany({ where: { userId: user.id } }),
    ]);
    res.json({ message: 'Password reset successfully.' });
});
router.get('/me', auth_1.requireAuth, async (req, res) => {
    const user = await prisma_1.default.user.findUnique({
        where: { id: req.user.userId },
        select: {
            id: true,
            publicId: true,
            email: true,
            name: true,
            role: true,
            phone: true,
            isBlocked: true,
            isStaffActive: true,
            businessId: true,
            createdAt: true,
            businessProfile: true,
            staffBusiness: {
                select: { id: true, name: true, logo: true, category: true, status: true },
            },
            _count: {
                select: { customerCards: true },
            },
        },
    });
    if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
    }
    const isBusinessSuspended = user.role === 'BUSINESS' && user.businessProfile?.status === 'SUSPENDED';
    const isStaffBusinessSuspended = user.role === 'STAFF' && user.staffBusiness?.status === 'SUSPENDED';
    const isSuspended = user.isBlocked || isBusinessSuspended || isStaffBusinessSuspended;
    res.json({
        user: {
            ...user,
            isSuspended,
            businessName: user.staffBusiness?.name ?? user.businessProfile?.name,
        },
    });
});
router.put('/profile', auth_1.requireAuth, async (req, res) => {
    const parsed = ProfileUpdateSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ error: parsed.error.flatten() });
        return;
    }
    const { name, phone } = parsed.data;
    const updatedUser = await prisma_1.default.user.update({
        where: { id: req.user.userId },
        data: {
            ...(name ? { name } : {}),
            ...(phone !== undefined ? { phone } : {}),
        },
        select: { id: true, publicId: true, email: true, name: true, role: true, phone: true, createdAt: true },
    });
    // Also update business profile name if business role
    if (name && updatedUser.role === 'BUSINESS') {
        await prisma_1.default.businessProfile.updateMany({
            where: { userId: updatedUser.id },
            data: { name },
        });
    }
    res.json({ message: 'Profile updated successfully', user: updatedUser });
});
router.delete('/account', auth_1.requireAuth, async (req, res) => {
    const userId = req.user.userId;
    const user = await prisma_1.default.user.findUnique({ where: { id: userId }, select: { role: true } });
    if (!user || user.role === 'ADMIN') {
        res.status(404).json({ error: 'Account not found' });
        return;
    }
    await prisma_1.default.$transaction(async (tx) => {
        await tx.notification.deleteMany({ where: { createdBy: userId } });
        await tx.supportTicket.deleteMany({ where: { authorId: userId } });
        await tx.activityLog.deleteMany({ where: { userId } });
        if (user.role === 'BUSINESS') {
            const profile = await tx.businessProfile.findUnique({ where: { userId }, select: { id: true } });
            if (profile) {
                const cards = await tx.loyaltyCard.findMany({ where: { businessId: profile.id }, select: { id: true } });
                const cardIds = cards.map((card) => card.id);
                const customerCards = await tx.customerCard.findMany({ where: { cardId: { in: cardIds } }, select: { id: true } });
                const customerCardIds = customerCards.map((card) => card.id);
                if (customerCardIds.length) {
                    await tx.punchTransaction.deleteMany({ where: { customerCardId: { in: customerCardIds } } });
                    await tx.redemption.deleteMany({ where: { customerCardId: { in: customerCardIds } } });
                    await tx.customerCard.deleteMany({ where: { id: { in: customerCardIds } } });
                }
                if (cardIds.length) {
                    await tx.punchMethod.deleteMany({ where: { cardId: { in: cardIds } } });
                    await tx.loyaltyCard.deleteMany({ where: { id: { in: cardIds } } });
                }
                await tx.user.deleteMany({ where: { businessId: profile.id } });
                await tx.businessProfile.delete({ where: { id: profile.id } });
            }
        }
        else {
            const customerCards = await tx.customerCard.findMany({ where: { customerId: userId }, select: { id: true } });
            const customerCardIds = customerCards.map((card) => card.id);
            if (customerCardIds.length) {
                await tx.punchTransaction.deleteMany({ where: { customerCardId: { in: customerCardIds } } });
                await tx.redemption.deleteMany({ where: { customerCardId: { in: customerCardIds } } });
                await tx.customerCard.deleteMany({ where: { id: { in: customerCardIds } } });
            }
        }
        await tx.user.delete({ where: { id: userId } });
    });
    res.json({ message: 'Account deleted successfully' });
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
        data: { token: newRefresh, userId: payload.userId, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
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