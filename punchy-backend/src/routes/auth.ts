import { Router, Request, Response } from 'express';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { v4 as uuid } from 'uuid';
import prisma from '../lib/prisma';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../lib/jwt';

const router = Router();

const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  role: z.enum(['BUSINESS', 'CUSTOMER']),
  phone: z.string().optional(),
});

const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;

router.post('/register', async (req: Request, res: Response): Promise<void> => {
  const parsed = RegisterSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const { email, password, role, phone } = parsed.data;
  if (await prisma.user.findUnique({ where: { email } })) {
    res.status(409).json({ error: 'Email already registered' }); return;
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({
    data: { email, passwordHash, role, phone },
    select: { id: true, email: true, role: true, createdAt: true },
  });

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
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    res.status(401).json({ error: 'Invalid credentials' }); return;
  }
  if (user.isBlocked) { res.status(403).json({ error: 'Account is blocked' }); return; }

  const tokenPayload = { userId: user.id, email: user.email, role: user.role };
  const accessToken = signAccessToken(tokenPayload);
  const refreshToken = signRefreshToken(tokenPayload);
  await prisma.refreshToken.create({
    data: { token: refreshToken, userId: user.id, expiresAt: new Date(Date.now() + REFRESH_TTL_MS) },
  });

  res.json({ user: { id: user.id, email: user.email, role: user.role }, accessToken, refreshToken });
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
