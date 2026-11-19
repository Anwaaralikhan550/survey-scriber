// D4 browser test of the photograph manager against the real backend (Chrome). Screenshots in ./proof/d4_*.png.
const { chromium } = require('playwright');
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');
const { prisma, seed, newLink, call, API, gate } = require('./lib.js');
const { enterEditor } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const OUT = path.join(__dirname, 'proof');
const FIX = path.join(__dirname, 'fixtures');
fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(FIX, { recursive: true });
const results = [];
const check = (name, ok, extra = '') => {
  results.push({ name, ok: !!ok });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  ' + extra : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(fn, ms = 8000, step = 100) {
  const end = Date.now() + ms;
  for (;;) {
    try {
      const v = await fn();
      if (v) return v;
    } catch {
      /* retry */
    }
    if (Date.now() > end) return false;
    await sleep(step);
  }
}
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `d4_${name}.png`) });
const stateText = (page) => page.locator('.chip.state').innerText();
const photosOf = async (s, includeDeleted = false) => (await call(s.token, 'GET', `/reports/${s.surveyId}/photos${includeDeleted ? '?includeDeleted=true' : ''}`)).body;

async function makeFixtures() {
  const exif = { IFD0: { Copyright: 'Secret Surveyor' }, IFD3: { GPSLatitudeRef: 'N', GPSLatitude: '51/1 24/1 0/1', GPSLongitudeRef: 'E', GPSLongitude: '0/1 12/1 0/1' } };
  const make = async (name, w, h, color, label, withExif) => {
    const svg = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="100%" height="100%" fill="${color}"/><text x="50%" y="50%" font-size="${Math.round(h / 6)}" fill="#fff" text-anchor="middle" font-family="Arial">${label}</text></svg>`);
    let img = sharp(svg).jpeg({ quality: 90 });
    if (withExif) img = img.withExif(exif);
    fs.writeFileSync(path.join(FIX, name), await img.toBuffer());
  };
  await make('roof_front.jpg', 800, 600, '#2e7d33', 'Roof front', true);
  await make('roof_rear.jpg', 800, 600, '#1466bf', 'Roof rear', false);
  await make('chimney.jpg', 640, 480, '#9c26b0', 'Chimney', false);
  await make('replacement.jpg', 800, 600, '#d42e2e', 'REPLACED', false);
  fs.writeFileSync(path.join(FIX, 'not_a_photo.jpg'), Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.from('<?php system($_GET[0]); ?>')]));
  fs.writeFileSync(path.join(FIX, 'notes.txt'), 'plain text');
  fs.writeFileSync(path.join(FIX, 'too_big.jpg'), Buffer.concat([fs.readFileSync(path.join(FIX, 'roof_front.jpg')), Buffer.alloc(11 * 1024 * 1024)]));
  await sharp({ create: { width: 60, height: 40, channels: 3, background: '#445566' } }).png().toFile(path.join(FIX, 'plan.png'));
}
const fx = (n) => path.join(FIX, n);

async function colleague(rawToken) {
  await gate();
  const res = await fetch(API + '/editor/open', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: rawToken }) });
  const body = await res.json();
  const cookie = res.headers.get('set-cookie').split(';')[0];
  return {
    async patch(reportId, payload) {
      await gate();
      const r = await fetch(`${API}/editor/reports/${reportId}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Cookie: cookie, 'X-CSRF-Token': body.csrfToken }, body: JSON.stringify(payload) });
      return { status: r.status, body: await r.json() };
    },
    async read(reportId) {
      await gate();
      return (await fetch(`${API}/editor/reports/${reportId}`, { headers: { Cookie: cookie } })).json();
    },
  };
}

async function openEditor(browser, s, link, viewport = { width: 1440, height: 900 }) {
  const ctx = await browser.newContext({ viewport });
  const page = await ctx.newPage();
  const errors = [];
  page.on('response', (r) => { if (/photos\/[0-9a-f-]{36}\/file/.test(r.url()) && r.status() >= 400) console.log('IMG', r.status(), r.url().slice(-60)); });
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => {
    if (m.type() === 'error' && !/Failed to load resource|net::ERR/.test(m.text())) errors.push(m.text());
  });
  await page.goto(`${EDITOR}/open/${link.rawToken}`);
  await enterEditor(page);
  await page.locator('.workspace').waitFor({ timeout: 15000 });
  return { ctx, page, errors };
}
const openPhotos = async (page) => {
  await page.getByRole('tab', { name: /Photographs/ }).click();
  await page.locator('.photos').waitFor();
  await until(async () => !(await page.getByText('Loading photographs…').count()), 6000);
};
const cards = (page) => page.locator('.photo');
const cardByCaption = (page, c) => page.locator('.photo', { has: page.locator(`textarea`) }).filter({ has: page.locator(`textarea`) }).nth(0);

(async () => {
  await makeFixtures();
  let browser;
  for (const channel of ['chrome', 'msedge']) {
    try {
      browser = await chromium.launch({ channel, headless: true });
      break;
    } catch {
      /* next */
    }
  }
  if (!browser) throw new Error('no browser');
  try {
    let s = await seed();
    let link = await newLink(s.token, s.surveyId);
    let { ctx, page, errors } = await openEditor(browser, s, link);

    // ---------- empty state ----------
    await openPhotos(page);
    check('Photographs tab opens and says there are none yet', (await page.locator('.empty').innerText()).includes('No photographs yet'));
    check('Add photographs button and drop hint are shown, with the EXIF notice', (await page.getByRole('button', { name: /Add photographs/ }).count()) === 1 && (await page.locator('.photos').innerText()).includes('Location and camera details are removed'));
    await shot(page, '01_empty');

    // ---------- upload (3 photos, one with GPS) ----------
    const v0 = (await photosOf(s)).version;
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles([fx('roof_front.jpg'), fx('roof_rear.jpg'), fx('chimney.jpg')]);
    check('three photographs appear', await until(async () => (await cards(page).count()) === 3, 15000));
    check('the uploads list empties when they are done', await until(async () => (await page.locator('.upload').count()) === 0, 8000));
    let l = await photosOf(s);
    check('the server has three photos and the version rose by three', l.photos.length === 3 && l.version === v0 + 3, `v${v0}->v${l.version}`);
    check('every thumbnail really loaded (cookie-authenticated picture)', await until(async () => page.locator('.thumb img').evaluateAll((imgs) => imgs.length === 3 && imgs.every((i) => i.complete && i.naturalWidth > 0)), 8000));
    check('the tab count shows 3', (await page.getByRole('tab', { name: /Photographs/ }).innerText()).includes('3'));
    const stored = await prisma.media.findMany({ where: { surveyId: s.surveyId, type: 'PHOTO' }, orderBy: { createdAt: 'asc' } });
    const root = path.resolve(__dirname, '..', '..', 'backend', 'storage');
    const front = fs.readFileSync(path.join(root, stored[0].storagePath));
    check('the photo that had GPS and a copyright in it was stored without them', !front.includes(Buffer.from('Secret Surveyor')) && !front.includes(Buffer.from('GPS')) && !(await sharp(front).metadata()).exif);
    await shot(page, '02_three_uploaded');

    // ---------- header version stays in step; text save after a photo change ----------
    check('the header shows the new report version', (await page.locator('.topbar').innerText()).includes(`Version ${l.version}`));
    await page.locator('.sections li button', { hasText: 'A. About the inspection' }).click();
    const firstBlock = s.content[0].blocks[0];
    await page.locator(`[data-block-id="${firstBlock.id}"] .textview`).click();
    await page.locator('.pm:focus').waitFor({ timeout: 5000 });
    await page.keyboard.press('End');
    await page.keyboard.type(' Edited after photos.');
    check('a text edit after photo changes autosaves with no conflict', await until(async () => (await stateText(page)).trim() === 'Saved', 9000) && (await page.getByRole('dialog').count()) === 0);
    check('the text edit reached the server', JSON.stringify((await call(s.token, 'POST', `/reports/${s.surveyId}/sync`)).body.content).includes('Edited after photos.'));
    await openPhotos(page);

    // ---------- caption ----------
    const first = cards(page).nth(0);
    const firstId = await first.getAttribute('data-photo-id');
    await first.locator('textarea').fill('Front slope of the main roof');
    await first.locator('textarea').blur();
    check('the caption is saved to the server on leaving the field', await until(async () => (await photosOf(s)).photos.find((p) => p.id === firstId).caption === 'Front slope of the main roof', 6000));
    await page.reload();
    await page.locator('.workspace').waitFor({ timeout: 15000 });
    await openPhotos(page);
    check('the caption is still there after reloading the page', (await cards(page).nth(0).locator('textarea').inputValue()) === 'Front slope of the main roof');

    // ---------- section and order ----------
    const sectionSelect = (i) => cards(page).nth(i).locator('select');
    await sectionSelect(0).selectOption({ label: 'E1. Roof coverings' });
    await until(async () => (await photosOf(s)).photos.find((p) => p.id === firstId).sectionKey === 'E1_ROOF', 6000);
    await sectionSelect(0).selectOption({ label: 'E1. Roof coverings' }).catch(() => {});
    const ids = (await photosOf(s)).photos.map((p) => p.id);
    const second = ids.find((i) => i !== firstId);
    await page.locator(`[data-photo-id="${second}"] select`).selectOption({ label: 'E1. Roof coverings' });
    check('photographs are grouped under the section they were given', await until(async () => (await page.locator('.photo-group h2', { hasText: 'E1. Roof coverings' }).count()) === 1 && (await page.locator('.photo-group h2', { hasText: 'No section' }).count()) === 1, 8000));
    l = await photosOf(s);
    check('the server holds the section and a gap-free order', l.photos.filter((p) => p.sectionKey === 'E1_ROOF').map((p) => p.sortOrder).sort().join(',') === '0,1');
    await shot(page, '03_sections');
    const roofGroup = page.locator('.photo-group', { has: page.locator('h2', { hasText: 'E1. Roof coverings' }) });
    check('both photographs are listed under the roof section', await until(async () => (await roofGroup.locator('.photo').count()) === 2 && (await photosOf(s)).photos.filter((p) => p.sectionKey === 'E1_ROOF').length === 2, 8000));
    const orderBefore = await roofGroup.locator('.photo').evaluateAll((els) => els.map((e) => e.getAttribute('data-photo-id')));
    await roofGroup.locator('.photo').nth(1).getByRole('button', { name: 'Move earlier' }).click();
    check('Move earlier swaps the order on the server and on screen', await until(async () => (await photosOf(s)).photos.filter((p) => p.sectionKey === 'E1_ROOF').sort((a, b) => a.sortOrder - b.sortOrder).map((p) => p.id).join() === [orderBefore[1], orderBefore[0]].join() && (await roofGroup.locator('.photo').evaluateAll((els) => els.map((e) => e.getAttribute('data-photo-id')))).join() === [orderBefore[1], orderBefore[0]].join(), 8000));
    check('the first photo cannot move earlier and the last cannot move later', (await page.locator('.photo-group').first().locator('.photo').first().getByRole('button', { name: 'Move earlier' }).isDisabled()) && (await page.locator('.photo-group').first().locator('.photo').last().getByRole('button', { name: 'Move later' }).isDisabled()));
    await page.locator('select', { has: page.locator('option', { hasText: 'All photographs' }) }).selectOption({ label: 'E1. Roof coverings (2)' });
    check('the Show filter limits the grid to one section', (await cards(page).count()) === 2);
    await page.locator('select', { has: page.locator('option', { hasText: 'All photographs' }) }).selectOption({ index: 0 });

    // ---------- replace ----------
    const target = cards(page).nth(0);
    const targetId = await target.getAttribute('data-photo-id');
    const beforeRow = (await photosOf(s)).photos.find((p) => p.id === targetId);
    if (!(await target.locator('img').count())) { console.log('DEBUG first card html:', (await target.innerHTML()).slice(0, 600)); await shot(page, 'debug_no_img'); }
    const oldSrc = await target.locator('img').getAttribute('src');
    await target.locator('input[type=file]').setInputFiles(fx('replacement.jpg'));
    check('replace shows the new picture, same caption, section and place', await until(async () => {
      const cur = await photosOf(s);
      const row = cur.photos.find((p) => p.sectionKey === beforeRow.sectionKey && p.sortOrder === beforeRow.sortOrder);
      return row && row.id !== targetId && row.caption === beforeRow.caption;
    }, 12000));
    l = await photosOf(s, true);
    check('the replaced photo is marked deleted and no longer listed', l.photos.find((p) => p.id === targetId).deleted === true && !(await photosOf(s)).photos.some((p) => p.id === targetId));
    check('the new thumbnail loaded and is a different picture', await until(async () => page.locator('.thumb img').evaluateAll((imgs) => imgs.every((i) => i.complete && i.naturalWidth > 0)), 8000) && !(await page.locator(`img[src^="${oldSrc.split('?')[0]}"]`).count()));
    await shot(page, '04_replaced');

    // ---------- failed replace keeps the old picture ----------
    const keep = cards(page).nth(1);
    const keepId = await keep.getAttribute('data-photo-id');
    const vBefore = (await photosOf(s)).version;
    await keep.locator('input[type=file]').setInputFiles(fx('not_a_photo.jpg'));
    check('a damaged replacement is refused with a message', await until(async () => (await page.locator('.inline-banner').count()) === 1, 8000));
    l = await photosOf(s);
    check('the current photo is untouched: same id, same version, picture still shown', l.photos.some((p) => p.id === keepId) && l.version === vBefore && (await keep.locator('img').evaluate((i) => i.complete && i.naturalWidth > 0)));
    await shot(page, '05_replace_failed');

    // ---------- client-side and server-side validation of new photos ----------
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(fx('notes.txt'));
    check('a text file is refused before anything is sent', (await page.locator('.inline-banner').innerText()).includes('only JPEG and PNG'));
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(fx('too_big.jpg'));
    check('a photo over 10 MB is refused before it is sent', (await page.locator('.inline-banner').innerText()).includes('larger than 10 MB'));
    const countNow = (await photosOf(s)).photos.length;
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(fx('not_a_photo.jpg'));
    check('a file that only pretends to be a photo fails with Retry and Dismiss', await until(async () => (await page.locator('.upload-failed').count()) === 1, 8000) && (await page.locator('.upload-failed').innerText()).includes('not a valid image'));
    await shot(page, '06_upload_failed');
    check('nothing was added by the refused uploads', (await photosOf(s)).photos.length === countNow);
    await page.locator('.upload-failed').getByRole('button', { name: 'Dismiss' }).click();
    check('Dismiss clears the failed upload', (await page.locator('.upload').count()) === 0);
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(fx('plan.png'));
    check('a small PNG is accepted', await until(async () => (await photosOf(s)).photos.length === countNow + 1, 10000));

    // ---------- drag and drop ----------
    const dropB64 = (await sharp({ create: { width: 40, height: 30, channels: 3, background: '#123456' } }).png().toBuffer()).toString('base64');
    await page.evaluate(async (b64) => {
      const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
      const dt = new DataTransfer();
      dt.items.add(new File([bytes], 'dropped.png', { type: 'image/png' }));
      document.querySelector('.photos').dispatchEvent(new DragEvent('drop', { dataTransfer: dt, bubbles: true, cancelable: true }));
    }, dropB64);
    check('dropping a file onto the panel adds it', await until(async () => (await photosOf(s)).photos.length === countNow + 2, 10000));

    // ---------- delete ----------
    const victim = cards(page).nth(0);
    const victimId = await victim.getAttribute('data-photo-id');
    const total = (await photosOf(s)).photos.length;
    await victim.getByRole('button', { name: 'Delete photo' }).click();
    await page.getByRole('dialog', { name: 'Delete this photograph?' }).waitFor();
    await shot(page, '07_delete_confirm');
    await page.getByRole('button', { name: 'Cancel' }).click();
    check('Cancel keeps the photograph', (await photosOf(s)).photos.length === total);
    await victim.getByRole('button', { name: 'Delete photo' }).click();
    await page.getByRole('dialog').getByRole('button', { name: 'Delete', exact: true }).click();
    check('delete removes it from the screen and the live list', await until(async () => (await photosOf(s)).photos.length === total - 1 && (await page.locator(`[data-photo-id="${victimId}"]`).count()) === 0, 8000));
    check('the owner list still reports it as deleted so the phone can remove it', (await photosOf(s, true)).photos.find((p) => p.id === victimId)?.deleted === true);
    check('the remaining photos in each section were renumbered without gaps', await (async () => {
      const bySection = {};
      for (const p of (await photosOf(s)).photos) (bySection[p.sectionKey || '_'] ||= []).push(p.sortOrder);
      return Object.values(bySection).every((a) => a.sort((x, y) => x - y).every((v, i) => v === i));
    })());

    // ---------- a colleague saves text while this editor uploads and edits captions ----------
    const mate = await colleague(link.rawToken);
    const cur = await mate.read(s.surveyId);
    const theirs = await mate.patch(s.surveyId, { baseVersion: cur.version, changes: [{ op: 'updateBlock', sectionId: cur.content[1].id, blockId: cur.content[1].blocks[0].id, fields: { text: 'Colleague edit while photos change.' } }] });
    check('setup: a colleague saved newer text', theirs.status === 200);
    const nBefore = (await photosOf(s)).photos.length;
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(fx('chimney.jpg'));
    check('an upload after a colleague\'s save still goes through (it takes the newer version)', await until(async () => (await photosOf(s)).photos.length === nBefore + 1, 12000));
    check('no editing conflict dialog appeared', (await page.getByRole('dialog').count()) === 0);
    const lastCard = cards(page).last();
    await lastCard.locator('textarea').fill('After the colleague');
    const mateAgain = await mate.read(s.surveyId);
    await mate.patch(s.surveyId, { baseVersion: mateAgain.version, changes: [{ op: 'updateBlock', sectionId: mateAgain.content[1].id, blockId: mateAgain.content[1].blocks[0].id, fields: { text: 'Colleague edit number two.' } }] });
    await lastCard.locator('textarea').blur();
    check('a caption saved against a stale version is refused with a clear message and the photos reload', await until(async () => (await page.locator('.inline-banner').count()) === 1, 8000) && (await page.locator('.inline-banner').innerText()).includes('changed while you were working'));
    await shot(page, '08_stale_message');
    await lastCard.locator('textarea').fill('After the colleague, again');
    await lastCard.locator('textarea').blur();
    check('trying again works', await until(async () => (await photosOf(s)).photos.some((p) => p.caption === 'After the colleague, again'), 8000));

    // ---------- history and audit ----------
    const rows = await prisma.reportVersion.findMany({ where: { reportId: s.surveyId } });
    check('every photo change left a history row and an audit event', rows.filter((r) => r.reason === 'PHOTO').length >= 10 && (await prisma.auditLog.count({ where: { entityId: s.surveyId, action: { startsWith: 'PHOTO_' } } })) >= 10);
    check('no script or console errors on the photograph screens', errors.length === 0, errors.join(' | ').slice(0, 300));
    await ctx.close();

    // ---------- read-only (link expired) ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    ({ ctx, page, errors } = await openEditor(browser, s, link));
    await openPhotos(page);
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(fx('roof_front.jpg'));
    await until(async () => (await cards(page).count()) === 1, 10000);
    await prisma.editLink.update({ where: { id: link.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
    await page.reload();
    await page.locator('.workspace').waitFor({ timeout: 15000 });
    await openPhotos(page);
    check('expired link: the photograph is still visible', (await cards(page).count()) === 1 && (await page.locator('.thumb img').evaluate((i) => i.complete && i.naturalWidth > 0)));
    check('expired link: no add, replace, delete or move controls, caption not editable', (await page.getByRole('button', { name: /Add photographs/ }).count()) === 0 && (await page.getByRole('button', { name: 'Delete photo' }).count()) === 0 && (await page.getByRole('button', { name: /Replace/ }).count()) === 0 && (await cards(page).first().locator('textarea').isDisabled()));
    await shot(page, '09_read_only');
    await ctx.close();

    // ---------- link cancelled mid-session ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    ({ ctx, page } = await openEditor(browser, s, link));
    await openPhotos(page);
    await call(s.token, 'DELETE', `/reports/${s.surveyId}/edit-links/${link.linkId}`);
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(fx('roof_front.jpg'));
    check('cancelled link: the upload fails with a clear message and no photo is added', await until(async () => (await page.locator('.upload-failed').count()) === 1, 8000) && (await photosOf(s).catch(() => ({ photos: [] }))).photos.length === 0);
    await shot(page, '10_link_cancelled');
    await ctx.close();

    // ---------- layouts ----------
    for (const [name, vp] of [['ipad_portrait', { width: 820, height: 1180 }], ['laptop', { width: 1366, height: 768 }]]) {
      s = await seed();
      link = await newLink(s.token, s.surveyId);
      const o = await openEditor(browser, s, link, vp);
      await openPhotos(o.page);
      await o.page.locator('input[aria-label="Choose photographs to add"]').setInputFiles([fx('roof_front.jpg'), fx('roof_rear.jpg'), fx('chimney.jpg')]);
      await until(async () => (await cards(o.page).count()) === 3, 15000);
      await o.page.locator('.thumb img').first().waitFor();
      await sleep(400);
      const overflow = await o.page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
      check(`Layout ${name}: photograph grid has no horizontal page scroll`, !overflow);
      check(`Layout ${name}: no script or console errors`, o.errors.length === 0, o.errors.join(' | ').slice(0, 200));
      await shot(o.page, `11_${name}`);
      await o.ctx.close();
    }
  } catch (e) {
    console.log('SCRIPT ERROR', e);
    results.push({ name: 'script completed', ok: false });
  } finally {
    await browser.close();
    await prisma.$disconnect();
  }
  const bad = results.filter((r) => !r.ok);
  console.log(`\n${results.length - bad.length}/${results.length} checks passed`);
  fs.writeFileSync(path.join(OUT, 'd4_results.json'), JSON.stringify(results, null, 1));
  process.exit(bad.length ? 1 : 0);
})();
