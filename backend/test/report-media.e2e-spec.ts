/**
 * E2E: pictures and signatures are never destroyed (Remote Editor spec v1.4 sections 9 and 20): a picture replaced or deleted in the
 * browser stays on the volume with its record and points to what replaced it; the phone's delete of a picture or signature of a
 * survey with a report only marks it deleted; the owner can read every file; a photo's drawing is kept with it; the report rules
 * (finalised, edited on a computer) apply to deleting from the phone too.
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { createHash, randomUUID } from 'crypto';
import sharp from 'sharp';
import { UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const TITLE = `${TEST_PREFIX}media`;
const sha = (b: Buffer) => createHash('sha256').update(b).digest('hex');
const jpeg = (color: string) => sharp({ create: { width: 64, height: 48, channels: 3, background: color } }).jpeg().toBuffer();
const png = () => sharp({ create: { width: 40, height: 20, channels: 3, background: '#222222' } }).png().toBuffer();

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}media_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

describe('Pictures and signatures are kept (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let admin: { id: string; token: string };
  let surveyId: string;
  let sectionId: string;
  let blockId: string;
  let cookie: string;
  let csrf: string;

  const h = () => ({ Cookie: cookie, 'X-CSRF-Token': csrf });
  const version = async () => (await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).version;
  const phoneUpload = async (buf: Buffer, type: 'PHOTO' | 'SIGNATURE', name: string) => {
    const r = await request(API).post('/media/upload').set(owner(a.token)).field('surveyId', surveyId).field('type', type).attach('file', buf, { filename: name, contentType: type === 'PHOTO' ? 'image/jpeg' : 'image/png' });
    expect(r.status).toBe(201);
    return r.body.id as string;
  };
  const row = (id: string) => prisma.media.findUniqueOrThrow({ where: { id } });
  const onDisk = (storagePath: string) => path.join(STORAGE_ROOT, storagePath);

  async function newReport(withLink = true) {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '11 Media Road', userId: a.id } });
    surveyId = survey.id;
    sectionId = randomUUID();
    blockId = randomUUID();
    const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'Roof.' }] }];
    expect((await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content })).status).toBe(200);
    if (withLink) {
      const link = await request(API).post(`/reports/${surveyId}/edit-links`).set(owner(a.token));
      const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
      cookie = (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0];
      csrf = open.body.csrfToken;
    }
  }

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
  });
  beforeEach(async () => {
    await newReport();
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: TITLE }, select: { id: true } });
    for (const s of surveys) fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}media_` } } });
    await prisma.$disconnect();
  });

  describe('replacing a photo in the browser', () => {
    it('the old picture stays on the volume and in the database and points to the new one; the original is the phone one', async () => {
      const original = await jpeg('#aa0000');
      const photoId = await phoneUpload(original, 'PHOTO', 'roof.jpg');
      const replacement = await jpeg('#0000aa');
      const rep = await request(API).post(`/editor/reports/${surveyId}/photos/${photoId}/replace`).set(h()).field('expectedReportVersion', String(await version())).attach('file', replacement, { filename: 'new.jpg', contentType: 'image/jpeg' });
      expect(rep.status).toBe(201);
      const newId = rep.body.photo.id as string;
      const oldRow = await row(photoId);
      const newRow = await row(newId);
      expect(oldRow.deletedAt).not.toBeNull();
      expect(oldRow.replacedById).toBe(newId);
      expect(oldRow.source).toBe('PHONE');
      expect(newRow.source).toBe('EDITOR');
      expect(newRow.replacedById).toBeNull();
      // the old bytes are still there, byte for byte (the stored file is the processed original)
      expect(fs.existsSync(onDisk(oldRow.storagePath))).toBe(true);
      expect(sha(fs.readFileSync(onDisk(oldRow.storagePath)))).not.toBe(sha(fs.readFileSync(onDisk(newRow.storagePath))));
    });

    it('the browser deleting a photo keeps the file too', async () => {
      const photoId = await phoneUpload(await jpeg('#00aa00'), 'PHOTO', 'a.jpg');
      const del = await request(API).delete(`/editor/reports/${surveyId}/photos/${photoId}`).query({ expectedReportVersion: await version() }).set(h());
      expect(del.status).toBe(200);
      const r = await row(photoId);
      expect(r.deletedAt).not.toBeNull();
      expect(fs.existsSync(onDisk(r.storagePath))).toBe(true);
    });

    it('a photo added in the browser is marked EDITOR, so it is not mistaken for an original', async () => {
      const up = await request(API).post(`/editor/reports/${surveyId}/photos`).set(h()).field('expectedReportVersion', String(await version())).attach('file', await jpeg('#555555'), { filename: 'b.jpg', contentType: 'image/jpeg' });
      expect(up.status).toBe(201);
      expect(up.body.photo).toMatchObject({ source: 'EDITOR', replacedBy: null, hasAnnotations: false });
    });
  });

  describe('deleting from the phone', () => {
    it('a picture of a survey with a report is only marked deleted: the file and the record stay, the phone sees it gone', async () => {
      const photoId = await phoneUpload(await jpeg('#aa00aa'), 'PHOTO', 'p.jpg');
      const before = await row(photoId);
      const del = await request(API).delete(`/media/${photoId}`).set(owner(a.token));
      expect(del.status).toBe(200);
      expect(del.body).toEqual({ success: true, id: photoId });
      const after = await row(photoId);
      expect(after.deletedAt).not.toBeNull();
      expect(fs.existsSync(onDisk(after.storagePath))).toBe(true);
      expect(after.size).toBe(before.size);
      expect((await request(API).get(`/media/${photoId}`).set(owner(a.token))).status).toBe(404);
    });

    it('a signature is kept as well, and the deletion is audited', async () => {
      const sigId = await phoneUpload(await png(), 'SIGNATURE', 'sig.png');
      expect((await request(API).delete(`/media/${sigId}`).set(owner(a.token))).status).toBe(200);
      const r = await row(sigId);
      expect(r.deletedAt).not.toBeNull();
      expect(fs.existsSync(onDisk(r.storagePath))).toBe(true);
      let log = null;
      for (let i = 0; i < 20 && !log; i++) {
        log = await prisma.auditLog.findFirst({ where: { entityId: surveyId, action: 'SIGNATURE_DELETED' } });
        if (!log) await new Promise((res) => setTimeout(res, 250));
      }
      expect(log).not.toBeNull();
      expect(log!.metadata).toMatchObject({ mediaId: sigId, type: 'SIGNATURE' });
    });

    it('a survey without a report behaves as before: the file and the record are removed', async () => {
      const lone = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '12 Lone Road', userId: a.id } });
      const up = await request(API).post('/media/upload').set(owner(a.token)).field('surveyId', lone.id).field('type', 'PHOTO').attach('file', await jpeg('#123123'), { filename: 'l.jpg', contentType: 'image/jpeg' });
      const stored = await row(up.body.id);
      expect((await request(API).delete(`/media/${up.body.id}`).set(owner(a.token))).status).toBe(200);
      expect(await prisma.media.count({ where: { id: up.body.id } })).toBe(0);
      expect(fs.existsSync(onDisk(stored.storagePath))).toBe(false);
    });

    it('the report rules apply: refused once finalised, and when the report was edited on a computer and the phone has not taken it', async () => {
      const photoId = await phoneUpload(await jpeg('#bbbbbb'), 'PHOTO', 'r.jpg');
      const save = await request(API).patch(`/editor/reports/${surveyId}`).set(h()).send({ baseVersion: await version(), idempotencyKey: randomUUID(), changes: [{ op: 'updateBlock', sectionId, blockId, fields: { text: 'Edited.' } }] });
      expect(save.status).toBe(200);
      const stale = await request(API).delete(`/media/${photoId}`).set(owner(a.token)).set('X-Report-Version', '1');
      expect([stale.status, stale.body.error]).toEqual([409, 'REPORT_VERSION_CONFLICT']);
      expect((await row(photoId)).deletedAt).toBeNull();
      await prisma.report.update({ where: { id: surveyId }, data: { status: 'FINALISED', finalVersion: await version() } });
      const late = await request(API).delete(`/media/${photoId}`).set(owner(a.token)).set('X-Report-Version', String(await version()));
      expect([late.status, late.body.error]).toEqual([403, 'REPORT_FINALISED']);
      expect((await row(photoId)).deletedAt).toBeNull();
    });
  });

  describe('the owner reads every picture', () => {
    it('lists photos and signatures with where they came from, what replaced them and whether they were deleted', async () => {
      const photoId = await phoneUpload(await jpeg('#101010'), 'PHOTO', 'one.jpg');
      const sigId = await phoneUpload(await png(), 'SIGNATURE', 'sig.png');
      const rep = await request(API).post(`/editor/reports/${surveyId}/photos/${photoId}/replace`).set(h()).field('expectedReportVersion', String(await version())).attach('file', await jpeg('#202020'), { filename: 'two.jpg', contentType: 'image/jpeg' });
      const list = await request(API).get(`/reports/${surveyId}/media`).set(owner(a.token));
      expect(list.status).toBe(200);
      const byId = Object.fromEntries(list.body.media.map((m: { id: string }) => [m.id, m]));
      expect(byId[photoId]).toMatchObject({ type: 'PHOTO', source: 'PHONE', original: true, deleted: true, replacedBy: rep.body.photo.id });
      expect(byId[rep.body.photo.id]).toMatchObject({ type: 'PHOTO', source: 'EDITOR', original: false, deleted: false, replacedBy: null });
      expect(byId[sigId]).toMatchObject({ type: 'SIGNATURE', original: true, deleted: false });
    });

    it('serves the bytes of a replaced or deleted picture to the owner and an admin, nobody else', async () => {
      const photoId = await phoneUpload(await jpeg('#303030'), 'PHOTO', 'old.jpg');
      await request(API).post(`/editor/reports/${surveyId}/photos/${photoId}/replace`).set(h()).field('expectedReportVersion', String(await version())).attach('file', await jpeg('#404040'), { filename: 'n.jpg', contentType: 'image/jpeg' });
      const stored = fs.readFileSync(onDisk((await row(photoId)).storagePath));
      const get = (token: string | null) => {
        const r = request(API).get(`/reports/${surveyId}/media/${photoId}/file`);
        return (token ? r.set(owner(token)) : r).buffer(true).parse((res, cb) => {
          const chunks: Buffer[] = [];
          res.on('data', (c: Buffer) => chunks.push(c));
          res.on('end', () => cb(null, Buffer.concat(chunks)));
        });
      };
      const ok = await get(a.token);
      expect(ok.status).toBe(200);
      expect(sha(ok.body as Buffer)).toBe(sha(stored));
      expect(ok.headers['x-content-type-options']).toBe('nosniff');
      expect(ok.headers['cache-control']).toContain('no-store');
      expect((await get(admin.token)).status).toBe(200);
      expect((await get(b.token)).status).toBe(403);
      expect((await get(null)).status).toBe(401);
      expect((await request(API).get(`/reports/${surveyId}/media/${randomUUID()}/file`).set(owner(a.token))).status).toBe(404);
    });

    it('a media id of another report is not found through this one', async () => {
      const photoId = await phoneUpload(await jpeg('#505050'), 'PHOTO', 'x.jpg');
      const mine = surveyId;
      await newReport(false);
      expect((await request(API).get(`/reports/${surveyId}/media/${photoId}/file`).set(owner(a.token))).status).toBe(404);
      expect((await request(API).get(`/reports/${mine}/media/${photoId}/file`).set(owner(a.token))).status).toBe(200);
    });

    it('the editor photo list also tells source, replacement and drawing', async () => {
      const photoId = await phoneUpload(await jpeg('#606060'), 'PHOTO', 'y.jpg');
      const list = await request(API).get(`/editor/reports/${surveyId}/photos`).set({ Cookie: cookie });
      expect(list.body.photos.find((p: { id: string }) => p.id === photoId)).toMatchObject({ source: 'PHONE', replacedBy: null, hasAnnotations: false });
    });
  });

  describe("a photo's drawing", () => {
    const elements = [
      { type: 'arrow', x1: 0.1, y1: 0.2, x2: 0.5, y2: 0.6, color: '#ff0000', width: 3 },
      { type: 'text', x: 0.4, y: 0.4, text: 'Slipped tile <b>here</b>', size: 14 },
      { type: 'circle', cx: 0.7, cy: 0.3, r: 0.1, filled: false },
    ];

    it('the phone sends it, it is kept with the photo, text is plain, and it can be read back', async () => {
      const photoId = await phoneUpload(await jpeg('#707070'), 'PHOTO', 'd.jpg');
      const put = await request(API).put(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token)).send({ annotations: elements });
      expect(put.status).toBe(200);
      expect(put.body).toEqual({ mediaId: photoId, items: 3 });
      const got = await request(API).get(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token));
      expect(got.body.annotations).toHaveLength(3);
      expect(got.body.annotations[1].text).toBe('Slipped tile here');
      expect(got.body.annotations[0]).toMatchObject({ type: 'arrow', color: '#ff0000', width: 3 });
      const list = await request(API).get(`/reports/${surveyId}/media`).set(owner(a.token));
      expect(list.body.media.find((m: { id: string }) => m.id === photoId).hasAnnotations).toBe(true);
    });

    it('it survives the photo being replaced in the browser (it belongs to the original picture)', async () => {
      const photoId = await phoneUpload(await jpeg('#808080'), 'PHOTO', 'e.jpg');
      await request(API).put(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token)).send({ annotations: elements });
      await request(API).post(`/editor/reports/${surveyId}/photos/${photoId}/replace`).set(h()).field('expectedReportVersion', String(await version())).attach('file', await jpeg('#909090'), { filename: 'n.jpg', contentType: 'image/jpeg' });
      expect((await request(API).get(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token))).body.annotations).toHaveLength(3);
    });

    it('an empty list removes it; a replacement list replaces it', async () => {
      const photoId = await phoneUpload(await jpeg('#a0a0a0'), 'PHOTO', 'f.jpg');
      await request(API).put(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token)).send({ annotations: elements });
      await request(API).put(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token)).send({ annotations: [elements[0]] });
      expect((await request(API).get(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token))).body.annotations).toHaveLength(1);
      await request(API).put(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token)).send({ annotations: [] });
      expect((await row(photoId)).annotations).toBeNull();
    });

    it('bad drawings are refused: not a list, too many, too deep, odd keys, too large, not a number', async () => {
      const photoId = await phoneUpload(await jpeg('#b0b0b0'), 'PHOTO', 'g.jpg');
      const put = (annotations: unknown) => request(API).put(`/reports/${surveyId}/media/${photoId}/annotations`).set(owner(a.token)).send({ annotations });
      const nested = (n: number): unknown => (n === 0 ? 1 : { a: nested(n - 1) });
      for (const [name, bad] of [
        ['not a list', { type: 'arrow' }],
        ['a string', 'arrow'],
        ['too many', Array.from({ length: 201 }, () => ({ t: 1 }))],
        ['too deep', [nested(8)]],
        ['odd key', [{ 'a b': 1 }]],
        ['too large', Array.from({ length: 40 }, () => ({ t: 'x'.repeat(1990) }))],
      ] as const) {
        expect([name, (await put(bad)).status]).toEqual([name, 400]);
      }
      expect((await row(photoId)).annotations).toBeNull();
    });

    it('only for photos of this report, only by the owner, and not once finalised', async () => {
      const photoId = await phoneUpload(await jpeg('#c0c0c0'), 'PHOTO', 'h.jpg');
      const sigId = await phoneUpload(await png(), 'SIGNATURE', 's.png');
      const url = (id: string) => `/reports/${surveyId}/media/${id}/annotations`;
      expect((await request(API).put(url(sigId)).set(owner(a.token)).send({ annotations: elements })).status).toBe(404);
      expect((await request(API).put(url(randomUUID())).set(owner(a.token)).send({ annotations: elements })).status).toBe(404);
      expect((await request(API).put(url(photoId)).set(owner(b.token)).send({ annotations: elements })).status).toBe(403);
      expect((await request(API).put(url(photoId)).send({ annotations: elements })).status).toBe(401);
      await prisma.report.update({ where: { id: surveyId }, data: { status: 'FINALISED', finalVersion: await version() } });
      const late = await request(API).put(url(photoId)).set(owner(a.token)).send({ annotations: elements });
      expect([late.status, late.body.error]).toEqual([403, 'REPORT_FINALISED']);
    });
  });

  it('signatures cannot be touched from the browser: the editor photo routes do not see them', async () => {
    const sigId = await phoneUpload(await png(), 'SIGNATURE', 'sig.png');
    const v = await version();
    const rep = await request(API).post(`/editor/reports/${surveyId}/photos/${sigId}/replace`).set(h()).field('expectedReportVersion', String(v)).attach('file', await jpeg('#d0d0d0'), { filename: 'n.jpg', contentType: 'image/jpeg' });
    expect(rep.status).toBe(404);
    const del = await request(API).delete(`/editor/reports/${surveyId}/photos/${sigId}`).query({ expectedReportVersion: v }).set(h());
    expect(del.status).toBe(404);
    expect((await row(sigId)).deletedAt).toBeNull();
    const list = await request(API).get(`/editor/reports/${surveyId}/photos`).set({ Cookie: cookie });
    expect(list.body.photos.map((p: { id: string }) => p.id)).not.toContain(sigId);
  });
});
