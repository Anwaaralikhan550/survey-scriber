/**
 * E2E: the complete archive (Remote Editor spec v1.4 section 14 and section 20): the owner downloads one ZIP with manifest, original and
 * final documents and data, pictures and audit; a validated archive restores the report; tampered, foreign, traversal and colliding
 * archives are refused without writing anything; an existing report is never overwritten.
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { createHash, randomUUID } from 'crypto';
import sharp from 'sharp';
import { strFromU8, strToU8, unzipSync, zipSync } from 'fflate';
import { ReportStatus, UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const TITLE = `${TEST_PREFIX}archive`;
const sha = (b: Buffer | Uint8Array) => createHash('sha256').update(b).digest('hex');
const jpeg = (color: string) => sharp({ create: { width: 64, height: 48, channels: 3, background: color } }).jpeg().toBuffer();
const png = () => sharp({ create: { width: 40, height: 20, channels: 3, background: '#222222' } }).png().toBuffer();
const pdf = (tag: string) => Buffer.from(`%PDF-1.4\n1 0 obj<<>>endobj\n% ${tag}\ntrailer<<>>\n%%EOF\n`, 'latin1');
const docx = (tag: string) =>
  Buffer.concat([Buffer.from([0x50, 0x4b, 0x03, 0x04]), Buffer.from(tag, 'latin1'), Buffer.from('PK\x01\x02[Content_Types].xmlPK\x01\x02word/document.xmlPK\x05\x06', 'latin1'), Buffer.alloc(18)]);
const binary = (res: request.Response, cb: (err: Error | null, body: Buffer) => void) => {
  const chunks: Buffer[] = [];
  res.on('data', (c: Buffer) => chunks.push(c));
  res.on('end', () => cb(null, Buffer.concat(chunks)));
};

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}archive_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

describe('Report archive: export and restore (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let admin: { id: string; token: string };

  const exportZip = async (token: string, id: string) =>
    request(API).post(`/reports/${id}/archive`).set(owner(token)).buffer(true).parse(binary as never);
  const restore = (token: string, zip: Buffer | null, name = 'archive.zip') => {
    const r = request(API).post('/reports/restore-archive').set(owner(token));
    return zip === null ? r : r.attach('file', zip, { filename: name, contentType: 'application/zip' });
  };

  /** A report with everything in it: phone pictures, a signature, original documents, browser edits by a named reviewer, a replaced photo, a drawing. */
  async function build(finalised = false) {
    const survey = await prisma.survey.create({
      data: {
        title: TITLE,
        propertyAddress: '14 Archive Road',
        userId: a.id,
        jobRef: 'JOB-77',
        clientName: 'A. Client',
        sections: { create: [{ title: 'Outside', order: 0, userNotes: 'Notes', answers: { create: [{ questionKey: 'roof::type', value: 'Slate' }] } }, { title: 'Inside', order: 1 }] },
      },
    });
    const id = survey.id;
    const sectionId = randomUUID();
    const blockId = randomUUID();
    const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'Roof original.' }] }];
    const snap = await request(API).put(`/reports/${id}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content });
    expect(snap.status).toBe(200);
    const up = async (buf: Buffer, type: string, name: string, mime: string) => {
      const r = await request(API).post('/media/upload').set(owner(a.token)).field('surveyId', id).field('type', type).attach('file', buf, { filename: name, contentType: mime });
      expect(r.status).toBe(201);
      return r.body.id as string;
    };
    const photoId = await up(await jpeg('#aa0000'), 'PHOTO', 'roof.jpg', 'image/jpeg');
    const photo2 = await up(await jpeg('#00aa00'), 'PHOTO', 'two.jpg', 'image/jpeg');
    const sigId = await up(await png(), 'SIGNATURE', 'sig.png', 'image/png');
    expect((await request(API).put(`/reports/${id}/media/${photoId}/annotations`).set(owner(a.token)).send({ annotations: [{ type: 'arrow', x1: 0.1, y1: 0.2 }] })).status).toBe(200);
    for (const [buf, name] of [[pdf('original'), 'original.pdf'], [docx('original'), 'original.docx']] as const) {
      expect((await request(API).post(`/reports/${id}/files`).set(owner(a.token)).field('state', 'ORIGINAL').attach('file', buf, { filename: name })).status).toBe(201);
    }
    // the browser: a named reviewer edits, replaces a photo and adds one
    const link = await request(API).post(`/reports/${id}/edit-links`).set(owner(a.token));
    const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
    const h = { Cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], 'X-CSRF-Token': open.body.csrfToken as string };
    expect((await request(API).put('/editor/session/name').set(h).send({ name: 'Jane Reviewer' })).status).toBe(200);
    const save = await request(API).patch(`/editor/reports/${id}`).set(h).send({ baseVersion: 1, idempotencyKey: randomUUID(), changes: [{ op: 'updateBlock', sectionId, blockId, fields: { text: 'Roof edited.' } }] });
    expect(save.status).toBe(200);
    const version = save.body.version as number;
    const rep = await request(API).post(`/editor/reports/${id}/photos/${photo2}/replace`).set(h).field('expectedReportVersion', String(version)).attach('file', await jpeg('#0000aa'), { filename: 'n.jpg', contentType: 'image/jpeg' });
    expect(rep.status).toBe(201);
    if (finalised) {
      const v = (await prisma.report.findUniqueOrThrow({ where: { id } })).version;
      await prisma.report.update({ where: { id }, data: { status: ReportStatus.FINALISED, finalVersion: v, finalisedAt: new Date() } });
      await prisma.reportFinalisation.create({ data: { reportId: id, cycle: 1, version: v, finalisedBy: a.id } });
      for (const [buf, name] of [[pdf('final'), 'final.pdf'], [docx('final'), 'final.docx']] as const) {
        expect((await request(API).post(`/reports/${id}/files`).set(owner(a.token)).field('state', 'FINAL').attach('file', buf, { filename: name })).status).toBe(201);
      }
    }
    return { id, photoId, photo2, sigId, newPhoto: rep.body.photo.id as string };
  }

  /** Everything about a report that must survive a restore, as plain comparable data. */
  async function state(id: string) {
    const report = await prisma.report.findUniqueOrThrow({ where: { id } });
    const survey = await prisma.survey.findUniqueOrThrow({ where: { id }, include: { sections: { orderBy: { order: 'asc' }, include: { answers: { orderBy: { questionKey: 'asc' } } } } } });
    const media = await prisma.media.findMany({ where: { surveyId: id }, orderBy: { id: 'asc' } });
    const snap = await prisma.$queryRaw<{ checksum: string; snapshot: unknown }[]>`SELECT checksum, snapshot FROM report_original_snapshots WHERE report_id = ${id}::uuid`;
    const files = await prisma.reportFile.findMany({ where: { reportId: id }, orderBy: [{ state: 'asc' }, { kind: 'asc' }] });
    const events = (await prisma.reportAuditEvent.findMany({ where: { reportId: id, op: { not: 'RESTORED' } }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] })).map((e) => `${e.reportVersion}|${e.op}|${e.field}|${e.actor}|${e.actorName}|${e.source}|${e.createdAt.toISOString()}`);
    const versions = (await prisma.reportVersion.findMany({ where: { reportId: id }, orderBy: { version: 'asc' } })).map((v) => ({ version: v.version, content: v.content, reason: v.reason, savedByName: v.savedByName }));
    return {
      report: { status: report.status, version: report.version, editCycle: report.editCycle, finalVersion: report.finalVersion, content: report.content, reportType: report.reportType },
      survey: { title: survey.title, propertyAddress: survey.propertyAddress, jobRef: survey.jobRef, clientName: survey.clientName, ownerId: survey.userId },
      sections: survey.sections.map((s) => ({ id: s.id, title: s.title, order: s.order, userNotes: s.userNotes, answers: s.answers.map((x) => ({ id: x.id, k: x.questionKey, v: x.value })) })),
      media: media.map((m) => ({ id: m.id, type: m.type, fileName: m.fileName, mimeType: m.mimeType, size: m.size, source: m.source, replacedById: m.replacedById, deleted: m.deletedAt !== null, annotations: m.annotations, caption: m.caption, sortOrder: m.sortOrder, bytes: sha(fs.readFileSync(path.join(STORAGE_ROOT, m.storagePath))) })),
      snapshot: snap[0],
      files: files.map((f) => ({ state: f.state, kind: f.kind, sha256: f.sha256, size: f.size, cycle: f.cycle, version: f.version, fileName: f.fileName })),
      events,
      versions,
    };
  }

  const removeSurvey = async (id: string) => {
    await prisma.survey.deleteMany({ where: { id } });
  };

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: TITLE }, select: { id: true } });
    for (const s of surveys) {
      fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
      fs.rmSync(path.join(STORAGE_ROOT, 'report-files', s.id), { recursive: true, force: true });
    }
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.reportArchiveImport.deleteMany({ where: { uploaderId: { in: [a.id, b.id, admin.id] } } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}archive_` } } });
    await prisma.$disconnect();
  });

  describe('export', () => {
    let r: Awaited<ReturnType<typeof build>>;
    let zip: Buffer;
    let files: Record<string, Uint8Array>;
    let manifest: { files: { path: string; size: number; sha256: string }[]; signature: string; archiveSchemaVersion: number; reportId: string; ownerUserId: string; status: string; documents: { path: string; state: string; kind: string }[] };

    beforeAll(async () => {
      r = await build(true);
      const res = await exportZip(a.token, r.id);
      expect(res.status).toBe(200);
      zip = res.body as Buffer;
      expect(res.headers['content-type']).toContain('application/zip');
      expect(res.headers['content-disposition']).toContain('attachment; filename="surveyscriber-archive-');
      expect(res.headers['x-archive-sha256']).toBe(sha(zip));
      expect(res.headers['cache-control']).toContain('no-store');
      files = unzipSync(new Uint8Array(zip));
      manifest = JSON.parse(strFromU8(files['manifest.json']));
    });

    it('has the layout of spec 14.1: manifest, README, original/, final/, audit/, definitions/', () => {
      const names = Object.keys(files);
      for (const p of ['manifest.json', 'README.txt', 'original/snapshot.json', 'final/report.json', 'final/survey.json', 'final/media.json', 'audit/events.json', 'audit/versions.json', 'audit/reviews.json', 'definitions/references.json']) expect(names).toContain(p);
      expect(names.filter((n) => n.startsWith('original/documents/')).length).toBe(2);
      expect(names.filter((n) => n.startsWith('final/documents/')).length).toBe(2);
      expect(strFromU8(files['README.txt'])).toContain('Restore archived report');
    });

    it('the manifest lists every other file with its SHA-256 and size, and is signed', () => {
      expect(manifest.archiveSchemaVersion).toBe(1);
      expect(manifest.reportId).toBe(r.id);
      expect(manifest.ownerUserId).toBe(a.id);
      expect(manifest.signature).toMatch(/^[0-9a-f]{64}$/);
      expect(manifest.files.map((f) => f.path).sort()).toEqual(Object.keys(files).filter((n) => n !== 'manifest.json').sort());
      for (const f of manifest.files) {
        expect(files[f.path].length).toBe(f.size);
        expect(sha(files[f.path])).toBe(f.sha256);
      }
      expect(manifest.documents.map((d) => `${d.state}:${d.kind}`).sort()).toEqual(['FINAL:DOCX', 'FINAL:PDF', 'ORIGINAL:DOCX', 'ORIGINAL:PDF']);
    });

    it('contains the pictures themselves: the phone ones (also the replaced) under original/, the browser one under final/, drawing kept', () => {
      const media = JSON.parse(strFromU8(files['final/media.json'])) as { id: string; path: string; source: string; replacedById: string | null; deletedAt: string | null; annotations: unknown; sha256: string }[];
      const byId = Object.fromEntries(media.map((m) => [m.id, m]));
      expect(Object.keys(byId).sort()).toEqual([r.photoId, r.photo2, r.sigId, r.newPhoto].sort());
      expect(byId[r.photoId].path).toBe(`original/media/${r.photoId}.jpg`);
      expect(byId[r.sigId].path).toBe(`original/media/${r.sigId}.png`);
      expect(byId[r.photo2]).toMatchObject({ source: 'PHONE', replacedById: r.newPhoto });
      expect(byId[r.photo2].deletedAt).not.toBeNull();
      expect(byId[r.newPhoto]).toMatchObject({ source: 'EDITOR', path: `final/media/${r.newPhoto}.jpg` });
      expect(byId[r.photoId].annotations).toEqual([{ type: 'arrow', x1: 0.1, y1: 0.2 }]);
      for (const m of media) expect(sha(files[m.path])).toBe(m.sha256);
    });

    it('carries the original snapshot with its checksum, the field history with the reviewer name, every version', () => {
      const snap = JSON.parse(strFromU8(files['original/snapshot.json']));
      expect(snap.checksum).toMatch(/^[0-9a-f]{64}$/);
      expect(snap.snapshot.sections[0].blocks[0].text).toBe('Roof original.');
      const events = JSON.parse(strFromU8(files['audit/events.json'])) as { actorName: string | null; op: string }[];
      expect(events.some((e) => e.actorName === 'Jane Reviewer')).toBe(true);
      const versions = JSON.parse(strFromU8(files['audit/versions.json'])) as { version: number }[];
      expect(versions.length).toBeGreaterThanOrEqual(2);
    });

    it('is the owner’s or an admin’s only; nothing for others, strangers or unknown reports', async () => {
      expect((await exportZip(admin.token, r.id)).status).toBe(200);
      expect((await exportZip(b.token, r.id)).status).toBe(403);
      expect((await request(API).post(`/reports/${r.id}/archive`)).status).toBe(401);
      expect((await exportZip(a.token, randomUUID())).status).toBe(404);
    });

    it('is audited (who, size, checksum)', async () => {
      let log = null;
      for (let i = 0; i < 20 && !log; i++) {
        log = await prisma.auditLog.findFirst({ where: { entityId: r.id, action: 'REPORT_ARCHIVE_EXPORTED', actorId: a.id } });
        if (!log) await new Promise((res) => setTimeout(res, 250));
      }
      expect(log).not.toBeNull();
      expect(log!.metadata).toMatchObject({ sha256: sha(zip) });
    });
  });

  describe('restore: round trip', () => {
    it.each([
      ['a draft report', false],
      ['a finalised report', true],
    ])('%s comes back as it was: data, pictures byte for byte, original immutable, documents, history marked imported', async (_name, finalised) => {
      const r = await build(finalised);
      const before = await state(r.id);
      const exported = await exportZip(a.token, r.id);
      expect(exported.status).toBe(200);
      const eventsBefore = await prisma.reportAuditEvent.count({ where: { reportId: r.id } });
      await removeSurvey(r.id);
      expect(await prisma.report.count({ where: { id: r.id } })).toBe(0);

      const res = await restore(a.token, exported.body as Buffer);
      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({ reportId: r.id, restoredFromArchive: true, version: before.report.version });
      expect(res.body.counts).toMatchObject({ sections: 2, media: 4, documents: finalised ? 4 : 2 });

      const after = await state(r.id);
      // a report that was not finalised comes back as a draft; a finalised one stays final
      expect(after.report).toEqual({ ...before.report, status: finalised ? ReportStatus.FINALISED : ReportStatus.DRAFT });
      expect(after.survey).toEqual(before.survey);
      expect(after.sections).toEqual(before.sections);
      expect(after.media).toEqual(before.media);
      expect(after.snapshot).toEqual(before.snapshot);
      expect(after.files).toEqual(before.files);
      expect(after.events).toEqual(before.events.map((e) => e)); // the same history with the original timestamps and actors
      expect(after.versions).toEqual(before.versions);

      // history is marked imported; one new RESTORED event records who and when
      const imported = await prisma.reportAuditEvent.count({ where: { reportId: r.id, imported: true } });
      expect(imported).toBe(eventsBefore);
      const restoredEvent = await prisma.reportAuditEvent.findFirstOrThrow({ where: { reportId: r.id, op: 'RESTORED' } });
      expect(restoredEvent).toMatchObject({ actor: `owner:${a.id}`, source: 'RESTORE', imported: false });

      // the report is visibly marked, and the audit endpoint says what is imported
      const latest = await request(API).get(`/reports/${r.id}/latest`).set(owner(a.token));
      expect(latest.body).toMatchObject({ restoredFromArchive: true });
      const audit = await request(API).get(`/reports/${r.id}/audit`).set(owner(a.token));
      expect(audit.body.events.filter((e: { imported: boolean }) => e.imported).length).toBe(eventsBefore);
      expect(audit.body.events.some((e: { op: string; imported: boolean }) => e.op === 'RESTORED' && !e.imported)).toBe(true);

      // the original is intact and still immutable; files and pictures are served again
      const original = await request(API).get(`/reports/${r.id}/original`).set(owner(a.token));
      expect(original.body).toMatchObject({ intact: true, checksum: before.snapshot.checksum });
      expect(original.body.files.length).toBe(2);
      await expect(prisma.$executeRaw`UPDATE report_original_snapshots SET app_version = 'x' WHERE report_id = ${r.id}::uuid`).rejects.toThrow();
      const picture = await request(API).get(`/reports/${r.id}/media/${r.photo2}/file`).set(owner(a.token)).buffer(true).parse(binary as never);
      expect(picture.status).toBe(200);
      expect(sha(picture.body as Buffer)).toBe(before.media.find((m) => m.id === r.photo2)!.bytes);

      // the attempt is on record
      const rec = await prisma.reportArchiveImport.findFirst({ where: { restoredReportId: r.id } });
      expect(rec).toMatchObject({ outcome: 'RESTORED', uploaderId: a.id, errorCode: null });
      expect(rec!.sha256).toBe(sha(exported.body as Buffer));
    });

    it('the restored draft can be edited and exported again; a restored final report stays locked', async () => {
      const draft = await build(false);
      const dz = (await exportZip(a.token, draft.id)).body as Buffer;
      const fin = await build(true);
      const fz = (await exportZip(a.token, fin.id)).body as Buffer;
      await removeSurvey(draft.id);
      await removeSurvey(fin.id);
      expect((await restore(a.token, dz)).status).toBe(201);
      expect((await restore(a.token, fz)).status).toBe(201);

      const link = await request(API).post(`/reports/${draft.id}/edit-links`).set(owner(a.token));
      expect(link.status).toBe(201);
      const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
      const h = { Cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], 'X-CSRF-Token': open.body.csrfToken as string };
      const report = await prisma.report.findUniqueOrThrow({ where: { id: draft.id } });
      const content = report.content as { id: string; blocks: { id: string }[] }[];
      const save = await request(API).patch(`/editor/reports/${draft.id}`).set(h).send({ baseVersion: report.version, idempotencyKey: randomUUID(), changes: [{ op: 'updateBlock', sectionId: content[0].id, blockId: content[0].blocks[0].id, fields: { text: 'After restore.' } }] });
      expect(save.status).toBe(200);
      expect(save.body.version).toBe(report.version + 1);
      expect((await exportZip(a.token, draft.id)).status).toBe(200);

      const locked = await request(API).post(`/reports/${fin.id}/edit-links`).set(owner(a.token));
      expect(locked.status).toBe(403);
      expect(locked.body.error).toBe('REPORT_FINALISED');
    });

    it('an admin may restore a user’s archive for that user', async () => {
      const r = await build(false);
      const z = (await exportZip(a.token, r.id)).body as Buffer;
      await removeSurvey(r.id);
      const res = await restore(admin.token, z);
      expect(res.status).toBe(201);
      expect((await prisma.survey.findUniqueOrThrow({ where: { id: r.id } })).userId).toBe(a.id);
    });
  });

  describe('restore: refused, and nothing is written', () => {
    let r: Awaited<ReturnType<typeof build>>;
    let zip: Buffer;

    beforeAll(async () => {
      r = await build(true);
      zip = (await exportZip(a.token, r.id)).body as Buffer;
    });

    const nothingRestored = async (id: string) => {
      expect(await prisma.survey.count({ where: { id } })).toBe(0);
      expect(await prisma.report.count({ where: { id } })).toBe(0);
      expect(await prisma.media.count({ where: { surveyId: id } })).toBe(0);
      expect(await prisma.reportFile.count({ where: { reportId: id } })).toBe(0);
    };
    const storedFiles = () => {
      const count = (dir: string): number => (fs.existsSync(dir) ? fs.readdirSync(dir, { withFileTypes: true }).reduce((n, e) => n + (e.isDirectory() ? count(path.join(dir, e.name)) : 1), 0) : 0);
      return count(path.join(STORAGE_ROOT, r.id)) + count(path.join(STORAGE_ROOT, 'report-files', r.id));
    };
    const rezip = (change: (f: Record<string, Uint8Array>) => void): Buffer => {
      const f = unzipSync(new Uint8Array(zip));
      change(f);
      return Buffer.from(zipSync(f));
    };

    it('UUID collision: the report still exists, so nothing is overwritten and the answer says so', async () => {
      const before = await state(r.id);
      const res = await restore(a.token, zip);
      expect(res.status).toBe(409);
      expect(res.body.error).toBe('ARCHIVE_REPORT_ID_COLLISION');
      expect(res.body.details).toEqual({ reportId: r.id });
      expect(await state(r.id)).toEqual(before);
      const rec = await prisma.reportArchiveImport.findFirst({ where: { uploaderId: a.id, errorCode: 'ARCHIVE_REPORT_ID_COLLISION' }, orderBy: { createdAt: 'desc' } });
      expect(rec).toMatchObject({ outcome: 'REJECTED', restoredReportId: null });
    });

    describe('with the report gone', () => {
      beforeAll(async () => {
        await removeSurvey(r.id);
        fs.rmSync(path.join(STORAGE_ROOT, r.id), { recursive: true, force: true });
        fs.rmSync(path.join(STORAGE_ROOT, 'report-files', r.id), { recursive: true, force: true });
      });

      const refused = async (z: Buffer | null, status: number, error: string, message?: RegExp) => {
        const res = await restore(a.token, z);
        expect([res.status, res.body.error]).toEqual([status, error]);
        if (message) expect(res.body.message).toMatch(message);
        await nothingRestored(r.id);
        expect(storedFiles()).toBe(0);
      };

      it('no file', () => refused(null, 400, 'VALIDATION_ERROR'));
      it('something that is not a ZIP (a PDF, an empty file)', async () => {
        await refused(pdf('not an archive'), 422, 'ARCHIVE_INVALID', /not a ZIP/);
        await refused(Buffer.from('PK'), 422, 'ARCHIVE_INVALID');
      });
      it('a picture changed inside the archive (checksum)', () => refused(rezip((f) => { const k = Object.keys(f).find((n) => n.startsWith('original/media/'))!; f[k] = Uint8Array.from([...f[k]].map((v, i) => (i === 30 ? v ^ 0xff : v))); }), 422, 'ARCHIVE_INVALID', /checksum/));
      it('a document replaced inside the archive', () => refused(rezip((f) => { const k = Object.keys(f).find((n) => n.startsWith('final/documents/') && n.endsWith('.pdf'))!; f[k] = new Uint8Array(Buffer.from(pdf('evil'))); }), 422, 'ARCHIVE_INVALID', /size|checksum/));
      it('the report data changed inside the archive', () => refused(rezip((f) => { f['final/report.json'] = strToU8(strFromU8(f['final/report.json']).replace('Roof edited.', 'Roof hacked.')); }), 422, 'ARCHIVE_INVALID', /checksum|size/));
      it('the manifest rewritten with matching checksums (signature does not match)', () =>
        refused(
          rezip((f) => {
            f['final/report.json'] = strToU8(strFromU8(f['final/report.json']).replace('Roof edited.', 'Roof hacked.'));
            const m = JSON.parse(strFromU8(f['manifest.json']));
            m.files.find((x: { path: string }) => x.path === 'final/report.json').sha256 = sha(f['final/report.json']);
            m.files.find((x: { path: string }) => x.path === 'final/report.json').size = f['final/report.json'].length;
            f['manifest.json'] = strToU8(JSON.stringify(m));
          }),
          422,
          'ARCHIVE_INVALID',
          /signature/,
        ));
      it('the owner changed in the manifest (to take over someone else’s report)', () =>
        refused(rezip((f) => { const m = JSON.parse(strFromU8(f['manifest.json'])); m.ownerUserId = b.id; f['manifest.json'] = strToU8(JSON.stringify(m)); }), 422, 'ARCHIVE_INVALID', /signature/));
      it('an unexpected file, and a traversal path', async () => {
        await refused(rezip((f) => { f['final/run.sh'] = strToU8('rm -rf /'); }), 422, 'ARCHIVE_INVALID', /Unexpected file/);
        await refused(rezip((f) => { f['../../evil.txt'] = strToU8('x'); }), 422, 'ARCHIVE_INVALID', /Unexpected file/);
        await refused(rezip((f) => { f['final/../../../evil.txt'] = strToU8('x'); }), 422, 'ARCHIVE_INVALID', /Unexpected file/);
        await refused(rezip((f) => { f['audit/events.json.bak'] = strToU8('x'); }), 422, 'ARCHIVE_INVALID', /Unexpected file/);
      });
      it('a listed file removed from the archive', () => refused(rezip((f) => { delete f['audit/events.json']; }), 422, 'ARCHIVE_INVALID', /not in the archive/));
      it('a ZIP bomb (a huge, highly compressed file)', () => refused(rezip((f) => { f['audit/events.json'] = new Uint8Array(80 * 1024 * 1024); }), 422, 'ARCHIVE_INVALID', /expands suspiciously|larger than allowed|manifest/));
      it('another user cannot restore it (ownership), and nothing is created', async () => {
        const res = await restore(b.token, zip);
        expect([res.status, res.body.error]).toEqual([403, 'ARCHIVE_NOT_OWNER']);
        await nothingRestored(r.id);
        expect(storedFiles()).toBe(0);
      });
      it('every refusal is on record, with the reason', async () => {
        const recs = await prisma.reportArchiveImport.findMany({ where: { uploaderId: a.id, outcome: 'REJECTED', errorCode: 'ARCHIVE_INVALID' } });
        expect(recs.length).toBeGreaterThanOrEqual(8);
        expect(recs.some((x) => /signature/.test(x.message ?? ''))).toBe(true);
        expect(recs.some((x) => /Unexpected file/.test(x.message ?? ''))).toBe(true);
        expect(await prisma.reportArchiveImport.count({ where: { uploaderId: b.id, errorCode: 'ARCHIVE_NOT_OWNER' } })).toBe(1);
      });
      it('a picture id that already belongs to another report is a collision too, and writes nothing', async () => {
        const other = await prisma.survey.create({ data: { title: TITLE, propertyAddress: 'Other', userId: a.id } });
        await prisma.media.create({ data: { id: r.photoId, surveyId: other.id, type: 'PHOTO', fileName: 'x.jpg', mimeType: 'image/jpeg', size: 1, storagePath: 'nowhere/x.jpg' } });
        const res = await restore(a.token, zip);
        expect([res.status, res.body.error]).toEqual([409, 'ARCHIVE_REPORT_ID_COLLISION']);
        await nothingRestored(r.id);
        expect(storedFiles()).toBe(0);
        await prisma.survey.delete({ where: { id: other.id } });
      });
      it('and then the untouched archive still restores', async () => {
        const res = await restore(a.token, zip);
        expect(res.status).toBe(201);
        expect(res.body.status).toBe('FINALISED');
      });
    });
  });
});
