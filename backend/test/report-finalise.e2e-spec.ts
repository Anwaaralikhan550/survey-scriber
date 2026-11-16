/**
 * E2E: finalise and reopen (client spec v1.3 sections 15 and 22, D0 decision d): only the owner finalises, only an approved
 * version; finalising locks the report and ends every link and browser session; reopening is explicit, starts a new edit cycle
 * and keeps the earlier final version on record.
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';
import { UserRole, ReportStatus } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}final_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

interface Fx {
  surveyId: string;
  cookie: string;
  csrf: string;
  rawToken: string;
  blockId: string;
  sectionId: string;
}

async function openSession(rawToken: string) {
  const open = await request(API).post('/editor/open').send({ token: rawToken });
  return { cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], csrf: open.body.csrfToken as string };
}

describe('Finalise and reopen (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let f: Fx;

  async function fixture(): Promise<Fx> {
    const survey = await prisma.survey.create({ data: { title: `${TEST_PREFIX}final`, propertyAddress: '1 Final Road', userId: a.id } });
    const sectionId = randomUUID();
    const blockId = randomUUID();
    const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'Roof text.' }] }];
    expect((await request(API).put(`/reports/${survey.id}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content })).status).toBe(200);
    const link = await request(API).post(`/reports/${survey.id}/edit-links`).set(owner(a.token));
    const rawToken = link.body.url.split('/open/')[1];
    return { surveyId: survey.id, rawToken, ...(await openSession(rawToken)), blockId, sectionId };
  }

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
  });
  beforeEach(async () => {
    f = await fixture();
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: `${TEST_PREFIX}final` }, select: { id: true } });
    for (const s of surveys) fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
    await prisma.survey.deleteMany({ where: { title: `${TEST_PREFIX}final` } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}final_` } } });
    await prisma.$disconnect();
  });

  const h = () => ({ Cookie: f.cookie, 'X-CSRF-Token': f.csrf });
  const rep = () => prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } });
  const version = async () => (await rep()).version;
  const ed = async (action: string, body: Record<string, unknown> = {}) => request(API).post(`/editor/reports/${f.surveyId}/review/${action}`).set(h()).send({ expectedReportVersion: await version(), ...body });
  const own = async (p: string, body: Record<string, unknown> = {}, token = a.token, v?: number) =>
    request(API).post(`/reports/${f.surveyId}/${p}`).set(owner(token)).send({ expectedReportVersion: v ?? (await version()), ...body });
  const approveAll = async () => {
    expect((await ed('submit')).status).toBe(200);
    expect((await ed('decision', { decision: 'APPROVED' })).status).toBe(200);
    expect((await own('owner-approval')).status).toBe(200);
    expect((await rep()).status).toBe(ReportStatus.OWNER_FINAL_APPROVAL);
  };
  const finalise = (body?: Record<string, unknown>, token = a.token) => own('finalise', body, token);
  const reopen = (body: Record<string, unknown> = {}, token = a.token) => own('reopen', { reason: 'Client asked for a change to the roof wording', ...body }, token);

  describe('finalise', () => {
    it('is refused until the owner has approved the current version', async () => {
      for (const prep of [async () => undefined, async () => ed('submit'), async () => ed('decision', { decision: 'APPROVED' })]) {
        await prep();
        const r = await finalise();
        expect(r.status).toBe(409);
        expect(r.body.error).toBe('INVALID_STATE');
        expect(r.body.message).toMatch(/final approval/i);
      }
      expect((await rep()).status).not.toBe(ReportStatus.FINALISED);
    });

    it('only the owner can do it: another user, a browser session and no login are all refused', async () => {
      await approveAll();
      expect((await finalise(undefined, b.token)).status).toBe(403);
      const viaSession = await request(API).post(`/reports/${f.surveyId}/finalise`).set(h()).send({ expectedReportVersion: await version() });
      expect(viaSession.status).toBe(401);
      expect((await request(API).post(`/reports/${f.surveyId}/finalise`).send({ expectedReportVersion: 1 })).status).toBe(401);
      expect((await rep()).status).toBe(ReportStatus.OWNER_FINAL_APPROVAL);
    });

    it('is bound to the approved version: a different version number is a conflict', async () => {
      await approveAll();
      const r = await finalise({ expectedReportVersion: (await version()) + 3 });
      expect(r.status).toBe(409);
      expect(r.body.error).toBe('VERSION_CONFLICT');
    });

    it('rejects a bad body', async () => {
      await approveAll();
      expect((await finalise({ expectedReportVersion: 'x' })).status).toBe(400);
    });

    it('locks the report, records the final version, and ends every link and session', async () => {
      await approveAll();
      const v = await version();
      const r = await finalise();
      expect(r.status).toBe(200);
      expect(r.body).toMatchObject({ status: 'FINALISED', version: v, cycle: 1, finalVersion: v });
      const row = await rep();
      expect(row).toMatchObject({ status: 'FINALISED', finalVersion: v, activeEditLinkId: null });
      expect(row.finalisedAt).not.toBeNull();
      expect((await request(API).get(`/reports/${f.surveyId}/edit-links/current`).set(owner(a.token))).body.active).toBe(false);
      expect(await prisma.editorSession.count({ where: { reportId: f.surveyId, revokedAt: null } })).toBe(0);
      expect(await prisma.editLink.count({ where: { reportId: f.surveyId, status: 'ACTIVE' } })).toBe(0);
      const hist = await request(API).get(`/reports/${f.surveyId}/finalisations`).set(owner(a.token));
      expect(hist.body.finalisations).toHaveLength(1);
      expect(hist.body.finalisations[0]).toMatchObject({ cycle: 1, version: v, reopenedAt: null });
    });

    it('the browser is told the report is finalised, on the old session and on the old link', async () => {
      await approveAll();
      await finalise();
      const read = await request(API).get(`/editor/reports/${f.surveyId}`).set('Cookie', f.cookie);
      expect(read.status).toBe(403);
      expect(read.body.error).toBe('REPORT_FINALISED');
      const save = await request(API)
        .patch(`/editor/reports/${f.surveyId}`)
        .set(h())
        .send({ baseVersion: await version(), changes: [{ op: 'updateBlock', sectionId: f.sectionId, blockId: f.blockId, fields: { text: 'late edit' } }] });
      expect(save.status).toBe(403);
      expect(save.body.error).toBe('REPORT_FINALISED');
      const again = await request(API).post('/editor/open').send({ token: f.rawToken });
      expect(again.status).toBe(403);
      expect(again.body.error).toBe('REPORT_FINALISED');
      const text = ((await rep()).content as unknown as Array<{ blocks: Array<{ text?: string }> }>)[0].blocks[0].text;
      expect(text).toBe('Roof text.');
    });

    it('nothing on the owner side can change a finalised report, but the owner can still read it', async () => {
      await approveAll();
      await finalise();
      const content = [{ id: f.sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: f.blockId, type: 'paragraph', text: 'Changed after final' }] }];
      for (const res of [
        await request(API).put(`/reports/${f.surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content }),
        await request(API).post(`/reports/${f.surveyId}/edit-links`).set(owner(a.token)),
        await own('owner-approval'),
        await own('review/reset'),
        await own('review/decision', { decision: 'AMENDMENTS_REQUIRED', comment: 'x' }),
      ]) {
        expect([403, 409]).toContain(res.status);
      }
      const sync = await request(API).post(`/reports/${f.surveyId}/sync`).set(owner(a.token));
      expect(sync.status).toBe(200);
      expect(JSON.stringify(sync.body)).toContain('Roof text.');
    });

    it('finalising twice is refused, not repeated', async () => {
      await approveAll();
      expect((await finalise()).status).toBe(200);
      const second = await finalise();
      expect(second.status).toBe(409);
      expect(second.body.error).toBe('INVALID_STATE');
      expect(await prisma.reportFinalisation.count({ where: { reportId: f.surveyId } })).toBe(1);
    });

    it('two finalise requests at once: one wins', async () => {
      await approveAll();
      const v = await version();
      const [x, y] = await Promise.all([finalise({ expectedReportVersion: v }), finalise({ expectedReportVersion: v })]);
      expect([x.status, y.status].sort()).toEqual([200, 409]);
      expect(await prisma.reportFinalisation.count({ where: { reportId: f.surveyId } })).toBe(1);
    });

    it('an approval that a later change withdrew cannot be finalised', async () => {
      await approveAll();
      const save = await request(API)
        .patch(`/editor/reports/${f.surveyId}`)
        .set(h())
        .send({ baseVersion: await version(), changes: [{ op: 'updateBlock', sectionId: f.sectionId, blockId: f.blockId, fields: { text: 'Edited after approval' } }] });
      expect(save.status).toBe(200);
      const r = await finalise();
      expect(r.status).toBe(409);
      expect(r.body.error).toBe('INVALID_STATE');
    });

    it('is written to the audit trail without report text', async () => {
      await approveAll();
      await finalise();
      const row = await prisma.auditLog.findFirst({ where: { entityId: f.surveyId, action: 'REPORT_FINALISED' } });
      expect(row?.metadata).toMatchObject({ cycle: 1, linksEnded: 1 });
      expect(JSON.stringify(row?.metadata)).not.toMatch(/Roof text/);
    });
  });

  describe('reopen', () => {
    const finalised = async () => {
      await approveAll();
      expect((await finalise()).status).toBe(200);
    };

    it('only a finalised report can be reopened', async () => {
      const r = await reopen();
      expect(r.status).toBe(409);
      expect(r.body.error).toBe('INVALID_STATE');
    });

    it('needs a reason, from the owner only, for the final version', async () => {
      await finalised();
      expect((await reopen({ reason: '' })).status).toBe(400);
      expect((await reopen({ reason: 'ab' })).status).toBe(400);
      expect((await reopen({ reason: 'x'.repeat(501) })).status).toBe(400);
      expect((await reopen({}, b.token)).status).toBe(403);
      expect((await reopen({ expectedReportVersion: (await version()) + 1 })).status).toBe(409);
      expect((await rep()).status).toBe(ReportStatus.FINALISED);
    });

    it('starts a new cycle as a draft; the earlier final version stays on record with who and why', async () => {
      await finalised();
      const v = await version();
      const r = await reopen({ reason: 'Client asked for a change to the roof wording' });
      expect(r.status).toBe(200);
      expect(r.body).toMatchObject({ status: 'DRAFT', cycle: 2, previousFinalVersion: v });
      const row = await rep();
      expect(row).toMatchObject({ status: 'DRAFT', editCycle: 2, finalVersion: v, finalisedAt: null });
      const hist = (await request(API).get(`/reports/${f.surveyId}/finalisations`).set(owner(a.token))).body;
      expect(hist).toMatchObject({ status: 'DRAFT', cycle: 2, finalVersion: v });
      expect(hist.finalisations[0]).toMatchObject({ cycle: 1, version: v, reopenReason: 'Client asked for a change to the roof wording' });
      expect(hist.finalisations[0].reopenedAt).not.toBeNull();
      const stored = await prisma.reportFinalisation.findFirstOrThrow({ where: { reportId: f.surveyId, cycle: 1 } });
      expect(stored.reopenedBy).toBe(a.id);
      expect(stored.finalisedBy).toBe(a.id);
    });

    it('carries no approval over: the old approvals are marked out of date and review starts again', async () => {
      await finalised();
      await reopen();
      const view = (await request(API).get(`/reports/${f.surveyId}/review`).set(owner(a.token))).body;
      expect(view.status).toBe('DRAFT');
      expect(view.reviewerApproval).toBeNull();
      expect(view.ownerApproval).toBeNull();
      expect(await prisma.review.count({ where: { reportId: f.surveyId, invalidatedAt: null, decision: { in: ['APPROVED', 'OWNER_APPROVED'] } } })).toBe(0);
      expect((await finalise()).status).toBe(409);
    });

    it('editing works again: a new link, a saved change, the full review ladder, a second final version', async () => {
      await finalised();
      const firstFinal = await version();
      await reopen();
      const link = await request(API).post(`/reports/${f.surveyId}/edit-links`).set(owner(a.token));
      expect(link.status).toBe(201);
      f = { ...f, rawToken: link.body.url.split('/open/')[1], ...(await openSession(link.body.url.split('/open/')[1])) };
      const save = await request(API)
        .patch(`/editor/reports/${f.surveyId}`)
        .set(h())
        .send({ baseVersion: await version(), changes: [{ op: 'updateBlock', sectionId: f.sectionId, blockId: f.blockId, fields: { text: 'Roof text, second cycle.' } }] });
      expect(save.status).toBe(200);
      expect(await version()).toBe(firstFinal + 1);
      await approveAll();
      expect((await finalise()).status).toBe(200);
      const hist = (await request(API).get(`/reports/${f.surveyId}/finalisations`).set(owner(a.token))).body;
      expect(hist.finalisations.map((x: { cycle: number }) => x.cycle)).toEqual([2, 1]);
      expect(hist.finalisations[0]).toMatchObject({ cycle: 2, version: firstFinal + 1, reopenedAt: null });
      expect(hist.finalisations[1]).toMatchObject({ cycle: 1, version: firstFinal });
      // the first final version is still recoverable from the version history
      const versions = (await request(API).get(`/reports/${f.surveyId}/versions`).set(owner(a.token))).body;
      expect(JSON.stringify(versions)).toContain(`${firstFinal}`);
      const oldRow = await prisma.reportVersion.findUniqueOrThrow({ where: { reportId_version: { reportId: f.surveyId, version: firstFinal } } });
      expect(JSON.stringify(oldRow.content)).toContain('Roof text.');
      expect(JSON.stringify(oldRow.content)).not.toContain('second cycle');
    });

    it('is written to the audit trail with the reason length, not the reason', async () => {
      await finalised();
      await reopen({ reason: 'Secret client wording' });
      const row = await prisma.auditLog.findFirst({ where: { entityId: f.surveyId, action: 'REPORT_REOPENED' } });
      expect(row?.metadata).toMatchObject({ fromCycle: 1, toCycle: 2, reasonLength: 'Secret client wording'.length });
      expect(JSON.stringify(row?.metadata)).not.toMatch(/Secret/);
    });
  });

  it('a stranger cannot read the history', async () => {
    expect((await request(API).get(`/reports/${f.surveyId}/finalisations`).set(owner(b.token))).status).toBe(403);
    expect((await request(API).get(`/reports/${f.surveyId}/finalisations`)).status).toBe(401);
  });
});
