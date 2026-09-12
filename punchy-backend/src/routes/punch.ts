import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { notifyPunchEarned, notifyProgressMilestone } from '../lib/automatedNotifications';
import { PunchDomainError, PunchService } from '../services/punchService';

const router = Router();
const punchService = new PunchService(prisma);

const PunchSchema = z.object({ identifier: z.string().min(1) });

/**
 * POST /punch
 *
 * Called when a customer scans a QR code or taps an NFC tag.
 * Atomically validates the identifier, joins the card on first visit,
 * increments the punch count, and marks completion.
 */
router.post('/', requireAuth, requireRole('CUSTOMER'), async (req: Request, res: Response): Promise<void> => {
  const parsed = PunchSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }

  const customerId = req.user!.userId;
  let result;

  try {
    result = await punchService.record(customerId, parsed.data.identifier);
    const card = result.card;

    try {
      await notifyPunchEarned(customerId, result.newCount, card.punchesRequired);
      await notifyProgressMilestone(
        result.updated.id,
        customerId,
        card.business.name,
        card.business.category,
        card.rewardDescription,
        result.newCount,
        card.punchesRequired,
      );
    } catch (notificationError) {
      console.error('[Punch] push notification failed', notificationError);
    }

    res.json({
      message: result.isNowComplete
        ? '🎉 Reward unlocked! Show this to redeem in-store.'
        : `Punch recorded! ${result.newCount}/${card.punchesRequired}`,
      punchCount: result.newCount,
      punchesRequired: card.punchesRequired,
      isCompleted: result.isNowComplete,
      isFirstVisit: result.isFirstVisit,
      customerCard: result.updated,
    });
  } catch (err: unknown) {
    if (err instanceof PunchDomainError) { res.status(err.statusCode).json({ error: err.message }); return; }
    throw err;
  }
});

export default router;
