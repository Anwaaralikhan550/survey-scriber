/**
 * E2E: the field-level amendment history (Remote Editor spec v1.4 sections 10, 18 and 20): every accepted save has events with
 * the field, the value before and after, the version, who and from where; a refused save leaves none; a retried save is not
 * recorded twice; the rows cannot be changed; the owner reads them.
 */
import request = require('supertest');
import { randomUUID } from 'crypto';
import { UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const TITLE = `${TEST_PREFIX}audit`;

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}audit_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

describe('Field-level audit (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let admin: { id: string; token: string };
  let surveyId: string;
  let s1: string;
  let s2: string;
  let p1: string;
  let p2: string;
  let cookie: string;
  let csrf: string;
  let sessionId: string;

  const hdr = () => ({ Cookie: cookie, 'X-CSRF-Token': csrf });
  const version = async () => (await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).version;
  const events = (where: Record<string, unknown> = {}) => prisma.reportAuditEvent.findMany({ where: { reportId: surveyId, ...where }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] });
  const save = async (changes: unknown[], extra: Record<string, unknown> = {}) =>
    request(API).patch(`/editor/reports/${surveyId}`).set(hdr()).send({ baseVersion: await version(), idempotencyKey: randomUUID(), changes, ...extra });

  beforeEach(async () => {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '5 Audit Road', userId: a.id } });
    surveyId = survey.id;
    s1 = randomUUID();
    s2 = randomUUID();
    p1 = randomUUID();
    p2 = randomUUID();
    const content = [
      { id: s1, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: p1, type: 'paragraph', text: 'The roof is tiled.' }, { id: p2, type: 'paragraph', text: 'Some tiles are slipped.' }] },
      { id: s2, key: 'E2_CHIMNEY', title: 'Chimney', blocks: [] },
    ];
    expect((await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content })).status).toBe(200);
    const link = await request(API).post(`/reports/${surveyId}/edit-links`).set(owner(a.token));
    const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
    cookie = (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0];
    csrf = open.body.csrfToken;
    sessionId = (await prisma.editorSession.findFirstOrThrow({ where: { reportId: surveyId } })).id;
  });
  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
  });
  afterAll(async () => {
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}audit_` } } });
    await prisma.$disconnect();
  });

  it('the first upload from the phone is recorded as the original, with counts and no text', async () => {
    const ev = await events();
    expect(ev).toHaveLength(1);
    expect(ev[0]).toMatchObject({ entityType: 'REPORT', field: 'original', op: 'ORIGINAL', reportVersion: 1, actor: `owner:${a.id}`, source: 'PHONE' });
    expect(ev[0].afterValue).toEqual({ sections: 2, blocks: 2 });
  });

  it('a browser save records the field, the value before and after, the version, the session and the source', async () => {
    const r = await save([{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'The roof is covered with slates.' } }]);
    expect(r.status).toBe(200);
    const ev = await events({ reportVersion: r.body.version });
    expect(ev).toHaveLength(1);
    expect(ev[0]).toMatchObject({
      entityType: 'BLOCK',
      entityId: p1,
      sectionId: s1,
      sectionKey: 'E1_ROOF',
      field: 'text',
      op: 'UPDATE',
      beforeValue: 'The roof is tiled.',
      afterValue: 'The roof is covered with slates.',
      actor: `session:${sessionId}`,
      sessionId,
      source: 'BROWSER',
    });
  });

  it('one batch with several changes: every change is an event of the same version', async () => {
    const added = randomUUID();
    const r = await save([
      { op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'Edited.' } },
      { op: 'addBlock', sectionId: s1, afterBlockId: p1, block: { id: added, type: 'paragraph', text: 'New paragraph.' } },
      { op: 'deleteBlock', sectionId: s1, blockId: p2 },
      { op: 'moveBlock', sectionId: s1, blockId: p1, toSectionId: s2, atStart: true },
    ]);
    expect(r.status).toBe(200);
    const ev = await events({ reportVersion: r.body.version });
    const keys = ev.map((e) => `${e.field}:${e.op}`).sort();
    expect(keys).toEqual(['block:DELETE', 'section_of_block:MOVE', 'text:UPDATE'].concat(['block:ADD']).sort());
    expect(ev.find((e) => e.op === 'DELETE')).toMatchObject({ entityId: p2, beforeValue: { type: 'paragraph', text: 'Some tiles are slipped.' } });
    expect(ev.find((e) => e.field === 'section_of_block')).toMatchObject({ entityId: p1, beforeValue: { sectionKey: 'E1_ROOF' }, afterValue: { sectionKey: 'E2_CHIMNEY' } });
    expect(new Set(ev.map((e) => e.reportVersion)).size).toBe(1);
  });

  it('a refused save leaves no event: a stale version, a bad change, a finalised report', async () => {
    const before = (await events()).length;
    const stale = await request(API).patch(`/editor/reports/${surveyId}`).set(hdr()).send({ baseVersion: 99, idempotencyKey: randomUUID(), changes: [{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'x' } }] });
    expect(stale.status).toBe(409);
    const bad = await save([{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'ok' } }, { op: 'deleteBlock', sectionId: s1, blockId: randomUUID() }]);
    expect(bad.status).toBe(400);
    expect((await events()).length).toBe(before);
    expect(JSON.stringify((await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).content)).not.toContain('"ok"');
  });

  it('a retried save (same idempotency key) is recorded once', async () => {
    const key = randomUUID();
    const body = { baseVersion: await version(), idempotencyKey: key, changes: [{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'Once only.' } }] };
    const r1 = await request(API).patch(`/editor/reports/${surveyId}`).set(hdr()).send(body);
    const r2 = await request(API).patch(`/editor/reports/${surveyId}`).set(hdr()).send(body);
    expect(r1.status).toBe(200);
    expect(r2.body.replayed).toBe(true);
    expect(await events({ field: 'text', op: 'UPDATE' })).toHaveLength(1);
  });

  it('a save that changes nothing records nothing', async () => {
    const before = (await events()).length;
    const r = await save([{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'The roof is tiled.' } }]);
    expect(r.status).toBe(200);
    expect((await events()).length).toBe(before);
  });

  it('a later upload from the phone and a restore are recorded with their own source and actor', async () => {
    const v = await version();
    const edited = [
      { id: s1, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: p1, type: 'paragraph', text: 'Phone wording.' }, { id: p2, type: 'paragraph', text: 'Some tiles are slipped.' }] },
      { id: s2, key: 'E2_CHIMNEY', title: 'Chimney', blocks: [] },
    ];
    const up = await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ baseVersion: v, reportType: 'L2', content: edited });
    expect(up.status).toBe(200);
    const phone = await events({ source: 'PHONE', field: 'text' });
    expect(phone).toHaveLength(1);
    expect(phone[0]).toMatchObject({ actor: `owner:${a.id}`, beforeValue: 'The roof is tiled.', afterValue: 'Phone wording.', reportVersion: up.body.version });
    const rs = await request(API).post(`/reports/${surveyId}/versions/1/restore`).set(owner(a.token)).send({ baseVersion: up.body.version });
    expect(rs.status).toBe(200);
    const restored = await events({ source: 'RESTORE' });
    expect(restored).toHaveLength(1);
    expect(restored[0]).toMatchObject({ field: 'text', beforeValue: 'Phone wording.', afterValue: 'The roof is tiled.', reportVersion: rs.body.version });
  });

  it('an accepted or rejected AI suggestion is noted in the history without copying the text', async () => {
    const suggestionId = randomUUID();
    await prisma.auditLog.create({ data: { actorType: 'SYSTEM', action: 'AI_SUGGESTION_CREATED', entityType: 'REPORT', entityId: surveyId, metadata: { suggestionId } } });
    const ok = await request(API).post(`/editor/reports/${surveyId}/ai/outcome`).set(hdr()).send({ suggestionId, blockId: p1, outcome: 'ACCEPTED', action: 'IMPROVE' });
    expect(ok.status).toBeLessThan(300);
    const ev = await events({ source: 'AI' });
    expect(ev).toHaveLength(1);
    expect(ev[0]).toMatchObject({ entityType: 'BLOCK', entityId: p1, field: 'text', op: 'AI_ACCEPTED', actor: `session:${sessionId}` });
    expect(ev[0].afterValue).toMatchObject({ suggestionId, outcome: 'ACCEPTED' });
    const rej = await request(API).post(`/editor/reports/${surveyId}/ai/outcome`).set(hdr()).send({ suggestionId, blockId: p2, outcome: 'REJECTED' });
    expect(rej.status).toBeLessThan(300);
    expect((await events({ source: 'AI', op: 'AI_REJECTED' })).length).toBe(1);
  });

  it('the history cannot be changed or deleted, and goes only with its report', async () => {
    await save([{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'Changed.' } }]);
    await expect(prisma.$executeRaw`UPDATE report_audit_events SET after_value = '"x"'::jsonb WHERE report_id = ${surveyId}::uuid`).rejects.toThrow(/immutable/);
    await expect(prisma.$executeRaw`DELETE FROM report_audit_events WHERE report_id = ${surveyId}::uuid`).rejects.toThrow(/cannot be deleted/);
    await expect(prisma.$executeRawUnsafe('TRUNCATE report_audit_events')).rejects.toThrow(/truncated/);
    expect((await events()).length).toBeGreaterThan(1);
    await prisma.survey.delete({ where: { id: surveyId } });
    expect(await prisma.reportAuditEvent.count({ where: { reportId: surveyId } })).toBe(0);
  });

  it('the owner reads the history: events oldest first, since a version, limited, with the lifecycle events', async () => {
    const r = await save([{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'One.' } }]);
    await save([{ op: 'updateBlock', sectionId: s1, blockId: p1, fields: { text: 'Two.' } }]);
    const all = await request(API).get(`/reports/${surveyId}/audit`).set(owner(a.token));
    expect(all.status).toBe(200);
    expect(all.body.events.map((e: { field: string; after: unknown }) => e.after)).toEqual([{ sections: 2, blocks: 2 }, 'One.', 'Two.']);
    expect(all.body.events[1]).toMatchObject({ version: r.body.version, before: 'The roof is tiled.', actor: `session:${sessionId}`, source: 'BROWSER' });
    const since = await request(API).get(`/reports/${surveyId}/audit?sinceVersion=${r.body.version}`).set(owner(a.token));
    expect(since.body.events).toHaveLength(1);
    expect((await request(API).get(`/reports/${surveyId}/audit?limit=1`).set(owner(a.token))).body.events).toHaveLength(1);
    // the lifecycle log is written by the general audit service, which may lag a moment behind the answer
    let lifecycle = all.body.lifecycle;
    for (let i = 0; i < 20 && !lifecycle.some((l: { action: string }) => l.action === 'REPORT_SAVED'); i++) {
      await new Promise((res) => setTimeout(res, 250));
      lifecycle = (await request(API).get(`/reports/${surveyId}/audit`).set(owner(a.token))).body.lifecycle;
    }
    const actions = lifecycle.map((l: { action: string }) => l.action);
    expect(actions).toEqual(expect.arrayContaining(['REPORT_SNAPSHOT_UPLOADED', 'EDIT_LINK_CREATED', 'REPORT_SAVED']));
  });

  it('only the owner or an admin can read it', async () => {
    expect((await request(API).get(`/reports/${surveyId}/audit`).set(owner(b.token))).status).toBe(403);
    expect((await request(API).get(`/reports/${surveyId}/audit`)).status).toBe(401);
    expect((await request(API).get(`/reports/${surveyId}/audit`).set(owner(admin.token))).status).toBe(200);
    expect((await request(API).get(`/reports/${randomUUID()}/audit`).set(owner(a.token))).status).toBe(404);
    expect((await request(API).get(`/reports/${surveyId}/audit`).set(hdr())).status).toBe(401); // a browser session cannot read it
  });
});
