/**
 * E2E: the immutable original report (Remote Editor spec v1.4 sections 5.1, 6.1 and 20): captured once when the phone first
 * uploads the report, with its header, sections, media and the versions it was built from; never changed by desktop edits,
 * later phone uploads, finalisation or reopening; the database itself refuses to change or delete it.
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
const TITLE = `${TEST_PREFIX}orig`;

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}orig_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

describe('Immutable original report (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let admin: { id: string; token: string };
  let surveyId: string;
  let sectionId: string;
  let blockId: string;
  const META = { treeVersionId: 'tree-v9', phraseBankVersionId: 'bank-v86', generatedAt: '2026-11-12T10:30:00.000Z', appVersion: '1.0.0+16' };

  const content = () => [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'The roof is covered with concrete tiles.' }] }];
  const original = (token = a.token, id = surveyId) => request(API).get(`/reports/${id}/original`).set(owner(token));
  const rawSnapshot = () =>
    prisma.$queryRaw<{ id: string; snapshot: unknown; checksum: string; created_at: Date; generated_at: Date }[]>`
      SELECT id, snapshot, checksum, created_at, generated_at FROM report_original_snapshots WHERE report_id = ${surveyId}::uuid`;

  async function newReport(extra: Record<string, unknown> = META) {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '2 Original Road', jobRef: 'VL-ORIG', clientName: 'Mrs Original', userId: a.id } });
    surveyId = survey.id;
    sectionId = randomUUID();
    blockId = randomUUID();
    await prisma.media.create({ data: { id: randomUUID(), surveyId, type: 'PHOTO', fileName: 'roof.jpg', mimeType: 'image/jpeg', size: 1234, storagePath: `${surveyId}/x.jpg`, caption: 'Front roof slope', sortOrder: 1, sectionKey: 'E1_ROOF' } });
    await prisma.media.create({ data: { id: randomUUID(), surveyId, type: 'SIGNATURE', fileName: 'sig.png', mimeType: 'image/png', size: 99, storagePath: `${surveyId}/s.png` } });
    return request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content: content(), ...extra });
  }

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: TITLE }, select: { id: true } });
    for (const s of surveys) {
      fs.rmSync(path.join(STORAGE_ROOT, 'report-files', s.id), { recursive: true, force: true });
    }
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}orig_` } } });
    await prisma.$disconnect();
  });

  it('the first upload creates the original with header, sections, media, signatures and the versions it was built from', async () => {
    expect((await newReport()).status).toBe(200);
    const r = await original();
    expect(r.status).toBe(200);
    expect(r.body).toMatchObject({ schemaVersion: 1, surveyType: 'INSPECTION', treeVersionId: 'tree-v9', phraseBankVersionId: 'bank-v86', appVersion: '1.0.0+16', intact: true });
    expect(r.body.checksum).toMatch(/^[0-9a-f]{64}$/);
    expect(new Date(r.body.generatedAt).toISOString()).toBe('2026-11-12T10:30:00.000Z');
    const s = r.body.snapshot;
    expect(s).toMatchObject({ schemaVersion: 1, surveyId, surveyType: 'INSPECTION', treeVersionId: 'tree-v9', phraseBankVersionId: 'bank-v86', generatedAt: '2026-11-12T10:30:00.000Z' });
    expect(s.survey).toEqual({ title: TITLE, propertyAddress: '2 Original Road', jobRef: 'VL-ORIG', clientName: 'Mrs Original' });
    // the report as the server holds it at version 1 (the input with its block order numbered)
    const v1 = await prisma.reportVersion.findFirstOrThrow({ where: { reportId: surveyId, version: 1 } });
    expect(s.sections).toEqual(v1.content);
    expect(s.sections[0].blocks[0].text).toBe('The roof is covered with concrete tiles.');
    expect(s.media).toHaveLength(1);
    expect(s.media[0]).toMatchObject({ fileName: 'roof.jpg', caption: 'Front roof slope', sortOrder: 1, sectionKey: 'E1_ROOF' });
    expect(s.signatures).toHaveLength(1);
    expect(s.signatures[0].fileName).toBe('sig.png');
  });

  it('a valuation is recorded as VALUATION and the optional details can be left out', async () => {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '3 Original Road', userId: a.id } });
    surveyId = survey.id;
    sectionId = randomUUID();
    blockId = randomUUID();
    expect((await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'VALUATION', content: content() })).status).toBe(200);
    const r = await original();
    expect(r.body).toMatchObject({ surveyType: 'VALUATION', treeVersionId: null, phraseBankVersionId: null, appVersion: null, intact: true });
    expect(Math.abs(Date.now() - new Date(r.body.generatedAt).getTime())).toBeLessThan(60_000);
  });

  it('bad details are refused: a date that is not a date, text that is too long', async () => {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '4 Original Road', userId: a.id } });
    const put = (extra: Record<string, unknown>) => request(API).put(`/reports/${survey.id}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content: content(), ...extra });
    expect((await put({ generatedAt: 'yesterday' })).status).toBe(400);
    expect((await put({ treeVersionId: 'x'.repeat(101) })).status).toBe(400);
    expect((await put({ appVersion: 'x'.repeat(51) })).status).toBe(400);
    expect(await prisma.report.count({ where: { id: survey.id } })).toBe(0);
  });

  describe('it never changes', () => {
    let before: Awaited<ReturnType<typeof rawSnapshot>>[number];
    beforeEach(async () => {
      expect((await newReport()).status).toBe(200);
      before = (await rawSnapshot())[0];
    });
    const same = async () => {
      const rows = await rawSnapshot();
      expect(rows).toHaveLength(1);
      expect(rows[0].id).toBe(before.id);
      expect(rows[0].checksum).toBe(before.checksum);
      expect(JSON.stringify(rows[0].snapshot)).toBe(JSON.stringify(before.snapshot));
      expect(rows[0].created_at.getTime()).toBe(before.created_at.getTime());
      expect((await original()).body.intact).toBe(true);
    };

    it('after a desktop edit and a later upload from the phone', async () => {
      const link = await request(API).post(`/reports/${surveyId}/edit-links`).set(owner(a.token));
      const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
      const cookie = (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0];
      const save = await request(API)
        .patch(`/editor/reports/${surveyId}`)
        .set({ Cookie: cookie, 'X-CSRF-Token': open.body.csrfToken })
        .send({ baseVersion: 1, idempotencyKey: randomUUID(), changes: [{ op: 'updateBlock', sectionId, blockId, fields: { text: 'Edited in the browser.' } }] });
      expect(save.status).toBe(200);
      const rep = await prisma.report.findUniqueOrThrow({ where: { id: surveyId } });
      expect(JSON.stringify(rep.content)).toContain('Edited in the browser.');
      await same();
      const edited = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'Phone edit after sync.' }] }];
      const up = await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ baseVersion: rep.version, reportType: 'L2', content: edited, treeVersionId: 'tree-v10' });
      expect(up.status).toBe(200);
      await same();
      expect((await original()).body.snapshot.sections[0].blocks[0].text).toBe('The roof is covered with concrete tiles.');
    });

    it('after approval, finalising and reopening', async () => {
      const link = await request(API).post(`/reports/${surveyId}/edit-links`).set(owner(a.token));
      const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
      const h = { Cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], 'X-CSRF-Token': open.body.csrfToken };
      const v = async () => (await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).version;
      expect((await request(API).post(`/editor/reports/${surveyId}/review/submit`).set(h).send({ expectedReportVersion: await v() })).status).toBe(200);
      expect((await request(API).post(`/editor/reports/${surveyId}/review/decision`).set(h).send({ expectedReportVersion: await v(), decision: 'APPROVED' })).status).toBe(200);
      expect((await request(API).post(`/reports/${surveyId}/owner-approval`).set(owner(a.token)).send({ expectedReportVersion: await v() })).status).toBe(200);
      expect((await request(API).post(`/reports/${surveyId}/finalise`).set(owner(a.token)).send({ expectedReportVersion: await v() })).status).toBe(200);
      expect((await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).status).toBe(ReportStatus.FINALISED);
      await same();
      expect((await request(API).post(`/reports/${surveyId}/reopen`).set(owner(a.token)).send({ expectedReportVersion: await v(), reason: 'Client asked for a change' })).status).toBe(200);
      await same();
    });

    it('the first version in the history is the same wording as the original', async () => {
      const v1 = await prisma.reportVersion.findFirstOrThrow({ where: { reportId: surveyId, version: 1 } });
      expect(v1.content).toEqual((await original()).body.snapshot.sections);
    });

    it('the database refuses to change it, to delete it on its own, or to empty the table', async () => {
      await expect(prisma.$executeRaw`UPDATE report_original_snapshots SET checksum = 'x' WHERE report_id = ${surveyId}::uuid`).rejects.toThrow(/immutable/);
      await expect(prisma.$executeRaw`UPDATE report_original_snapshots SET snapshot = '{}'::jsonb WHERE report_id = ${surveyId}::uuid`).rejects.toThrow(/immutable/);
      await expect(prisma.$executeRaw`DELETE FROM report_original_snapshots WHERE report_id = ${surveyId}::uuid`).rejects.toThrow(/cannot be deleted/);
      await expect(prisma.$executeRawUnsafe('TRUNCATE report_original_snapshots')).rejects.toThrow(/truncated/);
      await same();
    });

    it('a changed row would be noticed: the checksum no longer matches', async () => {
      // Simulate tampering by someone who could bypass the trigger (superuser): the integrity check must flag it.
      await prisma.$executeRawUnsafe('ALTER TABLE report_original_snapshots DISABLE TRIGGER report_original_snapshots_immutable');
      try {
        await prisma.$executeRaw`UPDATE report_original_snapshots SET snapshot = jsonb_set(snapshot, '{survey,title}', '"tampered"') WHERE report_id = ${surveyId}::uuid`;
        expect((await original()).body.intact).toBe(false);
      } finally {
        await prisma.$executeRaw`UPDATE report_original_snapshots SET snapshot = jsonb_set(snapshot, '{survey,title}', ${JSON.stringify(TITLE)}::jsonb) WHERE report_id = ${surveyId}::uuid`;
        await prisma.$executeRawUnsafe('ALTER TABLE report_original_snapshots ENABLE TRIGGER report_original_snapshots_immutable');
      }
      expect((await original()).body.intact).toBe(true);
    });

    it('it goes only with its report: deleting the survey removes the report and the original together', async () => {
      await prisma.survey.delete({ where: { id: surveyId } });
      expect(await prisma.report.count({ where: { id: surveyId } })).toBe(0);
      expect(await prisma.$queryRaw`SELECT 1 FROM report_original_snapshots WHERE report_id = ${surveyId}::uuid`).toEqual([]);
    });
  });

  it('only the owner or an admin can read it', async () => {
    expect((await newReport()).status).toBe(200);
    expect((await original(b.token)).status).toBe(403);
    expect((await request(API).get(`/reports/${surveyId}/original`)).status).toBe(401);
    expect((await original(admin.token)).status).toBe(200);
    expect((await original(a.token, randomUUID())).status).toBe(404);
  });

  it('the original documents appear next to it once the phone has stored them', async () => {
    expect((await newReport()).status).toBe(200);
    const pdf = Buffer.from('%PDF-1.4\n1 0 obj<<>>endobj\n%%EOF\n', 'latin1');
    expect((await request(API).post(`/reports/${surveyId}/files`).set(owner(a.token)).field('state', 'ORIGINAL').attach('file', pdf, { filename: 'orig.pdf' })).status).toBe(201);
    const r = await original();
    expect(r.body.files).toHaveLength(1);
    expect(r.body.files[0]).toMatchObject({ kind: 'PDF', fileName: 'orig.pdf', size: pdf.length });
  });
});
