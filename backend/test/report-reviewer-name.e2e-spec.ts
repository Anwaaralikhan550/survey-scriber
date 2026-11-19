/**
 * E2E: the reviewer display name (Remote Editor spec v1.4 sections 7 and 18, client decision of 19 Nov): the link stays frictionless,
 * the person types a name when the link is opened, the name is kept with the link session and written into the amendment history,
 * the review entries and the version list, always as not verified.
 */
import request = require('supertest');
import { randomUUID } from 'crypto';
import { UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const TITLE = `${TEST_PREFIX}rname`;

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}rname_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

interface Sess {
  cookie: string;
  csrf: string;
  id: string;
}

describe('Reviewer display name (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let surveyId: string;
  let sectionId: string;
  let blockId: string;
  let rawToken: string;
  let s: Sess;

  async function openSession(): Promise<Sess> {
    const open = await request(API).post('/editor/open').send({ token: rawToken });
    expect(open.status).toBe(200);
    const row = await prisma.editorSession.findFirstOrThrow({ where: { reportId: surveyId }, orderBy: { createdAt: 'desc' } });
    return { cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], csrf: open.body.csrfToken, id: row.id };
  }
  const h = (x: Sess = s) => ({ Cookie: x.cookie, 'X-CSRF-Token': x.csrf });
  const setName = (name: unknown, x: Sess = s) => request(API).put('/editor/session/name').set(h(x)).send({ name });
  const version = async () => (await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).version;
  const save = async (text: string, x: Sess = s) =>
    request(API).patch(`/editor/reports/${surveyId}`).set(h(x)).send({ baseVersion: await version(), idempotencyKey: randomUUID(), changes: [{ op: 'updateBlock', sectionId, blockId, fields: { text } }] });

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
  });
  beforeEach(async () => {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '6 Name Road', userId: a.id } });
    surveyId = survey.id;
    sectionId = randomUUID();
    blockId = randomUUID();
    const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'The roof is tiled.' }] }];
    expect((await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content })).status).toBe(200);
    const link = await request(API).post(`/reports/${surveyId}/edit-links`).set(owner(a.token));
    rawToken = link.body.url.split('/open/')[1];
    s = await openSession();
  });
  afterAll(async () => {
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}rname_` } } });
    await prisma.$disconnect();
  });

  it('a new session has no name; the editor is told so and the name is marked not verified', async () => {
    const r = await request(API).get(`/editor/reports/${surveyId}`).set({ Cookie: s.cookie });
    expect(r.status).toBe(200);
    expect(r.body.reviewer).toEqual({ name: null, verified: false });
  });

  it('the person gives a name; it is kept, tidied, and shown on the next read', async () => {
    const r = await setName('  Jane    Smith ');
    expect(r.status).toBe(200);
    expect(r.body).toEqual({ name: 'Jane Smith', verified: false });
    expect((await prisma.editorSession.findUniqueOrThrow({ where: { id: s.id } })).reviewerName).toBe('Jane Smith');
    expect((await request(API).get(`/editor/reports/${surveyId}`).set({ Cookie: s.cookie })).body.reviewer).toEqual({ name: 'Jane Smith', verified: false });
  });

  it('names in other languages and markup: letters stay, tags go', async () => {
    expect((await setName("Zoë O'Brien-Smith")).body.name).toBe("Zoë O'Brien-Smith");
    expect((await setName('محمد علي')).body.name).toBe('محمد علي');
    expect((await setName('<b>Jane</b> Smith')).body.name).toBe('Jane Smith');
  });

  it('a name that is not a name is refused and the earlier name stays', async () => {
    await setName('Jane Smith');
    for (const bad of ['', 'J', '12345', 'Jane; DROP TABLE x', 'a@b.com', 'x'.repeat(81), null, 42]) {
      const r = await setName(bad);
      expect([String(bad).slice(0, 10), r.status]).toEqual([String(bad).slice(0, 10), 400]);
    }
    expect((await prisma.editorSession.findUniqueOrThrow({ where: { id: s.id } })).reviewerName).toBe('Jane Smith');
  });

  it('it needs a live session and the CSRF token; the owner login cannot set it', async () => {
    // no session: the same answer as every other editor route (the link is not valid)
    expect((await request(API).put('/editor/session/name').send({ name: 'Jane Smith' })).status).toBe(404);
    expect((await request(API).put('/editor/session/name').set({ Cookie: s.cookie }).send({ name: 'Jane Smith' })).status).toBe(403);
    expect((await request(API).put('/editor/session/name').set(owner(a.token)).send({ name: 'Jane Smith' })).status).toBe(404);
    expect((await prisma.editorSession.findUniqueOrThrow({ where: { id: s.id } })).reviewerName).toBeNull();
  });

  it('the name goes into the amendment history and the version list from the next save; an earlier save stays unnamed', async () => {
    const first = await save('Before the name was given.');
    await setName('Jane Smith');
    const second = await save('After the name.');
    const events = await prisma.reportAuditEvent.findMany({ where: { reportId: surveyId, field: 'text' }, orderBy: { createdAt: 'asc' } });
    expect(events.map((e) => [e.reportVersion, e.actorName])).toEqual([
      [first.body.version, null],
      [second.body.version, 'Jane Smith'],
    ]);
    expect(events[1].actor).toBe(`session:${s.id}`);
    const versions = await request(API).get(`/reports/${surveyId}/versions`).set(owner(a.token));
    const byVersion = Object.fromEntries(versions.body.versions.map((v: { version: number; savedByName: string | null }) => [v.version, v.savedByName]));
    expect(byVersion[first.body.version]).toBeNull();
    expect(byVersion[second.body.version]).toBe('Jane Smith');
    const trail = await request(API).get(`/reports/${surveyId}/audit`).set(owner(a.token));
    const named = trail.body.events.find((e: { version: number }) => e.version === second.body.version);
    expect(named).toMatchObject({ actorName: 'Jane Smith', actorNameVerified: false });
  });

  it('a name changed during the session applies to what is saved after it', async () => {
    await setName('Jane Smith');
    await save('One.');
    await setName('Jane S. Smith');
    const r2 = await save('Two.');
    const names = (await prisma.reportAuditEvent.findMany({ where: { reportId: surveyId, field: 'text' }, orderBy: { createdAt: 'asc' } })).map((e) => e.actorName);
    expect(names).toEqual(['Jane Smith', 'Jane S. Smith']);
    expect(r2.status).toBe(200);
  });

  it('two people on the same link each have their own session and name', async () => {
    const s2 = await openSession();
    await setName('Jane Smith', s);
    await setName('Omar Khan', s2);
    await save('From Jane.', s);
    await save('From Omar.', s2);
    const events = await prisma.reportAuditEvent.findMany({ where: { reportId: surveyId, field: 'text' }, orderBy: { createdAt: 'asc' } });
    expect(events.map((e) => [e.afterValue, e.actorName])).toEqual([
      ['From Jane.', 'Jane Smith'],
      ['From Omar.', 'Omar Khan'],
    ]);
  });

  it('review entries made through the link carry the name, marked not verified; the owner entries carry none', async () => {
    await setName('Omar Khan');
    const v = await version();
    const submit = await request(API).post(`/editor/reports/${surveyId}/review/submit`).set(h()).send({ expectedReportVersion: v });
    expect(submit.status).toBe(200);
    const dec = await request(API).post(`/editor/reports/${surveyId}/review/decision`).set(h()).send({ expectedReportVersion: v, decision: 'APPROVED', comment: 'Looks right.' });
    expect(dec.status).toBe(200);
    const view = await request(API).get(`/reports/${surveyId}/review`).set(owner(a.token));
    expect(view.body.reviewerApproval).toMatchObject({ by: 'reviewer', reviewerName: 'Omar Khan', nameVerified: false });
    expect(view.body.reviews.find((r: { decision: string }) => r.decision === 'SUBMITTED')).toMatchObject({ reviewerName: 'Omar Khan', nameVerified: false });
    const own = await request(API).post(`/reports/${surveyId}/owner-approval`).set(owner(a.token)).send({ expectedReportVersion: v });
    expect(own.status).toBe(200);
    const after = await request(API).get(`/reports/${surveyId}/review`).set(owner(a.token));
    expect(after.body.ownerApproval).toMatchObject({ by: 'owner', reviewerName: null });
  });

  it('only the owner of the report reads the history that carries the names', async () => {
    await setName('Jane Smith');
    await save('Edit.');
    expect((await request(API).get(`/reports/${surveyId}/audit`).set(owner(b.token))).status).toBe(403);
  });

  it('the name is in the lifecycle log with its "not verified" flag', async () => {
    await setName('Jane Smith');
    let rows: { metadata: unknown }[] = [];
    for (let i = 0; i < 20 && rows.length === 0; i++) {
      rows = await prisma.auditLog.findMany({ where: { entityId: surveyId, action: 'REVIEWER_NAME_SET' }, select: { metadata: true } });
      if (rows.length === 0) await new Promise((r) => setTimeout(r, 250));
    }
    expect(rows).toHaveLength(1);
    expect(rows[0].metadata).toMatchObject({ name: 'Jane Smith', verified: false, sessionId: s.id });
  });
});
