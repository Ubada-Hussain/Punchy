import { z } from 'zod';

export const CardHexColorSchema = z.string()
  .regex(/^#[0-9A-Fa-f]{6}$/, 'Card color must be #RRGGBB')
  .transform((color) => color.toUpperCase());

// Existing documents remain readable without a migration. Legacy clients can
// still submit their original theme name/index; new clients write primaryColor.
export const CardVisualStyleSchema = z.object({
  primaryColor: CardHexColorSchema.optional(),
}).catchall(z.json());
