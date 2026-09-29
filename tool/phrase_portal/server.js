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
      const data = readBank(name);
      const entries = Object.entries(data).map(([key, value]) => ({
        key, value, tokens: tokenSet(value),
      }));
      return send(res, 200, { name, count: entries.length, entries });
    } catch (e) {
      return send(res, 500, { error: String(e.message || e) });
    }
  }

  // ── API: save one entry (token-preserving) ──
  if (req.method === 'POST' && u.pathname === '/api/save') {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => {
      try {
        const { name = 'inspection', key, value, force = false } = JSON.parse(raw || '{}');
        if (!key) return send(res, 400, { error: 'Missing key' });
        const data = readBank(name);
        if (!(key in data)) return send(res, 404, { error: 'Key not found: ' + key });

        const before = tokenSet(data[key]);
        const after = tokenSet(value);
        const removed = before.filter((t) => !after.includes(t));
        const added = after.filter((t) => !before.includes(t));

        // Guard: never silently drop a placeholder the engine substitutes, and
        // never introduce a new one it doesn't know about — either breaks the
        // report. Requires an explicit force to override.
        if (!force && (removed.length || added.length)) {
          return send(res, 409, {
            error: 'placeholder_mismatch', removed, added,
            message:
              'This edit changes the {TOKEN} placeholders. Removing or adding a ' +
              'token can break the report. Fix the tokens, or re-save with ' +
              'Override if you are certain.',
          });
        }

        data[key] = value;
        fs.writeFileSync(BANKS[name], asciiStringify(data), 'utf8');
        return send(res, 200, { ok: true, key, tokens: after });
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

server.listen(PORT, () => {
  console.log(`\n  Phrase Bank portal → http://localhost:${PORT}\n`);
  console.log(`  inspection: ${BANKS.inspection}`);
  console.log(`  valuation : ${BANKS.valuation}\n`);
});
