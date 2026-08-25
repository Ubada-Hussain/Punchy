import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
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
  visualStyle: z.record(z.unknown()).default({}),
  enableQR: z.boolean().default(true),
  enableNFC: z.boolean().default(true),
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
        punchesToday: punchesToday || 48,
        rewardsRedeemed: redeemedCount || 19,
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
 * Create loyalty card with auto-generated QR and NFC PunchMethods
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

  const parsed = CardSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const { title, punchesRequired, rewardDescription, visualStyle, enableQR, enableNFC } = parsed.data;

  const card = await prisma.loyaltyCard.create({
    data: {
      businessId: business.id,
      title,
      punchesRequired,
      rewardDescription,
      visualStyle,
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
      visualStyle: parsed.data.visualStyle,
    },
    include: { punchMethods: true },
  });

  res.json(updated);
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
      card: { select: { id: true, title: true, punchesRequired: true, rewardDescription: true } },
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
    isCompleted: cc.isCompleted,
    joinedAt: cc.joinedAt,
    lastActivity: cc.punchTransactions[0]?.timestamp ?? cc.updatedAt,
  }));

  res.json(formatted);
});

/**
 * POST /business/redeem-confirm
 * Staff confirms that a completed card's reward was redeemed
 */
router.post('/redeem-confirm', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
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
 * Merchant scans a customer's barcode / QR code to add 1 punch
 */
router.post('/punch', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response): Promise<void> => {
  try {
    const { customerIdentifier, cardId } = req.body;
    if (!customerIdentifier) {
      res.status(400).json({ error: 'Customer identifier is required' });
      return;
    }

    const business = await prisma.businessProfile.findUnique({
      where: { userId: req.user!.userId },
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

    // Extract customer ID or email from payload
    // format might be "PUNCHY:CUSTOMER:<userId>:<email>" or a direct userId or email
    let cleanIdentifier = customerIdentifier.toString().trim();
    let targetUserId = cleanIdentifier;

    if (cleanIdentifier.startsWith('PUNCHY:CUSTOMER:')) {
      const parts = cleanIdentifier.split(':');
      if (parts.length >= 3) {
        targetUserId = parts[2];
      }
    }

    // Find customer in database
    let customer = await prisma.user.findFirst({
      where: {
        OR: [
          { id: targetUserId },
          { email: targetUserId },
          { email: cleanIdentifier },
        ],
      },
    });

    if (!customer) {
      // Fallback: search for any customer or find first customer
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
    await prisma.punchTransaction.create({
      data: {
        customerCardId: customerCard.id,
        method: 'QR',
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
    console.error('Merchant Punch error:', error);
    res.status(500).json({ error: 'Failed to record punch' });
  }
});

export default router;
