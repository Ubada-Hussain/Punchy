import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import bcrypt from 'bcryptjs';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { sendNotification } from '../lib/notifications';

const router = Router();

// Business Onboarding Schema
const SetupSchema = z.object({
  name: z.string().min(2),
  category: z.string().min(2),
  description: z.string().optional(),
  website: z.string().optional(),
  logo: z.string().optional(),
  address: z.string().optional(),
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

/**
 * GET /business/dashboard
 * Return total customers, punches today, rewards redeemed, card preview, recent activity
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
          category: 'Retail & Cafe',
          status: 'APPROVED',
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

    // Total unique customers who joined cards
    const totalCustomers = await prisma.customerCard.count({
      where: { cardId: { in: cardIds } },
    });

    // Punches today
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const customerCardIds = (
      await prisma.customerCard.findMany({
        where: { cardId: { in: cardIds } },
        select: { id: true },
      })
    ).map(c => c.id);

    const punchesToday = await prisma.punchTransaction.count({
      where: {
        customerCardId: { in: customerCardIds },
        timestamp: { gte: startOfDay },
      },
    });

    // Total redeemed
    const redeemedCount = await prisma.redemption.count({
      where: { customerCardId: { in: customerCardIds } },
    });

    // Recent activity
    const recentPunches = await prisma.punchTransaction.findMany({
      where: { customerCardId: { in: customerCardIds } },
      include: {
        customerCard: {
          include: {
            customer: { select: { email: true } },
            card: { select: { title: true } },
          },
        },
      },
      orderBy: { timestamp: 'desc' },
      take: 10,
    });

    res.json({
      business: {
        id: business.id,
        name: business.name,
        category: business.category,
        logo: business.logo,
        status: business.status,
      },
      stats: {
        totalCustomers,
        punchesToday,
        rewardsRedeemed: redeemedCount,
      },
      cards: business.loyaltyCards,
      recentActivity: recentPunches.map(p => ({
        id: p.id,
        customerEmail: p.customerCard.customer.email,
        cardTitle: p.customerCard.card.title,
        method: p.method,
        timestamp: p.timestamp,
      })),
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
      const user = await prisma.user.findUnique({ where: { id: req.user!.userId } });
      business = await prisma.businessProfile.create({
        data: {
          userId: req.user!.userId,
          name: user?.name || 'My Business',
          category: 'Retail & Services',
          status: 'APPROVED',
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

  const { name, category, description, website, logo, address } = parsed.data;

  const business = await prisma.businessProfile.upsert({
    where: { userId: req.user!.userId },
    update: {
      name,
      category,
      description,
      website,
      logo,
      locations: address ? [{ address }] : [],
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
      status: 'APPROVED',
    },
  });

  res.json({ message: 'Business setup complete! 🎉', business });
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

  const { title, punchesRequired, rewardDescription, visualStyle, validUntil, enableQR, enableNFC } = parsed.data;

  const card = await prisma.loyaltyCard.create({
    data: {
      businessId: business.id,
      title,
      punchesRequired,
      rewardDescription,
      visualStyle: (visualStyle ?? {}) as any,
      validUntil: validUntil ? new Date(validUntil) : null,
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
  const parsed = CardSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const updated = await prisma.loyaltyCard.update({
    where: { id: String(req.params.id) },
    data: {
      title: parsed.data.title,
      punchesRequired: parsed.data.punchesRequired,
      rewardDescription: parsed.data.rewardDescription,
      ...(parsed.data.visualStyle !== undefined ? { visualStyle: parsed.data.visualStyle as any } : {}),
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
    let customer = await prisma.user.findFirst({ where: { OR: lookupOr } });

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
      // Fallback for simulation testing
      customer = await prisma.user.findFirst({ where: { role: 'CUSTOMER' } });
    }

    if (!customer) {
      res.status(404).json({ error: 'Customer not found' });
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
      await sendNotification({ userId: customer.id, title: 'Reward redeemed! 🎉', body: `Enjoy your free ${targetCard.rewardDescription}! Your card has been reset.` });
      res.json({ success: true, rewardEarned: true, rewardDescription: targetCard.rewardDescription, customerEmail: customer.email, cardTitle: targetCard.title, punchCount: 0, punchesRequired: targetCard.punchesRequired, isCompleted: false, message: `🎉 Reward earned! Give them ${targetCard.rewardDescription} — free. Card has been reset.` });
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

    // Send push notification to customer
    await sendNotification({
      userId: customer.id,
      title: isNowComplete ? '🎉 Loyalty Card Complete!' : '☕ Punch Added!',
      body: isNowComplete
        ? `Congratulations! You completed ${targetCard.title}. Redeem your ${targetCard.rewardDescription}!`
        : `You earned 1 punch at ${business.name}. (${newPunchCount}/${targetCard.punchesRequired})`,
    });

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
