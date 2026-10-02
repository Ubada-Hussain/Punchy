import test from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcryptjs';
import { buildOtpEmail } from '../src/lib/email';
import {
  generateSixDigitOtp,
  isOtpValid,
  OtpRequestThrottledError,
  otpCooldownRemainingSeconds,
  withOtpRequestGuard,
} from '../src/lib/otpRequestGuard';

test('signup and delete emails are lightweight, purpose-specific, and keep OTP out of the subject', () => {
  const otp = '482913';
  const signup = buildOtpEmail(otp, 'SIGNUP_VERIFICATION');
  const deletion = buildOtpEmail(otp, 'DELETE_ACCOUNT');

  assert.equal(signup.subject, 'Your Punchy verification code');
  assert.equal(deletion.subject, 'Confirm your Punchy account deletion');
  assert.equal(signup.subject.includes(otp), false);
  assert.equal(deletion.subject.includes(otp), false);
  assert.match(signup.html, /Verify your Punchy account/);
  assert.match(deletion.html, /Confirm your Punchy account deletion/);
  assert.match(signup.text, /expires in 10 minutes/);
  assert.match(deletion.text, /expires in 10 minutes/);
  assert.equal(/<img\b|https?:\/\//i.test(signup.html), false);
  assert.equal(/<img\b|https?:\/\//i.test(deletion.html), false);
});

test('OTP generation remains server-side and exactly six numeric digits', () => {
  for (let index = 0; index < 100; index += 1) {
    assert.match(generateSixDigitOtp(), /^\d{6}$/);
  }
});

test('signup and delete OTP values cannot authorize one another', async () => {
  const signupOtp = '123456';
  const deleteOtp = '654321';
  const signupHash = await bcrypt.hash(signupOtp, 4);
  const deleteHash = await bcrypt.hash(deleteOtp, 4);
  const common = { expiresAt: new Date(Date.now() + 60_000), attempts: 0, maxAttempts: 5 };

  assert.equal(await isOtpValid({ ...common, candidate: signupOtp, hash: signupHash }), true);
  assert.equal(await isOtpValid({ ...common, candidate: deleteOtp, hash: deleteHash }), true);
  assert.equal(await isOtpValid({ ...common, candidate: deleteOtp, hash: signupHash }), false);
  assert.equal(await isOtpValid({ ...common, candidate: signupOtp, hash: deleteHash }), false);
});

test('invalid, expired, and attempt-limited OTPs are rejected', async () => {
  const hash = await bcrypt.hash('123456', 4);
  const future = new Date(Date.now() + 60_000);
  assert.equal(await isOtpValid({ candidate: '000000', hash, expiresAt: future, attempts: 0, maxAttempts: 5 }), false);
  assert.equal(await isOtpValid({ candidate: '123456', hash, expiresAt: new Date(Date.now() - 1), attempts: 0, maxAttempts: 5 }), false);
  assert.equal(await isOtpValid({ candidate: '123456', hash, expiresAt: future, attempts: 5, maxAttempts: 5 }), false);
});

test('resend cooldown reports remaining time and later permits resend', () => {
  const issuedAt = new Date('2026-09-28T12:00:00.000Z');
  assert.equal(otpCooldownRemainingSeconds(issuedAt, issuedAt.getTime() + 10_000), 50);
  assert.equal(otpCooldownRemainingSeconds(issuedAt, issuedAt.getTime() + 60_000), 0);
});

test('duplicate taps cannot run the same OTP request concurrently', async () => {
  let releaseFirst!: () => void;
  const first = withOtpRequestGuard('signup:test@example.com', async () => {
    await new Promise<void>((resolve) => { releaseFirst = resolve; });
  });

  await assert.rejects(
    () => withOtpRequestGuard('signup:test@example.com', async () => undefined),
    (error: unknown) => error instanceof OtpRequestThrottledError,
  );
  releaseFirst();
  await first;

  await assert.doesNotReject(() => withOtpRequestGuard('signup:test@example.com', async () => undefined));
});
