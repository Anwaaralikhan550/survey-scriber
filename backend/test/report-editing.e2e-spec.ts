/**
 * E2E: Secure desktop report editing (client spec v1.3), D1 backend.
 * Covers the spec's acceptance cases for links, tokens, sessions, version-checked saves and security headers.
 * Runs against the real API and a real PostgreSQL (the partial unique index included).
 */
import request = require('supertest');
import { randomUUID } from 'crypto';
import { UserRole, EditLinkStatus, ReportStatus } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const sha = (v: string) => require('crypto').createHash('sha256').update(v).digest('hex');

interface Fixture {
  userId: string;
  token: string;
  surveyId: string;
}

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}edit_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'E', lastName: tag, role, isActive: true } });
  }
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

async function makeSurvey(userId: string): Promise<string> {
  const s = await prisma.survey.create({ data: { title: `${TEST_PREFIX}edit`, propertyAddress: '1 Test Road', userId } });
  return s.id;
}

function content() {
  const sec = randomUUID();
  const p1 = randomUUID();
  const p2 = randomUUID();
  const req = randomUUID();
  return {
    sec,
    p1,
    p2,
    req,
    body: [
      {
        id: sec,
        key: 'E1_ROOF',
        title: 'Roof',
        blocks: [
          { id: p1, type: 'paragraph', text: 'Roof is tiled.' },
          { id: p2, type: 'paragraph', text: 'Chimney is brick.' },
          { id: req, type: 'rating', rating: '2', required: true },
        ],
      },
    ],
  };
}

const owner = (t: string) => ({ Authorization: `Bearer ${t}` });

async function uploadReport(f: Fixture) {
  const c = content();
  const res = await request(API).put(`/reports/${f.surveyId}/snapshot`).set(owner(f.token)).send({ reportType: 'L2', content: c.body });
  expect(res.status).toBe(200);
  return c;
}

async function createLink(f: Fixture) {
  const res = await request(API).post(`/reports/${f.surveyId}/edit-links`).set(owner(f.token));
  return res;
}

/** Open a link and return cookie header + csrf token for later calls. */
async function openLink(url: string) {
  const token = url.split('/open/')[1];
  const res = await request(API).post('/editor/open').send({ token });
  return { res, token, cookie: (res.headers['set-cookie'] as unknown as string[] | undefined)?.[0]?.split(';')[0], csrf: res.body.csrfToken as string };
}

describe('Desktop report editing (E2E)', () => {
  let a: Fixture;
  let b: Fixture; // another surveyor
  let admin: { id: string; token: string };
  let sessionOf = (cookie: string, csrf: string) => ({ Cookie: cookie, 'X-CSRF-Token': csrf });

  beforeAll(async () => {
    const ua = await makeUser('owner');
    const ub = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
    a = { userId: ua.id, token: ua.token, surveyId: await makeSurvey(ua.id) };
    b = { userId: ub.id, token: ub.token, surveyId: await makeSurvey(ub.id) };
  });

  afterAll(async () => {
    await prisma.survey.deleteMany({ where: { title: `${TEST_PREFIX}edit` } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}edit_` } } });
    await prisma.$disconnect();
  });

  describe('snapshot upload and version rules', () => {
    it('first upload creates version 1; a second upload must name the cloud version', async () => {
      await uploadReport(a);
      const latest = await request(API).get(`/reports/${a.surveyId}/latest`).set(owner(a.token));
      expect(latest.body).toMatchObject({ reportId: a.surveyId, version: 1, status: 'DRAFT' });

      const stale = await request(API).put(`/reports/${a.surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content: content().body });
      expect(stale.status).toBe(409);
      expect(stale.body.error).toBe('VERSION_CONFLICT');
      expect(stale.body.details.serverVersion).toBe(1);

      const ok = await request(API).put(`/reports/${a.surveyId}/snapshot`).set(owner(a.token)).send({ baseVersion: 1, reportType: 'L2', content: content().body });
      expect(ok.status).toBe(200);
      expect(ok.body.version).toBe(2);
    });

    it('rejects malformed content with VALIDATION_ERROR', async () => {
      const s = await makeSurvey(a.userId);
      const res = await request(API).put(`/reports/${s}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content: [{ id: 'bad', key: 'k', title: 't', blocks: [] }] });
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('VALIDATION_ERROR');
    });

    it('only the survey owner (or an admin) can upload', async () => {
      const res = await request(API).put(`/reports/${a.surveyId}/snapshot`).set(owner(b.token)).send({ baseVersion: 2, reportType: 'L2', content: content().body });
      expect(res.status).toBe(403);
      expect(res.body.error).toBe('FORBIDDEN');
      const noAuth = await request(API).put(`/reports/${a.surveyId}/snapshot`).send({});
      expect(noAuth.status).toBe(401);
    });
  });

  describe('link lifecycle', () => {
    let f: Fixture;
    beforeAll(async () => {
      f = { userId: a.userId, token: a.token, surveyId: await makeSurvey(a.userId) };
      await uploadReport(f);
    });

    it('creates a link that expires in 72 hours and stores only the token hash', async () => {
      const res = await createLink(f);
      expect(res.status).toBe(201);
      expect(res.body.policy).toBe('single-live-link');
      const hours = (new Date(res.body.expiresAt).getTime() - Date.now()) / 3600000;
      expect(hours).toBeGreaterThan(71.9);
      expect(hours).toBeLessThanOrEqual(72);
      const raw = res.body.url.split('/open/')[1];
      expect(raw.length).toBeGreaterThanOrEqual(43); // 256 bits, base64url
      const row = await prisma.editLink.findUniqueOrThrow({ where: { id: res.body.linkId } });
      expect(row.tokenHash).toBe(sha(raw));
      expect(JSON.stringify(row)).not.toContain(raw);
      const audits = await prisma.auditLog.findMany({ where: { entityId: f.surveyId } });
      expect(JSON.stringify(audits)).not.toContain(raw);
      expect(audits.map((x) => x.action)).toContain('EDIT_LINK_CREATED');
    });

    it('an existing live link blocks a new one (ACTIVE_LINK_EXISTS)', async () => {
      const res = await createLink(f);
      expect(res.status).toBe(409);
      expect(res.body.error).toBe('ACTIVE_LINK_EXISTS');
    });

    it('cancelling frees the slot; the old link and its session stop at once', async () => {
      const cur = await request(API).get(`/reports/${f.surveyId}/edit-links/current`).set(owner(f.token));
      expect(cur.body.active).toBe(true);
      const del = await request(API).delete(`/reports/${f.surveyId}/edit-links/${cur.body.linkId}`).set(owner(f.token));
      expect(del.status).toBe(200);
      expect(del.body.status).toBe('CANCELLED');
      const none = await request(API).get(`/reports/${f.surveyId}/edit-links/current`).set(owner(f.token));
      expect(none.body.active).toBe(false);
      const next = await createLink(f);
      expect(next.status).toBe(201);
    });

    it('an expired live link is replaced by a new one and marked EXPIRED', async () => {
      const cur = await request(API).get(`/reports/${f.surveyId}/edit-links/current`).set(owner(f.token));
      await prisma.editLink.update({ where: { id: cur.body.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
      const next = await createLink(f);
      expect(next.status).toBe(201);
      const old = await prisma.editLink.findUniqueOrThrow({ where: { id: cur.body.linkId } });
      expect(old.status).toBe(EditLinkStatus.EXPIRED);
    });

    it('two simultaneous create requests produce exactly one active link', async () => {
      const s = await makeSurvey(a.userId);
      const g = { userId: a.userId, token: a.token, surveyId: s };
      await uploadReport(g);
      const results = await Promise.all([createLink(g), createLink(g), createLink(g), createLink(g)]);
      expect(results.filter((r: { status: number }) => r.status === 201)).toHaveLength(1);
      expect(results.filter((r: { status: number }) => r.status === 409)).toHaveLength(3);
      expect(await prisma.editLink.count({ where: { reportId: s, status: EditLinkStatus.ACTIVE } })).toBe(1);
    });

    it('the database itself refuses a second ACTIVE link (partial unique index)', async () => {
      const s = await makeSurvey(a.userId);
      await uploadReport({ userId: a.userId, token: a.token, surveyId: s });
      const make = (h: string) => prisma.editLink.create({ data: { reportId: s, tokenHash: h, createdBy: a.userId, expiresAt: new Date(Date.now() + 3600000) } });
      await make(sha('one'));
      await expect(make(sha('two'))).rejects.toThrow();
    });

    it('only the owner or an admin can create, cancel, sync and read the version', async () => {
      const x = await request(API).post(`/reports/${a.surveyId}/edit-links`).set(owner(b.token));
      expect(x.status).toBe(403);
      expect((await request(API).post(`/reports/${a.surveyId}/sync`).set(owner(b.token))).status).toBe(403);
      expect((await request(API).get(`/reports/${a.surveyId}/latest`).set(owner(b.token))).status).toBe(403);
      const missing = await request(API).post(`/reports/${randomUUID()}/edit-links`).set(owner(a.token));
      expect(missing.status).toBe(404);
      const byAdmin = await request(API).get(`/reports/${a.surveyId}/latest`).set(owner(admin.token));
      expect(byAdmin.status).toBe(200);
    });

    it('an admin who is not the owner revokes (status REVOKED, not CANCELLED)', async () => {
      const s = await makeSurvey(a.userId);
      const g = { userId: a.userId, token: a.token, surveyId: s };
      await uploadReport(g);
      const link = await createLink(g);
      const del = await request(API).delete(`/reports/${s}/edit-links/${link.body.linkId}`).set(owner(admin.token));
      expect(del.body.status).toBe('REVOKED');
    });
  });

  describe('opening a link', () => {
    let f: Fixture;
    let url: string;
    beforeAll(async () => {
      f = { userId: a.userId, token: a.token, surveyId: await makeSurvey(a.userId) };
      await uploadReport(f);
      url = (await createLink(f)).body.url;
    });

    it('a wrong token is LINK_INVALID and reveals nothing', async () => {
      const res = await request(API).post('/editor/open').send({ token: 'A'.repeat(43) });
      expect(res.status).toBe(404);
      expect(res.body.error).toBe('LINK_INVALID');
      expect(JSON.stringify(res.body)).not.toContain('Roof');
    });

    it('rejects a token with characters outside base64url', async () => {
      const res = await request(API).post('/editor/open').send({ token: "'; DROP TABLE reports;--" });
      expect(res.status).toBe(400);
    });

    it('sets an HttpOnly, SameSite=Strict cookie and sends no-store, no-referrer, noindex headers', async () => {
      const { res } = await openLink(url);
      expect(res.status).toBe(200);
      const cookie = (res.headers['set-cookie'] as unknown as string[])[0];
      expect(cookie).toMatch(/ss_editor=/);
      expect(cookie).toMatch(/HttpOnly/i);
      expect(cookie).toMatch(/SameSite=Strict/i);
      expect(cookie).toMatch(/Path=\/api\/v1\/editor/);
      expect(res.headers['cache-control']).toBe('no-store');
      expect(res.headers['referrer-policy']).toBe('no-referrer');
      expect(res.headers['x-robots-tag']).toMatch(/noindex/);
      expect(res.body.reportId).toBe(f.surveyId);
      expect(res.body.csrfToken.length).toBeGreaterThanOrEqual(43);
      const raw = (res.headers['set-cookie'] as unknown as string[])[0].split(';')[0].split('=')[1];
      const row = await prisma.editorSession.findFirstOrThrow({ where: { reportId: f.surveyId }, orderBy: { createdAt: 'desc' } });
      expect(row.sessionHash).toBe(sha(raw));
      expect(row.sessionHash).not.toBe(raw);
    });

    it('an expired link answers LINK_EXPIRED with no report content', async () => {
      const s = await makeSurvey(a.userId);
      const g = { userId: a.userId, token: a.token, surveyId: s };
      await uploadReport(g);
      const l = await createLink(g);
      await prisma.editLink.update({ where: { id: l.body.linkId }, data: { expiresAt: new Date(Date.now() - 5000) } });
      const res = await request(API).post('/editor/open').send({ token: l.body.url.split('/open/')[1] });
      expect(res.status).toBe(410);
      expect(res.body.error).toBe('LINK_EXPIRED');
      expect(JSON.stringify(res.body)).not.toContain('Roof');
      expect((await prisma.editLink.findUniqueOrThrow({ where: { id: l.body.linkId } })).status).toBe(EditLinkStatus.EXPIRED);
    });

    it('a cancelled link answers LINK_REVOKED', async () => {
      const s = await makeSurvey(a.userId);
      const g = { userId: a.userId, token: a.token, surveyId: s };
      await uploadReport(g);
      const l = await createLink(g);
      await request(API).delete(`/reports/${s}/edit-links/${l.body.linkId}`).set(owner(a.token));
      const res = await request(API).post('/editor/open').send({ token: l.body.url.split('/open/')[1] });
      expect(res.status).toBe(410);
      expect(res.body.error).toBe('LINK_REVOKED');
    });

    it('a new link invalidates the previous link and its sessions', async () => {
      const s = await makeSurvey(a.userId);
      const g = { userId: a.userId, token: a.token, surveyId: s };
      await uploadReport(g);
      const first = await createLink(g);
      const sess = await openLink(first.body.url);
      await prisma.editLink.update({ where: { id: first.body.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
      const second = await createLink(g);
      expect(second.status).toBe(201);
      const read = await request(API).get(`/editor/reports/${s}`).set('Cookie', sess.cookie!);
      expect(read.status).toBe(404); // session revoked
      const old = await request(API).post('/editor/open').send({ token: sess.token });
      expect(old.body.error).toBe('LINK_EXPIRED');
    });

    it('the editor API needs the session cookie, and the owner API needs the app login', async () => {
      expect((await request(API).get(`/editor/reports/${f.surveyId}`)).status).toBe(404);
      expect((await request(API).patch(`/editor/reports/${f.surveyId}`).send({ baseVersion: 1, changes: [] })).status).toBe(404);
      const sess = await openLink(url);
      expect((await request(API).get(`/reports/${f.surveyId}/latest`).set('Cookie', sess.cookie!)).status).toBe(401);
      expect((await request(API).post(`/reports/${f.surveyId}/edit-links`).set('Cookie', sess.cookie!)).status).toBe(401);
    });
  });

  describe('saving', () => {
    let f: Fixture;
    let c: ReturnType<typeof content>;
    let sess: { cookie: string; csrf: string; token: string };
    let linkId: string;
    let url: string;

    beforeEach(async () => {
      f = { userId: a.userId, token: a.token, surveyId: await makeSurvey(a.userId) };
      c = await uploadReport(f);
      const l = await createLink(f);
      linkId = l.body.linkId;
      url = l.body.url;
      const o = await openLink(l.body.url);
      sess = { cookie: o.cookie!, csrf: o.csrf, token: o.token };
    });

    const edit = (text: string, extra: Record<string, unknown> = {}) => ({
      baseVersion: 1,
      changes: [{ op: 'updateBlock', sectionId: c.sec, blockId: c.p1, fields: { text } }],
      ...extra,
    });

    it('reads the structured report with version, status and expiry', async () => {
      const res = await request(API).get(`/editor/reports/${f.surveyId}`).set('Cookie', sess.cookie);
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ reportId: f.surveyId, version: 1, status: 'DRAFT', readOnly: false, reportType: 'L2' });
      expect(res.body.content[0].blocks).toHaveLength(3);
      expect(res.body.linkExpiresAt).toBeDefined();
    });

    it('refuses a write without the CSRF header or with a wrong one', async () => {
      const none = await request(API).patch(`/editor/reports/${f.surveyId}`).set('Cookie', sess.cookie).send(edit('x'));
      expect(none.status).toBe(403);
      expect(none.body.error).toBe('CSRF_INVALID');
      const wrong = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, 'A'.repeat(43))).send(edit('x'));
      expect(wrong.body.error).toBe('CSRF_INVALID');
      expect((await prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } })).version).toBe(1);
    });

    it('saves, raises the version, and the owner sees it on sync and latest', async () => {
      const res = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('Roof is slate.'));
      expect(res.status).toBe(200);
      expect(res.body.version).toBe(2);
      const latest = await request(API).get(`/reports/${f.surveyId}/latest`).set(owner(f.token));
      expect(latest.body.version).toBe(2);
      const sync = await request(API).post(`/reports/${f.surveyId}/sync`).set(owner(f.token));
      expect(sync.body.version).toBe(2);
      expect(sync.body.content[0].blocks[0].text).toBe('Roof is slate.');
      expect(sync.body.content[0].blocks[0].id).toBe(c.p1); // stable id kept
    });

    it('a stale save returns 409 VERSION_CONFLICT and does not overwrite', async () => {
      await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('First save'));
      const stale = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('Stale save'));
      expect(stale.status).toBe(409);
      expect(stale.body.error).toBe('VERSION_CONFLICT');
      expect(stale.body.details.serverVersion).toBe(2);
      const r = await prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } });
      expect((r.content as any)[0].blocks[0].text).toBe('First save');
      const audits = await prisma.auditLog.findMany({ where: { entityId: f.surveyId, action: 'REPORT_CONFLICT_DETECTED' } });
      expect(audits).toHaveLength(1);
    });

    it('two simultaneous saves on the same version: exactly one wins', async () => {
      const [x, y] = await Promise.all([
        request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('Writer X')),
        request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('Writer Y')),
      ]);
      expect([x.status, y.status].sort()).toEqual([200, 409]);
      expect((await prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } })).version).toBe(2);
    });

    it('a retried save with the same idempotency key is applied once', async () => {
      const key = randomUUID();
      const one = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('Once', { idempotencyKey: key }));
      const two = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('Once', { idempotencyKey: key }));
      expect(one.body.version).toBe(2);
      expect(two.status).toBe(200);
      expect(two.body.version).toBe(2);
      expect(two.body.replayed).toBe(true);
      expect(await prisma.reportVersion.count({ where: { reportId: f.surveyId } })).toBe(2);
    });

    it('add, move and delete paragraphs persist; required template fields stay', async () => {
      const nb = randomUUID();
      const h = sessionOf(sess.cookie, sess.csrf);
      const add = await request(API).patch(`/editor/reports/${f.surveyId}`).set(h).send({
        baseVersion: 1,
        changes: [
          { op: 'addBlock', sectionId: c.sec, afterBlockId: c.p1, block: { id: nb, type: 'paragraph', text: 'Added <b>note</b>' } },
          { op: 'moveBlock', sectionId: c.sec, blockId: c.p2, afterBlockId: null },
        ],
      });
      expect(add.status).toBe(200);
      const r1 = await request(API).get(`/editor/reports/${f.surveyId}`).set('Cookie', sess.cookie);
      expect(r1.body.content[0].blocks.map((x: any) => x.id)).toEqual([c.p1, nb, c.req, c.p2]);
      expect(r1.body.content[0].blocks[1].text).toBe('Added note');
      const del = await request(API).patch(`/editor/reports/${f.surveyId}`).set(h).send({ baseVersion: 2, changes: [{ op: 'deleteBlock', sectionId: c.sec, blockId: nb }] });
      expect(del.status).toBe(200);
      const bad = await request(API).patch(`/editor/reports/${f.surveyId}`).set(h).send({ baseVersion: 3, changes: [{ op: 'deleteBlock', sectionId: c.sec, blockId: c.req }] });
      expect(bad.status).toBe(400);
      expect(bad.body.error).toBe('VALIDATION_ERROR');
      expect((await prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } })).version).toBe(3);
    });

    it('rating and recommendation edits persist and a bad rating is refused', async () => {
      const h = sessionOf(sess.cookie, sess.csrf);
      const ok = await request(API).patch(`/editor/reports/${f.surveyId}`).set(h).send({
        baseVersion: 1,
        changes: [{ op: 'updateBlock', sectionId: c.sec, blockId: c.req, fields: { rating: '3' } }],
      });
      expect(ok.status).toBe(200);
      const bad = await request(API).patch(`/editor/reports/${f.surveyId}`).set(h).send({
        baseVersion: 2,
        changes: [{ op: 'updateBlock', sectionId: c.sec, blockId: c.req, fields: { rating: '7' } }],
      });
      expect(bad.status).toBe(400);
    });

    it('sequential users on the same link: the second sees the first one\'s committed change', async () => {
      await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('From colleague 1'));
      const second = await openLink(url);
      expect(second.res.status).toBe(200);
      const read = await request(API).get(`/editor/reports/${f.surveyId}`).set('Cookie', second.cookie!);
      expect(read.body.version).toBe(2);
      expect(read.body.content[0].blocks[0].text).toBe('From colleague 1');
      const save = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(second.cookie!, second.csrf)).send({
        baseVersion: 2,
        changes: [{ op: 'updateBlock', sectionId: c.sec, blockId: c.p2, fields: { text: 'From colleague 2' } }],
      });
      expect(save.body.version).toBe(3);
      const sync = await request(API).post(`/reports/${f.surveyId}/sync`).set(owner(f.token));
      expect(sync.body.content[0].blocks.map((x: any) => x.text).slice(0, 2)).toEqual(['From colleague 1', 'From colleague 2']);
    });

    it('cancelling the link blocks writes at once', async () => {
      await request(API).delete(`/reports/${f.surveyId}/edit-links/${linkId}`).set(owner(f.token));
      const res = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('too late'));
      expect(res.status).toBe(410);
      expect(res.body.error).toBe('LINK_REVOKED');
      expect((await prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } })).version).toBe(1);
    });

    it('when the link expires mid-session the editor can read but not write', async () => {
      await prisma.editLink.update({ where: { id: linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
      const read = await request(API).get(`/editor/reports/${f.surveyId}`).set('Cookie', sess.cookie);
      expect(read.status).toBe(200);
      expect(read.body.readOnly).toBe(true);
      expect(read.body.readOnlyReason).toBe('LINK_EXPIRED');
      const w = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('late'));
      expect(w.status).toBe(410);
      expect(w.body.error).toBe('LINK_EXPIRED');
    });

    it('a session cannot touch a different report', async () => {
      const other = await makeSurvey(a.userId);
      await uploadReport({ userId: a.userId, token: a.token, surveyId: other });
      expect((await request(API).get(`/editor/reports/${other}`).set('Cookie', sess.cookie)).status).toBe(403);
    });

    it('finalisation locks everything: editor, owner upload, new links, phone sync, new sessions', async () => {
      const section = await prisma.section.create({ data: { surveyId: f.surveyId, title: 'S', order: 0 } });
      await prisma.report.update({ where: { id: f.surveyId }, data: { status: ReportStatus.FINALISED } });
      const w = await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(sess.cookie, sess.csrf)).send(edit('after final'));
      expect(w.status).toBe(403);
      expect(w.body.error).toBe('REPORT_FINALISED');
      const read = await request(API).get(`/editor/reports/${f.surveyId}`).set('Cookie', sess.cookie);
      expect(read.body.readOnly).toBe(true);
      expect(read.body.readOnlyReason).toBe('REPORT_FINALISED');
      const up = await request(API).put(`/reports/${f.surveyId}/snapshot`).set(owner(f.token)).send({ baseVersion: 1, reportType: 'L2', content: c.body });
      expect(up.body.error).toBe('REPORT_FINALISED');
      expect((await createLink(f)).body.error).toBe('REPORT_FINALISED');
      const reopen = await request(API).post('/editor/open').send({ token: sess.token });
      expect(reopen.body.error).toBe('REPORT_FINALISED');
      const push = await request(API)
        .post('/sync/push')
        .set(owner(f.token))
        .send({
          idempotencyKey: randomUUID(),
          operations: [{ operationId: randomUUID(), entityType: 'SECTION', operationType: 'UPDATE', entityId: section.id, data: { title: 'Changed' } }],
        });
      expect(JSON.stringify(push.body)).toContain('REPORT_FINALISED');
      expect((await prisma.section.findUniqueOrThrow({ where: { id: section.id } })).title).toBe('S');
    });
  });

  describe('version history', () => {
    it('keeps one snapshot per version and the owner can restore an earlier one as a new version', async () => {
      const f = { userId: a.userId, token: a.token, surveyId: await makeSurvey(a.userId) };
      const c = await uploadReport(f);
      const l = await createLink(f);
      const o = await openLink(l.body.url);
      await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(o.cookie!, o.csrf)).send({
        baseVersion: 1,
        changes: [{ op: 'updateBlock', sectionId: c.sec, blockId: c.p1, fields: { text: 'Edited in browser' } }],
      });
      const list = await request(API).get(`/reports/${f.surveyId}/versions`).set(owner(f.token));
      expect(list.body.versions.map((v: any) => [v.version, v.reason])).toEqual([[2, 'SAVE'], [1, 'SNAPSHOT']]);
      expect(list.body.versions[0].savedBy).toMatch(/^session:/);
      const stale = await request(API).post(`/reports/${f.surveyId}/versions/1/restore`).set(owner(f.token)).send({ baseVersion: 1 });
      expect(stale.status).toBe(409);
      const res = await request(API).post(`/reports/${f.surveyId}/versions/1/restore`).set(owner(f.token)).send({ baseVersion: 2 });
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ version: 3, restoredFrom: 1 });
      const sync = await request(API).post(`/reports/${f.surveyId}/sync`).set(owner(f.token));
      expect(sync.body.content[0].blocks[0].text).toBe('Roof is tiled.');
      const all = await request(API).get(`/reports/${f.surveyId}/versions`).set(owner(f.token));
      expect(all.body.versions).toHaveLength(3);
      expect((await request(API).get(`/reports/${f.surveyId}/versions`).set(owner(b.token))).status).toBe(403);
    });
  });

  describe('audit trail', () => {
    it('records link, open, save, conflict and sync events without tokens', async () => {
      const f = { userId: a.userId, token: a.token, surveyId: await makeSurvey(a.userId) };
      const c = await uploadReport(f);
      const l = await createLink(f);
      const o = await openLink(l.body.url);
      await request(API).patch(`/editor/reports/${f.surveyId}`).set(sessionOf(o.cookie!, o.csrf)).send({
        baseVersion: 1,
        changes: [{ op: 'updateBlock', sectionId: c.sec, blockId: c.p1, fields: { text: 'a' } }],
      });
      await request(API).post(`/reports/${f.surveyId}/sync`).set(owner(f.token));
      const rows = await prisma.auditLog.findMany({ where: { entityId: f.surveyId } });
      const actions = rows.map((r) => r.action);
      for (const want of ['REPORT_SNAPSHOT_UPLOADED', 'EDIT_LINK_CREATED', 'REPORT_OPENED', 'REPORT_SAVED', 'REPORT_SYNCHRONISED']) {
        expect(actions).toContain(want);
      }
      const dump = JSON.stringify(rows);
      expect(dump).not.toContain(o.token);
      expect(dump).not.toContain(o.cookie!.split('=')[1]);
      expect(dump).not.toContain(o.csrf);
    });
  });
});
