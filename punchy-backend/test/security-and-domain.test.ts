import test from 'node:test';
import assert from 'node:assert/strict';
import { strongPassword } from '../src/lib/passwordPolicy';
import { createRateLimiter } from '../src/middleware/rateLimit';
import { PunchDomainError, PunchService } from '../src/services/punchService';

test('strong password policy rejects weak passwords and accepts compliant passwords', () => {
  assert.equal(strongPassword.safeParse('password').success, false);
  assert.equal(strongPassword.safeParse('Password1!').success, true);
  assert.equal(strongPassword.safeParse('PASSWORD1!').success, false);
});

test('rate limiter returns 429 after the configured budget', () => {
  const limiter = createRateLimiter({ windowMs: 60_000, max: 1, name: 'test' });
  const response = { headers: new Map<string, string>(), statusCode: 200, body: null as unknown,
    setHeader(name: string, value: string | number) { this.headers.set(name, String(value)); return this; },
    status(code: number) { this.statusCode = code; return this; },
    json(body: unknown) { this.body = body; return this; },
  };
  const request = { ip: '127.0.0.1', path: '/login', socket: { remoteAddress: '127.0.0.1' } };
  let nextCalls = 0;
  limiter(request as never, response as never, () => { nextCalls += 1; });
  limiter(request as never, response as never, () => { nextCalls += 1; });
  assert.equal(nextCalls, 1);
  assert.equal(response.statusCode, 429);
});

test('punch service rejects an unknown identifier before writing data', async () => {
  const fakeDb = { punchMethod: { findUnique: async () => null } };
  const service = new PunchService(fakeDb as never);
  await assert.rejects(() => service.record('customer-1', 'missing'), (error: unknown) => {
    return error instanceof PunchDomainError && error.statusCode === 404;
  });
});
