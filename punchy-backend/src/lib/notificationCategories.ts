export type ProgressNotification = { title: string; body: string };

type CategoryTone = {
  emoji: string;
  phrase: (remaining: number) => string;
  unit: 'punch' | 'visit';
};

// Extend this table when new business categories are introduced. The engine
// never branches on category names outside this lookup.
export const CATEGORY_TONES: Record<string, CategoryTone> = {
  restaurant: { emoji: '🍽️', phrase: () => "You're almost at", unit: 'punch' },
  'coffee shop': { emoji: '☕', phrase: (r) => r === 1 ? 'One more coffee and' : "You're almost at", unit: 'punch' },
  café: { emoji: '☕', phrase: (r) => r === 1 ? 'One more visit and' : "You're almost at", unit: 'punch' },
  cafe: { emoji: '☕', phrase: (r) => r === 1 ? 'One more visit and' : "You're almost at", unit: 'punch' },
  salon: { emoji: '✨', phrase: () => "You're getting close to", unit: 'visit' },
  gym: { emoji: '💪', phrase: (r) => r === 1 ? 'One more visit and' : "You're almost at", unit: 'visit' },
  fitness: { emoji: '💪', phrase: (r) => r === 1 ? 'One more visit and' : "You're almost at", unit: 'visit' },
};

const fallbackTone: CategoryTone = { emoji: '🎁', phrase: (r) => r === 1 ? 'One more visit and' : "You're almost at", unit: 'punch' };

export function generateProgressNotification(
  businessName: string,
  category: string,
  rewardDescription: string,
  punchesRemaining: number,
): ProgressNotification {
  const remaining = Math.max(1, Math.round(punchesRemaining));
  const key = category.trim().toLowerCase();
  const tone = CATEGORY_TONES[key] ?? fallbackTone;
  const unit = tone.unit;
  const unitText = remaining === 1 ? unit : unit === 'punch' ? 'punches' : 'visits';
  const title = `Only ${remaining} ${unitText} left! ${tone.emoji}`;
  const body = `${tone.phrase(remaining)} your ${rewardDescription} at ${businessName}.`;
  return { title, body };
}
