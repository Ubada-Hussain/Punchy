import test from 'node:test';
import assert from 'node:assert/strict';

import { notificationVisibilityWhere } from '../src/lib/notificationInbox';

test('business inbox includes broadcasts, business announcements, and direct notifications', () => {
  const where = notificationVisibilityWhere('business-user', 'BUSINESS');
  assert.deepEqual(where, {
    sentAt: { not: null },
    OR: [
      { targetType: 'ALL' },
      { targetType: 'BUSINESSES' },
      { targetType: 'USER', targetId: 'business-user' },
    ],
  });
});

test('customer inbox includes joined-business and direct notifications only', () => {
  const where = notificationVisibilityWhere('customer-user', 'CUSTOMER', ['business-a']);
  assert.deepEqual(where, {
    sentAt: { not: null },
    OR: [
      { targetType: 'ALL' },
      { targetType: 'CUSTOMERS', creator: { role: 'ADMIN' } },
      { targetType: 'CUSTOMERS', createdBy: { in: ['business-a'] } },
      { targetType: 'USER', targetId: 'customer-user' },
    ],
  });
});
