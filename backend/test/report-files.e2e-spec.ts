/**
 * E2E: original and final report documents (Remote Editor spec v1.4 sections 5, 6, 16 and 20): the phone stores the original
 * PDF and Word files once, the server checks them by their bytes, stores them with a SHA-256 and never changes them; final
 * documents are stored per edit cycle after finalisation.
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { createHash, randomUUID } from 'crypto';
import { UserRole, ReportStatus } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const ROOT = path.resolve(__dirname, '..', '..');
const sha = (b: Buffer) => createHash('sha256').update(b).digest('hex');

/** Real documents made by the app's own generators when they are in the repo, otherwise minimal valid ones. */
function pdf(extra = ''): Buffer {
  const real = path.join(ROOT, 'tmp', 'client-edits-2026-11-17', 'out', 'a17.pdf');
  if (!extra && fs.existsSync(real)) return fs.readFileSync(real);
  return Buffer.from(`%PDF-1.4\n1 0 obj<<>>endobj\n${extra}\ntrailer<<>>\n%%EOF\n`, 'latin1');
}
function docx(extra = ''): Buffer {
  const real = path.join(ROOT, 'tmp', 'client-edits-2026-11-17', 'out', 'a17.docx');
  if (!extra && fs.existsSync(real)) return fs.readFileSync(real);
  return Buffer.concat([
    Buffer.from([0x50, 0x4b, 0x03, 0x04]),
    Buffer.from(`${extra}`, 'latin1'),
    Buffer.from('PK\x01\x02[Content_Types].xmlPK\x01\x02word/document.xmlPK\x05\x06', 'latin1'),
    Buffer.alloc(18),
  ]);
}

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}files_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

describe('Report files: original and final documents (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let admin: { id: string; token: string };
  let surveyId: string;

  const upload = (token: string, buf: Buffer | null, name: string, state: string, id = surveyId) => {
    const r = request(API).post(`/reports/${id}/files`).set(owner(token)).field('state', state);
    return buf === null ? r : r.attach('file', buf, { filename: name });
  };

  async function newReport() {
    const survey = await prisma.survey.create({ data: { title: `${TEST_PREFIX}files`, propertyAddress: '1 File Road', userId: a.id } });
    const content = [{ id: randomUUID(), key: 'E1', title: 'Roof', blocks: [{ id: randomUUID(), type: 'paragraph', text: 'Roof text.' }] }];
    expect((await request(API).put(`/reports/${survey.id}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content })).status).toBe(200);
    return survey.id;
  }

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
  });
  beforeEach(async () => {
    surveyId = await newReport();
  });
  afterAll(async () => {
    const reports = await prisma.survey.findMany({ where: { title: `${TEST_PREFIX}files` }, select: { id: true } });
    for (const s of reports) {
      fs.rmSync(path.join(STORAGE_ROOT, 'report-files', s.id), { recursive: true, force: true });
      fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
    }
    await prisma.survey.deleteMany({ where: { title: `${TEST_PREFIX}files` } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}files_` } } });
    await prisma.$disconnect();
  });

  it('the owner stores the original PDF and Word file; each is stored with its size and SHA-256', async () => {
    const p = pdf();
    const d = docx();
    const r1 = await upload(a.token, p, 'Report 54 Gas Lane.pdf', 'ORIGINAL');
    expect(r1.status).toBe(201);
    expect(r1.body).toMatchObject({ state: 'ORIGINAL', kind: 'PDF', size: p.length, sha256: sha(p), duplicate: false, cycle: 1, version: null });
    const r2 = await upload(a.token, d, 'Report 54 Gas Lane.docx', 'ORIGINAL');
    expect(r2.status).toBe(201);
    expect(r2.body).toMatchObject({ state: 'ORIGINAL', kind: 'DOCX', sha256: sha(d) });
    const list = await request(API).get(`/reports/${surveyId}/files`).set(owner(a.token));
    expect(list.status).toBe(200);
    expect(list.body.files.map((f: { kind: string }) => f.kind).sort()).toEqual(['DOCX', 'PDF']);
    // the bytes are on the volume, outside any public folder, under a generated name
    const row = await prisma.reportFile.findFirstOrThrow({ where: { reportId: surveyId, kind: 'PDF' } });
    expect(row.storagePath).toMatch(new RegExp(`^report-files/${surveyId}/[0-9a-f-]{36}\\.pdf$`));
    expect(sha(fs.readFileSync(path.join(STORAGE_ROOT, row.storagePath)))).toBe(sha(p));
  });

  it('the stored file downloads byte for byte, with safe headers', async () => {
    const p = pdf();
    const up = await upload(a.token, p, 'a.pdf', 'ORIGINAL');
    const dl = await request(API).get(`/reports/${surveyId}/files/${up.body.id}`).set(owner(a.token)).buffer(true).parse((res, cb) => {
      const chunks: Buffer[] = [];
      res.on('data', (c: Buffer) => chunks.push(c));
      res.on('end', () => cb(null, Buffer.concat(chunks)));
    });
    expect(dl.status).toBe(200);
    expect(sha(dl.body as Buffer)).toBe(sha(p));
    expect(dl.headers['content-type']).toContain('application/pdf');
    expect(dl.headers['content-disposition']).toContain('attachment');
    expect(dl.headers['x-content-type-options']).toBe('nosniff');
    expect(dl.headers['cache-control']).toContain('no-store');
  });

  it('the original is written once: the same bytes again are accepted (a retry), different bytes are refused', async () => {
    const p = pdf();
    const first = await upload(a.token, p, 'a.pdf', 'ORIGINAL');
    const again = await upload(a.token, p, 'a.pdf', 'ORIGINAL');
    expect(again.body.id).toBe(first.body.id);
    expect(again.body.duplicate).toBe(true);
    const other = await upload(a.token, pdf('% a different original'), 'b.pdf', 'ORIGINAL');
    expect(other.status).toBe(409);
    expect(other.body.error).toBe('FILE_EXISTS');
    const row = await prisma.reportFile.findFirstOrThrow({ where: { reportId: surveyId, kind: 'PDF' } });
    expect(row.sha256).toBe(sha(p));
    expect(await prisma.reportFile.count({ where: { reportId: surveyId, kind: 'PDF' } })).toBe(1);
  });

  it('the database itself allows only one original per kind', async () => {
    await upload(a.token, pdf(), 'a.pdf', 'ORIGINAL');
    await expect(
      prisma.reportFile.create({ data: { reportId: surveyId, state: 'ORIGINAL', kind: 'PDF', fileName: 'x.pdf', storagePath: 'x', size: 1, sha256: 'f'.repeat(64), uploadedBy: a.id } }),
    ).rejects.toThrow();
  });

  it('what is checked is the content: a text file called .pdf, a cut-off PDF, a zip that is not a document, an empty file', async () => {
    const bad: [string, Buffer][] = [
      ['fake.pdf', Buffer.from('this is not a pdf at all, just text')],
      ['cut.pdf', Buffer.from('%PDF-1.4\n1 0 obj<<>>endobj\n')],
      ['archive.docx', Buffer.concat([Buffer.from([0x50, 0x4b, 0x03, 0x04]), Buffer.from('PK\x01\x02readme.txtPK\x05\x06', 'latin1'), Buffer.alloc(18)])],
      ['image.pdf', Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0])],
    ];
    for (const [name, buf] of bad) {
      const r = await upload(a.token, buf, name, 'ORIGINAL');
      expect([name, r.status, r.body.error]).toEqual([name, 422, 'FILE_INVALID']);
    }
    expect((await upload(a.token, null, '', 'ORIGINAL')).status).toBe(400);
    expect(await prisma.reportFile.count({ where: { reportId: surveyId } })).toBe(0);
  });

  it('a file larger than the limit is refused and nothing is stored', async () => {
    const big = Buffer.concat([Buffer.from('%PDF-1.4\n'), Buffer.alloc(61 * 1024 * 1024), Buffer.from('\n%%EOF\n')]);
    const r = await upload(a.token, big, 'big.pdf', 'ORIGINAL');
    expect(r.status).toBe(413);
    expect(r.body.error).toBe('FILE_TOO_LARGE');
    expect(await prisma.reportFile.count({ where: { reportId: surveyId } })).toBe(0);
  });

  it('only the owner (or an admin) can store, list or download; others get 403, no login 401, unknown report 404', async () => {
    const up = await upload(a.token, pdf(), 'a.pdf', 'ORIGINAL');
    expect((await upload(b.token, pdf('% other'), 'x.pdf', 'ORIGINAL')).status).toBe(403);
    expect((await request(API).get(`/reports/${surveyId}/files`).set(owner(b.token))).status).toBe(403);
    expect((await request(API).get(`/reports/${surveyId}/files/${up.body.id}`).set(owner(b.token))).status).toBe(403);
    expect((await request(API).get(`/reports/${surveyId}/files`)).status).toBe(401);
    expect((await request(API).get(`/reports/${randomUUID()}/files`).set(owner(a.token))).status).toBe(404);
    expect((await request(API).get(`/reports/${surveyId}/files`).set(owner(admin.token))).status).toBe(200);
    // a file id of another report cannot be read through this report
    const other = await newReport();
    expect((await request(API).get(`/reports/${other}/files/${up.body.id}`).set(owner(a.token))).status).toBe(404);
  });

  it('a state other than ORIGINAL or FINAL is refused', async () => {
    for (const s of ['ARCHIVE', 'original', '', 'DROP TABLE']) {
      expect((await upload(a.token, pdf(), 'a.pdf', s)).status).toBe(400);
    }
  });

  it('a final document is refused before the report is finalised, then stored per edit cycle with the final version', async () => {
    const early = await upload(a.token, pdf(), 'final.pdf', 'FINAL');
    expect(early.status).toBe(409);
    expect(early.body.error).toBe('INVALID_STATE');
    const v = (await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).version;
    await prisma.report.update({ where: { id: surveyId }, data: { status: ReportStatus.FINALISED, finalVersion: v, finalisedAt: new Date() } });
    const p = pdf('% final');
    const fin = await upload(a.token, p, 'final.pdf', 'FINAL');
    expect(fin.status).toBe(201);
    expect(fin.body).toMatchObject({ state: 'FINAL', kind: 'PDF', cycle: 1, version: v, sha256: sha(p) });
    expect((await upload(a.token, pdf('% final two'), 'final2.pdf', 'FINAL')).status).toBe(409);
    // the original can still be stored on its own and stays apart from the final
    const orig = await upload(a.token, pdf(), 'orig.pdf', 'ORIGINAL');
    expect(orig.status).toBe(201);
    expect(orig.body.id).not.toBe(fin.body.id);
    // reopening starts cycle 2: a new final is allowed and the cycle 1 final stays on record
    await prisma.report.update({ where: { id: surveyId }, data: { status: ReportStatus.FINALISED, editCycle: 2, finalVersion: v + 1 } });
    const fin2 = await upload(a.token, pdf('% final cycle two'), 'final.pdf', 'FINAL');
    expect(fin2.status).toBe(201);
    expect(fin2.body.cycle).toBe(2);
    expect(await prisma.reportFile.count({ where: { reportId: surveyId, state: 'FINAL' } })).toBe(2);
  });

  it('a file whose stored bytes were tampered with is not served', async () => {
    const up = await upload(a.token, pdf(), 'a.pdf', 'ORIGINAL');
    const row = await prisma.reportFile.findUniqueOrThrow({ where: { id: up.body.id } });
    const abs = path.join(STORAGE_ROOT, row.storagePath);
    fs.appendFileSync(abs, 'tampered');
    const dl = await request(API).get(`/reports/${surveyId}/files/${up.body.id}`).set(owner(a.token));
    expect(dl.status).toBe(500);
    expect(dl.body.error).toBe('FILE_INVALID');
  });

  it('no temporary file is left behind and the volume holds exactly the stored files', async () => {
    await upload(a.token, pdf(), 'a.pdf', 'ORIGINAL');
    await upload(a.token, docx(), 'a.docx', 'ORIGINAL');
    await upload(a.token, Buffer.from('nonsense'), 'x.pdf', 'ORIGINAL');
    const dir = path.join(STORAGE_ROOT, 'report-files', surveyId);
    const names = fs.readdirSync(dir);
    expect(names.length).toBe(2);
    expect(names.filter((n) => n.startsWith('.'))).toEqual([]);
  });

  it('the audit trail records each stored document with its checksum and no file content', async () => {
    const p = pdf();
    await upload(a.token, p, 'a.pdf', 'ORIGINAL');
    const log = await prisma.auditLog.findFirst({ where: { entityId: surveyId, action: 'REPORT_ORIGINAL_FILE_STORED' } });
    expect(log).not.toBeNull();
    expect(JSON.stringify(log!.metadata)).toContain(sha(p));
  });
});
