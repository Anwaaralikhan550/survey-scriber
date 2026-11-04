/**
 * SurveyScriber Phrase Bank portal — local development server.
 *
 * Production is static: the files in public/ are deployed to the VPS and nginx
 * proxies /api/ to the SurveyScriber backend (see deploy.sh / README.md).
 * This script reproduces that setup on a laptop:
 *   - serves public/ (plus the baseline banks from the repo assets)
 *   - proxies /api/* to the backend at SS_API_ORIGIN (default: production VPS)
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
const API_ORIGIN = (process.env.SS_API_ORIGIN || 'http://158.69.1.183:3000').replace(/\/+$/, '');

/** Baseline banks (used by the portal only until a bank is published on the server). */
const BASELINE = {
  '/assets/banks/inspection.json': path.join(REPO, 'assets', 'property_inspection', 'phrase_texts.json'),
  '/assets/banks/valuation.json': path.join(REPO, 'assets', 'property_valuation', 'phrase_texts.json'),
  '/assets/trees/inspection.json': path.join(REPO, 'assets', 'property_inspection', 'inspection_tree.json'),
  '/assets/trees/valuation.json': path.join(REPO, 'assets', 'property_valuation', 'valuation_tree.json'),
};

/** Which built-in tree this app version has: the published tree must say the same. */
function bundledVersions() {
  const read = (rel) => {
    const code = fs.readFileSync(path.join(REPO, rel), 'utf8');
    const m = code.match(/static const int bundledVersion = (\d+);/);
    if (!m) throw new Error('bundledVersion not found in ' + rel);
    return Number(m[1]);
  };
  return {
    inspection: read('lib/features/property_inspection/data/inspection_repository.dart'),
    valuation: read('lib/features/property_valuation/data/valuation_repository.dart'),
  };
}

const TYPES = { html: 'text/html; charset=utf-8', js: 'text/javascript', css: 'text/css', json: 'application/json' };

function send(res, code, body, type = 'text/plain') {
  res.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store' });
  res.end(body);
}

function serveFile(res, file) {
  fs.readFile(file, (err, data) => {
    if (err) return send(res, 404, 'Not found');
    send(res, 200, data, TYPES[path.extname(file).slice(1)] || 'application/octet-stream');
  });
}

function proxy(req, res) {
  const target = new URL(req.url, API_ORIGIN);
  const opts = {
    method: req.method,
    headers: { ...req.headers, host: target.host },
  };
  const up = http.request(target, opts, (r) => {
    res.writeHead(r.statusCode, r.headers);
    r.pipe(res);
  });
  up.on('error', (e) => send(res, 502, JSON.stringify({ message: 'API unreachable: ' + e.message }), TYPES.json));
  req.pipe(up);
}

const server = http.createServer((req, res) => {
  const u = new URL(req.url, `http://localhost:${PORT}`);
  if (u.pathname.startsWith('/api/')) return proxy(req, res);
  if (BASELINE[u.pathname]) return serveFile(res, BASELINE[u.pathname]);
  if (u.pathname === '/assets/trees/meta.json') return send(res, 200, JSON.stringify(bundledVersions()), TYPES.json);
  if (req.method !== 'GET') return send(res, 405, 'Method not allowed');
  const rel = u.pathname === '/' ? 'index.html' : u.pathname.replace(/^\//, '');
  const file = path.join(ROOT, 'public', rel);
  if (!file.startsWith(path.join(ROOT, 'public'))) return send(res, 403, 'Forbidden');
  serveFile(res, file);
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`\n  Phrase Bank portal (dev) -> http://localhost:${PORT}`);
    console.log(`  API proxied to ${API_ORIGIN}\n`);
  });
}

module.exports = { server, BASELINE, API_ORIGIN, bundledVersions };
