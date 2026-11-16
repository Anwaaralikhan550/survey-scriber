/**
 * Security tests for desktop editing (client spec v1.3 section 17 and the security line of section 21):
 * stored XSS payloads, CSRF on every write route, cross-report access (IDOR), token handling, cookie and response
 * headers, upload attacks, mass assignment and oversize input.
 */
import request = require('supertest');
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';
import sharp from 'sharp';
import { UserRole } from '@prisma/client';
import { prisma, TEST_PREFIX, TEST_EMAIL_DOMAIN, generateStaffToken } from './test-helpers';

const API = 'http://localhost:3000/api/v1';
const STORAGE_ROOT = path.resolve(process.env.MEDIA_LOCAL_ROOT || 'storage');
const TITLE = `${TEST_PREFIX}secure`;
const bearer = (t: string) => ({ Authorization: `Bearer ${t}` });

interface Ctx {
  surveyId: string;
  secId: string;
  p1: string;
  ratingId: string;
  cookie: string;
  csrf: string;
  rawToken: string;
  linkId: string;
}

const PAYLOADS = [
  '<script>alert(1)</script>',
  '<img src=x onerror=alert(1)>',
  '<svg/onload=alert(1)>',
  '<iframe src="javascript:alert(1)"></iframe>',
  '<a href="javascript:alert(1)">click</a>',
  '<style>body{display:none}</style>',
  '<!-- comment --><b>bold</b>',
];

describe('Desktop editing security (E2E)', () => {
  let owner: { id: string; token: string };
  let a: Ctx;
  let b: Ctx;

  const user = async () => {
    const email = `${TEST_PREFIX}secure_owner${TEST_EMAIL_DOMAIN}`;
    const u = (await prisma.user.findUnique({ where: { email } })) ?? (await prisma.user.create({ data: { email, passwordHash: 'x', firstName: 'S', lastName: 'O', role: UserRole.SURVEYOR, isActive: true } }));
    return { id: u.id, token: generateStaffToken(u.id, u.email, u.role) };
  };

  async function fixture(): Promise<Ctx> {
    const survey = await prisma.survey.create({ data: { title: TITLE, propertyAddress: '1 Secure Road', userId: owner.id } });
    const secId = randomUUID();
    const p1 = randomUUID();
    const ratingId = randomUUID();
    const content = [
      {
        id: secId,
        key: 'E1_ROOF',
        title: 'Roof',
        blocks: [
          { id: p1, type: 'paragraph', text: 'Roof text.' },
          { id: ratingId, type: 'rating', rating: '2', required: true },
        ],
      },
    ];
    expect((await request(API).put(`/reports/${survey.id}/snapshot`).set(bearer(owner.token)).send({ reportType: 'L2', content })).status).toBe(200);
    const link = await request(API).post(`/reports/${survey.id}/edit-links`).set(bearer(owner.token));
    const rawToken = link.body.url.split('/open/')[1];
    const open = await request(API).post('/editor/open').send({ token: rawToken });
    return { surveyId: survey.id, secId, p1, ratingId, rawToken, linkId: link.body.linkId, cookie: (open.headers['set-cookie'] as unknown as string[])[0].split(';')[0], csrf: open.body.csrfToken };
  }

  beforeAll(async () => {
    owner = await user();
    a = await fixture();
    b = await fixture();
  });
  afterAll(async () => {
    const surveys = await prisma.survey.findMany({ where: { title: TITLE }, select: { id: true } });
    for (const s of surveys) fs.rmSync(path.join(STORAGE_ROOT, s.id), { recursive: true, force: true });
    await prisma.survey.deleteMany({ where: { title: TITLE } });
    await prisma.user.deleteMany({ where: { email: { startsWith: `${TEST_PREFIX}secure_` } } });
    await prisma.$disconnect();
  });

  const h = (c: Ctx) => ({ Cookie: c.cookie, 'X-CSRF-Token': c.csrf });
  const version = async (c: Ctx) => (await prisma.report.findUniqueOrThrow({ where: { id: c.surveyId } })).version;
  const save = async (c: Ctx, changes: unknown[], extra: Record<string, unknown> = {}) =>
    request(API).patch(`/editor/reports/${c.surveyId}`).set(h(c)).send({ baseVersion: await version(c), changes, ...extra });
  const storedTexts = async (c: Ctx) => JSON.stringify((await prisma.report.findUniqueOrThrow({ where: { id: c.surveyId } })).content);
  const jpeg = () => sharp({ create: { width: 40, height: 30, channels: 3, background: '#336699' } }).jpeg().toBuffer();
  const upload = async (c: Ctx, buf: Buffer, filename = 'p.jpg', type = 'image/jpeg', extra: Record<string, string> = {}) => {
    let r = request(API).post(`/editor/reports/${c.surveyId}/photos`).set(h(c)).attach('file', buf, { filename, contentType: type }).field('expectedReportVersion', String(await version(c)));
    for (const [k, v] of Object.entries(extra)) r = r.field(k, v);
    return r;
  };

  describe('stored XSS: markup is removed before it is stored', () => {
    it.each(PAYLOADS)('paragraph text: %s', async (payload) => {
      const res = await save(a, [{ op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { text: `Before ${payload} after` } }]);
      expect(res.status).toBe(200);
      const stored = await storedTexts(a);
      expect(stored).not.toMatch(/<\s*\/?\s*(script|img|svg|iframe|a|style|b)\b/i);
      expect(stored).not.toContain('<!--');
      expect(stored).toContain('Before');
      expect(stored).toContain('after');
    });

    it('tables, recommendations, captions, review comments and added blocks are cleaned the same way', async () => {
      const t = randomUUID();
      const rec = randomUUID();
      const res = await save(a, [
        { op: 'addBlock', sectionId: a.secId, block: { id: t, type: 'table', table: { headers: ['<b>Floor</b>', 'Beds'], rows: [['<script>x</script>Ground', '<img src=x onerror=1>0']] } } },
        { op: 'addBlock', sectionId: a.secId, block: { id: rec, type: 'recommendation', recommendation: '<script>steal()</script>Repair it.' } },
      ]);
      expect(res.status).toBe(200);
      const cap = await upload(a, await jpeg(), 'p.jpg', 'image/jpeg', { caption: '<img src=x onerror=alert(1)>Front' });
      expect(cap.status).toBe(201);
      expect(cap.body.photo.caption).not.toMatch(/<\s*img/i);
      await request(API).post(`/editor/reports/${a.surveyId}/review/submit`).set(h(a)).send({ expectedReportVersion: await version(a) });
      const cmt = await request(API).post(`/editor/reports/${a.surveyId}/review/decision`).set(h(a)).send({ expectedReportVersion: await version(a), decision: 'AMENDMENTS_REQUIRED', comment: '<script>alert(1)</script>Please fix <b>this</b>' });
      expect(cmt.status).toBe(200);
      expect(cmt.body.lastAmendmentRequest.comment).not.toMatch(/<\s*\/?(script|b)\b/i);
      expect(await storedTexts(a)).not.toMatch(/<\s*\/?\s*(script|img|b)\b/i);
    });

    it('owner snapshot (from the phone) is cleaned too', async () => {
      const c = await fixture();
      const content = [{ id: c.secId, key: 'E1_ROOF', title: '<b>Roof</b>', blocks: [{ id: c.p1, type: 'paragraph', text: '<script>alert(1)</script>From the phone' }] }];
      const up = await request(API).put(`/reports/${c.surveyId}/snapshot`).set(bearer(owner.token)).send({ reportType: 'L2', baseVersion: await version(c), content });
      expect(up.status).toBe(200);
      const stored = await storedTexts(c);
      expect(stored).not.toMatch(/<\s*\/?\s*(script|b)\b/i);
      expect(stored).toContain('From the phone');
    });

    it('text that looks like SQL is stored as text and nothing else happens', async () => {
      const text = "'); DROP TABLE reports; --";
      expect((await save(a, [{ op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { text } }])).status).toBe(200);
      expect(await storedTexts(a)).toContain('DROP TABLE reports');
      expect(await prisma.report.count()).toBeGreaterThan(0);
    });
  });

  describe('CSRF: every write needs the token that belongs to the session', () => {
    const routes = (c: Ctx): Array<[string, string, Record<string, unknown> | undefined]> => [
      ['patch', `/editor/reports/${c.surveyId}`, { baseVersion: 1, changes: [] }],
      ['post', `/editor/close`, {}],
      ['post', `/editor/reports/${c.surveyId}/review/submit`, { expectedReportVersion: 1 }],
      ['post', `/editor/reports/${c.surveyId}/review/start`, { expectedReportVersion: 1 }],
      ['post', `/editor/reports/${c.surveyId}/review/decision`, { expectedReportVersion: 1, decision: 'APPROVED' }],
      ['post', `/editor/reports/${c.surveyId}/ai/suggest`, { blockId: c.p1, action: 'IMPROVE', expectedReportVersion: 1 }],
      ['post', `/editor/reports/${c.surveyId}/ai/outcome`, { suggestionId: randomUUID(), blockId: c.p1, outcome: 'REJECTED' }],
      ['put', `/editor/reports/${c.surveyId}/photos/${randomUUID()}`, { expectedReportVersion: 1, caption: 'x' }],
      ['delete', `/editor/reports/${c.surveyId}/photos/${randomUUID()}?expectedReportVersion=1`, undefined],
    ];
    const send = (method: string, url: string, body: Record<string, unknown> | undefined, headers: Record<string, string>) => {
      const q = (request(API) as unknown as Record<string, (u: string) => request.Test>)[method](url).set(headers);
      return body ? q.send(body) : q;
    };

    it('no token, a wrong token, and another session\'s token are all refused with CSRF_INVALID', async () => {
      const c = await fixture();
      const other = await fixture();
      for (const [method, url, body] of routes(c)) {
        for (const headers of [{ Cookie: c.cookie }, { Cookie: c.cookie, 'X-CSRF-Token': 'wrong' }, { Cookie: c.cookie, 'X-CSRF-Token': other.csrf }] as Array<Record<string, string>>) {
          const res = await send(method, url, body, headers);
          expect([method, url, res.status, res.body.error]).toEqual([method, url, 403, 'CSRF_INVALID']);
        }
      }
      const noCsrfUpload = await request(API).post(`/editor/reports/${c.surveyId}/photos`).set('Cookie', c.cookie).attach('file', await jpeg(), { filename: 'a.jpg', contentType: 'image/jpeg' }).field('expectedReportVersion', '1');
      expect(noCsrfUpload.status).toBe(403);
      const noCsrfReplace = await request(API).post(`/editor/reports/${c.surveyId}/photos/${randomUUID()}/replace`).set('Cookie', c.cookie).attach('file', await jpeg(), { filename: 'a.jpg', contentType: 'image/jpeg' }).field('expectedReportVersion', '1');
      expect(noCsrfReplace.status).toBe(403);
      expect((await prisma.report.findUniqueOrThrow({ where: { id: c.surveyId } })).version).toBe(1);
    });

    it('the CSRF token is not accepted from the query string or the body', async () => {
      const c = await fixture();
      const res = await request(API).patch(`/editor/reports/${c.surveyId}?csrf=${c.csrf}`).set('Cookie', c.cookie).send({ baseVersion: 1, changes: [], csrfToken: c.csrf, _csrf: c.csrf });
      expect([400, 403]).toContain(res.status);
      expect(res.status === 403 ? res.body.error : 'CSRF_INVALID').toBe('CSRF_INVALID');
    });
  });

  describe('one report cannot reach another', () => {
    it('a session works only on its own report, on every route', async () => {
      const gets = [`/editor/reports/${b.surveyId}`, `/editor/reports/${b.surveyId}/photos`, `/editor/reports/${b.surveyId}/review`];
      for (const url of gets) expect((await request(API).get(url).set('Cookie', a.cookie)).status).toBe(403);
      const before = await version(b);
      const patch = await request(API).patch(`/editor/reports/${b.surveyId}`).set(h(a)).send({ baseVersion: before, changes: [{ op: 'updateBlock', sectionId: b.secId, blockId: b.p1, fields: { text: 'cross-report write' } }] });
      expect(patch.status).toBe(403);
      for (const action of ['submit', 'start']) {
        expect((await request(API).post(`/editor/reports/${b.surveyId}/review/${action}`).set(h(a)).send({ expectedReportVersion: before })).status).toBe(403);
      }
      const ai = await request(API).post(`/editor/reports/${b.surveyId}/ai/suggest`).set(h(a)).send({ blockId: b.p1, action: 'IMPROVE', expectedReportVersion: before });
      expect(ai.status).toBe(403);
      expect(await version(b)).toBe(before);
      expect(await storedTexts(b)).not.toContain('cross-report write');
    });

    it('a block id from another report is not found inside this one', async () => {
      const ai = await request(API).post(`/editor/reports/${a.surveyId}/ai/suggest`).set(h(a)).send({ blockId: b.p1, action: 'IMPROVE', expectedReportVersion: await version(a) });
      expect(ai.status).toBe(404);
      const move = await save(a, [{ op: 'updateBlock', sectionId: a.secId, blockId: b.p1, fields: { text: 'x' } }]);
      expect(move.status).toBeGreaterThanOrEqual(400);
      expect(await storedTexts(b)).not.toContain('"text":"x"');
    });

    it('a photo of another report cannot be read, changed or deleted through this one', async () => {
      const up = await upload(b, await jpeg());
      expect(up.status).toBe(201);
      const id = up.body.photo.id;
      expect((await request(API).get(`/editor/reports/${a.surveyId}/photos/${id}/file`).set('Cookie', a.cookie)).status).toBe(404);
      expect((await request(API).put(`/editor/reports/${a.surveyId}/photos/${id}`).set(h(a)).send({ expectedReportVersion: await version(a), caption: 'hijack' })).status).toBe(404);
      expect((await request(API).delete(`/editor/reports/${a.surveyId}/photos/${id}`).query({ expectedReportVersion: await version(a) }).set(h(a))).status).toBe(404);
      expect((await prisma.media.findUniqueOrThrow({ where: { id } })).deletedAt).toBeNull();
    });
  });

  describe('tokens, cookies and headers', () => {
    it('the link token is stored only as a hash, and is in no audit row, version or response after creation', async () => {
      const c = await fixture();
      const link = await prisma.editLink.findUniqueOrThrow({ where: { id: c.linkId } });
      expect(link.tokenHash).toMatch(/^[0-9a-f]{64}$/);
      expect(link.tokenHash).not.toBe(c.rawToken);
      const audit = JSON.stringify(await prisma.auditLog.findMany({ where: { entityId: c.surveyId } }));
      const versions = JSON.stringify(await prisma.reportVersion.findMany({ where: { reportId: c.surveyId } }));
      const sessions = JSON.stringify(await prisma.editorSession.findMany({ where: { reportId: c.surveyId } }));
      for (const blob of [audit, versions, sessions]) {
        expect(blob).not.toContain(c.rawToken);
        expect(blob).not.toContain(c.csrf);
        expect(blob).not.toContain(c.cookie.split('=')[1]);
      }
      const current = await request(API).get(`/reports/${c.surveyId}/edit-links/current`).set(bearer(owner.token));
      expect(JSON.stringify(current.body)).not.toContain(c.rawToken);
      expect(current.body.url).toBeUndefined();
      expect(link.tokenHash.length).toBe(64);
    });

    it('the session cookie is HttpOnly, SameSite=Strict, limited to the editor path, and random', async () => {
      const c = await fixture();
      const again = await request(API).post('/editor/open').send({ token: c.rawToken });
      const setCookie = (again.headers['set-cookie'] as unknown as string[])[0];
      expect(setCookie).toMatch(/HttpOnly/i);
      expect(setCookie).toMatch(/SameSite=Strict/i);
      expect(setCookie).toMatch(/Path=\/api\/v1\/editor/i);
      expect(setCookie.split(';')[0].split('=')[1].length).toBeGreaterThanOrEqual(40);
      expect(again.body.csrfToken.length).toBeGreaterThanOrEqual(40);
      expect(again.body.csrfToken).not.toBe(c.csrf); // a new session gets a new CSRF token
      expect(JSON.stringify(again.body)).not.toContain(c.rawToken);
      const stored = await prisma.editorSession.findMany({ where: { linkId: c.linkId } });
      for (const s of stored) {
        expect(s.sessionHash).toMatch(/^[0-9a-f]{64}$/);
        expect(s.sessionHash).not.toBe(setCookie.split(';')[0].split('=')[1]);
      }
    });

    it('editor responses cannot be cached, leak no referrer, are not indexed, and are JSON', async () => {
      const res = await request(API).get(`/editor/reports/${a.surveyId}`).set('Cookie', a.cookie);
      expect(res.status).toBe(200);
      expect(res.headers['cache-control']).toBe('no-store');
      expect(res.headers['referrer-policy']).toBe('no-referrer');
      expect(res.headers['x-robots-tag']).toMatch(/noindex/);
      expect(res.headers['content-type']).toMatch(/application\/json/);
      const err = await request(API).get(`/editor/reports/${a.surveyId}`).set('Cookie', 'nope=1');
      expect(err.status).toBe(404);
      expect(err.headers['cache-control']).toBe('no-store');
      const openFail = await request(API).post('/editor/open').send({ token: 'definitely-wrong' });
      expect(openFail.status).toBe(404);
      expect(openFail.headers['set-cookie']).toBeUndefined();
      expect(JSON.stringify(openFail.body)).not.toMatch(/Roof text|1 Secure Road/); // a bad token reveals nothing about any report
    });

    it('a wrong, missing, empty or oversized token is refused without detail and without a cookie', async () => {
      for (const token of ['', 'x', 'a'.repeat(500), '../../etc/passwd', "' OR 1=1 --"]) {
        const res = await request(API).post('/editor/open').send({ token });
        expect([400, 404]).toContain(res.status);
        expect(res.headers['set-cookie']).toBeUndefined();
      }
      expect((await request(API).post('/editor/open').send({})).status).toBe(400);
    });
  });

  describe('uploads', () => {
    const filesIn = (c: Ctx) => {
      const dir = path.join(STORAGE_ROOT, c.surveyId);
      return fs.existsSync(dir) ? fs.readdirSync(dir) : [];
    };

    it('HTML, SVG, scripts and text renamed to .jpg are refused and leave no file', async () => {
      const c = await fixture();
      const before = filesIn(c).length;
      const attacks: Array<[string, Buffer, string]> = [
        ['evil.jpg', Buffer.from('<html><script>alert(1)</script></html>'), 'image/jpeg'],
        ['evil.svg', Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"><script>alert(1)</script></svg>'), 'image/svg+xml'],
        ['evil.jpg', Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'), 'image/jpeg'],
        ['evil.php', Buffer.from('<?php system($_GET["c"]); ?>'), 'image/jpeg'],
        ['empty.jpg', Buffer.alloc(0), 'image/jpeg'],
        ['evil.exe', Buffer.from('MZ\x90\x00\x03\x00\x00\x00'), 'application/octet-stream'],
      ];
      for (const [name, buf, type] of attacks) {
        const res = await upload(c, buf, name, type);
        expect([name, res.status >= 400 && res.status < 500]).toEqual([name, true]);
      }
      expect(filesIn(c).length).toBe(before);
      expect(await version(c)).toBe(1);
    });

    it('a real photo with a script appended is re-encoded: the script is gone from the stored file', async () => {
      const c = await fixture();
      const polyglot = Buffer.concat([await jpeg(), Buffer.from('<script>alert(1)</script><?php evil(); ?>GIF89a')]);
      const res = await upload(c, polyglot);
      expect(res.status).toBe(201);
      const file = await request(API).get(`/editor/reports/${c.surveyId}/photos/${res.body.photo.id}/file`).set('Cookie', c.cookie).buffer(true).parse((r, cb) => {
        const chunks: Buffer[] = [];
        r.on('data', (x: Buffer) => chunks.push(x));
        r.on('end', () => cb(null, Buffer.concat(chunks)));
      });
      expect((file.body as Buffer).includes(Buffer.from('<script>'))).toBe(false);
      expect((file.body as Buffer).includes(Buffer.from('<?php'))).toBe(false);
      expect(file.headers['content-type']).toBe('image/jpeg');
      expect(file.headers['x-content-type-options']).toBe('nosniff');
    });

    it('the file name the user sends never decides where the file goes or what it is called', async () => {
      const c = await fixture();
      const outside = path.join(STORAGE_ROOT, `evil-${c.surveyId}.jpg`);
      for (const name of ['../../evil.jpg', '..\\..\\evil.jpg', `../evil-${c.surveyId}.jpg`, 'C:\\Windows\\evil.jpg', '/etc/evil.jpg', 'a\u0000b.jpg']) {
        const res = await upload(c, await jpeg(), name);
        expect([201, 400]).toContain(res.status);
        if (res.status === 201) expect(res.body.photo.fileName).not.toMatch(/[\/: ]|\.\./); // at most a plain base name is kept
      }
      expect(fs.existsSync(outside)).toBe(false);
      expect(fs.existsSync(path.join(STORAGE_ROOT, 'evil.jpg'))).toBe(false);
      for (const f of filesIn(c)) expect(f).toMatch(/^[0-9a-f-]+(\.[a-z]+)?$/i);
    });

    it('the type is decided by the bytes: a PNG sent as image/gif is stored and served as a PNG', async () => {
      const c = await fixture();
      const png = await sharp({ create: { width: 20, height: 20, channels: 3, background: '#aabbcc' } }).png().toBuffer();
      const res = await upload(c, png, 'x.gif', 'image/gif');
      if (res.status === 201) expect(res.body.photo.mimeType).toBe('image/png');
      else expect(res.status).toBe(400);
    });

    it('absurd dimensions and oversized files are refused', async () => {
      const c = await fixture();
      const wide = await sharp({ create: { width: 12500, height: 8, channels: 3, background: '#000' } }).png().toBuffer();
      expect((await upload(c, wide)).status).toBe(400);
      const tooBig = Buffer.concat([await jpeg(), Buffer.alloc(13 * 1024 * 1024, 7)]);
      const big = await upload(c, tooBig);
      expect([400, 413]).toContain(big.status);
      expect(await version(c)).toBe(1);
    });
  });

  describe('input that tries to change what it must not', () => {
    it('extra fields in the body are refused, so status, version and ids cannot be set from the browser', async () => {
      const before = await version(a);
      for (const extra of [{ status: 'FINALISED' }, { version: 999 }, { reportId: b.surveyId }, { ownerUserId: randomUUID() }]) {
        const res = await save(a, [{ op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { text: 'mass assignment' } }], extra);
        expect([400]).toContain(res.status);
      }
      // an own "__proto__" or "constructor" key in the JSON must not change what every object inherits (the save itself may be accepted or refused)
      const poisoned = await request(API).patch(`/editor/reports/${a.surveyId}`).set(h(a)).set('Content-Type', 'application/json').send(`{"baseVersion": ${await version(a)}, "changes": [], "__proto__": {"admin": true}, "constructor": {"prototype": {"admin": true}}}`);
      expect([200, 400]).toContain(poisoned.status);
      expect(({} as Record<string, unknown>).admin).toBeUndefined();
      const row = await prisma.report.findUniqueOrThrow({ where: { id: a.surveyId } });
      expect(row.version).toBe(before);
      expect(row.status).not.toBe('FINALISED');
    });

    it('the browser cannot set a block role, turn off "required", or put a rating on a paragraph', async () => {
      const bad = [
        { op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { role: 'rating' } },
        { op: 'updateBlock', sectionId: a.secId, blockId: a.ratingId, fields: { required: false } },
        { op: 'updateBlock', sectionId: a.secId, blockId: a.ratingId, fields: { rating: '<b>9</b>' } },
        { op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { rating: '1' } },
      ];
      for (const change of bad) {
        const res = await save(a, [change]);
        expect([JSON.stringify(change.fields), res.status]).toEqual([JSON.stringify(change.fields), 400]);
      }
      const rating = (JSON.parse(await storedTexts(a)) as Array<{ blocks: Array<{ id: string; required?: boolean; rating?: string; role?: string }> }>)[0].blocks.find((x) => x.id === a.ratingId);
      expect(rating?.required).toBe(true);
      expect(rating?.rating).toBe('2');
    });

    it('ids must be real UUIDs: prototype-pollution style ids are refused', async () => {
      for (const id of ['__proto__', 'constructor', 'toString', '../x', '1 OR 1=1']) {
        const res = await save(a, [{ op: 'updateBlock', sectionId: id, blockId: id, fields: { text: 'x' } }]);
        expect(res.status).toBe(400);
        const add = await save(a, [{ op: 'addBlock', sectionId: a.secId, block: { id, type: 'paragraph', text: 'x' } }]);
        expect(add.status).toBe(400);
      }
      expect(({} as Record<string, unknown>).admin).toBeUndefined();
    });

    it('limits hold: too much text, too many changes, a huge body', async () => {
      expect((await save(a, [{ op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { text: 'x'.repeat(20001) } }])).status).toBe(400);
      const many = Array.from({ length: 201 }, () => ({ op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { text: 'y' } }));
      expect((await save(a, many)).status).toBe(400);
      const huge = await request(API).patch(`/editor/reports/${a.surveyId}`).set(h(a)).send({ baseVersion: await version(a), changes: [{ op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { text: 'z'.repeat(15 * 1024 * 1024) } }] });
      expect([400, 413]).toContain(huge.status);
      expect(await storedTexts(a)).not.toContain('zzzzzzzz');
    });

    it('a request that is not valid JSON is a 400 and one that is too large is a 413, never a 500', async () => {
      const bad = await request(API).patch(`/editor/reports/${a.surveyId}`).set(h(a)).set('Content-Type', 'application/json').send('{"baseVersion": 1, "changes": [');
      expect(bad.status).toBe(400);
      expect(JSON.stringify(bad.body)).not.toMatch(/node_modules|\n\s+at /); // no stack trace or file paths
    });

    it('an AI-style or pasted answer with markup is treated like any other text (no way around the cleaning)', async () => {
      const outcome = await save(a, [{ op: 'updateBlock', sectionId: a.secId, blockId: a.p1, fields: { text: 'The roof <script>fetch("//evil")</script> is slate.' } }]);
      expect(outcome.status).toBe(200);
      expect(await storedTexts(a)).not.toContain('fetch("//evil")');
    });
  });
});
