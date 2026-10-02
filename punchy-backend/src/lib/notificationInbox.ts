import { Prisma } from '@prisma/client';

import prisma from './prisma';

export function notificationVisibilityWhere(
  userId: string,
  role: string,
  allowedBusinessUserIds: string[] = [],
): Prisma.NotificationWhereInput {
  if (role === 'ADMIN') return { sentAt: { not: null } };

  if (role === 'CUSTOMER') {
    return {
      sentAt: { not: null },
      OR: [
        { targetType: 'ALL' },
        { targetType: 'CUSTOMERS', creator: { role: 'ADMIN' } },
        { targetType: 'CUSTOMERS', createdBy: { in: allowedBusinessUserIds } },
        { targetType: 'USER', targetId: userId },
      ],
    };
  }

  if (role === 'BUSINESS') {
    return {
      sentAt: { not: null },
      OR: [
        { targetType: 'ALL' },
        { targetType: 'BUSINESSES' },
        { targetType: 'USER', targetId: userId },
      ],
    };
  }

  return { sentAt: { not: null }, targetType: 'ALL' };
}

export async function notificationInboxWhere(
  userId: string,
  role: string,
): Promise<Prisma.NotificationWhereInput> {
  const [joinedCards, lastCleared, deletedEvents] = await Promise.all([
    role === 'CUSTOMER'
      ? prisma.customerCard.findMany({
          where: { customerId: userId },
          include: { card: { select: { business: { select: { userId: true } } } } },
        })
      : Promise.resolve([]),
    prisma.activityLog.findFirst({
      where: { userId, action: 'NOTIFICATIONS_CLEARED' },
      orderBy: { createdAt: 'desc' },
      select: { createdAt: true },
    }),
    prisma.activityLog.findMany({
      where: { userId, action: 'NOTIFICATION_DELETED' },
      orderBy: { createdAt: 'desc' },
      take: 500,
      select: { metadata: true },
    }),
  ]);
  const allowedBusinessUserIds = Array.from(
    new Set(joinedCards.map((item) => item.card.business.userId)),
  );
  const deletedIds = deletedEvents
    .map((event) => {
      const metadata = event.metadata as { notificationId?: unknown } | null;
      return typeof metadata?.notificationId === 'string' ? metadata.notificationId : null;
    })
    .filter((id): id is string => id !== null);

  return {
    AND: [
      notificationVisibilityWhere(userId, role, allowedBusinessUserIds),
      ...(lastCleared ? [{ createdAt: { gt: lastCleared.createdAt } }] : []),
      ...(deletedIds.length ? [{ id: { notIn: deletedIds } }] : []),
    ],
  };
}

export async function unreadNotificationCount(userId: string, role: string): Promise<number> {
  const [where, lastRead] = await Promise.all([
    notificationInboxWhere(userId, role),
    prisma.activityLog.findFirst({
      where: { userId, action: 'NOTIFICATIONS_READ' },
      orderBy: { createdAt: 'desc' },
      select: { createdAt: true },
    }),
  ]);

  return prisma.notification.count({
    where: {
      AND: [
        where,
        ...(lastRead ? [{ createdAt: { gt: lastRead.createdAt } }] : []),
      ],
    },
  });
}

export async function markNotificationsRead(userId: string, readThrough: Date): Promise<void> {
  const now = new Date();
  const safeReadThrough = readThrough > now ? now : readThrough;
  const lastRead = await prisma.activityLog.findFirst({
    where: { userId, action: 'NOTIFICATIONS_READ' },
    orderBy: { createdAt: 'desc' },
    select: { createdAt: true },
  });
  if (lastRead && lastRead.createdAt >= safeReadThrough) return;

  await prisma.activityLog.create({
    data: {
      userId,
      action: 'NOTIFICATIONS_READ',
      createdAt: safeReadThrough,
      metadata: { readThrough: safeReadThrough.toISOString() },
    },
  });
}
