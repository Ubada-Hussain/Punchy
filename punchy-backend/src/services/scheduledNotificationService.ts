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
    const result = await sendNotification({
      userId: notification.targetType === 'USER' ? notification.targetId ?? undefined : undefined,
      targetRole: notification.targetType === 'CUSTOMERS' ? 'CUSTOMER' : notification.targetType === 'BUSINESSES' ? 'BUSINESS' : 'ALL',
      title: notification.title,
      body: notification.body,
    });
    if (result.success) {
      await prisma.notification.update({ where: { id: notification.id }, data: { sentAt: new Date() } });
      delivered += 1;
    }
  }
  return delivered;
}
