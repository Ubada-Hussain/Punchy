import { Router, Request, Response } from 'express';
import multer from 'multer';
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';
import { createHash, randomUUID } from 'node:crypto';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { supportedCountries } from '../lib/international';

const router = Router();
const paymentLogoUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 2 * 1024 * 1024, files: 1 }, fileFilter: (_req, file, cb) => cb(null, file.mimetype.startsWith('image/')) });
const PaymentMethodSchema = z.object({ name: z.string().trim().min(1).max(80), logoUrl: z.string().trim().url().optional().or(z.literal('')), accountName: z.string().trim().min(1).max(160), accountNumber: z.string().trim().max(80).optional().default(''), bankName: z.string().trim().max(120).optional().default(''), iban: z.string().trim().max(80).optional().default(''), instructions: z.string().trim().max(2000).optional().default(''), isActive: z.boolean().default(true), sortOrder: z.number().int().min(0).default(0) });
const PaymentSubmissionSchema = z.object({ paymentMethodId: z.string().min(1), plan: z.enum(['MONTHLY', 'YEARLY']), transactionId: z.string().trim().min(1).max(160), clientRequestId: z.string().trim().min(8).max(128) });
const PaymentDecisionSchema = z.discriminatedUnion('action', [
  z.object({ action: z.literal('APPROVE'), adminNote: z.string().trim().max(1000).optional().default('') }),
  z.object({ action: z.literal('REJECT'), adminNote: z.string().trim().min(3, 'A rejection reason is required.').max(1000) }),
]);
const hashKey = (value: string) => createHash('sha256').update(value).digest('hex');

const PricingSchema = z.object({
  countryCode: z.string().length(2).transform(value => value.toUpperCase()),
  currencyCode: z.string().length(3).transform(value => value.toUpperCase()),
  monthlyPrice: z.number().min(0),
  yearlyPrice: z.number().min(0),
  isActive: z.boolean().default(true),
});
const AssignmentSchema = z.object({ plan: z.enum(['MONTHLY', 'YEARLY']) });
const FreeSubscriptionSchema = z.object({ status: z.enum(['ACTIVE', 'INACTIVE']), months: z.number().int().min(1).max(120) });

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
  const [loadedSubscription, pricing] = await Promise.all([
    prisma.businessSubscription.findFirst({
      where: { businessId: business.id },
      orderBy: { endDate: 'desc' },
    }),
    prisma.countrySubscriptionPricing.findUnique({
      where: { countryCode: business.countryCode.toUpperCase() },
    }),
  ]);
  let subscription = loadedSubscription;
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

  const activePricing = pricing?.isActive ? pricing : null;
  const yearlySavings = activePricing ? Math.max(0, activePricing.monthlyPrice * 12 - activePricing.yearlyPrice) : null;
  const [paymentMethods, paymentSubmissions, supportConfig] = await Promise.all([
    prisma.paymentMethod.findMany({ where: { isActive: true }, orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] }),
    prisma.subscriptionPayment.findMany({ where: { businessId: business.id }, orderBy: { createdAt: 'desc' }, take: 10 }),
    prisma.adminConfig.findUnique({ where: { key: 'supportEmail' } }),
  ]);
  res.json({ subscription, pricing: activePricing, yearlySavings, paymentMethods, paymentSubmissions, supportEmail: typeof supportConfig?.value === 'string' ? supportConfig.value : process.env.SUPPORT_EMAIL || 'support.punchy@gmail.com' });
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

router.put('/businesses/:businessId/free-subscription', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const parsed = FreeSubscriptionSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const business = await prisma.businessProfile.findUnique({ where: { id: String(req.params.businessId) } });
  if (!business) { res.status(404).json({ error: 'Business not found.' }); return; }

  const latest = await prisma.businessSubscription.findFirst({ where: { businessId: business.id }, orderBy: { endDate: 'desc' } });
  if (latest && latest.plan !== 'TRIAL') {
    res.status(400).json({ error: 'This business has a paid subscription. Free subscription controls apply only to free subscriptions.' });
    return;
  }

  const now = new Date();
  const active = parsed.data.status === 'ACTIVE';
  const endDate = active ? addMonths(now, parsed.data.months) : now;
  const data = {
    status: active ? 'TRIALING' as const : 'INACTIVE' as const,
    startDate: now,
    endDate,
    trialStart: active ? now : null,
    trialEnd: active ? endDate : null,
    freeMonths: parsed.data.months,
  };
  const subscription = latest
    ? await prisma.businessSubscription.update({ where: { id: latest.id }, data })
    : await prisma.businessSubscription.create({ data: { businessId: business.id, plan: 'TRIAL', price: 0, currency: business.currencyCode, ...data } });
  await prisma.activityLog.create({ data: { userId: req.user!.userId, action: 'ADMIN_FREE_SUBSCRIPTION_UPDATED', metadata: { businessId: business.id, subscriptionId: subscription.id, status: parsed.data.status, months: parsed.data.months } } });
  res.json({ subscription });
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


// Public contact destination used by help and international payment flows.
router.get('/support-contact', async (_req, res) => {
  const config = await prisma.adminConfig.findUnique({ where: { key: 'supportEmail' } });
  res.json({ supportEmail: typeof config?.value === 'string' ? config.value : process.env.SUPPORT_EMAIL || 'support.punchy@gmail.com' });
});

// Payment method catalogue, maintained entirely by Admin.
router.get('/payment-methods', requireAuth, requireRole('ADMIN'), async (_req, res) => {
  res.json(await prisma.paymentMethod.findMany({ orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] }));
});
router.post('/payment-methods', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const parsed = PaymentMethodSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  res.status(201).json(await prisma.paymentMethod.create({ data: { ...parsed.data, logoUrl: parsed.data.logoUrl || null } }));
});
router.put('/payment-methods/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const parsed = PaymentMethodSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  res.json(await prisma.paymentMethod.update({ where: { id: String(req.params.id) }, data: { ...parsed.data, logoUrl: parsed.data.logoUrl || null } }));
});
router.delete('/payment-methods/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const id = String(req.params.id);
  await prisma.subscriptionPayment.updateMany({ where: { paymentMethodId: id }, data: { paymentMethodId: null } });
  await prisma.paymentMethod.delete({ where: { id } });
  res.json({ message: 'Payment method deleted.' });
});
router.post('/payment-methods/:id/logo', requireAuth, requireRole('ADMIN'), paymentLogoUpload.single('logo'), async (req, res) => {
  const file = req.file;
  if (!file) { res.status(400).json({ error: 'Please select a valid image file.' }); return; }
  try {
    const image = sharp(file.buffer, { failOn: 'error' });
    const metadata = await image.metadata();
    if (!metadata.width || !metadata.height || metadata.width < 24 || metadata.height < 24 || metadata.width > 10000 || metadata.height > 10000) {
      res.status(400).json({ error: 'Logo dimensions must be between 24px and 10000px.' }); return;
    }
    const outputDir = path.resolve(process.env.UPLOAD_DIR || '/var/www/punchy-backend/uploads', 'payment-method-logos');
    await fs.mkdir(outputDir, { recursive: true });
    const filename = `${randomUUID()}.webp`;
    const outputPath = path.join(outputDir, filename);
    const output = await image.resize(512, 512, { fit: 'inside', withoutEnlargement: true }).webp({ quality: 84 }).toFile(outputPath);
    if (output.size > 300 * 1024) { await fs.unlink(outputPath).catch(() => undefined); res.status(400).json({ error: 'Logo could not be compressed below 300KB.' }); return; }
    const baseUrl = (process.env.PUBLIC_BASE_URL || 'https://trypunchy.site').replace(/\/$/, '');
    const method = await prisma.paymentMethod.update({ where: { id: String(req.params.id) }, data: { logoUrl: `${baseUrl}/uploads/payment-method-logos/${filename}` } });
    res.json({ logoUrl: method.logoUrl });
  } catch (error) {
    console.error('Payment method logo upload failed:', error);
    res.status(400).json({ error: 'The selected file is not a supported image.' });
  }
});

router.post('/payments', requireAuth, requireRole('BUSINESS'), async (req: Request, res: Response) => {
  const parsed = PaymentSubmissionSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  const { paymentMethodId, plan, transactionId, clientRequestId } = parsed.data;
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId } });
  if (!business?.countryCode) { res.status(400).json({ error: 'Select a business country before submitting payment.' }); return; }
  const method = await prisma.paymentMethod.findFirst({ where: { id: paymentMethodId, isActive: true } });
  if (!method) { res.status(400).json({ error: 'This payment method is no longer available.' }); return; }
  const pricing = await prisma.countrySubscriptionPricing.findUnique({ where: { countryCode: business.countryCode.toUpperCase() } });
  if (!pricing?.isActive) { res.status(400).json({ error: 'Subscription pricing is not available for your business country.' }); return; }
  const requestKey = hashKey(`${business.id}\u0000${clientRequestId}`);
  const transactionKey = hashKey(`${paymentMethodId}\u0000${transactionId.toLowerCase()}`);
  const previousRequest = await prisma.subscriptionPayment.findUnique({ where: { requestKey } });
  if (previousRequest) { res.status(200).json(previousRequest); return; }
  const previousTransaction = await prisma.subscriptionPayment.findUnique({ where: { transactionKey } });
  if (previousTransaction) { res.status(409).json({ error: 'This transaction ID has already been submitted.' }); return; }
  const amount = plan === 'YEARLY' ? pricing.yearlyPrice : pricing.monthlyPrice;
  try {
    const payment = await prisma.subscriptionPayment.create({ data: {
      businessId: business.id, paymentMethodId: method.id, paymentMethodName: method.name, plan,
      transactionId, transactionKey, requestKey, amount, currency: pricing.currencyCode,
      accountName: method.accountName, accountNumber: method.accountNumber, bankName: method.bankName,
      iban: method.iban, instructions: method.instructions,
    } });
    res.status(201).json(payment);
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      const duplicate = await prisma.subscriptionPayment.findUnique({ where: { requestKey } });
      if (duplicate) { res.status(200).json(duplicate); return; }
      res.status(409).json({ error: 'This transaction ID has already been submitted.' }); return;
    }
    throw error;
  }
});

router.get('/payments/mine', requireAuth, requireRole('BUSINESS'), async (req, res) => {
  const business = await prisma.businessProfile.findUnique({ where: { userId: req.user!.userId }, select: { id: true } });
  if (!business) { res.status(404).json({ error: 'Business profile not found.' }); return; }
  res.json(await prisma.subscriptionPayment.findMany({ where: { businessId: business.id }, orderBy: { createdAt: 'desc' }, take: 20 }));
});

router.get('/payments', requireAuth, requireRole('ADMIN'), async (_req, res) => {
  res.json(await prisma.subscriptionPayment.findMany({
    include: { business: { select: { id: true, name: true, countryCode: true, user: { select: { publicId: true } } } }, verifiedBy: { select: { email: true } }, subscription: true },
    orderBy: { createdAt: 'desc' }, take: 500,
  }));
});

router.post('/payments/:id/decision', requireAuth, requireRole('ADMIN'), async (req: Request, res: Response) => {
  const parsed = PaymentDecisionSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  const paymentId = String(req.params.id);
  const payment = await prisma.subscriptionPayment.findUnique({ where: { id: paymentId }, include: { business: { select: { userId: true, name: true } } } });
  if (!payment) { res.status(404).json({ error: 'Payment submission not found.' }); return; }
  if (payment.status !== 'PENDING') { res.status(409).json({ error: 'This payment submission has already been reviewed.' }); return; }
  if (parsed.data.action === 'REJECT') {
    const result = await prisma.subscriptionPayment.updateMany({ where: { id: paymentId, status: 'PENDING' }, data: { status: 'REJECTED', adminNote: parsed.data.adminNote || null, verifiedById: req.user!.userId, verifiedAt: new Date() } });
    if (!result.count) { res.status(409).json({ error: 'This payment submission has already been reviewed.' }); return; }
    await prisma.activityLog.create({ data: { userId: req.user!.userId, action: 'ADMIN_PAYMENT_REJECTED', metadata: { paymentId, businessId: payment.businessId, transactionId: payment.transactionId, reason: parsed.data.adminNote } } });
    res.json({ message: 'Payment submission rejected.' });
    return;
  }
  const months = payment.plan === 'YEARLY' ? 12 : 1;
  const now = new Date();
  const result = await prisma.$transaction(async (tx) => {
    const claim = await tx.subscriptionPayment.updateMany({ where: { id: paymentId, status: 'PENDING' }, data: { status: 'APPROVED', adminNote: parsed.data.adminNote || null, verifiedById: req.user!.userId, verifiedAt: now } });
    if (!claim.count) throw new Error('PAYMENT_ALREADY_REVIEWED');
    const current = await tx.businessSubscription.findFirst({ where: { businessId: payment.businessId, status: { in: ['ACTIVE', 'TRIALING'] }, endDate: { gt: now } }, orderBy: { endDate: 'desc' } });
    if (current?.status === 'TRIALING') await tx.businessSubscription.update({ where: { id: current.id }, data: { status: 'EXPIRED', endDate: now } });
    const startDate = current?.status === 'ACTIVE' ? current.endDate : now;
    const subscription = await tx.businessSubscription.create({ data: { businessId: payment.businessId, status: 'ACTIVE', plan: payment.plan, price: payment.amount, currency: payment.currency, startDate, endDate: addMonths(startDate, months) } });
    await tx.subscriptionPayment.update({ where: { id: paymentId }, data: { subscriptionId: subscription.id } });
    return subscription;
  }).catch((error) => {
    if (error instanceof Error && error.message === 'PAYMENT_ALREADY_REVIEWED') return null;
    throw error;
  });
  if (!result) { res.status(409).json({ error: 'This payment submission has already been reviewed.' }); return; }
  await prisma.activityLog.create({ data: { userId: req.user!.userId, action: 'ADMIN_PAYMENT_APPROVED', metadata: { paymentId, businessId: payment.businessId, subscriptionId: result.id, previousStatus: 'PENDING', newStatus: 'APPROVED' } } });
  res.json({ message: 'Payment approved and subscription activated.', subscription: result });
});
export default router;
