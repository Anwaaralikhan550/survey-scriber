// Run: node --test tool/phrase_portal/test.js   (Node 18+, no dependencies)
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const { entriesOf, applyEdit, isTemplatesBank, entryCount, API_TYPE } = require('./public/bank-logic.js');
const { BASELINE } = require('./server.js');

const REPO = path.resolve(__dirname, '..', '..');
const load = (rel) => JSON.parse(fs.readFileSync(path.join(REPO, rel), 'utf8'));

test('portal roles: staff get in, field users do not; admin pages stay with the administrator', () => {
  const AL = require('./public/admin-logic.js');
  assert.ok(AL.canUsePortal('ADMIN'));
  assert.ok(AL.canUsePortal('MANAGER'));
  assert.ok(!AL.canUsePortal('SURVEYOR'));
  assert.ok(!AL.canUsePortal('VIEWER'));
  assert.ok(!AL.canUsePortal(undefined));
  for (const key of ['subAdmins', 'email', 'settings']) {
    assert.ok(AL.canSee(key, 'ADMIN'), key);
    assert.ok(!AL.canSee(key, 'MANAGER'), key);
  }
  for (const key of ['dash', 'fieldUsers', 'options', 'tree', 'inspection', 'valuation']) {
    assert.ok(AL.canSee(key, 'MANAGER'), key);
  }
  assert.strictEqual(AL.roleLabel('MANAGER'), 'Sub Admin');
});

test('the address bar opens only pages the role may see', () => {
  const AL = require('./public/admin-logic.js');
  assert.strictEqual(AL.startPage('#/fieldUsers', 'MANAGER'), 'fieldUsers');
  assert.strictEqual(AL.startPage('#/settings', 'MANAGER'), 'dash');
  assert.strictEqual(AL.startPage('#/settings', 'ADMIN'), 'settings');
  assert.strictEqual(AL.startPage('#/nonsense', 'ADMIN'), 'dash');
  assert.strictEqual(AL.startPage('', 'ADMIN'), 'dash');
});

test('every page has its nav button and every nav button has a page', () => {
  const AL = require('./public/admin-logic.js');
  const html = fs.readFileSync(path.join(__dirname, 'public', 'index.html'), 'utf8');
  const nav = [...html.matchAll(/class="nav-item[^"]*" data-view="([a-zA-Z]+)"/g)].map((m) => m[1]);
  assert.deepStrictEqual(nav.slice().sort(), AL.PAGES.map((p) => p.key).sort());
});

test('admin pages never put text in through innerHTML', () => {
  const dir = path.join(__dirname, 'public');
  const files = ['ui.js', 'app.js', ...(fs.existsSync(path.join(dir, 'pages')) ? fs.readdirSync(path.join(dir, 'pages')).map((f) => 'pages/' + f) : [])];
  for (const file of files) {
    const code = fs.readFileSync(path.join(dir, file), 'utf8');
    const uses = [...code.matchAll(/innerHTML\s*=\s*([^;]+);/g)].map((m) => m[1].trim());
    assert.ok(uses.every((u) => u === "''"), file + ': ' + uses.join(' | '));
  }
});

test('inspection bank (flat map) loads every key', () => {
  const raw = load('assets/property_inspection/phrase_texts.json');
  const entries = entriesOf(raw);
  assert.strictEqual(entries.length, Object.keys(raw).length);
  assert.ok(entries.every((e) => typeof e.value === 'string'));
  assert.strictEqual(entryCount(raw), entries.length);
});

test('valuation bank ({meta, templates}) lists its templates, not meta/templates', () => {
  const raw = load('assets/property_valuation/phrase_texts.json');
  assert.ok(isTemplatesBank(raw));
  const entries = entriesOf(raw);
  assert.strictEqual(entries.length, Object.keys(raw.templates).length);
  assert.ok(entries.length > 100);
  assert.ok(!entries.some((e) => e.key === 'meta' || e.key === 'templates'));
  assert.ok(entries[0].value.length > 20, 'text is shown, not an object');
  assert.ok(entries[0].screenId, 'screenId is carried for display/search');
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

test('API bank types match the backend contract', () => {
  assert.deepStrictEqual(API_TYPE, { inspection: 'inspection_phrases', valuation: 'valuation_phrases' });
});

test('baseline banks served by the dev server are the repo assets', () => {
  for (const file of Object.values(BASELINE)) assert.ok(fs.existsSync(file), file);
  const insp = JSON.parse(fs.readFileSync(BASELINE['/assets/banks/inspection.json'], 'utf8'));
  assert.ok(Object.keys(insp).length > 1000);
});

test('an edited bank round-trips through JSON unchanged apart from the edit (publish payload)', () => {
  const raw = load('assets/property_inspection/phrase_texts.json');
  const key = Object.keys(raw)[0];
  const draft = JSON.parse(JSON.stringify(raw));
  applyEdit(draft, key, raw[key] + ' EDIT', true);
  const back = JSON.parse(JSON.stringify(draft));
  assert.strictEqual(back[key], raw[key] + ' EDIT');
  delete back[key]; delete raw[key];
  assert.deepStrictEqual(back, raw);
});
