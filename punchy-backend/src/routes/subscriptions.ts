import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { supportedCountries } from '../lib/international';

const router = Router();

const PricingSchema = z.object({
  countryCode: z.string().length(2).transform(value => value.toUpperCase()),
  currencyCode: z.string().length(3).transform(value => value.toUpperCase()),
  monthlyPrice: z.number().min(0),
  yearlyPrice: z.number().min(0),
  isActive: z.boolean().default(true),
});
const AssignmentSchema = z.object({ plan: z.enum(['MONTHLY', 'YEARLY']) });

function addMonths(date: Date, months: number) {
  const next = new Date(date);
  next.setMonth(next.getMonth() + months);
  return next;
}

router.get('/business/current', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response) => {
  const business = await prisma.businessProfile.findUnique({
    where: { userId: req.user!.userId },
    select: { id: true, countryCode: true },
  });
  if (!business?.countryCode) {
    res.status(400).json({ error: 'Select a business country first.' });
    return;
  }

  const now = new Date();
  let subscription = await prisma.businessSubscription.findFirst({
    where: { businessId: business.id },
    orderBy: { endDate: 'desc' },
  });
  if (subscription?.status === 'TRIALING' && subscription.endDate <= now) {
    subscription = await prisma.businessSubscription.update({
      where: { id: subscription.id },
      data: { status: 'PAYMENT_PENDING' },
    });
  } else if (subscription?.status === 'ACTIVE' && subscription.endDate <= now) {
    subscription = await prisma.businessSubscription.update({
      where: { id: subscription.id },
      data: { status: 'EXPIRED' },
    });
  }

  const pricing = await prisma.countrySubscriptionPricing.findUnique({
    where: { countryCode: business.countryCode.toUpperCase() },
  });
  const activePricing = pricing?.isActive ? pricing : null;
  const yearlySavings = activePricing ? Math.max(0, activePricing.monthlyPrice * 12 - activePricing.yearlyPrice) : null;
  res.json({ subscription, pricing: activePricing, yearlySavings });
});

router.get('/countries', requireAuth, requireRole('ADMIN'), async (_req, res) => {
  res.json(supportedCountries());
});

router.get('/pricing', requireAuth, requireRole('ADMIN'), async (_req, res) => {
  res.json(await prisma.countrySubscriptionPricing.findMany({ orderBy: { countryCode: 'asc' } }));
});

router.post('/pricing', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const parsed = PricingSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }
  res.json(await prisma.countrySubscriptionPricing.upsert({
    where: { countryCode: parsed.data.countryCode },
    create: parsed.data,
    update: parsed.data,
  }));
});

router.put('/pricing/:countryCode', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const parsed = PricingSchema.safeParse({ ...req.body, countryCode: req.params.countryCode });
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }
  res.json(await prisma.countrySubscriptionPricing.upsert({
    where: { countryCode: parsed.data.countryCode },
    create: parsed.data,
    update: parsed.data,
  }));
});

router.get('/businesses', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const search = String(req.query.search || '');
  const businesses = await prisma.businessProfile.findMany({
    where: search ? {
      OR: [
        { name: { contains: search, mode: 'insensitive' } },
        { user: { publicId: { contains: search, mode: 'insensitive' } } },
      ],
    } : {},
    include: {
      user: { select: { publicId: true } },
      subscriptions: { orderBy: { endDate: 'desc' }, take: 1 },
    },
    take: 50,
    orderBy: { name: 'asc' },
  });
  res.json(businesses);
});

router.post('/businesses/:businessId/assign', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const parsed = AssignmentSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const business = await prisma.businessProfile.findUnique({ where: { id: String(req.params.businessId) } });
  if (!business?.countryCode) {
    res.status(400).json({ error: 'Business has no country.' });
    return;
  }

  const pricing = await prisma.countrySubscriptionPricing.findUnique({
    where: { countryCode: business.countryCode.toUpperCase() },
  });
  if (!pricing?.isActive) {
    res.status(400).json({ error: 'No active pricing is configured for this business country.' });
    return;
  }

  const now = new Date();
  const current = await prisma.businessSubscription.findFirst({
    where: { businessId: business.id, status: { in: ['ACTIVE', 'TRIALING'] }, endDate: { gt: now } },
    orderBy: { endDate: 'desc' },
  });

  // A paid plan replaces a trial immediately. An already-active paid plan is
  // extended from its end date, so subscription periods never overlap.
  if (current?.status === 'TRIALING') {
    await prisma.businessSubscription.update({
      where: { id: current.id },
      data: { status: 'EXPIRED', endDate: now },
    });
  }
  const startDate = current?.status === 'ACTIVE' ? current.endDate : now;
  const months = parsed.data.plan === 'YEARLY' ? 12 : 1;
  const price = parsed.data.plan === 'YEARLY' ? pricing.yearlyPrice : pricing.monthlyPrice;
  const subscription = await prisma.businessSubscription.create({
    data: {
      businessId: business.id,
      status: 'ACTIVE',
      plan: parsed.data.plan,
      price,
      currency: pricing.currencyCode,
      startDate,
      endDate: addMonths(startDate, months),
    },
  });
  res.json({ subscription });
});

export default router;