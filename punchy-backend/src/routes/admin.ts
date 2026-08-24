import { Router, Request, Response } from 'express';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';

const router = Router();

// GET /admin/users — all users
router.get('/users', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const { role, search, page = '1', limit = '20' } = req.query;
  const skip = (Number(page) - 1) * Number(limit);
  const where: Record<string, unknown> = {};
  if (role) where.role = role;
  if (search) where.email = { contains: String(search), mode: 'insensitive' };

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where, skip, take: Number(limit),
      select: { id: true, email: true, phone: true, role: true, isBlocked: true, createdAt: true, businessProfile: { select: { name: true, status: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.user.count({ where }),
  ]);
  res.json({ users, total });
});

// GET /admin/users/:id — detail with activity
router.get('/users/:id', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const user = await prisma.user.findUnique({
    where: { id: String(req.params.id) },
    select: {
      id: true, email: true, phone: true, role: true, isBlocked: true, createdAt: true,
      businessProfile: true,
      customerCards: { include: { card: { include: { business: { select: { name: true } } } } } },
      activityLogs: { orderBy: { createdAt: 'desc' }, take: 30 },
    },
  });
  if (!user) { res.status(404).json({ error: 'User not found' }); return; }
  res.json(user);
});

// POST /admin/users/:id/block
router.post('/users/:id/block', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  res.json(await prisma.user.update({ where: { id: String(req.params.id) }, data: { isBlocked: true } }));
});

// POST /admin/users/:id/unblock
router.post('/users/:id/unblock', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  res.json(await prisma.user.update({ where: { id: String(req.params.id) }, data: { isBlocked: false } }));
});

// GET /admin/config
router.get('/config', requireAuth, requireRole('ADMIN'), async (_req: Request, res: Response): Promise<void> => {
  const config = await prisma.adminConfig.findMany();
  res.json(Object.fromEntries(config.map(c => [c.key, c.value])));
});

// PUT /admin/config/:key
router.put('/config/:key', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const { value } = req.body;
  if (value === undefined) { res.status(400).json({ error: 'Missing value' }); return; }

  const key = String(req.params.key);
  const config = await prisma.adminConfig.upsert({
    where: { key },
    update: { value, updatedBy: req.user!.userId },
    create: { key, value, updatedBy: req.user!.userId },
  });
  res.json(config);
});

export default router;
