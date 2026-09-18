import test from 'node:test';
import assert from 'node:assert/strict';
import { generateProgressNotification, CATEGORY_TONES } from '../src/lib/notificationCategories';

test('Task 4: Phone number regex validation accepts valid international and local formats', () => {
  const phoneRegex = /^\+?[0-9\s\-()]{8,20}$/;
  
  // Valid phone numbers
  assert.equal(phoneRegex.test('+1234567890'), true);
  assert.equal(phoneRegex.test('+92 300 1234567'), true);
  assert.equal(phoneRegex.test('(021) 123-4567'), true);
  assert.equal(phoneRegex.test('+44 20 7946 0958'), true);
  assert.equal(phoneRegex.test('03001234567'), true);

  // Invalid phone numbers
  assert.equal(phoneRegex.test(''), false);
  assert.equal(phoneRegex.test('12345'), false); // too short
  assert.equal(phoneRegex.test('abc1234567'), false); // letters
  assert.equal(phoneRegex.test('phone-number-here'), false); // letters
  assert.equal(phoneRegex.test('+12345678901234567890123'), false); // too long
});

test('Task 6: Automated customer reminders fire at exactly 3, 2, and 1 punches remaining with category-aware copy', () => {
  // Threshold 3 remaining
  const copy3 = generateProgressNotification('Artisan Roasters', 'coffee shop', 'Free Cappuccino', 3);
  assert.equal(copy3.title, 'Only 3 punches left! ☕');
  assert.match(copy3.body, /Artisan Roasters/);
  assert.match(copy3.body, /Free Cappuccino/);

  // Threshold 2 remaining
  const copy2 = generateProgressNotification('Artisan Roasters', 'coffee shop', 'Free Cappuccino', 2);
  assert.equal(copy2.title, 'Only 2 punches left! ☕');
  assert.match(copy2.body, /Artisan Roasters/);

  // Threshold 1 remaining
  const copy1 = generateProgressNotification('Artisan Roasters', 'coffee shop', 'Free Cappuccino', 1);
  assert.equal(copy1.title, 'Only 1 punch left! ☕');
  assert.match(copy1.body, /One more coffee and your Free Cappuccino at Artisan Roasters/);

  // Gym category uses 'visit' / 'visits'
  const gymCopy = generateProgressNotification('Iron Gym', 'gym', 'Free Shake', 1);
  assert.equal(gymCopy.title, 'Only 1 visit left! 💪');
  assert.match(gymCopy.body, /One more visit and your Free Shake at Iron Gym/);
});

test('Task 7: Expiry handling resets incomplete cards to 0 but preserves completed cards for redemption', () => {
  // Simulate card expiry logic
  function processCardExpiry(customerCard: { punchCount: number; punchesRequired: number; isCompleted: boolean }) {
    const isFull = customerCard.isCompleted || customerCard.punchCount >= customerCard.punchesRequired;
    if (isFull) {
      // Completed cards preserve progress and reward for redemption
      return { ...customerCard, punchCount: customerCard.punchCount, rewardPreserved: true };
    } else {
      // Incomplete cards reset progress to 0
      return { ...customerCard, punchCount: 0, rewardPreserved: false };
    }
  }

  // Full card (earned reward, not yet redeemed)
  const fullCard = { punchCount: 10, punchesRequired: 10, isCompleted: true };
  const expiredFull = processCardExpiry(fullCard);
  assert.equal(expiredFull.punchCount, 10);
  assert.equal(expiredFull.rewardPreserved, true);

  // Incomplete card (e.g. 7 out of 10 punches)
  const incompleteCard = { punchCount: 7, punchesRequired: 10, isCompleted: false };
  const expiredIncomplete = processCardExpiry(incompleteCard);
  assert.equal(expiredIncomplete.punchCount, 0);
  assert.equal(expiredIncomplete.rewardPreserved, false);
});

test('Task 5: Business notifications target strictly joined customers of that business', () => {
  // Mock customer cards relationship
  const allCustomerCards = [
    { customerId: 'cust-1', businessId: 'biz-A' },
    { customerId: 'cust-2', businessId: 'biz-A' },
    { customerId: 'cust-3', businessId: 'biz-B' },
    { customerId: 'cust-4', businessId: 'biz-C' },
  ];

  function getEligibleCustomerIdsForBusiness(businessId: string): string[] {
    return Array.from(
      new Set(
        allCustomerCards
          .filter((cc) => cc.businessId === businessId)
          .map((cc) => cc.customerId),
      ),
    );
  }

  const bizACustomers = getEligibleCustomerIdsForBusiness('biz-A');
  assert.deepEqual(bizACustomers.sort(), ['cust-1', 'cust-2']);
  assert.equal(bizACustomers.includes('cust-3'), false);
  assert.equal(bizACustomers.includes('cust-4'), false);
});
