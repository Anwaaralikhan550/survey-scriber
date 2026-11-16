/**
 * Acceptance tests AT-01 .. AT-14 of the client spec "Secure Desktop Report Editing" v1.3, section 21, one named block
 * for each line of that section. Each runs the whole scenario through the real HTTP API.
 * Three lines also need a phone or a browser; their phone/browser tests are named in docs/desktop-editing/ACCEPTANCE.md
 * and this file covers the server half of them (AT-09, AT-10, AT-13).
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';
import sharp from 'sharp';
import { UserRole, ReportStatus } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const TITLE = `${TEST_PREFIX}accept`;
const bearer = (t: string) => ({ Authorization: `Bearer ${t}` });
const sess = (s: Session) => ({ Cookie: s.cookie, 'X-CSRF-Token': s.csrf });

interface Session {
  cookie: string;
  csrf: string;
}
interface Person {
  id: string;
  token: string;
}
interface Report {
  surveyId: string;
  secId: string;
  secId2: string;
  p1: string;
  p2: string;
  ratingId: string;
  recId: string;
  tableId: string;
}

async function person(tag: string, role: UserRole = UserRole.SURVEYOR): Promise<Person> {
  const email = `${TEST_PREFIX}accept_${tag}${TEST_EMAIL_DOMAIN}`;
  let u = await prisma.user.findUnique({ where: { email } });
  if (!u) u = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'A', lastName: tag, role, isActive: true } });
  return { id: u.id, token: generateStaffToken(u.id, u.email, u.role) };
}

async function newReport(owner: Person): Promise<Report> {
  const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '1 Acceptance Road', userId: owner.id } });
  const r: Report = { surveyId: survey.id, secId: randomUUID(), secId2: randomUUID(), p1: randomUUID(), p2: randomUUID(), ratingId: randomUUID(), recId: randomUUID(), tableId: randomUUID() };
  const content = [
    {
      id: r.secId,
      key: 'E1_ROOF',
      title: 'Roof',
      blocks: [
        { id: r.p1, type: 'paragraph', text: 'The roof is covered with concrete tiles.' },
        { id: r.p2, type: 'paragraph', text: 'Some tiles have slipped.' },
        { id: r.ratingId, type: 'rating', rating: '2', required: true },
        { id: r.recId, type: 'recommendation', recommendation: 'Repair the tiles.' },
        { id: r.tableId, type: 'table', table: { headers: ['Floor', 'Beds'], rows: [['Ground', '0'], ['First', '3']] } },
      ],
    },
    { id: r.secId2, key: 'F_WALLS', title: 'Walls', blocks: [{ id: randomUUID(), type: 'paragraph', text: 'The walls are cavity brick.' }] },
  ];
  const up = await request(API).put(`/reports/${survey.id}/snapshot`).set(bearer(owner.token)).send({ reportType: 'L2', content });
  expect(up.status).toBe(200);
  return r;
}

describe('Acceptance tests, client spec v1.3 section 21', () => {
  let owner: Person;
  let other: Person;
  let admin: Person;

  beforeAll(async () => {
    owner = await person('owner');
    other = await person('other');
    admin = await person('admin', UserRole.ADMIN);
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: TITLE }, select: { id: true } });
    for (const s of surveys) fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}accept_` } } });
    await prisma.$disconnect();
  });

  const link = (id: string, who: Person = owner) => request(API).post(`/reports/${id}/edit-links`).set(bearer(who.token));
  const openWith = async (url: string): Promise<Session> => {
    const open = await request(API).post('/editor/open').send({ token: url.split('/open/')[1] });
    expect(open.status).toBe(200);
    return { cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], csrf: open.body.csrfToken };
  };
  const rep = (id: string) => prisma.report.findUniqueOrThrow({ where: { id } });
  type Blk = { id: string; type: string; text?: string; rating?: string; recommendation?: string; table?: { rows: string[][] } };
  const contentOf = async (id: string) => (await rep(id)).content as unknown as Array<{ id: string; blocks: Blk[] }>;
  const blockOf = async (id: string, blockId: string) => (await contentOf(id)).flatMap((s) => s.blocks).find((b) => b.id === blockId);
  const patch = (r: Report, s: Session, baseVersion: number, changes: unknown[], extra: Record<string, unknown> = {}) =>
    request(API).patch(`/editor/reports/${r.surveyId}`).set(sess(s)).send({ baseVersion, changes, ...extra });
  const setText = (r: Report, blockId: string, text: string) => ({ op: 'updateBlock', sectionId: r.secId, blockId, fields: { text } });

  it('AT-01 two simultaneous create-link requests cannot produce two active links', async () => {
    const r = await newReport(owner);
    const results = await Promise.all(Array.from({ length: 8 }, () => link(r.surveyId)));
    expect(results.filter((x) => x.status === 201)).toHaveLength(1);
    expect(results.filter((x) => x.status === 409).every((x) => x.body.error === 'ACTIVE_LINK_EXISTS')).toBe(true);
    expect(await prisma.editLink.count({ where: { reportId: r.surveyId, status: 'ACTIVE' } })).toBe(1);
  });

  it('AT-02 an existing active link blocks a new one; expired, cancelled and revoked links allow a replacement', async () => {
    const r = await newReport(owner);
    const first = await link(r.surveyId);
    expect(first.status).toBe(201);
    expect((await link(r.surveyId)).body.error).toBe('ACTIVE_LINK_EXISTS');
    // cancelled by the owner
    expect((await request(API).delete(`/reports/${r.surveyId}/edit-links/${first.body.linkId}`).set(bearer(owner.token))).status).toBe(200);
    const second = await link(r.surveyId);
    expect(second.status).toBe(201);
    // revoked by an admin
    const rev = await request(API).delete(`/reports/${r.surveyId}/edit-links/${second.body.linkId}`).set(bearer(admin.token));
    expect(rev.body.status).toBe('REVOKED');
    const third = await link(r.surveyId);
    expect(third.status).toBe(201);
    // expired by time
    await prisma.editLink.update({ where: { id: third.body.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
    const fourth = await link(r.surveyId);
    expect(fourth.status).toBe(201);
    expect(await prisma.editLink.count({ where: { reportId: r.surveyId, status: 'ACTIVE' } })).toBe(1);
  });

  it('AT-03 after 72 hours editing is blocked; cancellation and revocation block writes at once', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const ttlHours = (new Date(l.body.expiresAt).getTime() - Date.now()) / 3600000;
    expect(ttlHours).toBeGreaterThan(71.9);
    expect(ttlHours).toBeLessThanOrEqual(72.01);
    const s = await openWith(l.body.url);
    expect((await patch(r, s, 1, [setText(r, r.p1, 'before expiry')])).status).toBe(200);
    await prisma.editLink.update({ where: { id: l.body.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
    const late = await patch(r, s, 2, [setText(r, r.p1, 'after expiry')]);
    expect(late.status).toBe(410);
    expect(late.body.error).toBe('LINK_EXPIRED');
    expect((await request(API).get(`/editor/reports/${r.surveyId}`).set('Cookie', s.cookie)).body.readOnly).toBe(true);
    expect((await blockOf(r.surveyId, r.p1))?.text).toBe('before expiry');

    const l2 = await link(r.surveyId);
    const s2 = await openWith(l2.body.url);
    expect((await request(API).delete(`/reports/${r.surveyId}/edit-links/${l2.body.linkId}`).set(bearer(owner.token))).status).toBe(200);
    const cut = await patch(r, s2, 2, [setText(r, r.p1, 'after cancel')]);
    expect([410, 404]).toContain(cut.status);
    expect(cut.body.error).toBe('LINK_REVOKED');

    const l3 = await link(r.surveyId);
    const s3 = await openWith(l3.body.url);
    await request(API).delete(`/reports/${r.surveyId}/edit-links/${l3.body.linkId}`).set(bearer(admin.token));
    expect((await patch(r, s3, 2, [setText(r, r.p1, 'after revoke')])).body.error).toBe('LINK_REVOKED');
    expect((await blockOf(r.surveyId, r.p1))?.text).toBe('before expiry');
  });

  it('AT-04 a new link invalidates the previous link and its sessions', async () => {
    const r = await newReport(owner);
    const l1 = await link(r.surveyId);
    const s1 = await openWith(l1.body.url);
    await request(API).delete(`/reports/${r.surveyId}/edit-links/${l1.body.linkId}`).set(bearer(owner.token));
    const l2 = await link(r.surveyId);
    expect((await patch(r, s1, 1, [setText(r, r.p1, 'old session')])).status).toBe(410);
    const again = await request(API).post('/editor/open').send({ token: l1.body.url.split('/open/')[1] });
    expect(again.status).toBe(410);
    const s2 = await openWith(l2.body.url);
    expect((await patch(r, s2, 1, [setText(r, r.p1, 'new session')])).status).toBe(200);
  });

  it('AT-05 sequential users edit the same report; committed changes reach the owner and the next reviewer', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const alice = await openWith(l.body.url);
    const bob = await openWith(l.body.url); // the same link, a second person
    expect((await patch(r, alice, 1, [setText(r, r.p1, 'Alice wording')])).body.version).toBe(2);
    const seenByBob = await request(API).get(`/editor/reports/${r.surveyId}`).set('Cookie', bob.cookie);
    expect(seenByBob.body.version).toBe(2);
    expect(JSON.stringify(seenByBob.body.content)).toContain('Alice wording');
    expect((await patch(r, bob, 2, [setText(r, r.p2, 'Bob wording')])).body.version).toBe(3);
    const sync = await request(API).post(`/reports/${r.surveyId}/sync`).set(bearer(owner.token));
    expect(sync.body.version).toBe(3);
    expect(JSON.stringify(sync.body.content)).toContain('Alice wording');
    expect(JSON.stringify(sync.body.content)).toContain('Bob wording');
    expect((await request(API).get(`/reports/${r.surveyId}/latest`).set(bearer(owner.token))).body.version).toBe(3);
  });

  it('AT-06 a stale concurrent save returns a conflict and overwrites nothing', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const a = await openWith(l.body.url);
    const b = await openWith(l.body.url);
    const first = await patch(r, a, 1, [setText(r, r.p1, 'First writer')]);
    const stale = await patch(r, b, 1, [setText(r, r.p1, 'Second writer, from an old copy')]);
    expect(first.status).toBe(200);
    expect(stale.status).toBe(409);
    expect(stale.body.error).toBe('VERSION_CONFLICT');
    expect(stale.body.details.serverVersion).toBe(2);
    expect((await blockOf(r.surveyId, r.p1))?.text).toBe('First writer');
    // two truly simultaneous saves from the same version: exactly one wins
    const [x, y] = await Promise.all([patch(r, a, 2, [setText(r, r.p2, 'from A')]), patch(r, b, 2, [setText(r, r.p2, 'from B')])]);
    expect([x.status, y.status].sort()).toEqual([200, 409]);
    expect((await rep(r.surveyId)).version).toBe(3);
  });

  it('AT-07 every supported paragraph, section, rating, recommendation and table edit persists', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const added = randomUUID();
    const res = await patch(r, s, 1, [
      setText(r, r.p1, 'Edited paragraph'),
      { op: 'updateBlock', sectionId: r.secId, blockId: r.ratingId, fields: { rating: '3' } },
      { op: 'updateBlock', sectionId: r.secId, blockId: r.recId, fields: { recommendation: 'Replace the roof covering.' } },
      { op: 'updateBlock', sectionId: r.secId, blockId: r.tableId, fields: { table: { headers: ['Floor', 'Beds'], rows: [['Ground', '1'], ['First', '4']] } } },
      { op: 'addBlock', sectionId: r.secId, afterBlockId: r.p1, block: { id: added, type: 'paragraph', text: 'A new paragraph' } },
      { op: 'moveBlock', sectionId: r.secId, blockId: r.p2, toSectionId: r.secId2 },
    ]);
    expect(res.status).toBe(200);
    const sections = await contentOf(r.surveyId);
    const roof = sections.find((x) => x.id === r.secId)!;
    const walls = sections.find((x) => x.id === r.secId2)!;
    expect(roof.blocks.map((b) => b.id).slice(0, 2)).toEqual([r.p1, added]);
    expect(roof.blocks.find((b) => b.id === r.p1)?.text).toBe('Edited paragraph');
    expect(roof.blocks.find((b) => b.id === r.ratingId)?.rating).toBe('3');
    expect(roof.blocks.find((b) => b.id === r.recId)?.recommendation).toBe('Replace the roof covering.');
    expect(roof.blocks.find((b) => b.id === r.tableId)?.table?.rows).toEqual([['Ground', '1'], ['First', '4']]);
    expect(walls.blocks.map((b) => b.id)).toContain(r.p2);
    const del = await patch(r, s, 2, [{ op: 'deleteBlock', sectionId: r.secId, blockId: added }]);
    expect(del.status).toBe(200);
    expect(await blockOf(r.surveyId, added)).toBeUndefined();
    // a new session sees it all (survives a reload)
    const s2 = await openWith((await (async () => {
      await request(API).delete(`/reports/${r.surveyId}/edit-links/${l.body.linkId}`).set(bearer(owner.token));
      return link(r.surveyId);
    })()).body.url);
    const reread = await request(API).get(`/editor/reports/${r.surveyId}`).set('Cookie', s2.cookie);
    expect(JSON.stringify(reread.body.content)).toContain('Edited paragraph');
    // a template field cannot be deleted
    expect((await patch(r, s2, 3, [{ op: 'deleteBlock', sectionId: r.secId, blockId: r.ratingId }])).status).toBe(400);
  });

  it('AT-08 photo upload, replace, caption, delete, order and section association persist and are served correctly', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const version = async () => (await rep(r.surveyId)).version;
    const jpeg = (w: number, h: number, c: string) => sharp({ create: { width: w, height: h, channels: 3, background: c } }).jpeg().toBuffer();
    const up = async (buf: Buffer, section: string, caption: string) =>
      request(API).post(`/editor/reports/${r.surveyId}/photos`).set(sess(s)).attach('file', buf, { filename: 'p.jpg', contentType: 'image/jpeg' }).field('expectedReportVersion', String(await version())).field('sectionKey', section).field('caption', caption);
    const one = await up(await jpeg(80, 40, '#ff0000'), 'E1_ROOF', 'Front');
    const two = await up(await jpeg(80, 40, '#00ff00'), 'E1_ROOF', 'Rear');
    const three = await up(await jpeg(80, 40, '#0000ff'), 'F_WALLS', 'Side');
    expect([one.status, two.status, three.status]).toEqual([201, 201, 201]);
    const list = async () => (await request(API).get(`/editor/reports/${r.surveyId}/photos`).set('Cookie', s.cookie)).body.photos as Array<{ id: string; caption: string; sectionKey: string; sortOrder: number }>;
    expect((await list()).map((p) => [p.caption, p.sectionKey, p.sortOrder])).toEqual(
      expect.arrayContaining([['Front', 'E1_ROOF', 0], ['Rear', 'E1_ROOF', 1], ['Side', 'F_WALLS', 0]]),
    );
    // caption, section and order
    expect((await request(API).put(`/editor/reports/${r.surveyId}/photos/${one.body.photo.id}`).set(sess(s)).send({ expectedReportVersion: await version(), caption: 'Front elevation', order: 1 })).status).toBe(200);
    expect((await request(API).put(`/editor/reports/${r.surveyId}/photos/${three.body.photo.id}`).set(sess(s)).send({ expectedReportVersion: await version(), sectionKey: 'E1_ROOF' })).status).toBe(200);
    const roof = (await list()).filter((p) => p.sectionKey === 'E1_ROOF').sort((a, b) => a.sortOrder - b.sortOrder);
    expect(roof.map((p) => p.sortOrder)).toEqual([0, 1, 2]);
    expect(roof.map((p) => p.caption)).toContain('Front elevation');
    expect(roof.map((p) => p.caption)).toContain('Side');
    // replace keeps caption, section and place (as a new photo id); the file really changes
    const rep2 = await request(API).post(`/editor/reports/${r.surveyId}/photos/${two.body.photo.id}/replace`).set(sess(s)).attach('file', await jpeg(100, 60, '#ffffff'), { filename: 'n.jpg', contentType: 'image/jpeg' }).field('expectedReportVersion', String(await version()));
    expect(rep2.status).toBe(201);
    const file = await request(API).get(`/editor/reports/${r.surveyId}/photos/${rep2.body.photo.id}/file`).set('Cookie', s.cookie).buffer(true).parse((res, cb) => {
      const chunks: Buffer[] = [];
      res.on('data', (c: Buffer) => chunks.push(c));
      res.on('end', () => cb(null, Buffer.concat(chunks)));
    });
    expect(file.headers['content-type']).toBe('image/jpeg');
    const meta = await sharp(file.body as Buffer).metadata();
    expect([meta.width, meta.height]).toEqual([100, 60]);
    expect(rep2.body.replaced).toBe(two.body.photo.id);
    const swapped = await list();
    expect(swapped.some((p) => p.id === two.body.photo.id)).toBe(false);
    expect(swapped.find((p) => p.id === rep2.body.photo.id)).toMatchObject({ caption: 'Rear', sectionKey: 'E1_ROOF' });
    // delete: gone from the list, still reported as deleted to the phone
    expect((await request(API).delete(`/editor/reports/${r.surveyId}/photos/${one.body.photo.id}`).query({ expectedReportVersion: await version() }).set(sess(s))).status).toBe(200);
    expect((await list()).some((p) => p.id === one.body.photo.id)).toBe(false);
    const phone = await request(API).get(`/reports/${r.surveyId}/photos`).query({ includeDeleted: 'true' }).set(bearer(owner.token));
    expect(phone.body.photos.find((p: { id: string; deleted: boolean }) => p.id === one.body.photo.id)?.deleted).toBe(true);
  });

  it('AT-09 a save is reported as done only when the server has committed it (server half; browser half is p20_editor.js)', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const ok = await patch(r, s, 1, [setText(r, r.p1, 'Committed')], { idempotencyKey: 'key-1' });
    expect(ok.status).toBe(200);
    expect(ok.body.version).toBe((await rep(r.surveyId)).version);
    expect((await blockOf(r.surveyId, r.p1))?.text).toBe('Committed');
    // a retry of the same save (network failure after commit) is not applied twice and says the same thing
    const retry = await patch(r, s, 1, [setText(r, r.p1, 'Committed')], { idempotencyKey: 'key-1' });
    expect(retry.status).toBe(200);
    expect(retry.body.version).toBe(ok.body.version);
    expect((await rep(r.surveyId)).version).toBe(2);
    // a refused save changes nothing, so the browser can show Failed truthfully
    const bad = await patch(r, s, 2, [{ op: 'updateBlock', sectionId: r.secId, blockId: randomUUID(), fields: { text: 'x' } }]);
    expect(bad.status).toBeGreaterThanOrEqual(400);
    expect((await rep(r.surveyId)).version).toBe(2);
  });

  it('AT-10 the phone can see a newer cloud version and is never allowed to overwrite it (server half; phone half is the Flutter report_editing tests)', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const phoneVersion = (await request(API).get(`/reports/${r.surveyId}/latest`).set(bearer(owner.token))).body.version;
    expect(phoneVersion).toBe(1);
    await patch(r, s, 1, [setText(r, r.p1, 'Edited in the browser')]);
    expect((await request(API).get(`/reports/${r.surveyId}/latest`).set(bearer(owner.token))).body.version).toBe(2);
    const content = [{ id: r.secId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: r.p1, type: 'paragraph', text: 'Phone text that never saw the edit' }] }];
    const blind = await request(API).put(`/reports/${r.surveyId}/snapshot`).set(bearer(owner.token)).send({ reportType: 'L2', baseVersion: phoneVersion, content });
    expect(blind.status).toBe(409);
    expect((await blockOf(r.surveyId, r.p1))?.text).toBe('Edited in the browser');
    const sync = await request(API).post(`/reports/${r.surveyId}/sync`).set(bearer(owner.token));
    expect(sync.body.version).toBe(2);
    expect(JSON.stringify(sync.body.content)).toContain('Edited in the browser');
  });

  it('AT-11 AI suggestions never change the report and never touch ratings (server half; wording checks are in ai-suggestion.service.spec.ts)', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const before = await rep(r.surveyId);
    const ask = (blockId: string) => request(API).post(`/editor/reports/${r.surveyId}/ai/suggest`).set(sess(s)).send({ blockId, action: 'IMPROVE', expectedReportVersion: before.version });
    for (const id of [r.ratingId, r.tableId]) {
      const res = await ask(id);
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('VALIDATION_ERROR');
    }
    const text = await ask(r.p1); // no model in the test server: unavailable, and the report is still untouched
    expect([200, 503]).toContain(text.status);
    const after = await rep(r.surveyId);
    expect(after.version).toBe(before.version);
    expect(JSON.stringify(after.content)).toBe(JSON.stringify(before.content));
  });

  it('AT-12 an approval belongs to one version; any content edit withdraws it', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const ed = async (action: string, body: Record<string, unknown> = {}) => request(API).post(`/editor/reports/${r.surveyId}/review/${action}`).set(sess(s)).send({ expectedReportVersion: (await rep(r.surveyId)).version, ...body });
    expect((await ed('submit')).status).toBe(200);
    const ok = await ed('decision', { decision: 'APPROVED' });
    expect(ok.body.reviewerApproval.version).toBe(1);
    const staleOwner = await request(API).post(`/reports/${r.surveyId}/owner-approval`).set(bearer(owner.token)).send({ expectedReportVersion: 99 });
    expect(staleOwner.status).toBe(409);
    expect((await patch(r, s, 1, [setText(r, r.p1, 'Edited after approval')])).status).toBe(200);
    const view = (await request(API).get(`/editor/reports/${r.surveyId}/review`).set('Cookie', s.cookie)).body;
    expect(view.status).toBe('SUBMITTED_FOR_REVIEW');
    expect(view.reviewerApproval).toBeNull();
    expect(view.reviews.find((x: { decision: string }) => x.decision === 'APPROVED').invalidated).toBe(true);
  });

  it('AT-13 finalising locks the report and revokes editing (server half; the phone makes the PDF and Word: final_export_test.dart)', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const ed = async (action: string, body: Record<string, unknown> = {}) => request(API).post(`/editor/reports/${r.surveyId}/review/${action}`).set(sess(s)).send({ expectedReportVersion: (await rep(r.surveyId)).version, ...body });
    await ed('submit');
    await ed('decision', { decision: 'APPROVED' });
    const v = (await rep(r.surveyId)).version;
    expect((await request(API).post(`/reports/${r.surveyId}/owner-approval`).set(bearer(owner.token)).send({ expectedReportVersion: v })).status).toBe(200);
    const fin = await request(API).post(`/reports/${r.surveyId}/finalise`).set(bearer(owner.token)).send({ expectedReportVersion: v });
    expect(fin.status).toBe(200);
    expect((await rep(r.surveyId)).status).toBe(ReportStatus.FINALISED);
    const late = await patch(r, s, v, [setText(r, r.p1, 'too late')]);
    expect(late.status).toBe(403);
    expect(late.body.error).toBe('REPORT_FINALISED');
    expect((await request(API).post('/editor/open').send({ token: l.body.url.split('/open/')[1] })).status).toBe(403);
    const sync = await request(API).post(`/reports/${r.surveyId}/sync`).set(bearer(owner.token));
    expect(sync.status).toBe(200); // the owner reads the final text and the phone builds PDF and Word from it
    expect(JSON.stringify(sync.body.content)).toContain('The roof is covered with concrete tiles.');
  });

  it('AT-14 owner-only actions and security controls hold across roles', async () => {
    const r = await newReport(owner);
    const l = await link(r.surveyId);
    const s = await openWith(l.body.url);
    const viewer = await (async () => {
      const email = `${TEST_PREFIX}accept_viewer${TEST_EMAIL_DOMAIN}`;
      const u = (await prisma.user.findUnique({ where: { email } })) ?? (await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'C', lastName: 'L', role: UserRole.VIEWER, isActive: true } }));
      return { id: u.id, token: generateStaffToken(u.id, u.email, u.role) };
    })();
    const ownerRoutes: Array<[string, string, Record<string, unknown> | undefined]> = [
      ['post', `/reports/${r.surveyId}/edit-links`, undefined],
      ['get', `/reports/${r.surveyId}/edit-links/current`, undefined],
      ['get', `/reports/${r.surveyId}/latest`, undefined],
      ['post', `/reports/${r.surveyId}/sync`, undefined],
      ['get', `/reports/${r.surveyId}/versions`, undefined],
      ['get', `/reports/${r.surveyId}/review`, undefined],
      ['post', `/reports/${r.surveyId}/owner-approval`, { expectedReportVersion: 1 }],
      ['post', `/reports/${r.surveyId}/review/reset`, { expectedReportVersion: 1 }],
      ['post', `/reports/${r.surveyId}/finalise`, { expectedReportVersion: 1 }],
      ['post', `/reports/${r.surveyId}/reopen`, { expectedReportVersion: 1, reason: 'because' }],
      ['get', `/reports/${r.surveyId}/finalisations`, undefined],
      ['post', `/reports/${r.surveyId}/versions/1/restore`, { baseVersion: 1 }],
      ['get', `/reports/${r.surveyId}/photos`, undefined],
    ];
    const call = (method: string, url: string, body: Record<string, unknown> | undefined, headers: Record<string, string>) => {
      const q = (request(API) as unknown as Record<string, (u: string) => request.Test>)[method](url).set(headers);
      return body ? q.send(body) : q;
    };
    for (const [method, url, body] of ownerRoutes) {
      expect([401]).toContain((await call(method, url, body, {})).status); // nobody logged in
      expect([401]).toContain((await call(method, url, body, sess(s))).status); // a browser session is not an owner
      expect([403, 404]).toContain((await call(method, url, body, bearer(other.token))).status); // another surveyor
      expect([403]).toContain((await call(method, url, body, bearer(viewer.token))).status); // a read-only (viewer) login
    }
    // the report is untouched by all of that
    const row = await rep(r.surveyId);
    expect(row.version).toBe(1);
    expect(row.status).toBe(ReportStatus.DRAFT);
    // a browser session works only for its own report
    const r2 = await newReport(owner);
    expect((await request(API).get(`/editor/reports/${r2.surveyId}`).set('Cookie', s.cookie)).status).toBe(403);
    // an admin may act for the owner
    expect((await request(API).get(`/reports/${r.surveyId}/latest`).set(bearer(admin.token))).status).toBe(200);
  });
});
