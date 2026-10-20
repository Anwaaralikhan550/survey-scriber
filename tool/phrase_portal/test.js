// Run: node --test tool/phrase_portal/test.js   (Node 18+, no dependencies)
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const { entriesOf, applyEdit, asciiStringify } = require('./server.js');

const REPO = path.resolve(__dirname, '..', '..');
const load = (rel) => JSON.parse(fs.readFileSync(path.join(REPO, rel), 'utf8'));

test('inspection bank (flat map) loads every key', () => {
  const raw = load('assets/property_inspection/phrase_texts.json');
  const entries = entriesOf(raw);
  assert.strictEqual(entries.length, Object.keys(raw).length);
  assert.ok(entries.every((e) => typeof e.value === 'string'));
});

test('valuation bank ({meta, templates}) lists its templates, not meta/templates', () => {
  const raw = load('assets/property_valuation/phrase_texts.json');
  const entries = entriesOf(raw);
  assert.strictEqual(entries.length, Object.keys(raw.templates).length);
  assert.ok(entries.length > 100);
  assert.ok(!entries.some((e) => e.key === 'meta' || e.key === 'templates'));
  const first = entries[0];
  assert.ok(first.value.length > 20, 'text is shown, not an object');
  assert.ok(first.screenId, 'screenId is carried for display/search');
});

test('valuation edit changes only text and keeps screenId and the other fields', () => {
  const raw = load('assets/property_valuation/phrase_texts.json');
  const key = Object.keys(raw.templates)[0];
  const before = { ...raw.templates[key] };
  const r = applyEdit(raw, key, before.text + ' Extra.');
  assert.strictEqual(r.status, 200);
  assert.strictEqual(raw.templates[key].text, before.text + ' Extra.');
  assert.strictEqual(raw.templates[key].screenId, before.screenId);
  assert.deepStrictEqual(Object.keys(raw.templates[key]), Object.keys(before));
  assert.ok(raw.meta, 'meta untouched');
});

test('token lock works for both bank shapes (409, nothing written)', () => {
  const inspection = { '{A}::{B}': 'Hello {X}.' };
  const r1 = applyEdit(inspection, '{A}::{B}', 'Hello {Y}.');
  assert.strictEqual(r1.status, 409);
  assert.strictEqual(inspection['{A}::{B}'], 'Hello {X}.');

  const valuation = { meta: {}, templates: { T1: { screenId: 's', text: 'Value {PRICE}.' } } };
  const r2 = applyEdit(valuation, 'T1', 'Value.');
  assert.strictEqual(r2.status, 409);
  assert.strictEqual(valuation.templates.T1.text, 'Value {PRICE}.');
  assert.strictEqual(applyEdit(valuation, 'T1', 'Value.', true).status, 200); // explicit override
});

test('unknown key is 404 and a missing key is 400', () => {
  assert.strictEqual(applyEdit({ a: 'x' }, 'nope', 'y').status, 404);
  assert.strictEqual(applyEdit({ a: 'x' }, '', 'y').status, 400);
  assert.strictEqual(applyEdit({ meta: {}, templates: {} }, 'nope', 'y').status, 404);
});

test('valuation file round-trips through the portal writer without changing content', () => {
  const rel = 'assets/property_valuation/phrase_texts.json';
  const raw = load(rel);
  assert.deepStrictEqual(JSON.parse(asciiStringify(raw)), raw);
});

// ── live publishing (fake API, no network, no repo files touched) ──
const { login, logout, publishBank, orderLike, session } = require('./server.js');

const reply = (status, body) => ({ status, json: async () => body });
const fakeApi = (routes, calls = []) => async (url, init) => {
  const p = url.replace(/^https?:\/\/[^/]+\/api\/v1/, '');
  calls.push({ p, auth: init.headers.Authorization, body: init.body && JSON.parse(init.body) });
  return routes(p, init, calls.length);
};

test('not logged in: save stays file-only, nothing is sent', async () => {
  logout();
  const calls = [];
  const r = await publishBank('inspection', { a: 'b' }, fakeApi(() => reply(500, {}), calls));
  assert.deepStrictEqual(r, { live: false, reason: 'not_logged_in' });
  assert.strictEqual(calls.length, 0);
});

test('login then publish sends the whole bank with the admin token', async () => {
  const calls = [];
  const api = fakeApi((p) => {
    if (p === '/auth/login') return reply(200, { accessToken: 'AT', refreshToken: 'RT', user: { role: 'ADMIN' } });
    if (p === '/admin/config/phrase-bank/upload') return reply(201, { version: 7, unchanged: false });
    return reply(404, {});
  }, calls);
  const l = await login('a@b.c', 'pw', api);
  assert.ok(l.ok);
  const bank = { '{K}': 'Text {T}.' };
  const r = await publishBank('inspection', bank, api);
  assert.deepStrictEqual(r, { live: true, version: 7, unchanged: false });
  const up = calls[1];
  assert.strictEqual(up.auth, 'Bearer AT');
  assert.deepStrictEqual(up.body, { bankType: 'inspection_phrases', bank });
  const v = await publishBank('valuation', { meta: {}, templates: {} }, api);
  assert.strictEqual(calls[2].body.bankType, 'valuation_phrases');
  assert.ok(v.live);
  logout();
});

test('expired access token is refreshed once and the publish retried', async () => {
  session.accessToken = 'OLD'; session.refreshToken = 'RT';
  let uploads = 0;
  const api = fakeApi((p) => {
    if (p === '/auth/refresh') return reply(200, { accessToken: 'NEW', refreshToken: 'RT2' });
    uploads++;
    return uploads === 1 ? reply(401, {}) : reply(201, { version: 2 });
  });
  const r = await publishBank('inspection', { a: 'b' }, api);
  assert.strictEqual(r.live, true);
  assert.strictEqual(session.accessToken, 'NEW');
  logout();
});

test('non-admin (403), server error and unreachable server are reported, never silent', async () => {
  session.accessToken = 'AT';
  assert.match((await publishBank('inspection', {}, fakeApi(() => reply(403, {})))).reason, /not an admin/);
  assert.strictEqual((await publishBank('inspection', {}, fakeApi(() => reply(400, { message: 'Refusing to publish' })))).reason, 'Refusing to publish');
  const down = async () => { throw new Error('connect ECONNREFUSED'); };
  const r = await publishBank('inspection', {}, down);
  assert.strictEqual(r.live, false);
  assert.match(r.reason, /Cannot reach the server/);
  logout();
});

test('wrong password gives a clear login failure and no session', async () => {
  const r = await login('a@b.c', 'bad', fakeApi(() => reply(401, { message: 'Invalid credentials' })));
  assert.strictEqual(r.ok, false);
  assert.strictEqual(session.accessToken, null);
});

test('orderLike keeps the local key order so a pull does not churn git', () => {
  const local = { b: '1', a: '2' };
  const remote = { a: '2', c: '3', b: '1' }; // JSONB reorders keys
  assert.deepStrictEqual(Object.keys(orderLike(local, remote)), ['b', 'a', 'c']);
  const lv = { meta: {}, templates: { y: { text: 'Y' }, x: { text: 'X' } } };
  const rv = { meta: {}, templates: { x: { text: 'X' }, y: { text: 'Y2' } } };
  assert.deepStrictEqual(Object.keys(orderLike(lv, rv).templates), ['y', 'x']);
  assert.strictEqual(orderLike(lv, rv).templates.y.text, 'Y2');
});
