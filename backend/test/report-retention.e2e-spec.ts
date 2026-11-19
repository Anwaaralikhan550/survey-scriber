/**
 * E2E: retention (Remote Editor spec v1.4 sections 15 and 20): finalised reports are removed 60 days after finalisation, drafts 30 days
 * after the last meaningful activity; warnings on the days of the table; files first, then the report, leaving only a tombstone; a live
 * link, a review in progress and a legal hold stop it; the job can run any number of times. Reports are aged in the database and the job
 * runs with the real clock, so other suites' reports are never touched.
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';
import sharp from 'sharp';
import { ReportStatus, UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const TITLE = `${TEST_PREFIX}retention`;
const DAY = 24 * 60 * 60 * 1000;
const ago = (days: number, hours = 1) => new Date(Date.now() - days * DAY - hours * 3_600_000);
const jpeg = () => sharp({ create: { width: 32, height: 24, channels: 3, background: '#336699' } }).jpeg().toBuffer();
const pdf = () => Buffer.from('%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n', 'latin1');

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}retention_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

describe('Report retention (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let admin: { id: string; token: string };
  let manager: { id: string; token: string };
  let n = 0;

  const run = async (body: object = {}) => {
    const r = await request(API).post('/reports/retention/run').set(owner(admin.token)).send(body);
    expect(r.status).toBe(200);
    return r.body as { evaluated: number; warned: number; queued: number; cancelled: number; purged: number; retrying: number; failed: number };
  };
  const notices = (userId: string, type: string, title?: string) => prisma.notification.findMany({ where: { recipientId: userId, type: type as never, ...(title ? { title: { contains: title } } : {}) }, orderBy: { createdAt: 'asc' } });

  /** A report with a picture and an original document on disk, aged in the database. */
  async function make(opts: { draftAgeDays?: number; finalisedAgeDays?: number; status?: ReportStatus; user?: { id: string; token: string } } = {}) {
    const u = opts.user ?? a;
    const tag = `r${++n}_${randomUUID().slice(0, 6)}`;
    const survey = await prisma.survey.create({ data: { title: `${TITLE}_${tag}`, propertyAddress: '1 Retention Road', userId: u.id } });
    const id = survey.id;
    const content = [{ id: randomUUID(), key: 'E1', title: 'Roof', blocks: [{ id: randomUUID(), type: 'paragraph', text: 'Roof.' }] }];
    expect((await request(API).put(`/reports/${id}/snapshot`).set(owner(u.token)).send({ reportType: 'L2', content })).status).toBe(200);
    const photo = await request(API).post('/media/upload').set(owner(u.token)).field('surveyId', id).field('type', 'PHOTO').attach('file', await jpeg(), { filename: 'p.jpg', contentType: 'image/jpeg' });
    expect(photo.status).toBe(201);
    expect((await request(API).post(`/reports/${id}/files`).set(owner(u.token)).field('state', 'ORIGINAL').attach('file', pdf(), { filename: 'o.pdf' })).status).toBe(201);
    if (opts.finalisedAgeDays !== undefined) {
      const at = ago(opts.finalisedAgeDays);
      const v = (await prisma.report.findUniqueOrThrow({ where: { id } })).version;
      await prisma.report.update({ where: { id }, data: { status: ReportStatus.FINALISED, finalVersion: v, finalisedAt: at, updatedAt: at } });
    } else if (opts.status) {
      await prisma.report.update({ where: { id }, data: { status: opts.status, updatedAt: ago(opts.draftAgeDays ?? 0) } });
    } else {
      await prisma.report.update({ where: { id }, data: { updatedAt: ago(opts.draftAgeDays ?? 0) } });
    }
    return { id, title: `${TITLE}_${tag}`, mediaId: photo.body.id as string };
  }
  const reportDir = (id: string) => path.join(STORAGE_ROOT, id);
  const filesDir = (id: string) => path.join(STORAGE_ROOT, 'report-files', id);
  const exists = async (id: string) => (await prisma.report.count({ where: { id } })) + (await prisma.survey.count({ where: { id } }));
  const view = (token: string, id: string) => request(API).get(`/reports/${id}/retention`).set(owner(token));

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
    manager = await makeUser('manager', UserRole.MANAGER);
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: { startsWith: TITLE } }, select: { id: true } });
    for (const s of surveys) {
      fs.rmSync(reportDir(s.id), { recursive: true, force: true });
      fs.rmSync(filesDir(s.id), { recursive: true, force: true });
    }
    await prisma.survey.deleteMany({ where: { title: { startsWith: TITLE } } });
    await prisma.reportDeletion.deleteMany({ where: { ownerUserId: { in: [a.id, b.id] } } });
    await prisma.notification.deleteMany({ where: { recipientId: { in: [a.id, b.id, admin.id, manager.id] } } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}retention_` } } });
    await prisma.$disconnect();
  });

  describe("the owner's view", () => {
    it('a new draft: 30 days from now, the three warnings listed, no hold', async () => {
      const r = await make();
      const v = await view(a.token, r.id);
      expect(v.status).toBe(200);
      expect(v.body).toMatchObject({ policy: 'DRAFT', status: 'DRAFT', legalHold: { active: false }, restoredFromArchive: false });
      expect(v.body.daysLeft).toBeGreaterThanOrEqual(29);
      expect(v.body.daysLeft).toBeLessThanOrEqual(30);
      expect(v.body.warnings.map((w: { day: number; sent: boolean }) => [w.day, w.sent])).toEqual([[20, false], [25, false], [28, false]]);
      expect(v.body.policyText.archive).toContain('does not extend or pause the timer');
    });

    it('a finalised report: 60 days from finalisation, warnings 30, 45, 55', async () => {
      const r = await make({ finalisedAgeDays: 10 });
      const v = await view(a.token, r.id);
      expect(v.body.policy).toBe('FINALISED');
      expect(v.body.daysLeft).toBe(50);
      expect(v.body.warnings.map((w: { day: number }) => w.day)).toEqual([30, 45, 55]);
    });

    it('a review in progress has no clock at all; it is protected', async () => {
      const r = await make({ status: ReportStatus.UNDER_REVIEW, draftAgeDays: 100 });
      const v = await view(a.token, r.id);
      expect(v.body).toMatchObject({ policy: null, deleteAt: null, daysLeft: null, protectedReason: 'REVIEW_IN_PROGRESS' });
    });

    it('only the owner, an admin or a manager; nobody else', async () => {
      const r = await make();
      expect((await view(admin.token, r.id)).status).toBe(200);
      expect((await view(manager.token, r.id)).status).toBe(200);
      expect((await view(b.token, r.id)).status).toBe(403);
      expect((await request(API).get(`/reports/${r.id}/retention`)).status).toBe(401);
      expect((await view(a.token, randomUUID())).status).toBe(404);
    });
  });

  describe('draft warnings (spec 15.2)', () => {
    it('day 20, 25 and 28 each send one warning; running the job again sends nothing twice; the last says Final warning', async () => {
      const r = await make({ draftAgeDays: 20 });
      expect((await run()).warned).toBeGreaterThanOrEqual(1);
      let list = await notices(a.id, 'REPORT_RETENTION_WARNING', r.title);
      expect(list).toHaveLength(1);
      expect(list[0].title).toBe(`Draft "${r.title}" will be removed in 10 days`);
      expect(list[0].body).toContain('Merely opening the report does not restart the 30 days');
      await run();
      await run();
      expect(await notices(a.id, 'REPORT_RETENTION_WARNING', r.title)).toHaveLength(1);

      await prisma.report.update({ where: { id: r.id }, data: { updatedAt: ago(25) } });
      await run();
      list = await notices(a.id, 'REPORT_RETENTION_WARNING', r.title);
      expect(list.map((x) => x.title)).toEqual([`Draft "${r.title}" will be removed in 10 days`, `Draft "${r.title}" will be removed in 5 days`]);

      await prisma.report.update({ where: { id: r.id }, data: { updatedAt: ago(28) } });
      await run();
      list = await notices(a.id, 'REPORT_RETENTION_WARNING', r.title);
      expect(list[2].title).toBe(`Final warning: Draft "${r.title}" will be removed in 2 days`);
      const v = await view(a.token, r.id);
      expect(v.body.warnings.map((w: { sent: boolean }) => w.sent)).toEqual([true, true, true]);
    });

    it('days before the first warning send nothing; a job that first runs on day 27 sends one warning (the latest), not three', async () => {
      const early = await make({ draftAgeDays: 19 });
      const late = await make({ draftAgeDays: 27 });
      await run();
      expect(await notices(a.id, 'REPORT_RETENTION_WARNING', early.title)).toHaveLength(0);
      const l = await notices(a.id, 'REPORT_RETENTION_WARNING', late.title);
      expect(l).toHaveLength(1);
      expect(l[0].title).toContain('in 3 days');
    });

    it('meaningful activity restarts the 30 days and clears the warnings; merely viewing does not', async () => {
      const r = await make({ draftAgeDays: 26 });
      await run();
      expect((await notices(a.id, 'REPORT_RETENTION_WARNING', r.title)).length).toBe(1);
      await view(a.token, r.id); // opening / viewing is not activity
      expect((await view(a.token, r.id)).body.daysLeft).toBeLessThanOrEqual(4);
      const up = await request(API).put(`/reports/${r.id}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', baseVersion: 1, content: [{ id: randomUUID(), key: 'E1', title: 'Roof', blocks: [{ id: randomUUID(), type: 'paragraph', text: 'Worked on it.' }] }] });
      expect(up.status).toBe(200);
      await run();
      const v = await view(a.token, r.id);
      expect(v.body.daysLeft).toBeGreaterThanOrEqual(29);
      expect(v.body.warnings.every((w: { sent: boolean }) => !w.sent)).toBe(true);
    });
  });

  describe('finalised warnings (spec 15.1)', () => {
    it('day 30, 45 and 55 send the three warnings, each once', async () => {
      const r = await make({ finalisedAgeDays: 30 });
      await run();
      await run();
      expect((await notices(a.id, 'REPORT_RETENTION_WARNING', r.title)).map((x) => x.title)).toEqual([`Report "${r.title}" will be removed in 30 days`]);
      await prisma.report.update({ where: { id: r.id }, data: { finalisedAt: ago(45), updatedAt: ago(45) } });
      await run();
      await prisma.report.update({ where: { id: r.id }, data: { finalisedAt: ago(55), updatedAt: ago(55) } });
      await run();
      const list = await notices(a.id, 'REPORT_RETENTION_WARNING', r.title);
      expect(list.map((x) => x.title)).toEqual([`Report "${r.title}" will be removed in 30 days`, `Report "${r.title}" will be removed in 15 days`, `Final warning: Report "${r.title}" will be removed in 5 days`]);
      expect(list[0].body).toContain('Download the complete archive');
      expect(list[0].body).toContain('does not extend the 60 days');
    });
  });

  describe('purge (spec 15.1, 15.2, 15.3)', () => {
    it('a finalised report on day 59 stays; on day 61 files go first, then the report; only a tombstone with no content is left', async () => {
      const r = await make({ finalisedAgeDays: 59 });
      expect(fs.existsSync(reportDir(r.id))).toBe(true);
      expect(fs.existsSync(filesDir(r.id))).toBe(true);
      await run();
      expect(await exists(r.id)).toBe(2);
      expect(await prisma.reportDeletion.count({ where: { reportId: r.id } })).toBe(0);

      await prisma.report.update({ where: { id: r.id }, data: { finalisedAt: ago(61), updatedAt: ago(61) } });
      const summary = await run();
      expect(summary.purged).toBeGreaterThanOrEqual(1);
      expect(await exists(r.id)).toBe(0);
      expect(await prisma.media.count({ where: { surveyId: r.id } })).toBe(0);
      expect(await prisma.reportFile.count({ where: { reportId: r.id } })).toBe(0);
      expect(Number((await prisma.$queryRaw<{ n: bigint }[]>`SELECT count(*) AS n FROM report_original_snapshots WHERE report_id = ${r.id}::uuid`)[0].n)).toBe(0);
      expect(fs.existsSync(reportDir(r.id))).toBe(false);
      expect(fs.existsSync(filesDir(r.id))).toBe(false);
      const tomb = await prisma.reportDeletion.findUniqueOrThrow({ where: { reportId: r.id } });
      expect(tomb).toMatchObject({ status: 'DONE', policy: 'FINALISED', ownerUserId: a.id, lastError: null });
      expect(tomb.filesDeleted).toBeGreaterThanOrEqual(2);
      expect(tomb.purgedAt).not.toBeNull();
      expect(JSON.stringify(tomb)).not.toContain(r.title); // no report content in the tombstone
      expect((await request(API).get(`/reports/${r.id}/latest`).set(owner(a.token))).status).toBe(404);
      const log = await prisma.auditLog.findFirst({ where: { entityId: r.id, action: 'REPORT_PURGED' } });
      expect(log).not.toBeNull();
      expect(JSON.stringify(log!.metadata)).not.toContain(r.title);
      expect((await notices(a.id, 'REPORT_PURGED', r.title)).length).toBe(1);
      // running again changes nothing
      const again = await run();
      expect(again.purged).toBe(0);
      expect(await prisma.reportDeletion.count({ where: { reportId: r.id } })).toBe(1);
    });

    it('a draft is removed on day 31, not on day 29', async () => {
      const keep = await make({ draftAgeDays: 29 });
      const go = await make({ draftAgeDays: 31 });
      await run();
      expect(await exists(keep.id)).toBe(2);
      expect(await exists(go.id)).toBe(0);
      expect(fs.existsSync(reportDir(go.id))).toBe(false);
      expect(await prisma.reportDeletion.findUniqueOrThrow({ where: { reportId: go.id } })).toMatchObject({ status: 'DONE', policy: 'DRAFT' });
    });

    it('a review in progress or finalising, however old, is never purged and gets no warning', async () => {
      const ids: string[] = [];
      for (const status of [ReportStatus.SUBMITTED_FOR_REVIEW, ReportStatus.UNDER_REVIEW, ReportStatus.AMENDMENTS_REQUIRED, ReportStatus.REVIEWER_APPROVED, ReportStatus.OWNER_FINAL_APPROVAL, ReportStatus.FINALISING]) {
        ids.push((await make({ status, draftAgeDays: 200 })).id);
      }
      await run();
      for (const id of ids) {
        expect(await exists(id)).toBe(2);
        expect(await prisma.reportDeletion.count({ where: { reportId: id } })).toBe(0);
      }
    });

    it('a live edit link protects an old draft (active editing); when it ends the clock applies', async () => {
      const r = await make({ draftAgeDays: 0 });
      const link = await request(API).post(`/reports/${r.id}/edit-links`).set(owner(a.token));
      expect(link.status).toBe(201);
      await prisma.report.update({ where: { id: r.id }, data: { updatedAt: ago(45) } });
      await run();
      expect(await exists(r.id)).toBe(2);
      expect((await view(a.token, r.id)).body.linkLive).toBe(true);
      await prisma.editLink.updateMany({ where: { reportId: r.id }, data: { status: 'CANCELLED', endedAt: new Date() } });
      await run();
      expect(await exists(r.id)).toBe(0);
    });

    it('new activity after the job queued the report stops the purge (re-checked at the moment of deleting)', async () => {
      const r = await make({ draftAgeDays: 31 });
      // queued by hand, as a job that ran earlier would have
      await prisma.reportDeletion.create({ data: { reportId: r.id, ownerUserId: a.id, policy: 'DRAFT', anchorAt: ago(31), deleteAt: ago(1), status: 'PENDING', nextAttemptAt: new Date(Date.now() - 1000) } });
      await prisma.report.update({ where: { id: r.id }, data: { updatedAt: new Date() } });
      await run();
      expect(await exists(r.id)).toBe(2);
      expect(await prisma.reportDeletion.count({ where: { reportId: r.id } })).toBe(0);
    });

    it('a file that cannot be deleted keeps the report, retries later with back-off, and succeeds when the problem is gone', async () => {
      const r = await make({ draftAgeDays: 31 });
      // a directory where a file should be: unlink fails (not "not found")
      const blocker = path.join(reportDir(r.id), 'blocked');
      fs.mkdirSync(blocker, { recursive: true });
      await prisma.media.update({ where: { id: r.mediaId }, data: { storagePath: `${r.id}/blocked` } });
      const first = await run();
      expect(first.retrying).toBeGreaterThanOrEqual(1);
      expect(await exists(r.id)).toBe(2);
      const q = await prisma.reportDeletion.findUniqueOrThrow({ where: { reportId: r.id } });
      expect(q).toMatchObject({ status: 'PENDING', attempts: 1 });
      expect(q.lastError).toBeTruthy();
      expect(q.nextAttemptAt.getTime()).toBeGreaterThan(Date.now() + 4 * 60_000);
      // not retried before its time
      await run();
      expect((await prisma.reportDeletion.findUniqueOrThrow({ where: { reportId: r.id } })).attempts).toBe(1);
      // the problem goes away and the time comes
      fs.rmSync(blocker, { recursive: true, force: true });
      await prisma.reportDeletion.update({ where: { reportId: r.id }, data: { nextAttemptAt: new Date(Date.now() - 1000) } });
      const second = await run();
      expect(second.purged).toBeGreaterThanOrEqual(1);
      expect(await exists(r.id)).toBe(0);
      expect(await prisma.reportDeletion.findUniqueOrThrow({ where: { reportId: r.id } })).toMatchObject({ status: 'DONE', attempts: 2, lastError: null });
    });

    it('after too many failures the item is FAILED for an operator and stops retrying; retryFailed tries it again', async () => {
      const r = await make({ draftAgeDays: 31 });
      const blocker = path.join(reportDir(r.id), 'blocked');
      fs.mkdirSync(blocker, { recursive: true });
      await prisma.media.update({ where: { id: r.mediaId }, data: { storagePath: `${r.id}/blocked` } });
      await prisma.reportDeletion.create({ data: { reportId: r.id, ownerUserId: a.id, policy: 'DRAFT', anchorAt: ago(31), deleteAt: ago(1), status: 'PENDING', attempts: 7, nextAttemptAt: new Date(Date.now() - 1000) } });
      const s = await run();
      expect(s.failed).toBeGreaterThanOrEqual(1);
      expect(await prisma.reportDeletion.findUniqueOrThrow({ where: { reportId: r.id } })).toMatchObject({ status: 'FAILED', attempts: 8 });
      expect((await request(API).get('/reports/retention/overview').set(owner(admin.token))).body.queue.failed).toBeGreaterThanOrEqual(1);
      await run();
      expect((await prisma.reportDeletion.findUniqueOrThrow({ where: { reportId: r.id } })).attempts).toBe(8);
      fs.rmSync(blocker, { recursive: true, force: true });
      await run({ retryFailed: true });
      expect(await exists(r.id)).toBe(0);
    });
  });

  describe('legal hold (spec 15.2, 15.3)', () => {
    const hold = (token: string, id: string, reason: unknown) => request(API).post(`/reports/${id}/legal-hold`).set(owner(token)).send({ reason });
    const release = (token: string, id: string, reason: unknown) => request(API).delete(`/reports/${id}/legal-hold`).set(owner(token)).send({ reason });

    it('only Admin and Manager may place or release one; the owner and others may not; a reason is mandatory', async () => {
      const r = await make();
      expect((await hold(a.token, r.id, 'Client complaint ref 77')).status).toBe(403);
      expect((await hold(b.token, r.id, 'Client complaint ref 77')).status).toBe(403);
      expect((await request(API).post(`/reports/${r.id}/legal-hold`).send({ reason: 'Client complaint' })).status).toBe(401);
      expect((await hold(manager.token, r.id, '')).status).toBe(400);
      expect((await hold(manager.token, r.id, 'ab')).status).toBe(400);
      expect((await hold(manager.token, r.id, 'x'.repeat(501))).status).toBe(400);
      expect((await request(API).post(`/reports/${r.id}/legal-hold`).set(owner(manager.token)).send({})).status).toBe(400);
      expect((await hold(manager.token, randomUUID(), 'Client complaint ref 77')).status).toBe(404);
      const ok = await hold(manager.token, r.id, '  Client complaint ref 77  ');
      expect(ok.status).toBe(201);
      expect(ok.body.legalHold).toMatchObject({ active: true, reason: 'Client complaint ref 77', placedByRole: 'MANAGER' });
      expect((await release(a.token, r.id, 'Settled')).status).toBe(403);
      expect((await release(admin.token, r.id, 'Settled')).status).toBe(200);
    });

    it('a held report is never purged, however old, and sends no warnings; the owner is told and sees the reason', async () => {
      const r = await make({ finalisedAgeDays: 100 });
      // queued by an earlier run, then held: the hold cancels it
      await prisma.reportDeletion.create({ data: { reportId: r.id, ownerUserId: a.id, policy: 'FINALISED', anchorAt: ago(100), deleteAt: ago(40), status: 'PENDING', nextAttemptAt: new Date(Date.now() - 1000) } });
      const placed = await hold(admin.token, r.id, 'Complaint to the ombudsman, ref 12');
      expect(placed.status).toBe(201);
      expect(await prisma.reportDeletion.count({ where: { reportId: r.id } })).toBe(0);
      await run();
      await run();
      expect(await exists(r.id)).toBe(2);
      expect(await prisma.reportDeletion.count({ where: { reportId: r.id } })).toBe(0);
      expect(fs.existsSync(reportDir(r.id))).toBe(true);
      const told = await notices(a.id, 'REPORT_LEGAL_HOLD', r.title);
      expect(told).toHaveLength(1);
      expect(told[0].body).toContain('will not be deleted, whatever its age');
      expect(told[0].body).toContain('Complaint to the ombudsman, ref 12');
      const v = await view(a.token, r.id);
      expect(v.body.legalHold).toMatchObject({ active: true, reason: 'Complaint to the ombudsman, ref 12', placedByRole: 'ADMIN' });
      expect(v.body.deleteAt).toBeNull();
      const log = await prisma.auditLog.findFirst({ where: { entityId: r.id, action: 'REPORT_LEGAL_HOLD_PLACED' } });
      expect(log).toMatchObject({ actorId: admin.id });
      expect(log!.metadata).toMatchObject({ reason: 'Complaint to the ombudsman, ref 12', role: 'ADMIN' });
      expect((await request(API).get('/reports/retention/overview').set(owner(manager.token))).body.holds.some((h: { reportId: string }) => h.reportId === r.id)).toBe(true);
    });

    it('a second hold is refused; releasing without a hold is refused', async () => {
      const r = await make();
      expect((await release(admin.token, r.id, 'Nothing to release')).status).toBe(409);
      expect((await hold(admin.token, r.id, 'First hold reason')).status).toBe(201);
      const second = await hold(manager.token, r.id, 'Second hold reason');
      expect([second.status, second.body.error]).toEqual([409, 'INVALID_STATE']);
    });

    it('on release the owner is told, a grace period starts, and only after it does the normal rule delete the report', async () => {
      const r = await make({ finalisedAgeDays: 100 });
      expect((await hold(admin.token, r.id, 'Dispute with the client')).status).toBe(201);
      const rel = await release(manager.token, r.id, 'Dispute settled');
      expect(rel.status).toBe(200);
      expect(new Date(rel.body.notBefore).getTime()).toBeGreaterThan(Date.now() + 6 * DAY);
      const told = await notices(a.id, 'REPORT_LEGAL_HOLD', r.title);
      expect(told).toHaveLength(2);
      expect(told[1].body).toContain('released (Dispute settled)');
      await run();
      expect(await exists(r.id)).toBe(2); // still inside the grace period
      const v = await view(a.token, r.id);
      expect(v.body.legalHold.active).toBe(false);
      expect(v.body.graceUntil).not.toBeNull();
      const logs = await prisma.auditLog.findMany({ where: { entityId: r.id, action: { in: ['REPORT_LEGAL_HOLD_PLACED', 'REPORT_LEGAL_HOLD_RELEASED'] } }, orderBy: { createdAt: 'asc' } });
      expect(logs.map((l) => l.action)).toEqual(['REPORT_LEGAL_HOLD_PLACED', 'REPORT_LEGAL_HOLD_RELEASED']);
      await prisma.reportRetention.update({ where: { reportId: r.id }, data: { graceUntil: ago(1) } });
      await run();
      expect(await exists(r.id)).toBe(0);
    });
  });

  describe('the job is safe to repeat and watch', () => {
    it('Admin only can run it; a future asOf is for rehearsal; a bad one is refused', async () => {
      expect((await request(API).post('/reports/retention/run').set(owner(manager.token)).send({})).status).toBe(403);
      expect((await request(API).post('/reports/retention/run').set(owner(a.token)).send({})).status).toBe(403);
      expect((await request(API).post('/reports/retention/run').set(owner(admin.token)).send({ asOf: 'tomorrow-ish' })).status).toBe(400);
      expect((await request(API).post('/reports/retention/run').set(owner(admin.token)).send({ surprise: 1 })).status).toBe(400);
    });

    it('the overview (Admin, Manager) shows deadlines, holds, the queue and recent purges, never report content', async () => {
      const r = await make({ draftAgeDays: 31 });
      await run();
      const o = await request(API).get('/reports/retention/overview').set(owner(manager.token));
      expect(o.status).toBe(200);
      expect(o.body.policy).toMatchObject({ finalisedDays: 60, draftDays: 30, finalisedWarnings: [30, 45, 55], draftWarnings: [20, 25, 28] });
      expect(o.body.recent.some((x: { reportId: string }) => x.reportId === r.id)).toBe(true);
      expect(o.body.queue.purgedLast30Days).toBeGreaterThanOrEqual(1);
      expect(JSON.stringify(o.body)).not.toContain(r.title);
      expect((await request(API).get('/reports/retention/overview').set(owner(a.token))).status).toBe(403);
    });

    it('a restored report counts from the restore: its old dates do not make it due the same day', async () => {
      const r = await make({ finalisedAgeDays: 20 });
      const exported = await request(API).post(`/reports/${r.id}/archive`).set(owner(a.token)).buffer(true).parse((res, cb) => {
        const c: Buffer[] = [];
        res.on('data', (x: Buffer) => c.push(x));
        res.on('end', () => cb(null, Buffer.concat(c)));
      });
      expect(exported.status).toBe(200);
      await prisma.survey.delete({ where: { id: r.id } });
      const restored = await request(API).post('/reports/restore-archive').set(owner(a.token)).attach('file', exported.body as Buffer, { filename: 'a.zip', contentType: 'application/zip' });
      expect(restored.status).toBe(201);
      // pretend it was finalised long ago: the restore still gives it a fresh 60 days
      await prisma.report.update({ where: { id: r.id }, data: { finalisedAt: ago(300), restoredAt: ago(1) } });
      await run();
      expect(await exists(r.id)).toBe(2);
      const v = await view(a.token, r.id);
      expect(v.body.restoredFromArchive).toBe(true);
      expect(v.body.daysLeft).toBeGreaterThanOrEqual(58);
    });
  });
});
