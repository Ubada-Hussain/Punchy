import { Request, Response, NextFunction } from 'express';

type Bucket = { count: number; resetAt: number };

/**
 * Small dependency-free limiter for a single API instance. In a multi-instance
 * deployment this should be backed by Redis (the key format is intentionally
 * compatible with that migration).
 */
export function createRateLimiter(options: { windowMs: number; max: number; name: string }) {
  const buckets = new Map<string, Bucket>();
  let lastCleanup = 0;

  return (req: Request, res: Response, next: NextFunction): void => {
    const now = Date.now();
    if (now - lastCleanup > options.windowMs) {
      for (const [key, bucket] of buckets) if (bucket.resetAt <= now) buckets.delete(key);
      lastCleanup = now;
    }

    const identity = req.ip || req.socket.remoteAddress || 'unknown';
    const key = `${options.name}:${identity}:${req.path}`;
    const bucket = buckets.get(key);
    if (!bucket || bucket.resetAt <= now) {
      buckets.set(key, { count: 1, resetAt: now + options.windowMs });
      res.setHeader('RateLimit-Limit', options.max);
      res.setHeader('RateLimit-Remaining', options.max - 1);
      next();
      return;
    }

    bucket.count += 1;
    res.setHeader('RateLimit-Limit', options.max);
    res.setHeader('RateLimit-Remaining', Math.max(0, options.max - bucket.count));
    res.setHeader('Retry-After', Math.ceil((bucket.resetAt - now) / 1000));
    if (bucket.count > options.max) {
      res.status(429).json({ error: 'Too many requests. Please try again later.' });
      return;
    }
    next();
  };
}

export const authRateLimiter = createRateLimiter({ windowMs: 60_000, max: 30, name: 'auth' });
export const otpRateLimiter = createRateLimiter({ windowMs: 10 * 60_000, max: 8, name: 'otp' });
