#!/usr/bin/env node
// Publishes the bundled inspection phrase bank (assets/property_inspection/phrase_texts.json)
// to the server, so phones get the wording this app version added. Run it yourself:
//   node tool/phrase_portal/publish_bank.js            (shows what would change, asks first)
//   SS_API_URL=https://portal.surveyscriber.com/api/v1 node tool/phrase_portal/publish_bank.js
// It asks for the admin email and password; they stay in this process only.
// Keys the live bank already has are NOT overwritten (client edits in the portal stay);
// only keys missing from the live bank are added.
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const API = (process.env.SS_API_URL || 'https://portal.surveyscriber.com/api/v1').replace(/\/$/, '');
const BANK = path.join(__dirname, '..', '..', 'assets', 'property_inspection', 'phrase_texts.json');

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
  const added = Object.keys(mine).filter((k) => !(k in live));
  const changedHere = Object.keys(mine).filter((k) => k in live && live[k] !== mine[k]);
  console.log(`Live bank version ${latest.version}: ${Object.keys(live).length} keys. This app: ${Object.keys(mine).length} keys.`);
  console.log(`Missing on the server (will be added): ${added.length}`);
  added.slice(0, 40).forEach((k) => console.log('  + ' + k));
  console.log(`Different in the app, but the live text is kept: ${changedHere.length}`);
  if (!added.length) { console.log('Nothing to publish.'); return; }
  if ((await ask('Publish these keys now? Type yes: ')) !== 'yes') { console.log('Cancelled.'); return; }
  const email = await ask('Admin email: ');
  const password = await ask('Admin password: ', true);
  const login = await call('POST', '/auth/login', null, { email, password });
  const merged = { ...live };
  for (const k of added) merged[k] = mine[k];
  const out = await call('POST', '/admin/config/phrase-bank/upload', login.accessToken, { bankType: 'inspection_phrases', bank: merged });
  console.log(`Published. Version ${out.version}, unchanged=${out.unchanged}.`);
})().catch((e) => { console.error('FAILED:', e.message); process.exit(1); });
