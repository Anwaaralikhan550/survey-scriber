/**
 * E2E: the phone and a remotely edited report (Remote Editor spec v1.4 sections 10, 11, 17 and 20): a stale push from the phone is
 * refused with a code the phone can show, nothing is applied or silently lost, the same batch is judged again on a retry, and
 * the changes-since-version API tells a phone or a browser what is new.
 */
import request = require('supertest');
import { randomUUID } from 'crypto';
import { UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const owner = (t: string) => ({ Authorization: `Bearer ${t}` });
const TITLE = `${TEST_PREFIX}sync`;

async function makeUser(tag: string, role: UserRole = UserRole.SURVEYOR) {
  const email = `${TEST_PREFIX}sync_${tag}${TEST_EMAIL_DOMAIN}`;
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) user = await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'F', lastName: tag, role, isActive: true } });
  return { id: user.id, token: generateStaffToken(user.id, user.email, user.role) };
}

describe('Phone sync and remotely edited reports (E2E)', () => {
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  let admin: { id: string; token: string };
  let surveyId: string;
  let sectionId: string;
  let blockId: string;
  let cookie: string;
  let csrf: string;
  let answerSectionId: string;
  let answerId: string;

  const push = (ops: unknown[], reportVersions?: Record<string, number>, key = `batch-${randomUUID()}`) =>
    request(API).post('/sync/push').set(owner(a.token)).send({ idempotencyKey: key, operations: ops, ...(reportVersions ? { reportVersions } : {}) });
  const updateSurvey = (title: string) => ({ operationId: `op-${randomUUID()}`, operationType: 'UPDATE', entityType: 'SURVEY', entityId: surveyId, data: { title } });
  const updateAnswer = (value: string) => ({ operationId: `op-${randomUUID()}`, operationType: 'UPDATE', entityType: 'ANSWER', entityId: answerId, data: { value } });
  const reportVersion = async () => (await prisma.report.findUniqueOrThrow({ where: { id: surveyId } })).version;
  const surveyTitle = async () => (await prisma.survey.findUniqueOrThrow({ where: { id: surveyId } })).title;
  const browserSave = async (text: string) =>
    request(API)
      .patch(`/editor/reports/${surveyId}`)
      .set({ Cookie: cookie, 'X-CSRF-Token': csrf })
      .send({ baseVersion: await reportVersion(), idempotencyKey: randomUUID(), changes: [{ op: 'updateBlock', sectionId, blockId, fields: { text } }] });

  beforeAll(async () => {
    a = await makeUser('owner');
    b = await makeUser('other');
    admin = await makeUser('admin', UserRole.ADMIN);
  });
  beforeEach(async () => {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '7 Sync Road', userId: a.id } });
    surveyId = survey.id;
    const section = await prisma.section.create({ data: { surveyId, sectionTypeKey: 'ROOF', title: 'Roof' } });
    answerSectionId = section.id;
    const answer = await prisma.answer.create({ data: { sectionId: answerSectionId, questionKey: 'roof::covering', value: 'tiles' } });
    answerId = answer.id;
    sectionId = randomUUID();
    blockId = randomUUID();
    const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'The roof is tiled.' }] }];
    expect((await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ reportType: 'L2', content })).status).toBe(200);
    const link = await request(API).post(`/reports/${surveyId}/edit-links`).set(owner(a.token));
    const open = await request(API).post('/editor/open').send({ token: link.body.url.split('/open/')[1] });
    cookie = (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0];
    csrf = open.body.csrfToken;
  });
  afterAll(async () => {
    await prisma.survey.deleteMany({ where: { title: { startsWith: TITLE } } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}sync_` } } });
    await prisma.$disconnect();
  });

  describe('push from the phone', () => {
    it('before any computer edit the phone pushes as always, with or without a version', async () => {
      const r = await push([updateSurvey(`${TITLE} one`)]);
      expect(r.status).toBe(200);
      expect(r.body.results[0].success).toBe(true);
      expect(await surveyTitle()).toBe(`${TITLE} one`);
      const r2 = await push([updateSurvey(`${TITLE} two`)], { [surveyId]: 1 });
      expect(r2.body.results[0].success).toBe(true);
    });

    it('after a computer edit a stale push is refused with a code and the cloud version; nothing is applied', async () => {
      expect((await browserSave('Edited on the computer.')).status).toBe(200);
      const v = await reportVersion();
      const r = await push([updateSurvey(`${TITLE} stale`), updateAnswer('slates')], { [surveyId]: v - 1 });
      expect(r.status).toBe(200);
      expect(r.body.success).toBe(false);
      for (const res of r.body.results) {
        expect(res).toMatchObject({ success: false, errorCode: 'REPORT_VERSION_CONFLICT', currentReportVersion: v });
        expect(res.error).toMatch(/Synchronise it on the phone first/);
      }
      expect(await surveyTitle()).toBe(TITLE);
      expect((await prisma.answer.findUniqueOrThrow({ where: { id: answerId } })).value).toBe('tiles');
    });

    it('a push that names no version is refused too (an older app cannot overwrite blindly)', async () => {
      await browserSave('Edited on the computer.');
      const r = await push([updateSurvey(`${TITLE} blind`)]);
      expect(r.body.results[0]).toMatchObject({ success: false, errorCode: 'REPORT_VERSION_CONFLICT' });
      expect(await surveyTitle()).toBe(TITLE);
    });

    it('once the phone has the cloud version the same change goes through', async () => {
      await browserSave('Edited on the computer.');
      const v = await reportVersion();
      const r = await push([updateSurvey(`${TITLE} synced`), updateAnswer('slates')], { [surveyId]: v });
      expect(r.body.success).toBe(true);
      expect(await surveyTitle()).toBe(`${TITLE} synced`);
      expect((await prisma.answer.findUniqueOrThrow({ where: { id: answerId } })).value).toBe('slates');
    });

    it('a batch that was refused is judged again when it is sent again with the same key (never answered "duplicate, success")', async () => {
      await browserSave('Edited on the computer.');
      const key = `batch-${randomUUID()}`;
      const first = await push([updateSurvey(`${TITLE} again`)], undefined, key);
      expect(first.body.results[0].success).toBe(false);
      const v = await reportVersion();
      const retry = await push([updateSurvey(`${TITLE} again`)], { [surveyId]: v }, key);
      expect(retry.body.batchDuplicate).toBeFalsy();
      expect(retry.body.results[0].success).toBe(true);
      expect(await surveyTitle()).toBe(`${TITLE} again`);
    });

    it('a batch that went through stays idempotent: sending it again is answered as a duplicate and applies once', async () => {
      const key = `batch-${randomUUID()}`;
      const op = updateSurvey(`${TITLE} once`);
      expect((await push([op], undefined, key)).body.success).toBe(true);
      const again = await push([op], undefined, key);
      expect(again.body.batchDuplicate).toBe(true);
    });

    it('new data (CREATE) is not held back, and a survey with no report is untouched by the rule', async () => {
      await browserSave('Edited on the computer.');
      const create = await push([{ operationId: `op-${randomUUID()}`, operationType: 'CREATE', entityType: 'SECTION', entityId: randomUUID(), data: { surveyId, sectionTypeKey: 'WALLS', title: 'Walls', order: 2 } }]);
      expect(create.body.results[0].errorCode).toBeUndefined();
      const lone = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '8 Lone Road', userId: a.id } });
      const r = await push([{ operationId: `op-${randomUUID()}`, operationType: 'UPDATE', entityType: 'SURVEY', entityId: lone.id, data: { title: `${TITLE} lone` } }]);
      expect(r.body.results[0].success).toBe(true);
    });

    it('a mixed batch: the stale survey is refused, an untouched survey in the same batch goes through', async () => {
      await browserSave('Edited on the computer.');
      const lone = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '9 Lone Road', userId: a.id } });
      const r = await push([updateSurvey(`${TITLE} stale`), { operationId: `op-${randomUUID()}`, operationType: 'UPDATE', entityType: 'SURVEY', entityId: lone.id, data: { title: `${TITLE} fine` } }]);
      expect(r.body.results.map((x: { success: boolean }) => x.success)).toEqual([false, true]);
      expect((await prisma.survey.findUniqueOrThrow({ where: { id: lone.id } })).title).toBe(`${TITLE} fine`);
    });

    it('a finalised report still answers with its own code', async () => {
      const v = await reportVersion();
      await prisma.report.update({ where: { id: surveyId }, data: { status: 'FINALISED', finalVersion: v } });
      const r = await push([updateSurvey(`${TITLE} late`)], { [surveyId]: v });
      expect(r.body.results[0]).toMatchObject({ success: false, errorCode: 'REPORT_FINALISED' });
    });

    it('an upload of the phone copy itself (version bump without a computer edit) does not block the phone', async () => {
      const v = await reportVersion();
      const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'Phone wording.' }] }];
      const up = await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ baseVersion: v, reportType: 'L2', content });
      expect(up.status).toBe(200);
      const r = await push([updateSurvey(`${TITLE} after upload`)]);
      expect(r.body.results[0].success).toBe(true);
    });
  });

  describe('single-record updates from the phone (the calls the app really makes)', () => {
    const put = (path: string, body: unknown, version?: number, token = a.token) => {
      const r = request(API).put(path).set(owner(token));
      return (version === undefined ? r : r.set('X-Report-Version', String(version))).send(body as object);
    };
    const del = (path: string, version?: number, token = a.token) => {
      const r = request(API).delete(path).set(owner(token));
      return version === undefined ? r : r.set('X-Report-Version', String(version));
    };

    it('before any computer edit the app updates as always, with or without the version header', async () => {
      expect((await put(`/surveys/${surveyId}`, { title: `${TITLE} rest one` })).status).toBe(200);
      expect((await put(`/surveys/${surveyId}`, { title: `${TITLE} rest two` }, 1)).status).toBe(200);
      expect((await put(`/answers/${answerId}`, { value: 'slates' })).status).toBe(200);
    });

    it('after a computer edit a stale update is refused with 409, the code and the cloud version; nothing is applied', async () => {
      await browserSave('Edited on the computer.');
      const v = await reportVersion();
      for (const [name, r] of [
        ['survey', await put(`/surveys/${surveyId}`, { title: `${TITLE} stale` }, v - 1)],
        ['section', await put(`/sections/${answerSectionId}`, { title: 'Stale roof' }, v - 1)],
        ['answer', await put(`/answers/${answerId}`, { value: 'stale' }, v - 1)],
        ['answer without header', await put(`/answers/${answerId}`, { value: 'stale' })],
      ] as const) {
        expect([name, r.status, r.body.error]).toEqual([name, 409, 'REPORT_VERSION_CONFLICT']);
        expect(r.body.details).toEqual({ currentReportVersion: v });
        expect(r.body.message).toMatch(/Synchronise it on the phone first/);
      }
      expect(await surveyTitle()).toBe(TITLE);
      expect((await prisma.answer.findUniqueOrThrow({ where: { id: answerId } })).value).toBe('tiles');
      expect((await prisma.section.findUniqueOrThrow({ where: { id: answerSectionId } })).title).toBe('Roof');
    });

    it('deleting is held back the same way', async () => {
      await browserSave('Edited on the computer.');
      const v = await reportVersion();
      expect((await del(`/answers/${answerId}`, v - 1)).status).toBe(409);
      expect((await del(`/sections/${answerSectionId}`)).status).toBe(409);
      expect((await del(`/surveys/${surveyId}`, v - 1)).status).toBe(409);
      expect(await prisma.answer.count({ where: { id: answerId } })).toBe(1);
      expect((await prisma.survey.findUniqueOrThrow({ where: { id: surveyId } })).deletedAt).toBeNull();
    });

    it('with the cloud version the update goes through', async () => {
      await browserSave('Edited on the computer.');
      const v = await reportVersion();
      expect((await put(`/surveys/${surveyId}`, { title: `${TITLE} rest synced` }, v)).status).toBe(200);
      expect((await put(`/answers/${answerId}`, { value: 'slates' }, v + 5)).status).toBe(200);
      expect(await surveyTitle()).toBe(`${TITLE} rest synced`);
    });

    it('a bad header is the same as none; adding new data is never held back', async () => {
      await browserSave('Edited on the computer.');
      const r = await request(API).put(`/answers/${answerId}`).set(owner(a.token)).set('X-Report-Version', 'abc').send({ value: 'x' });
      expect(r.status).toBe(409);
      const create = await request(API).post(`/surveys/${surveyId}/sections`).set(owner(a.token)).send({ title: 'Walls', sectionTypeKey: 'WALLS', order: 3 });
      expect(create.status).toBeLessThan(300);
    });

    it('a finalised report refuses the phone with 403 and its own code', async () => {
      const v = await reportVersion();
      await prisma.report.update({ where: { id: surveyId }, data: { status: 'FINALISED', finalVersion: v } });
      for (const r of [await put(`/answers/${answerId}`, { value: 'late' }, v), await del(`/sections/${answerSectionId}`, v), await put(`/surveys/${surveyId}`, { title: 'late' }, v)]) {
        expect([r.status, r.body.error]).toEqual([403, 'REPORT_FINALISED']);
      }
    });

    it('another user learns nothing about the report: the usual refusal, not the report rule', async () => {
      await browserSave('Edited on the computer.');
      const r = await put(`/answers/${answerId}`, { value: 'x' }, undefined, b.token);
      expect([403, 404]).toContain(r.status);
      expect(r.body.error).not.toBe('REPORT_VERSION_CONFLICT');
    });

    it('a survey that never had a cloud report is not affected', async () => {
      const lone = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '10 Lone Road', userId: a.id } });
      expect((await put(`/surveys/${lone.id}`, { title: `${TITLE} lone rest` })).status).toBe(200);
    });
  });

  describe('changes since a version', () => {
    it('lists the amended sections and blocks and what kind of change, from the amendment history', async () => {
      await browserSave('One.');
      await browserSave('Two.');
      const r = await request(API).get(`/reports/${surveyId}/changes?sinceVersion=1`).set(owner(a.token));
      expect(r.status).toBe(200);
      const v = await reportVersion();
      expect(r.body).toMatchObject({ reportId: surveyId, version: v, sinceVersion: 1, changed: true, fromBrowser: true, fromPhone: false, restored: false });
      expect(r.body.sections).toEqual([{ sectionId, sectionKey: 'E1_ROOF', title: 'Roof', blockIds: [blockId], fields: ['text'] }]);
    });

    it('nothing is listed when the caller is up to date', async () => {
      await browserSave('One.');
      const r = await request(API).get(`/reports/${surveyId}/changes?sinceVersion=${await reportVersion()}`).set(owner(a.token));
      expect(r.body).toMatchObject({ changed: false, sections: [] });
    });

    it('says when the change came from the phone or from a restore', async () => {
      const v = await reportVersion();
      const content = [{ id: sectionId, key: 'E1_ROOF', title: 'Roof', blocks: [{ id: blockId, type: 'paragraph', text: 'Phone wording.' }] }];
      const up = await request(API).put(`/reports/${surveyId}/snapshot`).set(owner(a.token)).send({ baseVersion: v, reportType: 'L2', content });
      const r1 = await request(API).get(`/reports/${surveyId}/changes?sinceVersion=${v}`).set(owner(a.token));
      expect(r1.body).toMatchObject({ fromPhone: true, fromBrowser: false });
      await request(API).post(`/reports/${surveyId}/versions/1/restore`).set(owner(a.token)).send({ baseVersion: up.body.version });
      const r2 = await request(API).get(`/reports/${surveyId}/changes?sinceVersion=${up.body.version}`).set(owner(a.token));
      expect(r2.body).toMatchObject({ restored: true });
    });

    it('a browser session can ask too, also while read-only; it cannot ask about another report', async () => {
      await browserSave('One.');
      const r = await request(API).get(`/editor/reports/${surveyId}/changes?sinceVersion=1`).set({ Cookie: cookie });
      expect(r.status).toBe(200);
      expect(r.body.sections[0].blockIds).toEqual([blockId]);
      expect((await request(API).get(`/editor/reports/${randomUUID()}/changes?sinceVersion=1`).set({ Cookie: cookie })).status).toBe(403);
      expect((await request(API).get(`/editor/reports/${surveyId}/changes?sinceVersion=1`)).status).toBe(404);
    });

    it('bad input and access: a missing or odd version is 400, only the owner or an admin may ask, unknown report 404, no login 401', async () => {
      for (const q of ['', '?sinceVersion=', '?sinceVersion=-1', '?sinceVersion=abc', '?sinceVersion=1.5', '?sinceVersion=99999999999']) {
        expect([q, (await request(API).get(`/reports/${surveyId}/changes${q}`).set(owner(a.token))).status]).toEqual([q, 400]);
      }
      expect((await request(API).get(`/reports/${surveyId}/changes?sinceVersion=1`).set(owner(b.token))).status).toBe(403);
      expect((await request(API).get(`/reports/${surveyId}/changes?sinceVersion=1`).set(owner(admin.token))).status).toBe(200);
      expect((await request(API).get(`/reports/${randomUUID()}/changes?sinceVersion=1`).set(owner(a.token))).status).toBe(404);
      expect((await request(API).get(`/reports/${surveyId}/changes?sinceVersion=1`)).status).toBe(401);
    });
  });
});
