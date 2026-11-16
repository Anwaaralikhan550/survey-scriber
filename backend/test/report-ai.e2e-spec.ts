/**
 * E2E: AI wording suggestions over HTTP (client spec v1.3 section 13). The test server has no Gemini key, so this
 * covers everything around the model: who may ask, what may be asked about, and that nothing changes the report.
 * The model's answer, redaction and warnings are covered by `ai-suggestion.service.spec.ts` and the browser test.
 */
import request = require('supertest');
import { randomUUID } from 'crypto';
import { UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });

describe('AI suggestions (E2E)', () => {
  let userId: string;
  let token: string;
  let surveyId: string;
  let cookie: string;
  let csrf: string;
  const sectionId = randomUUID();
  const para = randomUUID();
  const rating = randomUUID();
  const table = randomUUID();

  const version = async () => (await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).version;
  const ask = async (body: Record<string, unknown>, headers: Record<string, string> = { Cookie: cookie, 'X-CSRF-Token': csrf }) =>
    request(API).post(`/editor/reports/${surveyId}/ai/suggest`).set(headers).send({ expectedReportVersion: await version(), action: 'IMPROVE', ...body });

  beforeAll(async () => {
    const email = `${TEST_PREFIX}ai_owner${TEST_EMAIL_DOMAIN}`;
    const user =
      (await prisma.user.findUnique({ where: { email } })) ??
      (await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'A', lastName: 'I', role: UserRole.SURVEYOR, isActive: true } }));
    userId = user.id;
    token = generateStaffToken(user.id, user.email, user.role);
    const survey = await prisma.survey.create({ data: { title: `${TEST_PREFIX}ai`, propertyAddress: '1 AI Road', userId } });
    surveyId = survey.id;
    const content = [
      {
        id: sectionId,
        key: 'E1_ROOF',
        title: 'Roof',
        blocks: [
          { id: para, type: 'paragraph', text: 'The roof has 12 slipped tiles.' },
          { id: rating, type: 'rating', rating: '2' },
          { id: table, type: 'table', table: { headers: ['a'], rows: [['b']] } },
        ],
      },
    ];
    expect((await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(token)).send({ reportType: 'L2', content })).status).toBe(200);
    const link = await request(API).post(`/reports/${surveyId}/edit-links`).set(owner(token));
    const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
    cookie = (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0];
    csrf = open.body.csrfToken;
  });

  afterAll(async () => {
    await prisma.survey.deleteMany({ where: { title: `${TEST_PREFIX}ai` } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}ai_` } } });
    await prisma.$disconnect();
  });

  it('needs the editor session: no cookie, no answer', async () => {
    const r = await ask({ blockId: para }, {});
    expect([401, 404]).toContain(r.status);
    expect(r.body.error === 'LINK_INVALID' || r.status === 401).toBe(true);
  });

  it('needs the CSRF header like every write', async () => {
    const r = await ask({ blockId: para }, { Cookie: cookie });
    expect(r.status).toBe(403);
    expect(r.body.error).toBe('CSRF_INVALID');
    expect((await ask({ blockId: para }, { Cookie: cookie, 'X-CSRF-Token': 'wrong' })).body.error).toBe('CSRF_INVALID');
  });

  it('an owner token is not an editor session', async () => {
    const r = await ask({ blockId: para }, owner(token));
    expect(r.status).not.toBe(200);
  });

  it('refuses ratings and tables: they are never sent to AI', async () => {
    for (const id of [rating, table]) {
      const r = await ask({ blockId: id });
      expect(r.status).toBe(400);
      expect(r.body.error).toBe('VALIDATION_ERROR');
      expect(r.body.message).toMatch(/never changed by AI|professional judgement/);
    }
  });

  it('rejects bad input: unknown action, bad ids, missing version', async () => {
    expect((await ask({ blockId: para, action: 'REWRITE_EVERYTHING' })).status).toBe(400);
    expect((await ask({ blockId: 'nope' })).status).toBe(400);
    const r = await request(API).post(`/editor/reports/${surveyId}/ai/suggest`).set({ Cookie: cookie, 'X-CSRF-Token': csrf }).send({ blockId: para, action: 'IMPROVE' });
    expect(r.status).toBe(400);
  });

  it('a block that does not exist is not found', async () => {
    expect((await ask({ blockId: randomUUID() })).status).toBe(404);
  });

  it('text the user is not looking at (old version) is a conflict', async () => {
    const r = await ask({ blockId: para, expectedReportVersion: (await version()) + 7 });
    expect(r.status).toBe(409);
    expect(r.body.error).toBe('VERSION_CONFLICT');
  });

  it('with no AI configured the answer is a clear 503 and the report is unchanged', async () => {
    const before = await prisma.report.findUniqueOrThrow({ where: { id: surveyId } });
    const r = await ask({ blockId: para });
    expect(r.status).toBe(503);
    expect(r.body.error).toBe('AI_UNAVAILABLE');
    const after = await prisma.report.findUniqueOrThrow({ where: { id: surveyId } });
    expect(after.version).toBe(before.version);
    expect(JSON.stringify(after.content)).toBe(JSON.stringify(before.content));
    const failed = await prisma.auditLog.count({ where: { entityId: surveyId, action: 'AI_SUGGESTION_FAILED' } });
    expect(failed).toBeGreaterThan(0);
  });

  it('an outcome can only be recorded for a suggestion that was actually made', async () => {
    const r = await request(API)
      .post(`/editor/reports/${surveyId}/ai/outcome`)
      .set({ Cookie: cookie, 'X-CSRF-Token': csrf })
      .send({ suggestionId: randomUUID(), blockId: para, outcome: 'ACCEPTED' });
    expect(r.status).toBe(404);
  });

  it('an outcome records lengths only and is found in the audit trail', async () => {
    const suggestionId = randomUUID();
    await prisma.auditLog.create({
      data: { actorType: 'SYSTEM', action: 'AI_SUGGESTION_CREATED', entityType: 'REPORT', entityId: surveyId, metadata: { suggestionId, blockId: para } },
    });
    const r = await request(API)
      .post(`/editor/reports/${surveyId}/ai/outcome`)
      .set({ Cookie: cookie, 'X-CSRF-Token': csrf })
      .send({ suggestionId, blockId: para, outcome: 'ACCEPTED', action: 'IMPROVE', finalLength: 31 });
    expect(r.status).toBe(200);
    const row = await prisma.auditLog.findFirst({ where: { entityId: surveyId, action: 'AI_SUGGESTION_ACCEPTED' } });
    expect(row?.metadata).toMatchObject({ suggestionId, finalLength: 31 });
    expect(JSON.stringify(row?.metadata)).not.toMatch(/slipped/);
    expect((await request(API).post(`/editor/reports/${surveyId}/ai/outcome`).set({ Cookie: cookie, 'X-CSRF-Token': csrf }).send({ suggestionId, blockId: para, outcome: 'MAYBE' })).status).toBe(400);
  });

  it('after finalising, nobody can ask: the report is read-only', async () => {
    await prisma.report.update({ where: { id: surveyId }, data: { status: 'FINALISED' } });
    const r = await ask({ blockId: para });
    expect(r.status).toBe(403);
    expect(r.body.error).toBe('REPORT_FINALISED');
  });
});
