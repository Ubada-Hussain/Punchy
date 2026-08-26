import { Router, Request, Response } from 'express';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { v4 as uuid } from 'uuid';
import prisma from '../lib/prisma';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../lib/jwt';
import { requireAuth } from '../middleware/auth';

const router = Router();

const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  role: z.enum(['BUSINESS', 'CUSTOMER']),
  name: z.string().optional(),
  phone: z.string().optional(),
});

const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

const ProfileUpdateSchema = z.object({
  name: z.string().min(1).optional(),
  phone: z.string().optional(),
});

const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;

router.post('/register', async (req: Request, res: Response): Promise<void> => {
  const parsed = RegisterSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const { email, password, role, name, phone } = parsed.data;
  if (await prisma.user.findUnique({ where: { email } })) {
    res.status(409).json({ error: 'Email already registered' }); return;
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({
    data: { email, passwordHash, role, name: name || email.split('@')[0], phone },
    select: { id: true, email: true, name: true, role: true, phone: true, createdAt: true },
  });

  // If new business, automatically create default business profile
  if (user.role === 'BUSINESS') {
    await prisma.businessProfile.create({
      data: {
        userId: user.id,
        name: name || 'My Business',
        category: 'Cafe & Retail',
        status: 'APPROVED',
      },
    });
  }

  const tokenPayload = { userId: user.id, email: user.email, role: user.role };
  const accessToken = signAccessToken(tokenPayload);
  const refreshToken = signRefreshToken(tokenPayload);
  await prisma.refreshToken.create({
    data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
  });

  res.status(201).json({ user, accessToken, refreshToken });
});

router.post('/login', async (req: Request, res: Response): Promise<void> => {
  const parsed = LoginSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const { email, password } = parsed.data;
  const user = await prisma.user.findUnique({
    where: { email },
    include: {
      businessProfile: true,
      staffBusiness: true,
    },
  });

  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    res.status(401).json({ error: 'Invalid credentials' }); return;
  }

  const isBusinessSuspended = user.role === 'BUSINESS' && user.businessProfile?.status === 'SUSPENDED';
  const isStaffBusinessSuspended = user.role === 'STAFF' && user.staffBusiness?.status === 'SUSPENDED';
  const isSuspended = user.isBlocked || isBusinessSuspended || isStaffBusinessSuspended;

  if (isSuspended) {
    res.status(403).json({
      error: 'Account has been suspended.',
      isSuspended: true,
      isBlocked: user.isBlocked,
      role: user.role,
    });
    return;
  }

  const tokenPayload = { userId: user.id, email: user.email, role: user.role };
  const accessToken = signAccessToken(tokenPayload);
  const refreshToken = signRefreshToken(tokenPayload);
  await prisma.refreshToken.create({
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

router.get('/me', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.userId },
    select: {
      id: true,
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

router.put('/profile', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parsed = ProfileUpdateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const { name, phone } = parsed.data;
  const updatedUser = await prisma.user.update({
    where: { id: req.user!.userId },
    data: {
      ...(name ? { name } : {}),
      ...(phone !== undefined ? { phone } : {}),
    },
    select: { id: true, email: true, name: true, role: true, phone: true, createdAt: true },
  });

  // Also update business profile name if business role
  if (name && updatedUser.role === 'BUSINESS') {
    await prisma.businessProfile.updateMany({
      where: { userId: updatedUser.id },
      data: { name },
    });
  }

  res.json({ message: 'Profile updated successfully', user: updatedUser });
});

router.post('/refresh', async (req: Request, res: Response): Promise<void> => {
  const { refreshToken } = req.body;
  if (!refreshToken) { res.status(400).json({ error: 'Missing refreshToken' }); return; }

  let payload;
  try { payload = verifyRefreshToken(refreshToken); }
  catch { res.status(401).json({ error: 'Invalid refresh token' }); return; }

  const stored = await prisma.refreshToken.findUnique({ where: { token: refreshToken } });
  if (!stored || stored.expiresAt < new Date()) {
    res.status(401).json({ error: 'Refresh token expired' }); return;
  }

  // Rotate
  await prisma.refreshToken.delete({ where: { token: refreshToken } });
  const tokenPayload = { userId: payload.userId, email: payload.email, role: payload.role };
  const newAccess = signAccessToken(tokenPayload);
  const newRefresh = signRefreshToken(tokenPayload);
  await prisma.refreshToken.create({
    data: { token: newRefresh, userId: payload.userId, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
  });

  res.json({ accessToken: newAccess, refreshToken: newRefresh });
});

router.post('/clerk', async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, name, role = 'CUSTOMER', provider } = req.body;
    if (!email) {
      res.status(400).json({ error: 'Email is required from Clerk' });
      return;
    }

    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      const dummyPassword = await bcrypt.hash(`Clerk_OAuth_${Date.now()}_${Math.random()}`, 12);
      user = await prisma.user.create({
        data: {
          email,
          passwordHash: dummyPassword,
          role: (role === 'BUSINESS' ? 'BUSINESS' : 'CUSTOMER'),
        },
      });

      // If new customer, optionally link demo cards
      if (user.role === 'CUSTOMER') {
        const demoCards = await prisma.loyaltyCard.findMany({ take: 3 });
        for (const c of demoCards) {
          await prisma.customerCard.create({
            data: {
              customerId: user.id,
              cardId: c.id,
              punchCount: Math.floor(Math.random() * 4) + 2,
            },
          });
        }
      }
    }

    if (user.isBlocked) {
      res.status(403).json({ error: 'Account is blocked' });
      return;
    }

    const tokenPayload = { userId: user.id, email: user.email, role: user.role };
    const accessToken = signAccessToken(tokenPayload);
    const refreshToken = signRefreshToken(tokenPayload);
    await prisma.refreshToken.create({
      data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
    });

    res.json({
      user: { id: user.id, email: user.email, role: user.role, name: name || user.email.split('@')[0] },
      accessToken,
      refreshToken,
      provider: provider || 'clerk',
    });
  } catch (error) {
    console.error('Clerk Auth error:', error);
    res.status(500).json({ error: 'Failed to authenticate with Clerk' });
  }
});

router.post('/logout', async (req: Request, res: Response): Promise<void> => {
  const { refreshToken } = req.body;
  if (refreshToken) await prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
  res.json({ message: 'Logged out' });
});

export default router;
