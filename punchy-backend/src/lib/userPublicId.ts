import crypto from 'crypto';

import prisma from './prisma';

const pendingPublicIds = new Map<string, Promise<string>>();

export async function uniquePublicId(): Promise<string> {
  for (;;) {
    const value = String(crypto.randomInt(100000, 1000000));
    if (!(await prisma.user.findUnique({ where: { publicId: value }, select: { id: true } }))) {
      return value;
    }
  }
}

/** Backfills immutable public IDs for accounts created before publicId existed. */
export function ensureUserPublicId(userId: string, currentPublicId?: string | null): Promise<string> {
  if (currentPublicId?.trim()) return Promise.resolve(currentPublicId);

  const pending = pendingPublicIds.get(userId);
  if (pending) return pending;

  const operation = (async () => {
    const latest = await prisma.user.findUnique({
      where: { id: userId },
      select: { publicId: true },
    });
    if (!latest) throw new Error('User not found while assigning public ID');
    if (latest.publicId?.trim()) return latest.publicId;

    const publicId = await uniquePublicId();
    await prisma.user.update({ where: { id: userId }, data: { publicId } });
    return publicId;
  })().finally(() => pendingPublicIds.delete(userId));

  pendingPublicIds.set(userId, operation);
  return operation;
}
