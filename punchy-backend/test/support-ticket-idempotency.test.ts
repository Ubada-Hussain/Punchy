import test from 'node:test';
import assert from 'node:assert/strict';
import { supportTicketDedupeKey } from '../src/routes/tickets';

test('support ticket request id stays idempotent across retries', () => {
  const first = supportTicketDedupeKey('user-1', 'Need help', 'The scanner is not working.', 'request-123', 0);
  const retry = supportTicketDedupeKey('user-1', 'Need help', 'The scanner is not working.', 'request-123', 120_000);
  assert.equal(first, retry);
  assert.notEqual(first, supportTicketDedupeKey('user-1', 'Need help', 'The scanner is not working.', 'request-456', 0));
  assert.notEqual(first, supportTicketDedupeKey('user-2', 'Need help', 'The scanner is not working.', 'request-123', 0));
});

test('legacy clients deduplicate identical complaints within the same minute', () => {
  const first = supportTicketDedupeKey('user-1', 'Need help', 'The scanner is not working.', undefined, 61_000);
  const retry = supportTicketDedupeKey('user-1', 'Need help', 'The scanner is not working.', undefined, 119_999);
  const later = supportTicketDedupeKey('user-1', 'Need help', 'The scanner is not working.', undefined, 120_000);
  assert.equal(first, retry);
  assert.notEqual(first, later);
});
