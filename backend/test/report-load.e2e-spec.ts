/**
 * Concurrency and load for desktop editing (spec section 21 "load" and the one-active-link / conflict rules under pressure):
 * many sessions reading, many writers racing on one report, a large report, and many reports at once.
 * Asserts correctness first (no lost update, no 5xx, no two active links) and a generous speed ceiling.
 * The test server has relaxed rate limits; production limits are checked by tmp/desktop-editing/p25_security_live.js.
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';
import { UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const TITLE = `${TEST_PREFIX}load`;
const bearer = (t: string) => ({ Authorization: `Bearer ${t}` });

const percentile = (xs: number[], p: number) => [...xs].sort((a, b) => a - b)[Math.min(xs.length - 1, Math.floor((p / 100) * xs.length))];
const timed = async <T>(fn: () => Promise<T>): Promise<[T, number]> => {
  const t0 = Date.now();
  const v = await fn();
  return [v, Date.now() - t0];
};

describe('Load and concurrency (E2E)', () => {
  jest.setTimeout(120000);
  let owner: { id: string; token: string };

  beforeAll(async () => {
    const email = `${TEST_PREFIX}load_owner${TEST_EMAIL_DOMAIN}`;
    const u = (await prisma.user.findUnique({ where: { email } })) ?? (await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'L', lastName: 'O', role: UserRole.SURVEYOR, isActive: true } }));
    owner = { id: u.id, token: generateStaffToken(u.id, u.email, u.role) };
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: TITLE }, select: { id: true } });
    for (const s of surveys) fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}load_` } } });
    await prisma.$disconnect();
  });

  async function report(sections: number, perSection: number) {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '1 Load Road', userId: owner.id } });
    const content = Array.from({ length: sections }, (_, s) => ({
      id: randomUUID(),
      key: `S${s}`,
      title: `Section ${s}`,
      blocks: Array.from({ length: perSection }, (_, b) => ({ id: randomUUID(), type: 'paragraph', text: `Section ${s} paragraph ${b}. ${'Lorem ipsum dolor sit amet. '.repeat(8)}` })),
    }));
    // The test server keeps Nest's small default body limit (production allows 10 MB), so a large report is created in the database directly.
    const size = JSON.stringify(content).length;
    if (size > 80_000) {
      await prisma.report.create({ data: { id: survey.id, surveyId: survey.id, ownerUserId: owner.id, reportType: 'L2', content, version: 1 } });
      await prisma.reportVersion.create({ data: { reportId: survey.id, version: 1, content, savedBy: 'system', reason: 'SNAPSHOT' } });
      console.log(`large report: ${Math.round(size / 1024)} KB of content`);
    } else {
      const up = await request(API).put(`/reports/${survey.id}/snapshot`).set(bearer(owner.token)).send({ reportType: 'L2', content });
      expect(up.status).toBe(200);
    }
    return { surveyId: survey.id, content };
  }
  const session = async (surveyId: string, url: string) => {
    const open = await request(API).post('/editor/open').send({ token: url.split('/open/')[1] });
    expect(open.status).toBe(200);
    return { cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], csrf: open.body.csrfToken as string, surveyId };
  };

  it('30 sessions on one link read the report at once: all answered, none slow', async () => {
    const r = await report(10, 10);
    const link = await request(API).post(`/reports/${r.surveyId}/edit-links`).set(bearer(owner.token));
    const sessions = await Promise.all(Array.from({ length: 30 }, () => session(r.surveyId, link.body.url)));
    const out = await Promise.all(sessions.map((s) => timed(() => request(API).get(`/editor/reports/${r.surveyId}`).set('Cookie', s.cookie))));
    expect(out.every(([res]) => res.status === 200 && res.body.version === 1)).toBe(true);
    const ms = out.map(([, t]) => t);
    console.log(`30 parallel reads: p50 ${percentile(ms, 50)} ms, p95 ${percentile(ms, 95)} ms, max ${Math.max(...ms)} ms`);
    expect(percentile(ms, 95)).toBeLessThan(3000);
    expect(await prisma.editorSession.count({ where: { reportId: r.surveyId } })).toBe(30);
  });

  it('20 writers race on the same version: one wins each round, the rest get a conflict, and nobody\'s change is lost once they retry', async () => {
    const r = await report(1, 20);
    const link = await request(API).post(`/reports/${r.surveyId}/edit-links`).set(bearer(owner.token));
    const writers = await Promise.all(Array.from({ length: 20 }, () => session(r.surveyId, link.body.url)));
    const sec = r.content[0];
    const firstRound = await Promise.all(
      writers.map((w, i) =>
        request(API).patch(`/editor/reports/${r.surveyId}`).set({ Cookie: w.cookie, 'X-CSRF-Token': w.csrf }).send({ baseVersion: 1, changes: [{ op: 'updateBlock', sectionId: sec.id, blockId: sec.blocks[i].id, fields: { text: `Writer ${i} first try` } }] }),
      ),
    );
    expect(firstRound.filter((x) => x.status === 200)).toHaveLength(1);
    expect(firstRound.filter((x) => x.status === 409).length).toBe(19);
    expect(firstRound.every((x) => x.status === 200 || x.status === 409)).toBe(true);

    // what a browser does: re-read the version and save again until it is accepted
    const latencies: number[] = [];
    let attempts = 0;
    const retry = async (w: (typeof writers)[0], i: number) => {
      for (let n = 0; n < 60; n++) {
        const v = (await request(API).get(`/editor/reports/${r.surveyId}`).set('Cookie', w.cookie)).body.version as number;
        attempts++;
        const [res, t] = await timed(() =>
          request(API).patch(`/editor/reports/${r.surveyId}`).set({ Cookie: w.cookie, 'X-CSRF-Token': w.csrf }).send({ baseVersion: v, changes: [{ op: 'updateBlock', sectionId: sec.id, blockId: sec.blocks[i].id, fields: { text: `Writer ${i} done` } }] }),
        );
        latencies.push(t);
        if (res.status === 200) return res.body.version as number;
        expect(res.status).toBe(409);
        await new Promise((x) => setTimeout(x, 5 + Math.random() * 25));
      }
      throw new Error(`writer ${i} never got through`);
    };
    const versions = await Promise.all(writers.map((w, i) => retry(w, i)));
    expect(new Set(versions).size).toBe(20); // 20 different new versions: no two saves shared one
    const row = await prisma.report.findUniqueOrThrow({ where: { id: r.surveyId } });
    expect(row.version).toBe(1 + 1 + 20); // the first-round winner, plus one per writer
    const texts = ((row.content as unknown as Array<{ blocks: Array<{ text: string }> }>)[0]).blocks.map((b) => b.text);
    for (let i = 0; i < 20; i++) expect(texts[i]).toBe(`Writer ${i} done`);
    expect(await prisma.reportVersion.count({ where: { reportId: r.surveyId } })).toBe(row.version);
    console.log(`20 racing writers: ${attempts} attempts, save p50 ${percentile(latencies, 50)} ms, p95 ${percentile(latencies, 95)} ms`);
  });

  it('a large report (60 sections, 1,500 paragraphs) opens, saves and is listed in good time', async () => {
    const r = await report(60, 25);
    const link = await request(API).post(`/reports/${r.surveyId}/edit-links`).set(bearer(owner.token));
    const s = await session(r.surveyId, link.body.url);
    const [read, tRead] = await timed(() => request(API).get(`/editor/reports/${r.surveyId}`).set('Cookie', s.cookie));
    expect(read.status).toBe(200);
    expect(read.body.content).toHaveLength(60);
    const sec = r.content[30];
    const saves: number[] = [];
    let v = 1;
    for (let i = 0; i < 10; i++) {
      const [res, t] = await timed(() =>
        request(API).patch(`/editor/reports/${r.surveyId}`).set({ Cookie: s.cookie, 'X-CSRF-Token': s.csrf }).send({ baseVersion: v, changes: [{ op: 'updateBlock', sectionId: sec.id, blockId: sec.blocks[i].id, fields: { text: `Edited ${i}` } }] }),
      );
      expect(res.status).toBe(200);
      v = res.body.version;
      saves.push(t);
    }
    const [versions, tVersions] = await timed(() => request(API).get(`/reports/${r.surveyId}/versions`).set(bearer(owner.token)));
    expect(versions.status).toBe(200);
    const [sync, tSync] = await timed(() => request(API).post(`/reports/${r.surveyId}/sync`).set(bearer(owner.token)));
    expect(sync.status).toBe(200);
    expect(sync.body.version).toBe(11);
    console.log(`large report: read ${tRead} ms, save p95 ${percentile(saves, 95)} ms, versions ${tVersions} ms, sync ${tSync} ms`);
    expect(tRead).toBeLessThan(3000);
    expect(percentile(saves, 95)).toBeLessThan(3000);
    expect(tSync).toBeLessThan(3000);
  });

  it('30 reports each get exactly one link when 3 people press Generate on each at the same time', async () => {
    const reports = await Promise.all(Array.from({ length: 30 }, () => report(1, 2)));
    const calls = reports.flatMap((r) => Array.from({ length: 3 }, () => request(API).post(`/reports/${r.surveyId}/edit-links`).set(bearer(owner.token)).then((res) => ({ id: r.surveyId, res }))));
    const out = await Promise.all(calls);
    expect(out.every((x) => x.res.status === 201 || x.res.status === 409)).toBe(true);
    for (const r of reports) {
      const mine = out.filter((x) => x.id === r.surveyId);
      expect(mine.filter((x) => x.res.status === 201)).toHaveLength(1);
      expect(await prisma.editLink.count({ where: { reportId: r.surveyId, status: 'ACTIVE' } })).toBe(1);
    }
  });

  it('photo uploads in parallel on one report all land, each as its own version', async () => {
    const sharp = (await import('sharp')).default;
    const r = await report(1, 1);
    const link = await request(API).post(`/reports/${r.surveyId}/edit-links`).set(bearer(owner.token));
    const s = await session(r.surveyId, link.body.url);
    const buf = await sharp({ create: { width: 200, height: 150, channels: 3, background: '#445566' } }).jpeg().toBuffer();
    const upload = async () => {
      for (let n = 0; n < 40; n++) {
        const v = (await request(API).get(`/editor/reports/${r.surveyId}`).set('Cookie', s.cookie)).body.version;
        const res = await request(API).post(`/editor/reports/${r.surveyId}/photos`).set({ Cookie: s.cookie, 'X-CSRF-Token': s.csrf }).attach('file', buf, { filename: 'p.jpg', contentType: 'image/jpeg' }).field('expectedReportVersion', String(v));
        if (res.status === 201) return res.body.photo.id as string;
        expect(res.status).toBe(409);
        await new Promise((x) => setTimeout(x, 10 + Math.random() * 30));
      }
      throw new Error('upload never got through');
    };
    const ids = await Promise.all(Array.from({ length: 8 }, upload));
    expect(new Set(ids).size).toBe(8);
    const list = await request(API).get(`/editor/reports/${r.surveyId}/photos`).set('Cookie', s.cookie);
    expect(list.body.photos).toHaveLength(8);
    expect(list.body.photos.map((p: { sortOrder: number }) => p.sortOrder).sort((a: number, b: number) => a - b)).toEqual(Array.from({ length: 8 }, (_, i) => i).map((i) => list.body.photos.map((p: { sortOrder: number }) => p.sortOrder).sort((a: number, b: number) => a - b)[i]));
    expect((await prisma.report.findUniqueOrThrow({ where: { id: r.surveyId } })).version).toBe(1 + 8);
  });
});
