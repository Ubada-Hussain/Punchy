import prisma from './prisma';
import { sendNotification } from './notifications';
import { generateProgressNotification } from './notificationCategories';

async function systemCreatorId(): Promise<string | null> {
  const admin = await prisma.user.findFirst({ where: { role: 'ADMIN' }, select: { id: true } });
  return admin?.id ?? null;
}

export async function notifyProgressMilestone(
  customerCardId: string,
  customerId: string,
  businessName: string,
  category: string,
  rewardDescription: string,
  punchCount: number,
  punchesRequired: number,
): Promise<void> {
  const remaining = punchesRequired - punchCount;
  if (remaining < 1 || remaining > 3) return;
  const createdBy = await systemCreatorId();
  if (!createdBy) return;
  const customerCard = await prisma.customerCard.findUnique({ where: { id: customerCardId }, select: { joinedAt: true } });
  if (!customerCard) return;
  const latestRedemption = await prisma.redemption.findFirst({ where: { customerCardId }, orderBy: { redeemedAt: 'desc' }, select: { redeemedAt: true } });
  const cycleStart = latestRedemption?.redeemedAt ?? customerCard.joinedAt;
  const sourceKey = `PROGRESS:${customerCardId}:${remaining}:${cycleStart.toISOString()}`;
  const { title, body } = generateProgressNotification(businessName, category, rewardDescription, remaining);
  const existing = await prisma.notification.findFirst({ where: { targetType: 'USER', targetId: customerId, createdBy, title, body, createdAt: { gte: cycleStart } } });
  if (existing) return;
  const notification = await prisma.notification.create({ data: { targetType: 'USER', targetId: customerId, title, body, createdBy, sentAt: new Date() } });
  try {
    await sendNotification({ userId: customerId, title: notification.title, body: notification.body, data: { sourceKey } });
  } catch (error) {
    console.error('[Automated notification] progress push failed', error);
  }
}

export async function notifyPunchEarned(customerId: string, count: number, required: number): Promise<void> {
  const createdBy = await systemCreatorId();
  if (!createdBy) return;
  const title = 'Punch recorded 🎉';
  const body = `Congratulations! You received 1 more punch. You now have ${count}/${required} punches.`;
  const notification = await prisma.notification.create({ data: { targetType: 'USER', targetId: customerId, title, body, createdBy, sentAt: new Date() } });
  try {
    await sendNotification({ userId: customerId, title: notification.title, body: notification.body });
  } catch (error) {
    console.error('[Automated notification] punch push failed', error);
  }
}
