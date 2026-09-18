import prisma from '../lib/prisma';
import { sendNotification } from '../lib/notifications';

/** Delivers due admin notifications. Safe to run repeatedly because sentAt is
 * checked and set after dispatch; production multi-instance deployments should
 * add a distributed lease/queue around this worker. */
export async function processScheduledNotifications(): Promise<number> {
  const due = await prisma.notification.findMany({
    where: { scheduledAt: { lte: new Date() }, sentAt: null },
    take: 50,
  });
  let delivered = 0;
  for (const notification of due) {
    const creator = await prisma.user.findUnique({ where: { id: notification.createdBy }, select: { role: true } });
    let result = { success: true };
    if (notification.targetType === 'CUSTOMERS' && creator?.role === 'BUSINESS') {
      // A business notification must reach only customers connected to that
      // business, including when it was scheduled for later delivery.
      const business = await prisma.businessProfile.findUnique({
        where: { userId: notification.createdBy },
        select: { loyaltyCards: { select: { customerCards: { select: { customerId: true } } } } },
      });
      const customerIds = Array.from(new Set(
        (business?.loyaltyCards ?? []).flatMap((card) => card.customerCards.map((cc) => cc.customerId)),
      ));
      for (const customerId of customerIds) {
        await sendNotification({ userId: customerId, title: notification.title, body: notification.body });
      }
    } else {
      result = await sendNotification({
        userId: notification.targetType === 'USER' ? notification.targetId ?? undefined : undefined,
        targetRole: notification.targetType === 'CUSTOMERS' ? 'CUSTOMER' : notification.targetType === 'BUSINESSES' ? 'BUSINESS' : 'ALL',
        title: notification.title,
        body: notification.body,
      });
    }
    if (result.success) {
      await prisma.notification.update({ where: { id: notification.id }, data: { sentAt: new Date() } });
      delivered += 1;
    }
  }
  return delivered;
}

export async function processDailyCustomerReminders(now = new Date()): Promise<number> {
  const admin = await prisma.user.findFirst({ where: { role: 'ADMIN' }, select: { id: true } });
  if (!admin) return 0;

  const todayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const title = "Don't forget to check your Punchy cards today! ☕";
  const body = 'Open Punchy to view your stamp progress, unlock rewards, and discover new offers.';

  const eligibleCustomers = await prisma.user.findMany({
    where: {
      role: 'CUSTOMER',
      isBlocked: false,
      pushNotificationsEnabled: true,
      customerCards: { some: {} },
    },
    select: { id: true },
  });

  let count = 0;
  for (const customer of eligibleCustomers) {
    const existing = await prisma.notification.findFirst({
      where: {
        targetType: 'USER',
        targetId: customer.id,
        title,
        createdAt: { gte: todayStart },
      },
      select: { id: true },
    });
    if (existing) continue;

    await prisma.notification.create({
      data: {
        targetType: 'USER',
        targetId: customer.id,
        title,
        body,
        createdBy: admin.id,
        sentAt: new Date(),
      },
    });

    try {
      await sendNotification({
        userId: customer.id,
        title,
        body,
      });
    } catch (e) {
      console.error(`[Daily reminder] failed for user ${customer.id}`, e);
    }
    count += 1;
  }
  return count;
}
