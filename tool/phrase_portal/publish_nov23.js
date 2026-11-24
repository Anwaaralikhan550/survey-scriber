#!/usr/bin/env node
// Publishes the wording changes of the client's 23 Nov 2026 edit list to the live inspection phrase bank.
//   node tool/phrase_portal/publish_nov23.js            (shows what would change, asks first)
//   SS_API_URL=https://portal.surveyscriber.com/api/v1 node tool/phrase_portal/publish_nov23.js
// It asks for the admin email and password; they stay in this process only.
//
// Phones already fill keys the live bank lacks from the bundled bank, so the three new keys only keep the portal in
// step. The one change phones cannot get any other way is Outside Doors "BS EN noted": the live text holds that
// sentence twice, and a key the live bank has is never overridden by the app. That key is replaced only while the live
// text is still exactly the old doubled text, so a later edit by the client is never overwritten.
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const API = (process.env.SS_API_URL || 'https://portal.surveyscriber.com/api/v1').replace(/\/$/, '');
const BANK = path.join(__dirname, '..', '..', 'assets', 'property_inspection', 'phrase_texts.json');

const ADD = [
  '{E_MAIN_WALLS}::{E4_WALL_FINISHED}',
  '{E_MAIN_WALLS}::{E4_LINTEL_WINDOW}',
  '{E_MAIN_WALLS}::{E4_LINTEL_DOOR}',
];
const REPLACE_WHEN_LIVE_IS_DOUBLED = ['{E_OUTSIDE_DOORS}::{E6_BS_EN_NOTED}'];

function ask(q, hidden) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
    if (hidden) {
      rl._writeToOutput = (s) => { if (s.includes(q)) rl.output.write(s); };
    }
    rl.question(q, (a) => { rl.close(); if (hidden) process.stdout.write('\n'); resolve(a.trim()); });
  });
}

async function call(method, url, token, body) {
  const res = await fetch(API + url, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = text; }
  if (!res.ok) throw new Error(`${method} ${url} -> ${res.status} ${typeof json === 'string' ? json : JSON.stringify(json)}`);
  return json;
}

(async () => {
  const mine = JSON.parse(fs.readFileSync(BANK, 'utf8'));
  const latest = await call('GET', '/config/phrase-bank/inspection_phrases');
  const live = latest.bank || latest;
  const changes = [];
  for (const k of ADD) {
    if (!(k in mine)) throw new Error('Not in this app bank: ' + k);
    if (k in live) { console.log(`  = ${k}: already on the server, left as it is`); continue; }
    changes.push({ key: k, kind: 'add' });
  }
  for (const k of REPLACE_WHEN_LIVE_IS_DOUBLED) {
    if (!(k in live)) { changes.push({ key: k, kind: 'add' }); continue; }
    const text = live[k];
    const once = (text.match(/BS EN noted:/g) || []).length;
    if (text === mine[k]) { console.log(`  = ${k}: already correct on the server`); continue; }
    if (once === 2 && text.includes(mine[k])) changes.push({ key: k, kind: 'replace' });
    else console.log(`  ! ${k}: the live text was edited since; left as it is`);
  }
  console.log(`Live bank version ${latest.version}: ${Object.keys(live).length} keys.`);
  changes.forEach((c) => console.log(`  ${c.kind === 'add' ? '+' : '~'} ${c.key}`));
  if (!changes.length) { console.log('Nothing to publish.'); return; }
  if ((await ask('Publish these now? Type yes: ')) !== 'yes') { console.log('Cancelled.'); return; }
  const email = await ask('Admin email: ');
  const password = await ask('Admin password: ', true);
  const login = await call('POST', '/auth/login', null, { email, password });
  const merged = { ...live };
  for (const c of changes) merged[c.key] = mine[c.key];
  const out = await call('POST', '/admin/config/phrase-bank/upload', login.accessToken, { bankType: 'inspection_phrases', bank: merged });
  console.log(`Published. Version ${out.version}, unchanged=${out.unchanged}.`);
})().catch((e) => { console.error('FAILED:', e.message); process.exit(1); });
