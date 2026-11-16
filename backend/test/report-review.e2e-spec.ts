/**
 * E2E: review workflow of desktop editing (client spec v1.3 section 14, Screen F): statuses, role-controlled
 * transitions, version-bound approvals, invalidation by any later change, identity and audit.
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
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const sessionOf = (cookie: string, csrf: string) => ({ Cookie: cookie, 'X-CSRF-Token': csrf });

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}review_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'R', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

interface Fx {
  surveyId: string;
  token: string;
  userId: string;
  linkId: string;
  cookie: string;
  csrf: string;
  blockId: string;
  sectionId: string;
}

async function openSession(rawToken: string) {
  const open = await request(API).post('/editor/open').send({ token: rawToken });
  return { cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], csrf: open.body.csrfToken as string };
}

async function fixture(u: { id: string; token: string }): Promise<Fx> {
  const survey = await prisma.survey.create({ data: { title: `${TEST_PREFIX}review`, propertyAddress: '1 Review Road', userId: u.id } });
  const sectionId = randomUUID();
  const blockId = randomUUID();
  const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'Roof text.' }] }];
  const up = await request(API).put(`/reports/${survey.id}/snapshot`).set(owner(u.token)).send({ reportType: 'L2', content });
  expect(up.status).toBe(200);
  const link = await request(API).post(`/reports/${survey.id}/edit-links`).set(owner(u.token));
  const s = await openSession(link.body.url.split('/open/')[1]);
  return { surveyId: survey.id, token: u.token, userId: u.id, linkId: link.body.linkId, ...s, blockId, sectionId };
}

describe('Review workflow (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let f: Fx;

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
  });
  beforeEach(async () => {
    f = await fixture(a);
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: `${TEST_PREFIX}review` }, select: { id: true } });
    for (const s of surveys) fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
    await prisma.survey.deleteMany({ where: { title: `${TEST_PREFIX}review` } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}review_` } } });
    await prisma.$disconnect();
  });

  const h = () => sessionOf(f.cookie, f.csrf);
  const version = async () => (await prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } })).version;
  const status = async () => (await prisma.report.findUniqueOrThrow({ where: { id: f.surveyId } })).status;
  const ed = async (action: string, body: Record<string, unknown> = {}, v?: number) =>
    request(API).post(`/editor/reports/${f.surveyId}/review/${action}`).set(h()).send({ expectedReportVersion: v ?? (await version()), ...body });
  const own = async (p: string, body: Record<string, unknown> = {}, token = f.token, v?: number) =>
    request(API).post(`/reports/${f.surveyId}/${p}`).set(owner(token)).send({ expectedReportVersion: v ?? (await version()), ...body });
  const saveText = async (text: string) => {
    const r = await request(API).patch(`/editor/reports/${f.surveyId}`).set(h()).send({
      baseVersion: await version(),
      changes: [{ op: 'updateBlock', sectionId: f.sectionId, blockId: f.blockId, fields: { text } }],
    });
    expect(r.status).toBe(200);
    return r;
  };
  const toReviewerApproved = async () => {
    const s = await status();
    if (s === ReportStatus.DRAFT || s === ReportStatus.AMENDMENTS_REQUIRED) expect((await ed('submit')).status).toBe(200);
    expect((await ed('decision', { decision: 'APPROVED' })).status).toBe(200);
    expect(await status()).toBe(ReportStatus.REVIEWER_APPROVED);
  };
  const toOwnerApproved = async () => {
    await toReviewerApproved();
    expect((await own('owner-approval')).status).toBe(200);
    expect(await status()).toBe(ReportStatus.OWNER_FINAL_APPROVAL);
  };

  describe('the ladder', () => {
    it('starts as Draft, and the view says what is possible to know: status, version, nobody has decided', async () => {
      const v = await request(API).get(`/editor/reports/${f.surveyId}/review`).set('Cookie', f.cookie);
      expect(v.status).toBe(200);
      expect(v.body).toMatchObject({ status: 'DRAFT', version: 1, submittedVersion: null, reviewerApproval: null, ownerApproval: null, reviews: [] });
    });

    it('Draft -> Submitted for Review (records the version) -> Under Review -> Reviewer Approved -> Owner Final Approval', async () => {
      const sub = await ed('submit', { comment: 'Ready for you' });
      expect(sub.status).toBe(200);
      expect(sub.body).toMatchObject({ status: 'SUBMITTED_FOR_REVIEW', submittedVersion: 1 });
      expect(sub.body.reviews[0]).toMatchObject({ decision: 'SUBMITTED', comment: 'Ready for you', version: 1, by: 'reviewer', invalidated: false });
      const start = await ed('start');
      expect(start.body.status).toBe('UNDER_REVIEW');
      const ok = await ed('decision', { decision: 'APPROVED', comment: 'Looks right' });
      expect(ok.body.status).toBe('REVIEWER_APPROVED');
      expect(ok.body.reviewerApproval).toMatchObject({ decision: 'APPROVED', version: 1, comment: 'Looks right' });
      const fin = await own('owner-approval', { comment: 'Approved by me' });
      expect(fin.status).toBe(200);
      expect(fin.body.status).toBe('OWNER_FINAL_APPROVAL');
      expect(fin.body.ownerApproval).toMatchObject({ decision: 'OWNER_APPROVED', version: 1, by: 'owner' });
    });

    it('a reviewer can approve straight from Submitted, without starting a review', async () => {
      await ed('submit');
      expect((await ed('decision', { decision: 'APPROVED' })).body.status).toBe('REVIEWER_APPROVED');
    });

    it('amendments: needs a comment, goes back to the editor, can be submitted again', async () => {
      await ed('submit');
      const none = await ed('decision', { decision: 'AMENDMENTS_REQUIRED' });
      expect(none.status).toBe(400);
      expect(none.body.error).toBe('VALIDATION_ERROR');
      const res = await ed('decision', { decision: 'AMENDMENTS_REQUIRED', comment: 'Please check the roof sentence' });
      expect(res.body).toMatchObject({ status: 'AMENDMENTS_REQUIRED', lastAmendmentRequest: { comment: 'Please check the roof sentence', version: 1 } });
      await saveText('Roof text, revised.');
      const again = await ed('submit', { comment: 'Fixed' });
      expect(again.body).toMatchObject({ status: 'SUBMITTED_FOR_REVIEW', submittedVersion: 2 });
    });

    it('the owner can send a report back, also after a reviewer approved it (the approval is withdrawn)', async () => {
      await toReviewerApproved();
      const res = await own('review/decision', { decision: 'AMENDMENTS_REQUIRED', comment: 'One more look' });
      expect(res.body.status).toBe('AMENDMENTS_REQUIRED');
      expect(res.body.reviewerApproval).toBeNull();
      expect(res.body.reviews.find((r: { decision: string }) => r.decision === 'APPROVED').invalidated).toBe(true);
      expect(res.body.reviews[0]).toMatchObject({ decision: 'AMENDMENTS_REQUIRED', by: 'owner' });
    });

    it('a working owner without a reviewer can approve from Draft (owner-only flow), and reset to Draft', async () => {
      const res = await own('owner-approval');
      expect(res.body.status).toBe('OWNER_FINAL_APPROVAL');
      const reset = await own('review/reset');
      expect(reset.body).toMatchObject({ status: 'DRAFT', ownerApproval: null });
      expect(reset.body.reviews[0].invalidated).toBe(true);
    });
  });

  describe('transitions that are not allowed', () => {
    it('refuses each wrong step with INVALID_STATE and changes nothing', async () => {
      const bad = async (res: request.Response, from: string) => {
        expect([res.status, res.body.error]).toEqual([409, 'INVALID_STATE']);
        expect(res.body.details.status).toBe(from);
      };
      await bad(await ed('start'), 'DRAFT'); // nothing submitted yet
      await bad(await ed('decision', { decision: 'APPROVED' }), 'DRAFT');
      await bad(await ed('decision', { decision: 'AMENDMENTS_REQUIRED', comment: 'x' }), 'DRAFT');
      await ed('submit');
      await bad(await ed('submit'), 'SUBMITTED_FOR_REVIEW'); // already submitted
      await ed('start');
      await bad(await ed('start'), 'UNDER_REVIEW');
      await ed('decision', { decision: 'APPROVED' });
      await bad(await ed('submit'), 'REVIEWER_APPROVED');
      await bad(await ed('decision', { decision: 'APPROVED' }), 'REVIEWER_APPROVED');
      expect(await status()).toBe(ReportStatus.REVIEWER_APPROVED);
      await own('owner-approval');
      await bad(await own('owner-approval'), 'OWNER_FINAL_APPROVAL');
      await bad(await own('review/start'), 'OWNER_FINAL_APPROVAL');
    });

    it('a link holder is never the owner: no final approval, no reset; the owner cannot approve as a reviewer', async () => {
      await ed('submit');
      const asEditor = await request(API).post(`/editor/reports/${f.surveyId}/review/owner-approval`).set(h()).send({ expectedReportVersion: 1 });
      expect(asEditor.status).toBe(404); // the route does not exist for a link holder
      const viaCookie = await request(API).post(`/reports/${f.surveyId}/owner-approval`).set('Cookie', f.cookie).send({ expectedReportVersion: 1 });
      expect(viaCookie.status).toBe(401);
      const asReviewer = await own('review/decision', { decision: 'APPROVED' });
      expect(asReviewer.status).toBe(403);
      expect(asReviewer.body.error).toBe('FORBIDDEN');
      expect(await status()).toBe(ReportStatus.SUBMITTED_FOR_REVIEW);
    });

    it('only the owner or an admin may use the owner routes', async () => {
      expect((await own('owner-approval', {}, b.token)).status).toBe(403);
      expect((await own('review/reset', {}, b.token)).status).toBe(403);
      expect((await request(API).get(`/reports/${f.surveyId}/review`).set(owner(b.token))).status).toBe(403);
      expect((await request(API).get(`/reports/${f.surveyId}/review`)).status).toBe(401);
      const admin = await makeUser('admin', UserRole.ADMIN);
      expect((await own('owner-approval', {}, admin.token)).status).toBe(200);
    });

    it('a decision must name the current version: approving an older one is refused', async () => {
      await ed('submit');
      await saveText('Changed while the reviewer was reading.');
      const res = await ed('decision', { decision: 'APPROVED' }, 1);
      expect(res.status).toBe(409);
      expect(res.body.error).toBe('VERSION_CONFLICT');
      expect(await status()).toBe(ReportStatus.SUBMITTED_FOR_REVIEW);
      expect((await ed('decision', { decision: 'APPROVED' })).body.reviewerApproval.version).toBe(2);
    });

    it('two simultaneous decisions: exactly one is applied', async () => {
      await ed('submit');
      const v = await version();
      const [x, y] = await Promise.all([ed('decision', { decision: 'APPROVED' }, v), ed('decision', { decision: 'APPROVED', comment: 'me too' }, v)]);
      expect([x.status, y.status].sort()).toEqual([200, 409]);
      expect([x, y].find((r) => r.status === 409)!.body.error).toBe('INVALID_STATE');
      expect(await prisma.review.count({ where: { reportId: f.surveyId, decision: 'APPROVED' } })).toBe(1);
    });

    it('validates the body', async () => {
      expect((await ed('decision', { decision: 'MAYBE' })).status).toBe(400);
      expect((await request(API).post(`/editor/reports/${f.surveyId}/review/submit`).set(h()).send({})).status).toBe(400);
      expect((await ed('submit', { comment: 'x'.repeat(4001) })).status).toBe(400);
      await ed('submit');
      const res = await ed('decision', { decision: 'AMENDMENTS_REQUIRED', comment: 'Fix <script>alert(1)</script>the <b>roof</b>' });
      expect(res.body.reviews[0].comment).toBe('Fix the roof');
    });
  });

  describe('approvals belong to a version: any later change invalidates them', () => {
    const view = async () => (await request(API).get(`/reports/${f.surveyId}/review`).set(owner(f.token))).body;

    it('a text edit after the reviewer approved: approval invalid, back to Submitted for Review', async () => {
      await toReviewerApproved();
      await saveText('Edited after approval.');
      const v = await view();
      expect(v.status).toBe('SUBMITTED_FOR_REVIEW');
      expect(v.reviewerApproval).toBeNull();
      expect(v.reviews.find((r: { decision: string }) => r.decision === 'APPROVED')).toMatchObject({ invalidated: true, version: 1 });
      expect(v.submittedVersion).toBe(1);
      expect(v.version).toBe(2);
    });

    it('a text edit after the owner approved: both approvals invalid', async () => {
      await toOwnerApproved();
      await saveText('Edited after the owner approved.');
      const v = await view();
      expect(v.status).toBe('SUBMITTED_FOR_REVIEW');
      expect(v.reviewerApproval).toBeNull();
      expect(v.ownerApproval).toBeNull();
      expect(v.reviews.filter((r: { invalidated: boolean }) => r.invalidated)).toHaveLength(2);
    });

    it('a photo change, a new phone upload and a restore do the same', async () => {
      const photo = await sharp({ create: { width: 64, height: 48, channels: 3, background: '#333' } }).jpeg().toBuffer();
      for (const change of ['photo', 'snapshot', 'restore']) {
        await toReviewerApproved();
        const v = await version();
        if (change === 'photo') {
          const r = await request(API).post(`/editor/reports/${f.surveyId}/photos`).set(h()).attach('file', photo, { filename: 'a.jpg', contentType: 'image/jpeg' }).field('expectedReportVersion', String(v));
          expect(r.status).toBe(201);
        } else if (change === 'snapshot') {
          const content = [{ id: f.sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: f.blockId, type: 'paragraph', text: 'From the phone.' }] }];
          expect((await request(API).put(`/reports/${f.surveyId}/snapshot`).set(owner(f.token)).send({ baseVersion: v, reportType: 'L2', content })).status).toBe(200);
        } else {
          expect((await request(API).post(`/reports/${f.surveyId}/versions/1/restore`).set(owner(f.token)).send({ baseVersion: v })).status).toBe(200);
        }
        const after = await view();
        expect([change, after.status, after.reviewerApproval]).toEqual([change, 'SUBMITTED_FOR_REVIEW', null]);
        await ed('decision', { decision: 'AMENDMENTS_REQUIRED', comment: 'reset for next round' });
        await saveText(`Round after ${change}`);
        await ed('submit');
      }
    });

    it('edits before any approval change nothing about the review state', async () => {
      await saveText('Draft edit.');
      expect(await status()).toBe(ReportStatus.DRAFT);
      await ed('submit');
      await saveText('Edit while submitted.');
      expect(await status()).toBe(ReportStatus.SUBMITTED_FOR_REVIEW);
      await ed('start');
      await saveText('Reviewer edits while reviewing.');
      expect(await status()).toBe(ReportStatus.UNDER_REVIEW);
      expect((await view()).submittedVersion).toBe(2); // submitted at version 2, after the draft edit
    });

    it('an invalidated report can be approved again at its new version', async () => {
      await toReviewerApproved();
      await saveText('Second draft.');
      expect((await ed('decision', { decision: 'APPROVED' })).body.reviewerApproval.version).toBe(2);
      expect((await own('owner-approval')).body.ownerApproval.version).toBe(2);
    });
  });

  describe('locks, identity and audit', () => {
    it('a finalised report allows no review action, for anyone', async () => {
      await prisma.report.update({ where: { id: f.surveyId }, data: { status: ReportStatus.FINALISED } });
      expect((await ed('submit')).body.error).toBe('REPORT_FINALISED');
      expect((await own('owner-approval')).body.error).toBe('REPORT_FINALISED');
      expect((await own('review/reset')).body.error).toBe('REPORT_FINALISED');
    });

    it('a cancelled or expired link cannot change the review state, but an expired one can still read it', async () => {
      await prisma.editLink.update({ where: { id: f.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
      const res = await ed('submit');
      expect(res.status).toBe(410);
      expect(res.body.error).toBe('LINK_EXPIRED');
      expect((await request(API).get(`/editor/reports/${f.surveyId}/review`).set('Cookie', f.cookie)).status).toBe(200);
      const g = await fixture(a);
      await request(API).delete(`/reports/${g.surveyId}/edit-links/${g.linkId}`).set(owner(g.token));
      const r2 = await request(API).post(`/editor/reports/${g.surveyId}/review/submit`).set(sessionOf(g.cookie, g.csrf)).send({ expectedReportVersion: 1 });
      expect(r2.status).toBe(410);
      expect(r2.body.error).toBe('LINK_REVOKED');
    });

    it('needs the CSRF header and the session, and only for its own report', async () => {
      const noCsrf = await request(API).post(`/editor/reports/${f.surveyId}/review/submit`).set('Cookie', f.cookie).send({ expectedReportVersion: 1 });
      expect(noCsrf.status).toBe(403);
      const other = await fixture(b);
      const wrong = await request(API).post(`/editor/reports/${other.surveyId}/review/submit`).set(h()).send({ expectedReportVersion: 1 });
      expect(wrong.status).toBe(403);
      expect((await request(API).get(`/editor/reports/${other.surveyId}/review`).set('Cookie', f.cookie)).status).toBe(403);
    });

    it('stores who decided: the session for a reviewer, the user for the owner', async () => {
      await toReviewerApproved();
      await own('owner-approval');
      const rows = await prisma.review.findMany({ where: { reportId: f.surveyId }, orderBy: { createdAt: 'asc' } });
      expect(rows.map((r) => r.decision)).toEqual(['SUBMITTED', 'APPROVED', 'OWNER_APPROVED']);
      expect(rows[0].sessionId).not.toBeNull();
      expect(rows[0].reviewerUserId).toBeNull();
      expect(rows[2].reviewerUserId).toBe(f.userId);
      expect(rows[2].sessionId).toBeNull();
      expect(rows.every((r) => r.version === 1)).toBe(true);
    });

    it('audits every action and the invalidation, without the comment text', async () => {
      await ed('submit', { comment: 'private words' });
      await ed('start');
      await ed('decision', { decision: 'APPROVED' });
      await own('owner-approval');
      await saveText('Later change.');
      await own('review/reset');
      const audits = await prisma.auditLog.findMany({ where: { entityId: f.surveyId } });
      const actions = audits.map((x) => x.action);
      for (const want of ['REVIEW_SUBMITTED', 'REVIEW_STARTED', 'REVIEW_APPROVED', 'OWNER_APPROVED', 'REVIEW_INVALIDATED', 'REVIEW_RESET']) expect(actions).toContain(want);
      expect(JSON.stringify(audits)).not.toContain('private words');
    });

    it('the phone list of reports shows the status', async () => {
      await ed('submit');
      const latest = await request(API).get(`/reports/${f.surveyId}/latest`).set(owner(f.token));
      expect(latest.body.status).toBe('SUBMITTED_FOR_REVIEW');
    });
  });
});
