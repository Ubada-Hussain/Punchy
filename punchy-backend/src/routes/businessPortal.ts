import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import bcrypt from 'bcryptjs';
import multer from 'multer';
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { sendNotification } from '../lib/notifications';
import { notifyPunchEarned, notifyProgressMilestone } from '../lib/automatedNotifications';
import { currencyForCountry, geocodeAddress, normalizeBusinessPhone } from '../lib/international';

const router = Router();
const logoUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => cb(null, file.mimetype.startsWith('image/')),
});

// Business Onboarding Schema
const SetupSchema = z.object({
  name: z.string().min(2),
  category: z.string().min(2),
  description: z.string().optional(),
  website: z.string().optional(),
  logo: z.string().optional(),
  address: z.string().optional(),
  phone: z.string().min(1),
  enableQR: z.boolean().default(true),
  enableNFC: z.boolean().default(true),
});

// Card Create/Edit Schema
const CardSchema = z.object({
  title: z.string().min(2),
  punchesRequired: z.number().min(2).max(20).default(10),
  rewardDescription: z.string().min(2),
  visualStyle: z.record(z.string(), z.any()).default({}),
  validUntil: z.string().nullable().optional(),
  pricePerPunch: z.number().min(0).optional().default(0),
  currency: z.string().min(1).max(10).optional(),
  isActive: z.boolean().optional(),
  enableQR: z.boolean().default(true),
  enableNFC: z.boolean().default(true),
});

// Staff Create Schema
const CreateStaffSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(6),
  phone: z.string().optional(),
});

function calculateTrend(curr7: number, prev7: number) {
  if (prev7 === 0) {
    if (curr7 > 0) return { pct: 100, isPositive: true, label: '+100%' };
    return { pct: 0, isPositive: true, label: '+0%' };
  }
  const diff = curr7 - prev7;
  const pct = Math.round((diff / prev7) * 100);
  return {
    pct: Math.abs(pct),
    isPositive: pct >= 0,
    label: `${pct >= 0 ? '+' : '-'}${Math.abs(pct)}%`,
  };
}

/**
 * GET /business/dashboard
 * Return total customers, punches, rewards, real 7-day stats, card preview, unified recent activity
 */
router.get('/dashboard', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  try {
    let business = await prisma.businessProfile.findUnique({
      where: { userId: req.user!.userId },
      include: {
        loyaltyCards: {
          include: {
            punchMethods: true,
            _count: { select: { customerCards: true } },
          },
        },
      },
    });

    // Auto-create default business profile if not yet created
    if (!business) {
      business = await prisma.businessProfile.create({
        data: {
          userId: req.user!.userId,
          name: 'My Business',
          category: 'Retail',
          status: 'PENDING',
          locations: [],
        },
        include: {
          loyaltyCards: {
            include: {
              punchMethods: true,
              _count: { select: { customerCards: true } },
            },
          },
        },
      });
    }

    const cardIds = business.loyaltyCards.map(c => c.id);

    const customerCardIds = (
      await prisma.customerCard.findMany({
        where: { cardId: { in: cardIds } },
        select: { id: true },
      })
    ).map(c => c.id);

    const now = new Date();
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const sevenDaysAgo = new Date(now.getTime() - 7 * 86_400_000);
    const fourteenDaysAgo = new Date(now.getTime() - 14 * 86_400_000);

    const [
      totalCustomers,
      customersLast7,
      customersPrev7,
      totalPunches,
      punchesLast7,
      punchesPrev7,
      punchesToday,
      totalRewards,
      rewardsLast7,
      rewardsPrev7,
      unreadNotificationsCount,
    ] = await Promise.all([
      prisma.customerCard.count({ where: { cardId: { in: cardIds } } }),
      prisma.customerCard.count({ where: { cardId: { in: cardIds }, joinedAt: { gte: sevenDaysAgo } } }),
      prisma.customerCard.count({ where: { cardId: { in: cardIds }, joinedAt: { gte: fourteenDaysAgo, lt: sevenDaysAgo } } }),

      prisma.punchTransaction.count({ where: { customerCardId: { in: customerCardIds } } }),
      prisma.punchTransaction.count({ where: { customerCardId: { in: customerCardIds }, timestamp: { gte: sevenDaysAgo } } }),
      prisma.punchTransaction.count({ where: { customerCardId: { in: customerCardIds }, timestamp: { gte: fourteenDaysAgo, lt: sevenDaysAgo } } }),
      prisma.punchTransaction.count({ where: { customerCardId: { in: customerCardIds }, timestamp: { gte: startOfDay } } }),

      prisma.redemption.count({ where: { customerCardId: { in: customerCardIds } } }),
      prisma.redemption.count({ where: { customerCardId: { in: customerCardIds }, redeemedAt: { gte: sevenDaysAgo } } }),
      prisma.redemption.count({ where: { customerCardId: { in: customerCardIds }, redeemedAt: { gte: fourteenDaysAgo, lt: sevenDaysAgo } } }),

      prisma.notification.count({
        where: {
          OR: [
            { targetType: 'ALL' },
            { targetType: 'BUSINESSES' },
            { targetType: 'USER', targetId: req.user!.userId },
          ],
        },
      }),
    ]);

    const customersTrend = calculateTrend(customersLast7, customersPrev7);
    const punchesTrend = calculateTrend(punchesLast7, punchesPrev7);
    const rewardsTrend = calculateTrend(rewardsLast7, rewardsPrev7);

    // Query unified recent events: Punches, Redemptions, Joins
    const [recentPunches, recentRedemptions, recentJoins] = await Promise.all([
      prisma.punchTransaction.findMany({
        where: { customerCardId: { in: customerCardIds } },
        include: {
          customerCard: {
            include: {
              customer: { select: { id: true, name: true, email: true } },
              card: { select: { title: true } },
            },
          },
        },
        orderBy: { timestamp: 'desc' },
        take: 10,
      }),
      prisma.redemption.findMany({
        where: { customerCardId: { in: customerCardIds } },
        include: {
          customerCard: {
            include: {
              customer: { select: { id: true, name: true, email: true } },
              card: { select: { title: true, punchesRequired: true, rewardDescription: true } },
            },
          },
        },
        orderBy: { redeemedAt: 'desc' },
        take: 10,
      }),
      prisma.customerCard.findMany({
        where: { cardId: { in: cardIds } },
        include: {
          customer: { select: { id: true, name: true, email: true } },
          card: { select: { title: true } },
        },
        orderBy: { joinedAt: 'desc' },
        take: 10,
      }),
    ]);

    interface ActivityItem {
      id: string;
      type: 'PUNCH' | 'REDEMPTION' | 'JOIN';
      customerName: string;
      customerEmail: string;
      action: string;
      cardTitle: string;
      timestamp: Date;
      resultBadge: string;
      badgeColor: 'green' | 'red' | 'teal';
    }

    const activityList: ActivityItem[] = [
      ...recentPunches.map(p => ({
        id: p.id,
        type: 'PUNCH' as const,
        customerName: p.customerCard.customer.name || p.customerCard.customer.email.split('@')[0],
        customerEmail: p.customerCard.customer.email,
        action: 'Earned 1 punch',
        cardTitle: p.customerCard.card.title,
        timestamp: p.timestamp,
        resultBadge: '+1 punch',
        badgeColor: 'green' as const,
      })),
      ...recentRedemptions.map(r => ({
        id: r.id,
        type: 'REDEMPTION' as const,
        customerName: r.customerCard.customer.name || r.customerCard.customer.email.split('@')[0],
        customerEmail: r.customerCard.customer.email,
        action: `Redeemed reward (${r.customerCard.card.rewardDescription || 'Free Reward'})`,
        cardTitle: r.customerCard.card.title,
        timestamp: r.redeemedAt,
        resultBadge: `-${r.customerCard.card.punchesRequired} punches`,
        badgeColor: 'red' as const,
      })),
      ...recentJoins.map(j => ({
        id: j.id,
        type: 'JOIN' as const,
        customerName: j.customer.name || j.customer.email.split('@')[0],
        customerEmail: j.customer.email,
        action: 'Joined loyalty card',
        cardTitle: j.card.title,
        timestamp: j.joinedAt,
        resultBadge: '+0 punch',
        badgeColor: 'teal' as const,
      })),
    ].sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime()).slice(0, 15);

    let address = '';
    if (business.locations && Array.isArray(business.locations) && business.locations.length > 0) {
      const loc = business.locations[0] as any;
      if (loc && loc.address) address = loc.address;
    }

    res.json({
      business: {
        id: business.id,
        name: business.name,
        category: business.category,
        logo: business.logo,
        status: business.status,
        address,
      },
      hasUnreadNotifications: unreadNotificationsCount > 0,
      stats: {
        totalCustomers,
        customersChangePct: customersTrend.label,
        customersIsPositive: customersTrend.isPositive,

        totalPunches,
        punchesChangePct: punchesTrend.label,
        punchesIsPositive: punchesTrend.isPositive,
        punchesToday,

        totalRewardsGiven: totalRewards,
        rewardsChangePct: rewardsTrend.label,
        rewardsIsPositive: rewardsTrend.isPositive,
        rewardsRedeemed: totalRewards,
      },
      cards: business.loyaltyCards,
      recentActivity: activityList,
    });
  } catch (error) {
    console.error('Business Dashboard error:', error);
    res.status(500).json({ error: 'Failed to load business dashboard' });
  }
});

/**
 * GET /business/profile
 * Get business profile, owner details, card counts, and member since date
 */
router.get('/profile', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  try {
    let business = await prisma.businessProfile.findUnique({
      where: { userId: req.user!.userId },
      include: {
        loyaltyCards: true,
        user: { select: { email: true, name: true, phone: true, createdAt: true } },
      },
    });

    if (!business) {
      const user = await prisma.user.findUnique({
        where: { id: req.user!.userId },
        select: { name: true, countryCode: true },
      });
      const countryCode = user?.countryCode?.toUpperCase() || 'PK';
      business = await prisma.businessProfile.create({
        data: {
          userId: req.user!.userId,
          name: user?.name || 'My Business',
          category: 'Retail & Services',
          status: 'APPROVED',
          countryCode,
          currencyCode: currencyForCountry(countryCode),
        },
        include: {
          loyaltyCards: true,
          user: { select: { email: true, name: true, phone: true, createdAt: true } },
        },
      });
    }

    const cardIds = business.loyaltyCards.map(c => c.id);
    const totalCustomers = await prisma.customerCard.count({
      where: { cardId: { in: cardIds } },
    });

    res.json({
      business,
      activeCardsCount: business.loyaltyCards.length,
      totalCustomers,
      memberSince: business.user.createdAt,
    });
  } catch (error) {
    console.error('Business Profile error:', error);
    res.status(500).json({ error: 'Failed to load business profile' });
  }
});

/**
 * POST /business/setup
 * Self-serve onboarding / setup
 */
router.post('/setup', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const parsed = SetupSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const { name, category, description, website, logo, address, phone } = parsed.data;
  // The country is selected once at signup. It is deliberately read from the
  // owner account here so setup requests can never alter it.
  const owner = await prisma.user.findUnique({
    where: { id: req.user!.userId },
    select: { countryCode: true },
  });
  const countryCode = owner?.countryCode?.toUpperCase() || 'PK';
  const normalizedPhone = normalizeBusinessPhone(phone, countryCode);
  if (!normalizedPhone) { res.status(400).json({ error: 'Enter a valid phone number for the selected country.' }); return; }
  const geocoded = address ? await geocodeAddress(address) : null;
  const currencyCode = currencyForCountry(countryCode);

  if (phone) {
    await prisma.user.update({
      where: { id: req.user!.userId },
      data: { phone: normalizedPhone },
    });
  }

  const business = await prisma.businessProfile.upsert({
    where: { userId: req.user!.userId },
    update: {
      name,
      category,
      description,
      website,
      logo,
      locations: address ? [{ address }] : [],
      ...(geocoded ? { location: geocoded.point } : {}),
      countryCode,
      currencyCode,
      status: 'APPROVED',
    },
    create: {
      userId: req.user!.userId,
      name,
      category,
      description,
      website,
      logo,
      locations: address ? [{ address }] : [],
      ...(geocoded ? { location: geocoded.point } : {}),
      countryCode,
      currencyCode,
      status: 'APPROVED',
    },
  });

  res.json({ message: 'Business setup complete! 🎉', business });
});

/** Upload a lightweight business logo; only its public URL is stored in MongoDB. */
router.post('/logo', requireAuth, requireRole('BUSINESS'), logoUpload.single('logo'), async (req: Request, res: Response): Promise<void> => {
  const file = req.file;
  if (!file) { res.status(400).json({ error: 'Please select a valid image file.' }); return; }
  try {
    const image = sharp(file.buffer, { failOn: 'error' });
    const metadata = await image.metadata();
    if (!metadata.width || !metadata.height || metadata.width < 32 || metadata.height < 32 || metadata.width > 10000 || metadata.height > 10000) {
      res.status(400).json({ error: 'Logo dimensions must be between 32px and 10000px.' }); return;
    }
    const outputDir = path.resolve(process.env.UPLOAD_DIR || '/var/www/punchy-backend/uploads', 'business-logos');
    await fs.mkdir(outputDir, { recursive: true });
    const filename = `${req.user!.userId}-${uuid()}.webp`;
    const outputPath = path.join(outputDir, filename);
    const output = await image.resize(512, 512, { fit: 'cover' }).webp({ quality: 82, effort: 4 }).toFile(outputPath);
    if (output.size > 300 * 1024) {
      await fs.unlink(outputPath).catch(() => undefined);
      res.status(400).json({ error: 'Logo could not be compressed below 300KB. Please choose a simpler image.' }); return;
    }
    const baseUrl = (process.env.PUBLIC_BASE_URL || 'https://trypunchy.site').replace(/\/$/, '');
    const logoUrl = `${baseUrl}/uploads/business-logos/${filename}`;
    const business = await prisma.businessProfile.update({ where: { userId: req.user!.userId }, data: { logo: logoUrl } });
    res.json({ logo: business.logo, sizeBytes: output.size, width: output.width, height: output.height });
  } catch (error) {
    console.error('Business logo upload failed:', error);
    res.status(400).json({ error: 'The selected file is not a supported image.' });
  }
});

/**
 * GET /business/cards
 */
router.get('/cards', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  const cards = await prisma.loyaltyCard.findMany({
    where: { businessId: business.id },
    include: {
      punchMethods: true,
      _count: { select: { customerCards: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  res.json(cards);
});

/**
 * POST /business/cards
 * Create loyalty card (enforces single active card rule per business)
 */
router.post('/cards', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  let business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    business = await prisma.businessProfile.create({
      data: {
        userId: req.user!.userId,
        name: 'My Business',
        category: 'Cafe & Retail',
        status: 'APPROVED',
      },
    });
  }

  // Enforce Single Active Card rule: Business can only hold 1 active card
  const existingCard = await prisma.loyaltyCard.findFirst({
    where: { businessId: business.id },
  });
  if (existingCard) {
    res.status(400).json({
      error: 'A business can only have one active loyalty card at a time. Please delete your existing card before creating a new one.',
    });
    return;
  }

  const parsed = CardSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const { title, punchesRequired, rewardDescription, visualStyle, validUntil, pricePerPunch, currency, enableQR, enableNFC } = parsed.data;

  const card = await prisma.loyaltyCard.create({
    data: {
      businessId: business.id,
      title,
      punchesRequired,
      rewardDescription,
      visualStyle: (visualStyle ?? {}) as any,
      validUntil: validUntil ? new Date(validUntil) : null,
      pricePerPunch: pricePerPunch ?? 0,
      currency: business.currencyCode,
      punchMethods: {
        create: [
          ...(enableQR ? [{ type: 'QR' as const, identifier: uuid(), label: `${title} QR Code` }] : []),
          ...(enableNFC ? [{ type: 'NFC' as const, identifier: uuid(), label: `${title} NFC Tag` }] : []),
        ],
      },
    },
    include: { punchMethods: true },
  });

  res.status(201).json(card);
});

/**
 * GET /business/cards/:id
 */
router.get('/cards/:id', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const card = await prisma.loyaltyCard.findUnique({
    where: { id: String(req.params.id) },
    include: { punchMethods: true, _count: { select: { customerCards: true } } },
  });
  if (!card) {
    res.status(404).json({ error: 'Card not found' });
    return;
  }
  res.json(card);
});

/**
 * PUT /business/cards/:id
 */
router.put('/cards/:id', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const existing = await prisma.loyaltyCard.findUnique({ where: { id: String(req.params.id) } });
  if (!existing) { res.status(404).json({ error: 'Card not found' }); return; }
  const owner = await prisma.businessProfile.findFirst({ where: { id: existing.businessId, userId: req.user!.userId }, select: { id: true, currencyCode: true } });
  if (!owner) { res.status(403).json({ error: 'Forbidden' }); return; }
  const parsed = CardSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const nextValidUntil = parsed.data.validUntil !== undefined
    ? (parsed.data.validUntil ? new Date(parsed.data.validUntil) : null)
    : existing.validUntil;
  if (parsed.data.isActive === true && nextValidUntil && nextValidUntil <= new Date()) {
    res.status(400).json({ error: 'A card can only be reactivated with a future expiry date.' });
    return;
  }

  const updated = await prisma.loyaltyCard.update({
    where: { id: String(req.params.id) },
    data: {
      title: parsed.data.title,
      punchesRequired: parsed.data.punchesRequired,
      rewardDescription: parsed.data.rewardDescription,
      ...(parsed.data.visualStyle !== undefined ? { visualStyle: parsed.data.visualStyle as any } : {}),
      ...(parsed.data.pricePerPunch !== undefined ? { pricePerPunch: parsed.data.pricePerPunch } : {}),
      currency: owner.currencyCode,
      ...(parsed.data.isActive !== undefined ? { isActive: parsed.data.isActive } : {}),
      ...(parsed.data.validUntil !== undefined
        ? { validUntil: parsed.data.validUntil ? new Date(parsed.data.validUntil) : null }
        : {}),
    },
    include: { punchMethods: true },
  });

  res.json(updated);
});

/**
 * DELETE /business/cards/:id
 * Allows business to delete their existing card so a new card can be created
 */
router.delete('/cards/:id', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  const cardId = String(req.params.id);
  const card = await prisma.loyaltyCard.findFirst({
    where: { id: cardId, businessId: business.id },
  });

  if (!card) {
    res.status(404).json({ error: 'Card not found or does not belong to your business' });
    return;
  }

  // Delete related punch methods, customer cards, and card
  await prisma.punchMethod.deleteMany({ where: { cardId } });
  await prisma.customerCard.deleteMany({ where: { cardId } });
  await prisma.loyaltyCard.delete({ where: { id: cardId } });

  res.json({ message: 'Loyalty card deleted successfully. You can now create a new loyalty card.' });
});

/**
 * GET /business/staff
 * Lists all staff child accounts under this business
 */
router.get('/staff', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  const staffMembers = await prisma.user.findMany({
    where: { businessId: business.id, role: 'STAFF' },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      isStaffActive: true,
      createdAt: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  res.json(staffMembers);
});

/**
 * POST /business/staff
 * Create a new staff child account for this business
 */
router.post('/staff', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  const parsed = CreateStaffSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const { name, email, password, phone } = parsed.data;
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    res.status(409).json({ error: 'Email is already registered in the system.' });
    return;
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const staff = await prisma.user.create({
    data: {
      email,
      name,
      passwordHash,
      phone,
      role: 'STAFF',
      businessId: business.id,
      isStaffActive: true,
    },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      isStaffActive: true,
      createdAt: true,
    },
  });

  res.status(201).json({ message: 'Staff member account created successfully! 🎉', staff });
});

/**
 * PATCH /business/staff/:id/toggle-active
 * Business owner toggles a staff member's scanner access ON/OFF
 */
router.patch('/staff/:id/toggle-active', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  const staffId = String(req.params.id);
  const staff = await prisma.user.findFirst({
    where: { id: staffId, businessId: business.id, role: 'STAFF' },
  });

  if (!staff) {
    res.status(404).json({ error: 'Staff member not found' });
    return;
  }

  const updated = await prisma.user.update({
    where: { id: staffId },
    data: { isStaffActive: !staff.isStaffActive },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      isStaffActive: true,
      createdAt: true,
    },
  });

  res.json({
    message: `Staff scanner access ${updated.isStaffActive ? 'activated' : 'deactivated'} successfully.`,
    staff: updated,
  });
});

/**
 * DELETE /business/staff/:id
 * Remove a staff account
 */
router.delete('/staff/:id', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  const staffId = String(req.params.id);
  const staff = await prisma.user.findFirst({
    where: { id: staffId, businessId: business.id, role: 'STAFF' },
  });

  if (!staff) {
    res.status(404).json({ error: 'Staff member not found' });
    return;
  }

  await prisma.user.delete({ where: { id: staffId } });
  res.json({ message: 'Staff member account deleted successfully.' });
});

/**
 * GET /business/customers
 * Returns all customers who joined cards of this business
 */
router.get('/customers', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business) {
    res.json([]);
    return;
  }

  const customerCards = await prisma.customerCard.findMany({
    where: { card: { businessId: business.id } },
    include: {
      customer: { select: { id: true, email: true, phone: true, createdAt: true } },
      card: { select: { id: true, title: true, punchesRequired: true, rewardDescription: true, validUntil: true } },
      punchTransactions: { orderBy: { timestamp: 'desc' }, take: 1 },
    },
    orderBy: { updatedAt: 'desc' },
  });

  const formatted = customerCards.map(cc => ({
    customerCardId: cc.id,
    customerId: cc.customer.id,
    email: cc.customer.email,
    cardTitle: cc.card.title,
    punchCount: cc.punchCount,
    punchesRequired: cc.card.punchesRequired,
    validUntil: cc.card.validUntil,
    isCompleted: cc.isCompleted,
    isExpired: Boolean(cc.card.validUntil && cc.card.validUntil <= new Date()),
    joinedAt: cc.joinedAt,
    lastActivity: cc.punchTransactions[0]?.timestamp ?? cc.updatedAt,
  }));

  res.json(formatted);
});

/**
 * POST /business/redeem-confirm
 * Staff or Business confirms that a completed card's reward was redeemed
 */
router.post('/redeem-confirm', requireAuth, requireRole('BUSINESS', 'STAFF'), async (req: Request, res: Response): Promise<void> => {
  const { customerCardId } = req.body;
  if (!customerCardId) {
    res.status(400).json({ error: 'customerCardId is required' });
    return;
  }

  const customerCard = await prisma.customerCard.findUnique({
    where: { id: String(customerCardId) },
    include: { card: true, customer: true },
  });

  if (!customerCard) {
    res.status(404).json({ error: 'Customer card not found' });
    return;
  }

  if (!customerCard.isCompleted && customerCard.punchCount < customerCard.card.punchesRequired) {
    res.status(400).json({ error: 'Card punches are not yet complete' });
    return;
  }

  await prisma.$transaction([
    prisma.redemption.create({
      data: {
        customerCardId: customerCard.id,
        verifiedBy: req.user!.userId,
      },
    }),
    prisma.customerCard.update({
      where: { id: customerCard.id },
      data: { punchCount: 0, isCompleted: false },
    }),
    prisma.activityLog.create({
      data: {
        userId: customerCard.customerId,
        action: 'REWARD_REDEEMED_BY_STAFF',
        metadata: {
          staffUserId: req.user!.userId,
          cardId: customerCard.cardId,
          cardTitle: customerCard.card.title,
        },
      },
    }),
  ]);

  // Send push notification trigger to customer
  await sendNotification({
    userId: customerCard.customerId,
    title: 'Reward Redeemed! 🎉',
    body: `Your reward for ${customerCard.card.title} has been confirmed. Thank you!`,
  });

  res.json({ message: 'Redemption verified and card reset successfully!' });
});

/**
 * POST /business/punch
 * Merchant OR Staff scans a customer's barcode / QR code to add 1 punch
 */
router.post('/punch', requireAuth, requireRole('BUSINESS', 'STAFF'), async (req: Request, res: Response): Promise<void> => {
  try {
    const { customerIdentifier, cardId } = req.body;
    if (!customerIdentifier) {
      res.status(400).json({ error: 'Customer identifier is required' });
      return;
    }

    let businessId: string | null = null;
    let executorName = 'Merchant';

    if (req.user!.role === 'STAFF') {
      const staffUser = await prisma.user.findUnique({ where: { id: req.user!.userId } });
      if (!staffUser || staffUser.role !== 'STAFF' || !staffUser.businessId) {
        res.status(403).json({ error: 'Invalid staff account' });
        return;
      }
      if (!staffUser.isStaffActive) {
        res.status(403).json({
          error: 'Staff scanner access is disabled. Please contact your business owner to activate your scanner.',
          isStaffInactive: true,
        });
        return;
      }
      businessId = staffUser.businessId;
      executorName = staffUser.name || 'Staff';
    } else {
      const business = await prisma.businessProfile.findUnique({
        where: { userId: req.user!.userId },
      });
      if (business) businessId = business.id;
    }

    if (!businessId) {
      res.status(404).json({ error: 'Business profile not found' });
      return;
    }

    const business = await prisma.businessProfile.findUnique({
      where: { id: businessId },
      include: { loyaltyCards: true },
    });

    if (!business || business.loyaltyCards.length === 0) {
      res.status(400).json({ error: 'No active loyalty card found for your business. Please create one first.' });
      return;
    }

    // Determine target card
    const targetCard = cardId
      ? business.loyaltyCards.find(c => c.id === cardId) ?? business.loyaltyCards[0]
      : business.loyaltyCards[0];

    // Card Validity Expiration Check
    if (targetCard.validUntil && new Date(targetCard.validUntil) < new Date()) {
      res.status(400).json({
        error: `This loyalty card expired on ${new Date(targetCard.validUntil).toLocaleDateString()}. Punches cannot be added to an expired card.`,
      });
      return;
    }

    // Extract customer ID or email from payload
    let cleanIdentifier = customerIdentifier.toString().trim();
    let targetUserId = cleanIdentifier;

    if (cleanIdentifier.startsWith('PUNCHY:CUSTOMER:')) {
      const parts = cleanIdentifier.split(':');
      if (parts.length >= 3) {
        targetUserId = parts[2];
      }
    }

    // Find customer in database
    const lookupOr: any[] = [
      { email: targetUserId.toLowerCase() },
      { email: cleanIdentifier.toLowerCase() },
      { publicId: targetUserId },
    ];
    if (/^[a-f0-9]{24}$/i.test(targetUserId)) lookupOr.unshift({ id: targetUserId });
    // A punch identifier must always resolve to a CUSTOMER account. In
    // particular, never allow a business/staff public ID to be treated as a
    // customer, and never fall back to an arbitrary customer for bad input.
    let customer = await prisma.user.findFirst({ where: { role: 'CUSTOMER', OR: lookupOr } });

    // Customer pass barcodes use the human-readable PUN-NAME-8492 format.
    // Resolve that code to the matching customer email before processing.
    if (!customer && cleanIdentifier.toUpperCase().startsWith('PUN-')) {
      const code = cleanIdentifier.split('-');
      const namePart = code.slice(1, -1).join('-').toLowerCase();
      if (namePart) {
        customer = await prisma.user.findFirst({
          where: { role: 'CUSTOMER', email: { startsWith: namePart } },
        });
      }
    }

    if (!customer) {
      res.status(404).json({ error: 'Wrong ID. Please enter a valid customer ID or scan the customer barcode.' });
      return;
    }

    // Find or create CustomerCard
    let customerCard = await prisma.customerCard.findUnique({
      where: {
        customerId_cardId: {
          customerId: customer.id,
          cardId: targetCard.id,
        },
      },
    });

    if (!customerCard) {
      customerCard = await prisma.customerCard.create({
        data: {
          customerId: customer.id,
          cardId: targetCard.id,
          punchCount: 0,
        },
      });
    }

    // A scan on an already-full card is the reward visit. Redeem and reset
    // atomically so the count can never become N+1 or be partially updated.
    if (customerCard.punchCount >= targetCard.punchesRequired) {
      await prisma.$transaction([
        prisma.redemption.create({ data: { customerCardId: customerCard.id, verifiedBy: req.user!.userId } }),
        prisma.customerCard.update({ where: { id: customerCard.id }, data: { punchCount: 0, isCompleted: false } }),
        prisma.activityLog.create({ data: { userId: customer.id, action: 'REWARD_REDEEMED_BY_STAFF', metadata: { businessId: business.id, cardId: targetCard.id, cardTitle: targetCard.title, verifiedBy: req.user!.userId, rewardDescription: targetCard.rewardDescription } } }),
      ]);
      await sendNotification({ userId: customer.id, title: 'Reward redeemed! 🎉', body: 'Your reward was redeemed successfully and your card has been reset. Start collecting punches again!' });
      res.json({ success: true, rewardEarned: true, rewardDescription: targetCard.rewardDescription, customerEmail: customer.email, cardTitle: targetCard.title, punchCount: 0, punchesRequired: targetCard.punchesRequired, isCompleted: false, message: '🎉 Reward earned! Give them their reward — free. Card has been reset.' });
      return;
    }

    // updatedAt is written by the punch update and acts as this card's last-punch timestamp.
    const cooldownExpiresAt = customerCard.updatedAt.getTime() + 3 * 60 * 1000;
    if (customerCard.punchCount > 0 && cooldownExpiresAt > Date.now()) {
      const remainingSeconds = Math.ceil((cooldownExpiresAt - Date.now()) / 1000);
      res.status(429).json({ error: 'Punch cooldown active', cooldown: true, remainingSeconds });
      return;
    }

    const newPunchCount = customerCard.punchCount + 1;
    const isNowComplete = newPunchCount >= targetCard.punchesRequired;

    const updated = await prisma.customerCard.update({
      where: { id: customerCard.id },
      data: {
        punchCount: newPunchCount,
        isCompleted: isNowComplete,
      },
    });

    // Record Punch Transaction
    let pm = await prisma.punchMethod.findFirst({ where: { cardId: targetCard.id } });
    if (!pm) {
      pm = await prisma.punchMethod.create({
        data: { cardId: targetCard.id, type: 'QR', identifier: uuid(), label: `${targetCard.title} QR` },
      });
    }

    await prisma.punchTransaction.create({
      data: {
        customerCardId: customerCard.id,
        punchMethodId: pm.id,
        method: 'QR',
      },
    });

    // Record Activity Log
    await prisma.activityLog.create({
      data: {
        userId: customer.id,
        action: req.user!.role === 'STAFF' ? 'PUNCH_RECORDED_BY_STAFF' : 'PUNCH_RECORDED_BY_BUSINESS',
        metadata: {
          executorId: req.user!.userId,
          executorName,
          businessId: business.id,
          cardId: targetCard.id,
          punchCount: newPunchCount,
          punchesRequired: targetCard.punchesRequired,
        },
      },
    });

    // Send a generic, professional punch notification; reward-specific copy
    // is intentionally reserved for the actual redemption event.
    await notifyPunchEarned(customer.id, newPunchCount, targetCard.punchesRequired);
    await notifyProgressMilestone(
      customerCard.id,
      customer.id,
      business.name,
      business.category,
      targetCard.rewardDescription,
      newPunchCount,
      targetCard.punchesRequired,
    );

    res.json({
      success: true,
      message: isNowComplete
        ? `🎉 Card Complete! ${customer.email} reached ${newPunchCount}/${targetCard.punchesRequired} punches!`
        : `Punch recorded! ${customer.email} now has ${newPunchCount}/${targetCard.punchesRequired} punches.`,
      customerEmail: customer.email,
      cardTitle: targetCard.title,
      punchCount: newPunchCount,
      punchesRequired: targetCard.punchesRequired,
      isCompleted: isNowComplete,
    });
  } catch (error) {
    console.error('Merchant/Staff Punch error:', error);
    res.status(500).json({ error: 'Failed to record punch' });
  }
});

export default router;
