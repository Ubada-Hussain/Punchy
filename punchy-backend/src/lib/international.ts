import { CountryCode, parsePhoneNumberFromString } from 'libphonenumber-js';
// Package supplies the complete ISO-country to ISO-currency mapping.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const countryCurrencyMap = require('country-currency-map') as {
  getCountryByAbbreviation?: (country: string) => string | undefined;
  getCountry?: (country: string) => { currency?: string } | undefined;
};

export const COUNTRY_CURRENCIES: Record<string, string> = {
  PK: 'PKR', GB: 'GBP', AE: 'AED', US: 'USD', CA: 'CAD', AU: 'AUD',
  DE: 'EUR', FR: 'EUR', ES: 'EUR', IT: 'EUR', NL: 'EUR', SA: 'SAR',
  IN: 'INR', TR: 'TRY', SG: 'SGD', MY: 'MYR', ZA: 'ZAR',
};

export function currencyForCountry(countryCode?: string | null): string {
  const code = (countryCode || 'PK').trim().toUpperCase();
  const countryName = countryCurrencyMap.getCountryByAbbreviation?.(code);
  return countryCurrencyMap.getCountry?.(countryName || '')?.currency || COUNTRY_CURRENCIES[code] || 'USD';
}

export function normalizeBusinessPhone(phone: string, countryCode: string): string | null {
  const number = parsePhoneNumberFromString(phone.trim(), countryCode.trim().toUpperCase() as CountryCode);
  return number?.isValid() ? number.number : null;
}

export type GeoPoint = { type: 'Point'; coordinates: [number, number] };

/** Geocode during onboarding. A failed lookup is non-fatal: the address remains saved. */
export async function geocodeAddress(address: string): Promise<{ point: GeoPoint; countryCode?: string } | null> {
  if (!address.trim()) return null;
  try {
    const response = await fetch(`https://nominatim.openstreetmap.org/search?format=jsonv2&addressdetails=1&limit=1&q=${encodeURIComponent(address)}`, {
      headers: { 'User-Agent': 'Punchy/1.0 (business-location-geocoding)' },
    });
    if (!response.ok) return null;
    const matches = await response.json() as Array<{ lon: string; lat: string; address?: { country_code?: string } }>;
    const match = matches[0];
    const lng = Number(match?.lon); const lat = Number(match?.lat);
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) return null;
    return { point: { type: 'Point', coordinates: [lng, lat] }, countryCode: match.address?.country_code?.toUpperCase() };
  } catch { return null; }
}

export async function ensureBusinessLocationIndex(prisma: { $runCommandRaw: (command: object) => Promise<unknown> }): Promise<void> {
  await prisma.$runCommandRaw({
    createIndexes: 'BusinessProfile',
    indexes: [{ key: { location: '2dsphere' }, name: 'business_location_2dsphere', sparse: true }],
  }).catch((error: unknown) => console.warn('Unable to ensure business location index:', error));
}
