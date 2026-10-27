/**
 * SurveyScriber Phrase Bank — web editor portal (standalone, zero-dependency).
 *
 * The RICS L2 phrase bank is too large/complex to edit on a phone (client's
 * App-Edit note). This little local web app lets an admin search and safely
 * edit the sentence templates in
 *   assets/property_inspection/phrase_texts.json   (and the valuation bank),
 * with hard protection against removing or renaming the {TOKEN} placeholders
 * that carry the sentence logic / parameter settings.
 *
 * Run:  node tool/phrase_portal/server.js   (then open http://localhost:4599)
 * No npm install required — Node built-ins only.
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const ROOT = __dirname;
const REPO = path.resolve(ROOT, '..', '..');
const PORT = process.env.PORT || 4599;

const BANKS = {
  inspection: path.join(REPO, 'assets', 'property_inspection', 'phrase_texts.json'),
  valuation: path.join(REPO, 'assets', 'property_valuation', 'phrase_texts.json'),
};

// Live publishing: edits are pushed to the SurveyScriber server so every phone
// gets them. The admin logs in from the page; tokens live in memory only.
const API_URL = (process.env.SS_API_URL || 'http://158.69.1.183:3000/api/v1').replace(/\/+$/, '');
const BANK_API_TYPE = { inspection: 'inspection_phrases', valuation: 'valuation_phrases' };
const session = { accessToken: null, refreshToken: null, email: null };

const TOKEN_RE = /\{[A-Z0-9_]+\}/g;
const tokens = (s) => (String(s).match(TOKEN_RE) || []);
const tokenSet = (s) => [...new Set(tokens(s))].sort();

/** Match the repo's json.dump(indent=2, ensure_ascii=True) formatting so edits
 *  produce minimal, consistent diffs. */
function asciiStringify(obj) {
  const s = JSON.stringify(obj, null, 2);
  return s.replace(/[\u0080-\uffff]/g,
    (c) => '\\u' + c.charCodeAt(0).toString(16).padStart(4, '0'));
}

function readBank(name) {
  const file = BANKS[name];
  if (!file) throw new Error('Unknown bank: ' + name);
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

/** A bank is either a flat {key: text} map (inspection) or
 *  {meta, templates: {id: {screenId, text, ...}}} (valuation). */
const isTemplatesBank = (raw) =>
  !!raw && typeof raw.templates === 'object' && raw.templates !== null && !Array.isArray(raw.templates);

const textOfTemplate = (t) => (typeof t === 'string' ? t : String((t && t.text) || ''));

/** Editable entries of a bank, whatever its shape. */
function entriesOf(raw) {
  if (isTemplatesBank(raw)) {
    return Object.entries(raw.templates).map(([key, t]) => {
      const value = textOfTemplate(t);
      return { key, value, tokens: tokenSet(value), screenId: (t && t.screenId) || undefined };
    });
  }
  return Object.entries(raw).map(([key, value]) => ({ key, value, tokens: tokenSet(value) }));
}

function currentText(raw, key) {
  if (isTemplatesBank(raw)) return key in raw.templates ? textOfTemplate(raw.templates[key]) : undefined;
  return key in raw ? raw[key] : undefined;
}

/** Writes the new text in place (a valuation template keeps its screenId and other fields). */
function setText(raw, key, value) {
  if (isTemplatesBank(raw)) {
    const t = raw.templates[key];
    raw.templates[key] = typeof t === 'object' && t !== null ? { ...t, text: value } : value;
  } else {
    raw[key] = value;
  }
}

/** Token-preserving edit of one entry. Returns {status, body}; mutates `raw` only on success. */
function applyEdit(raw, key, value, force = false) {
  if (!key) return { status: 400, body: { error: 'Missing key' } };
  const old = currentText(raw, key);
  if (old === undefined) return { status: 404, body: { error: 'Key not found: ' + key } };
  const before = tokenSet(old);
  const after = tokenSet(value);
  const removed = before.filter((t) => !after.includes(t));
  const added = after.filter((t) => !before.includes(t));
  // Guard: never silently drop a placeholder the engine substitutes, and never
  // introduce a new one it doesn't know about - either breaks the report.
  if (!force && (removed.length || added.length)) {
    return {
      status: 409,
      body: {
        error: 'placeholder_mismatch', removed, added,
        message:
          'This edit changes the {TOKEN} placeholders. Removing or adding a ' +
          'token can break the report. Fix the tokens, or re-save with ' +
          'Override if you are certain.',
      },
    };
  }
  setText(raw, key, value);
  return { status: 200, body: { ok: true, key, tokens: after } };
}

/** JSON call to the SurveyScriber API. Returns {status, body}; never throws on HTTP errors. */
async function callApi(method, apiPath, { body, auth = false, fetchFn = fetch } = {}) {
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
  if (auth && session.accessToken) headers.Authorization = 'Bearer ' + session.accessToken;
  let res;
  try {
    res = await fetchFn(API_URL + apiPath, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  } catch (e) {
    return { status: 0, body: { message: 'Cannot reach the server (' + API_URL + '): ' + (e.cause?.code || e.message) } };
  }
  let parsed = {};
  try { parsed = await res.json(); } catch { /* empty body */ }
  return { status: res.status, body: parsed };
}

const unwrap = (b) => (b && b.data && typeof b.data === 'object' ? b.data : b) || {};

async function login(email, password, fetchFn = fetch) {
  const r = await callApi('POST', '/auth/login', { body: { email, password }, fetchFn });
  if (r.status !== 200 && r.status !== 201) {
    return { ok: false, status: r.status || 502, message: r.body.message || 'Login failed' };
  }
  const d = unwrap(r.body);
  if (!d.accessToken) return { ok: false, status: 502, message: 'Login response had no token' };
  session.accessToken = d.accessToken;
  session.refreshToken = d.refreshToken || null;
  session.email = email;
  return { ok: true, email, role: (d.user && d.user.role) || undefined };
}

function logout() {
  session.accessToken = session.refreshToken = session.email = null;
}

async function refreshSession(fetchFn = fetch) {
  if (!session.refreshToken) return false;
  const r = await callApi('POST', '/auth/refresh', { body: { refreshToken: session.refreshToken }, fetchFn });
  const d = unwrap(r.body);
  if ((r.status === 200 || r.status === 201) && d.accessToken) {
    session.accessToken = d.accessToken;
    if (d.refreshToken) session.refreshToken = d.refreshToken;
    return true;
  }
  logout();
  return false;
}

/** Publishes a whole bank so phones receive it. Not logged in -> {live:false}. */
async function publishBank(name, data, fetchFn = fetch) {
  const bankType = BANK_API_TYPE[name];
  if (!bankType) return { live: false, reason: 'Unknown bank' };
  if (!session.accessToken) return { live: false, reason: 'not_logged_in' };
  const post = () => callApi('POST', '/admin/config/phrase-bank/upload', { body: { bankType, bank: data }, auth: true, fetchFn });
  let r = await post();
  if (r.status === 401 && (await refreshSession(fetchFn))) r = await post();
  if (r.status === 201 || r.status === 200) {
    const d = unwrap(r.body);
    return { live: true, version: d.version, unchanged: !!d.unchanged };
  }
  if (r.status === 401) return { live: false, reason: 'login_expired' };
  if (r.status === 403) return { live: false, reason: 'This account is not an admin - cannot publish.' };
  return { live: false, reason: r.body.message || ('Server error ' + r.status) };
}

/** Same key order as the local file (at every level), so an in-sync pull does not create a git diff.
 *  Postgres JSONB hands keys back in its own order. */
function orderLike(local, remote) {
  const isObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
  if (!isObj(remote)) return remote;
  const base = isObj(local) ? local : {};
  const out = {};
  for (const k of Object.keys(base)) if (k in remote) out[k] = orderLike(base[k], remote[k]);
  for (const k of Object.keys(remote)) if (!(k in out)) out[k] = orderLike(undefined, remote[k]);
  return out;
}

/** Server copy is the truth after login: pull it into the local file before editing. */
async function pullBank(name, fetchFn = fetch) {
  const bankType = BANK_API_TYPE[name];
  const r = await callApi('GET', '/config/phrase-bank/' + bankType, { fetchFn });
  if (r.status === 404) return { pulled: false, reason: 'nothing_published' };
  const d = unwrap(r.body);
  if (r.status !== 200 || !d.bank) return { pulled: false, reason: r.body.message || ('Server error ' + r.status) };
  const merged = orderLike(readBank(name), d.bank);
  const before = fs.readFileSync(BANKS[name], 'utf8');
  const after = asciiStringify(merged);
  if (before !== after) fs.writeFileSync(BANKS[name], after, 'utf8');
  return { pulled: true, changed: before !== after, version: d.version };
}

function send(res, code, body, type = 'application/json') {
  res.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store' });
  if (Buffer.isBuffer(body) || typeof body === 'string') res.end(body);
  else res.end(JSON.stringify(body));
}

function serveStatic(res, rel) {
  const file = path.join(ROOT, 'public', rel);
  if (!file.startsWith(path.join(ROOT, 'public'))) return send(res, 403, 'Forbidden', 'text/plain');
  fs.readFile(file, (err, data) => {
    if (err) return send(res, 404, 'Not found', 'text/plain');
    const ext = path.extname(file).slice(1);
    const types = { html: 'text/html', js: 'text/javascript', css: 'text/css' };
    send(res, 200, data, types[ext] || 'application/octet-stream');
  });
}

const server = http.createServer((req, res) => {
  const u = new URL(req.url, `http://localhost:${PORT}`);

  // ── API: load a bank ──
  if (req.method === 'GET' && u.pathname === '/api/bank') {
    const name = u.searchParams.get('name') || 'inspection';
    try {
      const entries = entriesOf(readBank(name));
      return send(res, 200, { name, count: entries.length, entries });
    } catch (e) {
      return send(res, 500, { error: String(e.message || e) });
    }
  }

  // ── API: login / status / logout / pull / publish ──
  if (u.pathname === '/api/status' && req.method === 'GET') {
    return send(res, 200, { apiUrl: API_URL, loggedIn: !!session.accessToken, email: session.email });
  }
  if (u.pathname === '/api/logout' && req.method === 'POST') {
    logout();
    return send(res, 200, { ok: true });
  }
  if (req.method === 'POST' && ['/api/login', '/api/pull', '/api/publish'].includes(u.pathname)) {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', async () => {
      try {
        const body = JSON.parse(raw || '{}');
        if (u.pathname === '/api/login') {
          const r = await login(String(body.email || ''), String(body.password || ''));
          if (!r.ok) return send(res, r.status === 401 ? 401 : 502, { error: r.message });
          const pulls = {};
          for (const n of Object.keys(BANKS)) pulls[n] = await pullBank(n);
          return send(res, 200, { ok: true, email: r.email, role: r.role, pulls });
        }
        const name = body.name || 'inspection';
        if (u.pathname === '/api/pull') return send(res, 200, await pullBank(name));
        return send(res, 200, await publishBank(name, readBank(name)));
      } catch (e) {
        return send(res, 500, { error: String(e.message || e) });
      }
    });
    return;
  }

  // ── API: save one entry (token-preserving) ──
  if (req.method === 'POST' && u.pathname === '/api/save') {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', async () => {
      try {
        const { name = 'inspection', key, value, force = false } = JSON.parse(raw || '{}');
        const data = readBank(name);
        const result = applyEdit(data, key, value, force);
        if (result.status !== 200) return send(res, result.status, result.body);
        fs.writeFileSync(BANKS[name], asciiStringify(data), 'utf8');
        const publish = await publishBank(name, data);
        return send(res, 200, { ...result.body, publish });
      } catch (e) {
        return send(res, 500, { error: String(e.message || e) });
      }
    });
    return;
  }

  // ── Static ──
  if (req.method === 'GET') {
    const rel = u.pathname === '/' ? 'index.html' : u.pathname.replace(/^\//, '');
    return serveStatic(res, rel);
  }
  send(res, 405, 'Method not allowed', 'text/plain');
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`\n  Phrase Bank portal → http://localhost:${PORT}\n`);
    console.log(`  inspection: ${BANKS.inspection}`);
    console.log(`  valuation : ${BANKS.valuation}\n`);
  });
}

module.exports = {
  entriesOf, applyEdit, tokenSet, isTemplatesBank, asciiStringify,
  login, logout, publishBank, pullBank, orderLike, session, callApi,
};
