import { Router, Request, Response } from 'express';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { reverseGeocodeLocation } from '../lib/international';
import { filterExploreBusinesses } from '../lib/exploreLocation';

const router = Router();

// GET /customer/cards — wallet
router.get('/cards', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const cards = await prisma.customerCard.findMany({
    where: { customerId: String(req.user!.userId) },
    include: {
      card: {
        include: {
          business: {
            select: {
              id: true, name: true, logo: true, category: true, locations: true,
              user: { select: { phone: true } },
            },
          },
          punchMethods: { where: { isActive: true }, select: { type: true } },
        },
      },
    },
    orderBy: { joinedAt: 'desc' },
  });
  res.json(cards.map((customerCard) => ({
    ...customerCard,
    isExpired: Boolean(customerCard.card.validUntil && customerCard.card.validUntil <= new Date()),
  })));
});

// GET /customer/cards/:id — single card with punch history
router.get('/cards/:id', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const card = await prisma.customerCard.findFirst({
    where: { id: String(req.params.id), customerId: req.user!.userId },
    include: {
      card: {
        include: {
          business: {
            select: {
              id: true, name: true, logo: true, category: true, locations: true,
              user: { select: { phone: true } },
            },
          },
        },
      },
      punchTransactions: {
        select: { method: true, timestamp: true },
        orderBy: { timestamp: 'desc' },
        take: 50,
      },
    },
  });
  if (!card) { res.status(404).json({ error: 'Card not found' }); return; }
  res.json({ ...card, isExpired: Boolean(card.card.validUntil && card.card.validUntil <= new Date()) });
});

// POST /customer/cards/:id/redeem
router.post('/cards/:id/redeem', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const customerCard = await prisma.customerCard.findFirst({
    where: { id: String(req.params.id), customerId: req.user!.userId },
  });
  if (!customerCard) { res.status(404).json({ error: 'Card not found' }); return; }
  if (!customerCard.isCompleted) { res.status(400).json({ error: 'Card is not yet complete' }); return; }

  const [redemption] = await prisma.$transaction([
    prisma.redemption.create({ data: { customerCardId: customerCard.id } }),
    prisma.customerCard.update({ where: { id: customerCard.id }, data: { punchCount: 0, isCompleted: false } }),
    prisma.activityLog.create({
      data: { userId: req.user!.userId, action: 'REWARD_REDEEMED', metadata: { customerCardId: customerCard.id, cardId: customerCard.cardId } },
    }),
  ]);

  res.json({ message: 'Reward redeemed! Enjoy! 🎉', redemption });
});

// GET /customer/explore — browse businesses from the customer's current location.
router.get('/explore', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { category, search, lat, lng } = req.query;
  const requestedScope: 'city' | 'country' = req.query.scope === 'country' ? 'country' : 'city';
  const latitude = Number(lat); const longitude = Number(lng);
  const hasCoordinates = Number.isFinite(latitude) && Number.isFinite(longitude);
  // The client sends its resolved location after the first GPS lookup so tab,
  // category and search changes do not call the geocoder repeatedly.
  const suppliedLocation = typeof req.query.currentCountryCode === 'string'
    ? { city: typeof req.query.currentCity === 'string' ? req.query.currentCity : undefined, countryCode: req.query.currentCountryCode }
    : null;
  const locationStartedAt = Date.now();
  const currentLocation = suppliedLocation ?? (hasCoordinates
    ? await reverseGeocodeLocation(latitude, longitude)
    : null);
  const locationDurationMs = Date.now() - locationStartedAt;
  const where: Record<string, unknown> = {
    status: 'APPROVED',
    loyaltyCards: {
      some: {
        isActive: true,
        OR: [{ validUntil: null }, { validUntil: { gt: new Date() } }],
      },
    },
  };
  // Location permission/reverse lookup failures fall back to an unfiltered
  // Explore list; wallet cards are never queried or filtered here.

  if (category && category !== 'All') {
    where.category = { contains: String(category), mode: 'insensitive' };
  }
  if (search) {
    where.OR = [
      { name: { contains: String(search), mode: 'insensitive' } },
      { category: { contains: String(search), mode: 'insensitive' } },
      { description: { contains: String(search), mode: 'insensitive' } },
    ];
  }

  const countryCode = currentLocation?.countryCode?.trim().toUpperCase();
  const city = currentLocation?.city?.trim();
  // City's canonical field is indexed; include legacy rows without a canonical
  // city only inside the customer's country, then retain their location fallback.
  if (requestedScope === 'country' && countryCode) {
    // Country codes are stored as ISO uppercase; plain equality uses the index.
    where.countryCode = countryCode;
  } else if (requestedScope === 'city' && city && countryCode) {
    where.countryCode = countryCode;
    // Keep location-array legacy records eligible; the exact city check below
    // handles both the canonical city and cities embedded in locations.
  }

  const databaseStartedAt = Date.now();
  const businesses = await prisma.businessProfile.findMany({
    where,
    select: {
      id: true, name: true, logo: true, category: true, description: true,
      website: true, currencyCode: true, locations: true, city: true, countryCode: true,
      user: { select: { phone: true } },
      loyaltyCards: {
        where: {
          isActive: true,
          OR: [{ validUntil: null }, { validUntil: { gt: new Date() } }],
        },
        select: {
          id: true, title: true, punchesRequired: true, rewardDescription: true,
          visualStyle: true, validUntil: true, pricePerPunch: true, currency: true,
        },
        take: 1,
      },
    },
    orderBy: { createdAt: 'desc' },
  });
  const databaseDurationMs = Date.now() - databaseStartedAt;
  const filterStartedAt = Date.now();
  const matchingBusinesses = filterExploreBusinesses(businesses, currentLocation, requestedScope);
  const filterDurationMs = Date.now() - filterStartedAt;
  res.setHeader('Server-Timing', `location;dur=${locationDurationMs}, database;dur=${databaseDurationMs}, filter;dur=${filterDurationMs}`);
  console.info(`[Explore] scope=${requestedScope} location=${locationDurationMs}ms database=${databaseDurationMs}ms filter=${filterDurationMs}ms results=${matchingBusinesses.length}`);
  res.json({ businesses: matchingBusinesses, location: currentLocation, locationAvailable: Boolean(currentLocation) });
});

// POST /customer/cards/join — join card without scan
router.post('/cards/join', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const { cardId } = req.body;
  if (!cardId) {
    res.status(400).json({ error: 'cardId is required' });
    return;
  }

  const card = await prisma.loyaltyCard.findUnique({
    where: { id: String(cardId) },
    include: { business: true },
  });

  if (!card || !card.isActive) {
    res.status(404).json({ error: 'Card not found or inactive' });
    return;
  }

  if (card.validUntil && new Date(card.validUntil) < new Date()) {
    res.status(400).json({ error: 'This loyalty card has expired and cannot be added.' });
    return;
  }

  const customerId = req.user!.userId;
  const existing = await prisma.customerCard.findUnique({
    where: { customerId_cardId: { customerId, cardId: card.id } },
  });

  if (existing) {
    res.json({ message: 'Card is already in your wallet', customerCard: existing });
    return;
  }

  const created = await prisma.customerCard.create({
    data: {
      customerId,
      cardId: card.id,
      punchCount: 0,
    },
  });

  await prisma.activityLog.create({
    data: {
      userId: customerId,
      action: 'CARD_JOINED_FROM_EXPLORE',
      metadata: { cardId: card.id, cardTitle: card.title, businessName: card.business.name },
    },
  });

  res.status(201).json({ message: 'Card added to your wallet! 🎉', customerCard: created });
});

// DELETE /customer/cards/:id — remove/unjoin card from wallet
router.delete('/cards/:id', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const customerId = req.user!.userId;
  const customerCardId = String(req.params.id);

  const customerCard = await prisma.customerCard.findFirst({
    where: {
      id: customerCardId,
      customerId,
    },
    include: {
      card: { select: { title: true } },
    },
  });

  if (!customerCard) {
    res.status(404).json({ error: 'Card not found in your wallet' });
    return;
  }

  await prisma.$transaction([
    prisma.punchTransaction.deleteMany({ where: { customerCardId: customerCard.id } }),
    prisma.redemption.deleteMany({ where: { customerCardId: customerCard.id } }),
    prisma.customerCard.delete({ where: { id: customerCard.id } }),
    prisma.activityLog.create({
      data: {
        userId: customerId,
        action: 'CARD_REMOVED_FROM_WALLET',
        metadata: { cardId: customerCard.cardId, cardTitle: customerCard.card.title },
      },
    }),
  ]);

  res.json({ message: 'Card removed from wallet', success: true });
});

export default router;
