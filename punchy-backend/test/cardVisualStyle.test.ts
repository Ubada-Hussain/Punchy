import { test } from 'node:test';
import assert from 'node:assert/strict';
import { CardVisualStyleSchema } from '../src/lib/cardVisualStyle';

test('card colors validate and serialize uppercase without dropping other style properties', () => {
  assert.deepEqual(CardVisualStyleSchema.parse({ primaryColor: '#e2503a', icon: 'coffee', theme: 'coral' }),
    { primaryColor: '#E2503A', icon: 'coffee', theme: 'coral' });
  for (const primaryColor of ['#FFF', '#FFFFFFFF', 'red', 'E2503A', '#GGGGGG', 123, null]) {
    assert.equal(CardVisualStyleSchema.safeParse({ primaryColor }).success, false);
  }
});

test('legacy theme names and swatch indices remain writable without adding a color', () => {
  for (const theme of ['coral', 'teal', 'purple', 'gold', 0, 1, 2, 3, '0', '#AbCdEf']) {
    assert.deepEqual(CardVisualStyleSchema.parse({ theme }), { theme });
  }
  assert.deepEqual(CardVisualStyleSchema.parse({}), {});
});
