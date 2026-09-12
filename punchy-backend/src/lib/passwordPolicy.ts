import { z } from 'zod';

export const strongPassword = z.string()
  .min(8)
  .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/, 'Password must be at least 8 characters and include an uppercase letter, lowercase letter, number, and symbol.');
