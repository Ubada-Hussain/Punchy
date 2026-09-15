import { z } from 'zod';

const schema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export function parsePagination(query: unknown) {
  const parsed = schema.safeParse(query);
  if (!parsed.success) return { page: 1, limit: 20, error: 'page must be a positive integer and limit must be between 1 and 100' };
  return { ...parsed.data, error: undefined };
}
