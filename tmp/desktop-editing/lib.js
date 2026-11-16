// Helpers for the desktop-editor browser tests: seed a report through the real API, create an edit link.
// Run with: NODE_PATH="<backend>/node_modules;<global playwright node_modules>" DATABASE_URL=... node p20_editor.js
const { PrismaClient } = require('@prisma/client');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');

const API = process.env.API || 'http://localhost:3099/api/v1';
// Same secret the test backend was started with (Prisma loads backend/.env into process.env, so JWT_ACCESS_SECRET cannot be used here).
const SECRET = process.env.EDITOR_TEST_SECRET || 'e2e-local-only-access-secret-0123456789abcdef';
const prisma = new PrismaClient();

async function owner(email = 'desk.owner@example.com') {
  let u = await prisma.user.findUnique({ where: { email } });
  if (!u) u = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'Desk', lastName: 'Owner', role: 'SURVEYOR', isActive: true } });
  return { user: u, token: jwt.sign({ sub: u.id, email: u.email, role: u.role }, SECRET, { expiresIn: '2h' }) };
}

// The API's global rate limit (3 requests a second per address) applies to the test helpers too: space them out.
let lastCall = 0;
async function gate(ms = 450) {
  const wait = lastCall + ms - Date.now();
  if (wait > 0) await new Promise((r) => setTimeout(r, wait));
  lastCall = Date.now();
}

async function call(token, method, path, body) {
  for (let attempt = 0; ; attempt++) {
    await gate();
    const res = await fetch(API + path, { method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: body ? JSON.stringify(body) : undefined });
    const data = await res.json().catch(() => ({}));
    if (res.status === 429 && attempt < 6) {
      await new Promise((r) => setTimeout(r, 1200)); // the browser under test shares the per-address rate limit
      continue;
    }
    return { status: res.status, body: data };
  }
}

const P = (text, extra = {}) => ({ id: randomUUID(), type: 'paragraph', text, ...extra });

function sampleReport() {
  const ids = {};
  const mk = (key, title, blocks) => ({ id: randomUUID(), key, title, blocks });
  const content = [
    mk('A_ABOUT', 'A. About the inspection', [P('The inspection was carried out on 12 November 2026 in dry weather.'), P('The surveyor was not able to access the loft hatch in the rear bedroom.')]),
    mk('D_PROPERTY', 'D. About the property', [
      P('A two-storey semi-detached house of traditional brick and tile construction, built in the 1930s.'),
      { id: randomUUID(), type: 'table', table: { headers: ['Floor', 'Living', 'Beds', 'Bath'], rows: [['Ground', '2', '0', '0'], ['First', '0', '3', '1']] } },
    ]),
    mk('E1_ROOF', 'E1. Roof coverings', [
      P('The main roof is covered with concrete interlocking tiles which are in reasonable condition for their age.'),
      P('Some slipped and cracked tiles were seen to the rear slope.'),
      { id: randomUUID(), type: 'rating', rating: '2', required: true },
      { id: randomUUID(), type: 'recommendation', recommendation: 'Have a roofer repair the slipped tiles within the next few months.' },
    ]),
    mk('E2_CHIMNEY', 'E2. Chimney stacks', [P('The brick chimney stack to the left flank has weathered pointing.'), { id: randomUUID(), type: 'rating', rating: '1', required: true }]),
    mk('F_WALLS', 'F. Walls', [P('The walls are of cavity brick construction. Hairline cracking was seen over the front bay window.'), { id: randomUUID(), type: 'rating', rating: '2', required: true }]),
    mk('H_SUMMARY', 'H. Summary of condition', []),
  ];
  content.forEach((s) => s.blocks.forEach((b) => (ids[b.id] = s.key)));
  return content;
}

async function seed({ fresh = true } = {}) {
  const { user, token } = await owner();
  if (fresh) await prisma.survey.deleteMany({ where: { userId: user.id, title: 'DESK TEST' } });
  const survey = await prisma.survey.create({ data: { title: 'DESK TEST', propertyAddress: '54 Gas Lane, Dartford, Kent DA1 4PL', jobRef: 'VL1433', userId: user.id } });
  const content = sampleReport();
  const up = await call(token, 'PUT', `/reports/${survey.id}/snapshot`, { reportType: 'L2', content });
  if (up.status !== 200) throw new Error('snapshot failed ' + JSON.stringify(up.body));
  return { token, surveyId: survey.id, content, user };
}

async function newLink(token, surveyId) {
  const r = await call(token, 'POST', `/reports/${surveyId}/edit-links`);
  if (r.status !== 201) throw new Error('link failed ' + JSON.stringify(r.body));
  return { url: r.body.url, rawToken: r.body.url.split('/open/')[1], linkId: r.body.linkId };
}

module.exports = { prisma, owner, call, seed, newLink, API, gate };
