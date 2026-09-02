import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken, JwtPayload } from '../lib/jwt';
import prisma from '../lib/prisma';

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export async function requireAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }
  try {
    const payload = verifyAccessToken(header.slice(7));
    const user = await prisma.user.findUnique({ where: { id: payload.userId }, select: { isBlocked: true, role: true, businessProfile: { select: { status: true } }, staffBusiness: { select: { status: true } } } });
    const businessSuspended = user?.role === 'BUSINESS' && user.businessProfile?.status === 'SUSPENDED';
    const staffBusinessSuspended = user?.role === 'STAFF' && user.staffBusiness?.status === 'SUSPENDED';
    if (!user || user.isBlocked || businessSuspended || staffBusinessSuspended) {
      res.status(403).json({ error: 'Account is suspended', isSuspended: true });
      return;
    }
    req.user = payload;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// Used only for support contact: suspended users may still submit an appeal.
export async function requireAuthAllowSuspended(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) { res.status(401).json({ error: 'Missing or invalid Authorization header' }); return; }
  try {
    req.user = verifyAccessToken(header.slice(7));
    const user = await prisma.user.findUnique({ where: { id: req.user.userId }, select: { id: true } });
    if (!user) { res.status(401).json({ error: 'User not found' }); return; }
    next();
  } catch { res.status(401).json({ error: 'Invalid or expired token' }); }
}

export function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user || !roles.includes(req.user.role)) {
      res.status(403).json({ error: `Requires role: ${roles.join(' or ')}` });
      return;
    }
    next();
  };
}
