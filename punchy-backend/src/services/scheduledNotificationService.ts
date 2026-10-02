import prisma from '../lib/prisma';
import { sendNotification } from '../lib/notifications';

let lastCustomerReminderDay: string | null = null;
let customerReminderInFlight = false;

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
      await sendNotification({ userIds: customerIds, title: notification.title, body: notification.body });
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
  const dayKey = `${now.getUTCFullYear()}-${now.getUTCMonth()}-${now.getUTCDate()}`;
  if (lastCustomerReminderDay === dayKey || customerReminderInFlight) return 0;
  customerReminderInFlight = true;
  try {
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
  const customerIds = eligibleCustomers.map((customer) => customer.id);
  if (customerIds.length === 0) {
    lastCustomerReminderDay = dayKey;
    return 0;
  }

  const existingNotifications = await prisma.notification.findMany({
    where: {
      targetType: 'USER',
      targetId: { in: customerIds },
      title,
      createdAt: { gte: todayStart },
    },
    select: { targetId: true },
  });
  const alreadyNotified = new Set(existingNotifications.map((item) => item.targetId));
  const pendingIds = customerIds.filter((customerId) => !alreadyNotified.has(customerId));
  if (pendingIds.length) {
    await prisma.notification.createMany({
      data: pendingIds.map((targetId) => ({
        targetType: 'USER' as const,
        targetId,
        title,
        body,
        createdBy: admin.id,
        sentAt: new Date(),
      })),
    });
    await sendNotification({ userIds: pendingIds, title, body });
  }
  lastCustomerReminderDay = dayKey;
  return pendingIds.length;
  } finally {
    customerReminderInFlight = false;
  }
}
