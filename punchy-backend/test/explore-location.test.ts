import test from 'node:test';
import assert from 'node:assert/strict';
import { filterExploreBusinesses } from '../src/lib/exploreLocation';

const businesses = [
  { id: 'lahore', city: 'Lahore', countryCode: 'PK', locations: [] },
  { id: 'london', city: 'London', countryCode: 'GB', locations: [{ city: 'London' }] },
  { id: 'legacy-lahore', city: null, countryCode: 'PK', locations: [{ city: 'Lahore' }] },
  { id: 'new-york', city: 'New York', countryCode: 'US', locations: [] },
];

test('Explore city results follow the current GPS city, including legacy address city', () => {
  assert.deepEqual(
    filterExploreBusinesses(businesses, { city: 'London', countryCode: 'GB' }, 'city').map((b) => b.id),
    ['london'],
  );
  assert.deepEqual(
    filterExploreBusinesses(businesses, { city: 'lahore', countryCode: 'PK' }, 'city').map((b) => b.id),
    ['lahore', 'legacy-lahore'],
  );
});

test('Explore country results follow the current GPS country, independent of signup country', () => {
  assert.deepEqual(
    filterExploreBusinesses(businesses, { city: 'London', countryCode: 'gb' }, 'country').map((b) => b.id),
    ['london'],
  );
  assert.deepEqual(
    filterExploreBusinesses(businesses, { city: 'Lahore', countryCode: 'PK' }, 'country').map((b) => b.id),
    ['lahore', 'legacy-lahore'],
  );
});

test('Explore gracefully leaves results unfiltered if current location is unavailable', () => {
  assert.deepEqual(filterExploreBusinesses(businesses, null, 'city'), businesses);
});
