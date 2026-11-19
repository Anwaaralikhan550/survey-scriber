// D8: the editor behind a real nginx (docker nginx:1.27-alpine with tool/desktop_editor/deploy/*.conf), backend on :3099.
// Checks headers, caching, hidden files, token masking in the access log, rate limit, clickjacking, uploads, and a full edit in Chrome.
const { chromium } = require('playwright');
const http = require('http');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { prisma, seed, newLink } = require('./lib.js');
const { enterEditor } = require('./lib.js');

const BASE = 'http://localhost:8085';
const OUT = path.join(__dirname, 'proof');
fs.mkdirSync(OUT, { recursive: true });
const results = [];
const check = (name, ok, extra = '') => {
  results.push({ name, ok: !!ok });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  ' + extra : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(fn, ms = 10000, step = 150) {
  const end = Date.now() + ms;
  for (;;) {
    try {
      const v = await fn();
      if (v) return v;
    } catch {
      /* retry */
    }
    if (Date.now() > end) return false;
    await sleep(step);
  }
}
const SECURITY = ['content-security-policy', 'x-frame-options', 'x-content-type-options', 'referrer-policy', 'permissions-policy', 'cross-origin-opener-policy', 'cross-origin-resource-policy', 'x-robots-tag', 'strict-transport-security'];

(async () => {
  // ---- static answers ----
  const idx = await fetch(`${BASE}/`);
  const csp = idx.headers.get('content-security-policy') || '';
  check('the page is served', idx.status === 200 && /id="root"/.test(await idx.text()));
  check('server banner has no version', idx.headers.get('server') === 'nginx');
  check('CSP: self only, no framing, no objects, no base tag, no form posts', /default-src 'self'/.test(csp) && /frame-ancestors 'none'/.test(csp) && /object-src 'none'/.test(csp) && /base-uri 'none'/.test(csp) && /form-action 'none'/.test(csp) && !/unsafe-eval/.test(csp) && !/script-src[^;]*unsafe-inline/.test(csp));
  for (const [name, url] of [['page', '/'], ['link page', '/open/anything-here'], ['index.html', '/index.html']]) {
    const r = await fetch(BASE + url);
    const missing = SECURITY.filter((h) => !r.headers.get(h));
    check(`${name}: all nine security headers present and no-store`, missing.length === 0 && r.headers.get('cache-control') === 'no-store', missing.join(','));
  }
  const link404 = await fetch(`${BASE}/open/abc/def`);
  check('the link page works for any token path (single-page fallback)', link404.status === 200 && /id="root"/.test(await link404.text()));
  const asset = /\/assets\/[^"']+\.js/.exec(await (await fetch(`${BASE}/`)).text())[0];
  const a = await fetch(BASE + asset);
  check('built assets are cached for a year, immutable, with the security headers', a.status === 200 && /max-age=31536000/.test(a.headers.get('cache-control')) && /immutable/.test(a.headers.get('cache-control')) && !!a.headers.get('x-content-type-options') && /javascript/.test(a.headers.get('content-type')));
  for (const p of ['/.env', '/.git/config', '/src/main.jsx', '/package.json', '/assets/', '/assets/../index.html.bak']) {
    const r = await fetch(BASE + p);
    check(`not served: ${p}`, r.status === 404 || r.status === 403, `status ${r.status}`);
  }
  const traceStatus = await new Promise((resolve) => {
    const rq = http.request(BASE + '/', { method: 'TRACE' }, (res) => {
      res.resume();
      resolve(res.statusCode);
    });
    rq.on('error', () => resolve(0));
    rq.end();
  });
  check('TRACE is refused', traceStatus === 405, `status ${traceStatus}`);

  // ---- the API through the proxy ----
  const wrong = await fetch(`${BASE}/api/v1/editor/open`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: 'nope' }) });
  check('API through nginx: wrong token is the backend\'s plain 404', wrong.status === 404 && /json/.test(wrong.headers.get('content-type')));
  const dup = SECURITY.filter((h) => { const v = wrong.headers.get(h) || ''; const parts = v.split(/,\s*(?=[A-Za-z-]+\s*[=:]?\s|max-age|nosniff|no-referrer|DENY|same-origin|noindex)/); return new Set(parts).size !== parts.length || /(nosniff, nosniff|no-referrer, no-referrer|DENY, DENY|same-origin, same-origin|max-age=\d+[^,]*, max-age)/i.test(v); });
  check('each security header appears once on API answers (no doubled values)', dup.length === 0, dup.join(','));
  check('API answers keep no-store from the backend', wrong.headers.get('cache-control') === 'no-store');

  // ---- rate limit in front of the backend ----
  const codes = [];
  for (let i = 0; i < 16; i++) codes.push((await fetch(`${BASE}/api/v1/editor/open`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: `guess-${i}` }) })).status);
  console.log('open attempts through nginx:', codes.join(' '));
  check('nginx stops token guessing (429 after the burst)', codes.includes(429) && codes.indexOf(429) <= 8, `first 429 at try ${codes.indexOf(429) + 1}`);
  await sleep(7000); // let the limiter refill before the real browser flow

  // ---- a real edit in Chrome through nginx ----
  const s = await seed();
  const link = await newLink(s.token, s.surveyId);
  let browser;
  for (const channel of ['chrome', 'msedge']) {
    try {
      browser = await chromium.launch({ channel, headless: true });
      break;
    } catch {
      /* next */
    }
  }
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => {
    if (m.type() === 'error' && !/Failed to load resource|net::ERR/.test(m.text())) errors.push(m.text());
  });
  await page.addInitScript(() => document.addEventListener('securitypolicyviolation', (e) => (window.__v = (window.__v || []).concat(e.violatedDirective))));
  await page.goto(`${BASE}/open/${link.rawToken}`);
  await enterEditor(page);
  await page.locator('.workspace').waitFor({ timeout: 15000 });
  check('the token is gone from the address bar (the page now shows /editor)', !page.url().includes(link.rawToken) && page.url() === `${BASE}/editor`, page.url());
  check('the session cookie is HttpOnly and cannot be read by the page', (await page.evaluate(() => document.cookie)) === '');
  const cookies = await ctx.cookies();
  const c = cookies.find((x) => x.name === 'ss_editor');
  check('cookie flags as the backend set them: HttpOnly, SameSite=Strict, path /api/v1/editor', c && c.httpOnly && c.sameSite === 'Strict' && c.path === '/api/v1/editor', JSON.stringify(c && { h: c.httpOnly, s: c.sameSite, p: c.path }));
  await page.reload();
  const cont = page.getByRole('button', { name: 'Continue to the editor' });
  await Promise.race([cont.waitFor({ timeout: 6000 }).then(() => cont.click()), page.locator('.workspace').waitFor({ timeout: 6000 })]).catch(() => {});
  check('reloading /editor behind nginx still opens the editor (not a 404)', await page.locator('.workspace').waitFor({ timeout: 8000 }).then(() => true).catch(() => false), page.url());
  await page.locator('.sections button', { hasText: 'E1. Roof coverings' }).click();
  await page.locator('.block.block-paragraph').first().locator('.textview').click();
  await page.locator('.block.is-active .pm').click();
  await page.keyboard.type(' Edited through nginx.');
  await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
  check('an edit saves through nginx', await until(async () => (await page.locator('.chip.state').innerText()) === 'Saved'));
  check('and is in the database', await until(async () => JSON.stringify((await prisma.report.findUniqueOrThrow({ where: { id: s.surveyId } })).content).includes('Edited through nginx.')));
  // photo through nginx
  const jpg = await sharp({ create: { width: 800, height: 600, channels: 3, background: '#445566' } }).jpeg({ quality: 90 }).toBuffer();
  const up = await page.evaluate(async ({ id, b64, v }) => {
    const fd = new FormData();
    fd.append('file', new Blob([Uint8Array.from(atob(b64), (ch) => ch.charCodeAt(0))], { type: 'image/jpeg' }), 'p.jpg');
    fd.append('expectedReportVersion', String(v));
    const r = await fetch(`/api/v1/editor/reports/${id}/photos`, { method: 'POST', credentials: 'include', headers: { 'X-CSRF-Token': sessionStorage.getItem('ss_editor_csrf') }, body: fd });
    return r.status;
  }, { id: s.surveyId, b64: jpg.toString('base64'), v: (await prisma.report.findUniqueOrThrow({ where: { id: s.surveyId } })).version });
  check('a photo upload goes through nginx (201)', up === 201, `status ${up}`);
  const big = await page.evaluate(async ({ id }) => {
    const fd = new FormData();
    fd.append('file', new Blob([new Uint8Array(14 * 1024 * 1024)], { type: 'image/jpeg' }), 'big.jpg');
    fd.append('expectedReportVersion', '1');
    const r = await fetch(`/api/v1/editor/reports/${id}/photos`, { method: 'POST', credentials: 'include', headers: { 'X-CSRF-Token': sessionStorage.getItem('ss_editor_csrf') }, body: fd });
    return r.status;
  }, { id: s.surveyId });
  check('a 14 MB body is stopped by nginx (413) before it reaches the backend', big === 413, `status ${big}`);
  // AI route (long timeout location) through nginx
  const ai = await page.evaluate(async ({ id, block, v }) => {
    const r = await fetch(`/api/v1/editor/reports/${id}/ai/suggest`, { method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': sessionStorage.getItem('ss_editor_csrf') }, body: JSON.stringify({ blockId: block, action: 'IMPROVE', expectedReportVersion: v }) });
    return r.status;
  }, { id: s.surveyId, block: s.content[0].blocks[0].id, v: (await prisma.report.findUniqueOrThrow({ where: { id: s.surveyId } })).version });
  check('the AI route is proxied (200 with the fake model, or 503 if it is off)', ai === 200 || ai === 503, `status ${ai}`);
  const violations = await page.evaluate(() => window.__v || []);
  check('the real nginx CSP breaks nothing: no violation, no console error', violations.length === 0 && errors.length === 0, `${violations.join(',')} ${errors.join(' | ')}`);
  await page.screenshot({ path: path.join(OUT, 'd8_03_editor_behind_nginx.png') });

  // ---- clickjacking: another site framing the editor ----
  const evil = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`<!doctype html><title>evil</title><h1>Win a prize</h1><iframe id="f" src="${BASE}/" width="900" height="500"></iframe>`);
  });
  await new Promise((r) => evil.listen(9997, '127.0.0.1', r));
  const evilPage = await ctx.newPage();
  const frameMsgs = [];
  evilPage.on('console', (m) => frameMsgs.push(m.text()));
  await evilPage.goto('http://127.0.0.1:9997/');
  await sleep(1500);
  const framed = await evilPage.evaluate(() => {
    const f = document.getElementById('f');
    try {
      return !!f.contentDocument && f.contentDocument.location.href !== 'about:blank' ? 'loaded' : 'empty';
    } catch {
      return 'cross-origin';
    }
  });
  const frames = evilPage.frames().map((f) => f.url());
  check('another site cannot show the editor in a frame', !frames.some((u) => u.startsWith(BASE) && !u.startsWith('chrome-error')) || frames.some((u) => u.startsWith('chrome-error')), `frames: ${frames.join(' , ')} / ${framed} / ${frameMsgs.find((m) => /frame|ancestor/i.test(m)) || ''}`.slice(0, 220));
  await evilPage.screenshot({ path: path.join(OUT, 'd8_04_framing_blocked.png') });
  await new Promise((r) => evil.close(r));
  await browser.close();

  // ---- the access log never holds a token ----
  const log = execSync('docker exec ss_editor_nginx cat /var/log/nginx/editor-access.log', { encoding: 'utf8' });
  check('nginx access log: the link token never appears', !log.includes(link.rawToken) && !/guess-\d/.test(log.replace(/api\/v1\/editor\/open/g, '')) === true);
  check('nginx access log: link page requests are written as /open/[token]', /"GET \/open\/\[token\] /.test(log), `${log.split('\n').length} lines`);
  const errLog = execSync('docker logs ss_editor_nginx 2>&1', { encoding: 'utf8' });
  check('nginx error log: the link token never appears', !errLog.includes(link.rawToken));

  await prisma.$disconnect();
  const failed = results.filter((r) => !r.ok);
  fs.writeFileSync(path.join(OUT, 'd8_nginx_results.json'), JSON.stringify(results, null, 2));
  console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
