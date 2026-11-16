import test from 'node:test';
import assert from 'node:assert/strict';
import { wordDiff } from '../src/wordDiff.js';

const join = (parts) => parts.map((p) => p.text).join('');
const changed = (parts) => parts.filter((p) => p.changed).map((p) => p.text);

test('both sides reproduce their texts exactly', () => {
  const a = 'The roof has 12 slipped tiles.';
  const b = 'Twelve roof tiles have slipped.';
  const d = wordDiff(a, b);
  assert.equal(join(d.before), a);
  assert.equal(join(d.after), b);
});

test('identical text has no marks', () => {
  const d = wordDiff('Same text here.', 'Same text here.');
  assert.deepEqual(changed(d.before), []);
  assert.deepEqual(changed(d.after), []);
});

test('a replaced word is marked on both sides, nothing else', () => {
  const d = wordDiff('The roof is slate.', 'The roof is tiled.');
  assert.deepEqual(changed(d.before), ['slate.']);
  assert.deepEqual(changed(d.after), ['tiled.']);
});

test('an added figure shows only on the suggestion side', () => {
  const d = wordDiff('Ridge in poor condition.', 'Ridge in poor condition, 15 tiles.');
  assert.deepEqual(changed(d.before), ['condition.']);
  assert.ok(changed(d.after).includes('15'));
});

test('empty sides do not crash', () => {
  assert.deepEqual(wordDiff('', 'new text').before, []);
  assert.equal(join(wordDiff('old', '').before), 'old');
});
