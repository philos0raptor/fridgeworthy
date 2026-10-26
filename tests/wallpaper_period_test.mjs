import assert from 'node:assert/strict';
import { periodBounds } from '../supabase/functions/generate-wallpaper/period.ts';

assert.deepEqual(
  periodBounds('2026-10-26T00:00:00Z', '2026-11-02T00:00:00Z'),
  { start: '2026-10-26T00:00:00.000Z', end: '2026-11-02T00:00:00.000Z' },
);
assert.throws(() => periodBounds('bad', '2026-11-02T00:00:00Z'));
assert.throws(() => periodBounds('2026-11-02T00:00:00Z', '2026-11-02T00:00:00Z'));
assert.throws(() => periodBounds('2026-11-03T00:00:00Z', '2026-11-02T00:00:00Z'));
assert.throws(() => periodBounds(undefined, '2026-11-02T00:00:00Z'));

console.log('wallpaper period tests passed');
