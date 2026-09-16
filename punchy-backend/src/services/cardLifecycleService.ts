import prisma from '../lib/prisma';
import { sendNotification } from '../lib/notifications';

/** Reminder checkpoints are intentionally small and deterministic so a worker
 * can run frequently without spamming customers. */
export const EXPIRY_REMINDER_DAYS = [7, 3, 1] as const;

export function daysUntilExpiry(validUntil: Date, now = new Date()): number {
  return Math.max(0, Math.ceil((validUntil.getTime() - now.getTime()) / 86_400_000));
}

export function expiryReminderCopy(args: {
  businessName: string;
  cardTitle: string;
  days: number;
  punchCount: number;
  punchesRequired: number;
  isCompleted: boolean;
  rewardDescription: string;
}): { title: string; body: string } {
  const time = args.days === 1 ? '1 day' : `${args.days} days`;
  if (args.isCompleted || args.punchCount >= args.punchesRequired) {
    return {
      title: `${args.cardTitle} expires in ${time}`,
      body: `Your ${args.businessName} card is complete. Your ${args.rewardDescription} is ready—use it before the card expires.`,
    };
  }
  const remaining = Math.max(0, args.punchesRequired - args.punchCount);
  return {
    title: `${args.cardTitle} expires in ${time}`,
    body: `You have ${args.punchCount}/${args.punchesRequired} punches on your ${args.businessName} card. ${remaining} more ${remaining === 1 ? 'punch' : 'punches'} unlocks your ${args.rewardDescription}.`,
  };
}

async function systemCreatorId(): Promise<string | null> {
  const admin = await prisma.user.findFirst({ where: { role: 'ADMIN' }, select: { id: true } });
  return admin?.id ?? null;
}

async function notifyOnce(customerId: string, createdBy: string, title: string, body: string, sourceKey: string, since: Date): Promise<boolean> {
  const existing = await prisma.notification.findFirst({
    where: { targetType: 'USER', targetId: customerId, createdBy, title, createdAt: { gte: since } },
    select: { id: true },
  });
  if (existing) return false;
  const notification = await prisma.notification.create({
    data: { targetType: 'USER', targetId: customerId, title, body, createdBy, sentAt: new Date() },
  });
  try {
    await sendNotification({ userId: customerId, title: notification.title, body: notification.body, data: { sourceKey } });
  } catch (error) {
    console.error('[Card lifecycle] push notification failed', error);
  }
  return true;
}

/**
 * Sends expiry reminders and closes expired cards. Incomplete customer cards
 * are reset for a new cycle; completed cards stay completed so their reward is
 * not lost. Deletion is deliberately not performed here: a business can
 * extend the date and reactivate the card, while DELETE removes all relations.
 */
export async function processCardLifecycle(now = new Date()): Promise<{ reminders: number; expired: number; reset: number }> {
  const createdBy = await systemCreatorId();
  if (!createdBy) return { reminders: 0, expired: 0, reset: 0 };
  const cards = await prisma.loyaltyCard.findMany({
    where: { validUntil: { not: null } },
    include: {
      business: { select: { name: true } },
      customerCards: { select: { id: true, customerId: true, punchCount: true, isCompleted: true } },
    },
  });
  let reminders = 0;
  let expired = 0;
  let reset = 0;
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

  for (const card of cards) {
    if (!card.validUntil) continue;
    if (card.validUntil > now && card.isActive) {
      const days = daysUntilExpiry(card.validUntil, now);
      if (!EXPIRY_REMINDER_DAYS.includes(days as (typeof EXPIRY_REMINDER_DAYS)[number])) continue;
      for (const customerCard of card.customerCards) {
        const copy = expiryReminderCopy({
          businessName: card.business.name,
          cardTitle: card.title,
          days,
          punchCount: customerCard.punchCount,
          punchesRequired: card.punchesRequired,
          isCompleted: customerCard.isCompleted,
          rewardDescription: card.rewardDescription,
        });
        const sent = await notifyOnce(customerCard.customerId, createdBy, copy.title, copy.body, `CARD_EXPIRY:${card.id}:${days}`, today);
        if (sent) reminders += 1;
      }
      continue;
    }

    if (card.validUntil > now || !card.isActive) continue;
    // Only one worker gets to transition the card, preventing duplicate reset
    // and expiry notifications when multiple API instances are running.
    const transitioned = await prisma.loyaltyCard.updateMany({ where: { id: card.id, isActive: true }, data: { isActive: false } });
    if (transitioned.count !== 1) continue;
    expired += 1;
    for (const customerCard of card.customerCards) {
      const complete = customerCard.isCompleted || customerCard.punchCount >= card.punchesRequired;
      const title = complete ? `${card.title} expired — reward ready` : `${card.title} expired — progress reset`;
      const body = complete
        ? `Your ${card.business.name} card expired, but your completed ${card.rewardDescription} is still available.`
        : `Your ${card.business.name} card expired with ${customerCard.punchCount}/${card.punchesRequired} punches. Start a new cycle if the business reactivates it.`;
      await notifyOnce(customerCard.customerId, createdBy, title, body, `CARD_EXPIRED:${card.id}`, today);
      if (!complete && customerCard.punchCount !== 0) {
        await prisma.customerCard.update({ where: { id: customerCard.id }, data: { punchCount: 0, isCompleted: false } });
        reset += 1;
      }
    }
  }
  return { reminders, expired, reset };
}
