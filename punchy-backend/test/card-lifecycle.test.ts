import test from 'node:test';
import assert from 'node:assert/strict';
import { daysUntilExpiry, expiryReminderCopy, EXPIRY_REMINDER_DAYS } from '../src/services/cardLifecycleService';

test('expiry checkpoints are exactly one week, three days, and one day', () => {
  assert.deepEqual(EXPIRY_REMINDER_DAYS, [7, 3, 1]);
  const now = new Date('2026-09-16T12:00:00.000Z');
  assert.equal(daysUntilExpiry(new Date('2026-09-23T11:59:59.000Z'), now), 7);
  assert.equal(daysUntilExpiry(new Date('2026-09-16T11:59:59.000Z'), now), 0);
});

test('expiry reminder tells an incomplete customer how many punches remain', () => {
  const copy = expiryReminderCopy({
    businessName: 'The Cozy Spot', cardTitle: 'Loyalty Card', days: 7,
    punchCount: 6, punchesRequired: 10, isCompleted: false, rewardDescription: 'reward',
  });
  assert.equal(copy.title, 'Loyalty Card expires in 7 days');
  assert.match(copy.body, /6\/10/);
  assert.match(copy.body, /4 more punches/);
});

test('completed cards keep the reward message after expiry', () => {
  const copy = expiryReminderCopy({
    businessName: 'The Cozy Spot', cardTitle: 'Loyalty Card', days: 1,
    punchCount: 10, punchesRequired: 10, isCompleted: true, rewardDescription: 'reward',
  });
  assert.match(copy.body, /is ready/);
  assert.doesNotMatch(copy.body, /more punches/);
});
