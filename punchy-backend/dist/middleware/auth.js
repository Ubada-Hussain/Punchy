"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAuth = requireAuth;
exports.requireAuthAllowSuspended = requireAuthAllowSuspended;
exports.requireRole = requireRole;
const jwt_1 = require("../lib/jwt");
const prisma_1 = __importDefault(require("../lib/prisma"));
async function requireAuth(req, res, next) {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Missing or invalid Authorization header' });
        return;
    }
    try {
        const payload = (0, jwt_1.verifyAccessToken)(header.slice(7));
        const user = await prisma_1.default.user.findUnique({ where: { id: payload.userId }, select: { isBlocked: true, role: true, businessProfile: { select: { status: true } }, staffBusiness: { select: { status: true } } } });
        const businessSuspended = user?.role === 'BUSINESS' && user.businessProfile?.status === 'SUSPENDED';
        const staffBusinessSuspended = user?.role === 'STAFF' && user.staffBusiness?.status === 'SUSPENDED';
        if (!user || user.isBlocked || businessSuspended || staffBusinessSuspended) {
            res.status(403).json({ error: 'Account is suspended', isSuspended: true });
            return;
        }
        req.user = payload;
        next();
    }
    catch {
        res.status(401).json({ error: 'Invalid or expired token' });
    }
}
// Used only for support contact: suspended users may still submit an appeal.
async function requireAuthAllowSuspended(req, res, next) {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Missing or invalid Authorization header' });
        return;
    }
    try {
        req.user = (0, jwt_1.verifyAccessToken)(header.slice(7));
        const user = await prisma_1.default.user.findUnique({ where: { id: req.user.userId }, select: { id: true } });
        if (!user) {
            res.status(401).json({ error: 'User not found' });
            return;
        }
        next();
    }
    catch {
        res.status(401).json({ error: 'Invalid or expired token' });
    }
}
function requireRole(...roles) {
    return (req, res, next) => {
        if (!req.user || !roles.includes(req.user.role)) {
            res.status(403).json({ error: `Requires role: ${roles.join(' or ')}` });
            return;
        }
        next();
    };
}
//# sourceMappingURL=auth.js.map