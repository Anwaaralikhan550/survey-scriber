// D8 live security checks against running backends: default rate limits (:3098), headers, CORS, and that no secret is written to the server log (:3099).
// Run: node p25_security_live.js <path of the :3099 server log file>
const fs = require('fs');
const path = require('path');
const { prisma, seed, newLink } = require('./lib.js');

const LIVE = process.env.API || 'http://localhost:3099/api/v1';
const DEFAULTS = process.env.API_DEFAULTS || 'http://localhost:3098/api/v1';
const EDITOR_ORIGIN = 'http://localhost:5174';
const logFile = process.argv[2];
const OUT = path.join(__dirname, 'proof');
const results = [];
const check = (name, ok, extra = '') => {
  results.push({ name, ok: !!ok });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  ' + extra : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const post = (base, p, body, headers = {}) => fetch(base + p, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(body) });

(async () => {
  // ---- brute force on the token page, with the production defaults ----
  const codes = [];
  for (let i = 0; i < 14; i++) {
    const r = await post(DEFAULTS, '/editor/open', { token: `wrong-token-${i}-${Math.random().toString(36).slice(2)}` });
    codes.push(r.status);
  }
  console.log('open attempts:', codes.join(' '));
  check('guessing tokens is rate limited (429 appears within 14 tries)', codes.includes(429));
  check('before the limit a wrong token is a plain 404, with no detail', codes[0] === 404);
  const first429 = codes.indexOf(429);
  check('the limit starts early (within the first 11 tries)', first429 > 0 && first429 <= 11, `first 429 at try ${first429 + 1}`);
  const limited = await post(DEFAULTS, '/editor/open', { token: 'again' });
  check('a limited request gets no cookie and no report data', limited.status === 429 && !limited.headers.get('set-cookie'));

  // ---- headers and the token page ----
  const s = await seed();
  const link = await newLink(s.token, s.surveyId);
  await sleep(600);
  const open = await post(LIVE, '/editor/open', { token: link.rawToken });
  const cookie = open.headers.get('set-cookie');
  const body = await open.json();
  check('open: success with HttpOnly, SameSite=Strict cookie limited to /api/v1/editor', open.status === 200 && /HttpOnly/i.test(cookie) && /SameSite=Strict/i.test(cookie) && /Path=\/api\/v1\/editor/i.test(cookie));
  check('open: cache-control no-store, referrer-policy no-referrer, noindex', open.headers.get('cache-control') === 'no-store' && open.headers.get('referrer-policy') === 'no-referrer' && /noindex/.test(open.headers.get('x-robots-tag') || ''));
  const asGet = await fetch(`${LIVE}/editor/open/${'not-a-real-token-probe-12345'}`);
  check('a token in a URL does nothing on the API (the page POSTs it; GET is 404)', asGet.status === 404);
  const cookieHeader = cookie.split(';')[0];
  const refused = await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { headers: { Cookie: 'ss_editor=bad' } });
  check('a refused request still carries no-store / no-referrer', refused.status === 404 && refused.headers.get('cache-control') === 'no-store' && refused.headers.get('referrer-policy') === 'no-referrer');
  const read = await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { headers: { Cookie: cookieHeader } });
  check('read: security headers on a normal answer', read.status === 200 && read.headers.get('cache-control') === 'no-store' && /nosniff/i.test(read.headers.get('x-content-type-options') || ''), `x-content-type-options=${read.headers.get('x-content-type-options')}`);
  check('read: no server banner or framework header', !read.headers.get('x-powered-by'), `x-powered-by=${read.headers.get('x-powered-by')}`);

  // ---- CORS ----
  const good = await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { headers: { Cookie: cookieHeader, Origin: EDITOR_ORIGIN } });
  check('CORS: the editor origin is allowed, with credentials', good.headers.get('access-control-allow-origin') === EDITOR_ORIGIN && good.headers.get('access-control-allow-credentials') === 'true');
  const evil = await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { headers: { Cookie: cookieHeader, Origin: 'https://evil.example' } });
  check('CORS: another origin gets no permission to read the answer', !evil.headers.get('access-control-allow-origin'), `acao=${evil.headers.get('access-control-allow-origin')}`);
  const pre = await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { method: 'OPTIONS', headers: { Origin: EDITOR_ORIGIN, 'Access-Control-Request-Method': 'PATCH', 'Access-Control-Request-Headers': 'content-type,x-csrf-token' } });
  check('CORS preflight: PATCH with X-CSRF-Token is allowed from the editor origin', (pre.status === 204 || pre.status === 200) && /x-csrf-token/i.test(pre.headers.get('access-control-allow-headers') || ''));
  const preEvil = await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { method: 'OPTIONS', headers: { Origin: 'https://evil.example', 'Access-Control-Request-Method': 'PATCH', 'Access-Control-Request-Headers': 'content-type,x-csrf-token' } });
  check('CORS preflight: another origin is not allowed', !preEvil.headers.get('access-control-allow-origin'));

  // ---- the server log holds no secret ----
  await post(LIVE, '/editor/open', { token: link.rawToken });
  await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Cookie: cookieHeader, 'X-CSRF-Token': body.csrfToken }, body: JSON.stringify({ baseVersion: 1, changes: [] }) });
  await fetch(`${LIVE}/editor/reports/${s.surveyId}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Cookie: cookieHeader, 'X-CSRF-Token': 'wrong' }, body: JSON.stringify({ baseVersion: 1, changes: [{ op: 'updateBlock', fields: { text: 'SECRET REPORT WORDING ZZ91' } }] }) });
  await sleep(800);
  if (logFile && fs.existsSync(logFile)) {
    const log = fs.readFileSync(logFile, 'utf8');
    check('server log: the link token never appears', !log.includes(link.rawToken));
    check('server log: the session cookie value never appears', !log.includes(cookieHeader.split('=')[1]));
    check('server log: the CSRF token never appears', !log.includes(body.csrfToken));
    check('server log: report wording sent in a refused request is not written either', !log.includes('SECRET REPORT WORDING ZZ91'));
    check('server log: the editor requests are logged (the check is looking at the right file)', /editor\/open/.test(log), `${log.length} characters`);
  } else {
    check('server log file given', false, 'pass the log path as the first argument');
  }

  await prisma.$disconnect();
  const failed = results.filter((r) => !r.ok);
  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, 'd8_security_live_results.json'), JSON.stringify(results, null, 2));
  console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
