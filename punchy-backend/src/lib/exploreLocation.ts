export type ExploreLocation = { city?: string; countryCode?: string } | null;

/** Filter discovery results using the current GPS reverse-geocode result. */
export function filterExploreBusinesses<T extends {
  city?: string | null;
  countryCode?: string | null;
  locations?: unknown;
}>(businesses: T[], location: ExploreLocation, scope: 'city' | 'country'): T[] {
  if (!location) return businesses;
  if (scope === 'country') {
    const countryCode = location.countryCode?.trim().toUpperCase();
    return countryCode
      ? businesses.filter((business) => business.countryCode?.trim().toUpperCase() === countryCode)
      : businesses;
  }
  const city = location.city?.trim().toLocaleLowerCase();
  if (!city) return businesses;
  return businesses.filter((business) => {
    const locations = Array.isArray(business.locations) ? business.locations : [];
    const locationCities = locations.flatMap((item) =>
      item && typeof item === 'object' && 'city' in item && typeof item.city === 'string'
        ? [item.city]
        : [],
    );
    return [business.city, ...locationCities].some((businessCity) =>
      businessCity?.trim().toLocaleLowerCase() === city,
    );
  });
}
