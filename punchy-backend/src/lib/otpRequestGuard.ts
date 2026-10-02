import crypto from 'crypto';
import bcrypt from 'bcryptjs';

export const OTP_RESEND_COOLDOWN_SECONDS = 60;

const requestsInFlight = new Set<string>();

export class OtpRequestThrottledError extends Error {
  constructor(public readonly retryAfterSeconds: number) {
    super('Please wait before requesting another verification code.');
    this.name = 'OtpRequestThrottledError';
  }
}

export function otpCooldownRemainingSeconds(
  lastIssuedAt: Date | null | undefined,
  nowMs = Date.now(),
): number {
  if (!lastIssuedAt) return 0;
  const elapsedMs = nowMs - lastIssuedAt.getTime();
  return Math.max(0, Math.ceil(OTP_RESEND_COOLDOWN_SECONDS - elapsedMs / 1000));
}

export async function withOtpRequestGuard<T>(key: string, action: () => Promise<T>): Promise<T> {
  if (requestsInFlight.has(key)) throw new OtpRequestThrottledError(OTP_RESEND_COOLDOWN_SECONDS);
  requestsInFlight.add(key);
  try {
    return await action();
  } finally {
    requestsInFlight.delete(key);
  }
}

export function generateSixDigitOtp(): string {
  return crypto.randomInt(100000, 1000000).toString();
}

export async function isOtpValid(options: {
  candidate: string;
  hash: string;
  expiresAt: Date;
  attempts: number;
  maxAttempts: number;
  now?: Date;
}): Promise<boolean> {
  const now = options.now ?? new Date();
  if (options.expiresAt < now || options.attempts >= options.maxAttempts) return false;
  return bcrypt.compare(options.candidate, options.hash);
}
