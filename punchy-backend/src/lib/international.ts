import { CountryCode, parsePhoneNumberFromString } from 'libphonenumber-js';
// Package supplies the complete ISO-country to ISO-currency mapping.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const countryCurrencyMap = require('country-currency-map') as {
  getCountryByAbbreviation?: (country: string) => string | undefined;
  getCountry?: (country: string) => { currency?: string } | undefined;
};
const countryMap = require('country-currency-map/lib/countryMap') as Record<string, { abbreviation: string; currency?: string }>;

export const COUNTRY_CURRENCIES: Record<string, string> = {
  PK: 'PKR', GB: 'GBP', AE: 'AED', US: 'USD', CA: 'CAD', AU: 'AUD',
  DE: 'EUR', FR: 'EUR', ES: 'EUR', IT: 'EUR', NL: 'EUR', SA: 'SAR',
  IN: 'INR', TR: 'TRY', SG: 'SGD', MY: 'MYR', ZA: 'ZAR',
};


export function isSupportedCountry(countryCode?: string | null): countryCode is string {
  const code = countryCode?.trim().toUpperCase();
  if (!code || !/^[A-Z]{2}$/.test(code)) return false;
  const countryName = countryCurrencyMap.getCountryByAbbreviation?.(code);
  return Boolean(countryName && countryCurrencyMap.getCountry?.(countryName)?.currency);
}
export function currencyForCountry(countryCode?: string | null): string {
  const code = (countryCode || 'PK').trim().toUpperCase();
  const countryName = countryCurrencyMap.getCountryByAbbreviation?.(code);
  return countryCurrencyMap.getCountry?.(countryName || '')?.currency || COUNTRY_CURRENCIES[code] || 'USD';
}

export type SupportedCountry = { code: string; name: string; flag: string; currencyCode: string };

function flagForCountry(code: string): string {
  return [...code.toUpperCase()].map(letter => String.fromCodePoint(127397 + letter.charCodeAt(0))).join('');
}

export function supportedCountries(): SupportedCountry[] {
  return Object.entries(countryMap)
    .filter(([, country]) => /^[A-Z]{2}$/.test(country.abbreviation || ''))
    .map(([name, country]) => ({ code: country.abbreviation, name, flag: flagForCountry(country.abbreviation), currencyCode: currencyForCountry(country.abbreviation) }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export function normalizeBusinessPhone(phone: string, countryCode: string): string | null {
  const number = parsePhoneNumberFromString(phone.trim(), countryCode.trim().toUpperCase() as CountryCode);
  return number?.isValid() ? number.number : null;
}

export type GeoPoint = { type: 'Point'; coordinates: [number, number] };

/** Geocode during onboarding. A failed lookup is non-fatal: the address remains saved. */
export async function geocodeAddress(address: string): Promise<{ point: GeoPoint; city?: string; countryCode?: string; countryName?: string } | null> {
  if (!address.trim()) return null;
  try {
    const response = await fetch(`https://nominatim.openstreetmap.org/search?format=jsonv2&addressdetails=1&limit=1&q=${encodeURIComponent(address)}`, {
      headers: { 'User-Agent': 'Punchy/1.0 (business-location-geocoding)' },
    });
    if (!response.ok) return null;
    const matches = await response.json() as Array<{ lon: string; lat: string; address?: { country_code?: string; country?: string; city?: string; town?: string; village?: string; municipality?: string; county?: string } }>;
    const match = matches[0];
    const lng = Number(match?.lon); const lat = Number(match?.lat);
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) return null;
    return { point: { type: 'Point', coordinates: [lng, lat] }, city: match.address?.city || match.address?.town || match.address?.village || match.address?.municipality || match.address?.county, countryCode: match.address?.country_code?.toUpperCase(), countryName: match.address?.country };
  } catch { return null; }
}

type ReverseGeocodeResult = { city?: string; countryCode?: string; countryName?: string } | null;
const reverseGeocodeCache = new Map<string, { value: NonNullable<ReverseGeocodeResult>; expiresAt: number }>();
const reverseGeocodePending = new Map<string, Promise<ReverseGeocodeResult>>();
const REVERSE_GEOCODE_TTL_MS = 15 * 60_000;
const REVERSE_GEOCODE_CACHE_LIMIT = 512;

/** Resolve a customer's current GPS point into the city and country used by Explore. */
export async function reverseGeocodeLocation(latitude: number, longitude: number): Promise<ReverseGeocodeResult> {
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;
  // City/country resolution is stable at this precision. Reuse recent results
  // across Explore visits and coalesce simultaneous identical point lookups.
  const cacheKey = `${latitude.toFixed(4)},${longitude.toFixed(4)}`;
  const now = Date.now();
  const cached = reverseGeocodeCache.get(cacheKey);
  if (cached && cached.expiresAt > now) return cached.value;
  if (cached) reverseGeocodeCache.delete(cacheKey);
  const inFlight = reverseGeocodePending.get(cacheKey);
  if (inFlight) return inFlight;

  const lookup = (async (): Promise<ReverseGeocodeResult> => {
  try {
    const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1&lat=${latitude}&lon=${longitude}`, {
      headers: { 'User-Agent': 'Punchy/1.0 (customer-location-discovery)' },
    });
    if (!response.ok) return null;
    const match = await response.json() as { address?: { country_code?: string; country?: string; city?: string; town?: string; village?: string; municipality?: string; county?: string } };
    const address = match.address;
    const result = {
      city: address?.city || address?.town || address?.village || address?.municipality || address?.county,
      countryCode: address?.country_code?.toUpperCase(),
      countryName: address?.country,
    };
    if (result.city || result.countryCode) {
      if (reverseGeocodeCache.size >= REVERSE_GEOCODE_CACHE_LIMIT) {
        reverseGeocodeCache.delete(reverseGeocodeCache.keys().next().value!);
      }
      reverseGeocodeCache.set(cacheKey, { value: result, expiresAt: Date.now() + REVERSE_GEOCODE_TTL_MS });
    }
    return result;
  } catch { return null; }
  })();
  reverseGeocodePending.set(cacheKey, lookup);
  try {
    return await lookup;
  } finally {
    reverseGeocodePending.delete(cacheKey);
  }
}
export async function ensureBusinessLocationIndex(prisma: { $runCommandRaw: (command: object) => Promise<unknown> }): Promise<void> {
  await prisma.$runCommandRaw({
    createIndexes: 'BusinessProfile',
    indexes: [{ key: { location: '2dsphere' }, name: 'business_location_2dsphere', sparse: true }],
  }).catch((error: unknown) => console.warn('Unable to ensure business location index:', error));
}
