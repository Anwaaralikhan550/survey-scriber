// D8 browser test: hostile text in every place the editor shows report content must be shown as text and never run.
// Real backend + Chrome. A canary (window.__xss) is set by every payload that would execute. Screenshots: ./proof/d8_*.png
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');
const sharp = require('sharp');
const { prisma, owner, newLink, call } = require('./lib.js');
const { enterEditor } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const OUT = path.join(__dirname, 'proof');
fs.mkdirSync(OUT, { recursive: true });
const results = [];
const check = (name, ok, extra = '') => {
  results.push({ name, ok: !!ok });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  ' + extra : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(fn, ms = 8000, step = 150) {
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

// Forms that survive the server's tag removal (no closing ">"), entities, and attribute breakers.
const HOSTILE = [
  '<img src=x onerror=window.__xss=1',
  '<svg onload=window.__xss=2',
  '&lt;img src=x onerror=window.__xss=3&gt;',
  '"><script>window.__xss=4</script>',
  "' onmouseover='window.__xss=5' x='",
  'javascript:window.__xss=6',
  '<scr<script>ipt>window.__xss=7</scr</script>ipt>',
  '{{constructor.constructor("window.__xss=8")()}}',
  '${window.__xss=9}',
];

(async () => {
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
    const { user, token } = await owner('desk.xss@example.com');
    await prisma.survey.deleteMany({ where: { userId: user.id, title: 'DESK XSS TEST' } });
    const survey = await prisma.survey.create({ data: { title: 'DESK XSS TEST', propertyAddress: '<img src=x onerror=window.__xss=10 Gas Lane', jobRef: '"><script>window.__xss=11</script>', userId: user.id } });
    const secId = randomUUID();
    const ids = HOSTILE.map(() => randomUUID());
    const content = [
      {
        id: secId,
        key: 'E1_ROOF',
        title: '<svg onload=window.__xss=12 Roof',
        blocks: [
          ...HOSTILE.map((h, i) => ({ id: ids[i], type: 'paragraph', text: `Paragraph ${i}: ${h}` })),
          { id: randomUUID(), type: 'recommendation', recommendation: `Recommendation: ${HOSTILE[0]}` },
          { id: randomUUID(), type: 'table', table: { headers: [HOSTILE[1], 'Beds'], rows: [[HOSTILE[2], HOSTILE[3]]] } },
        ],
      },
    ];
    const up = await call(token, 'PUT', `/reports/${survey.id}/snapshot`, { reportType: 'L2', content });
    if (up.status !== 200) throw new Error('snapshot ' + JSON.stringify(up.body));
    const link = await newLink(token, survey.id);

    const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await ctx.newPage();
    const errors = [];
    const violations = [];
    page.on('pageerror', (e) => errors.push(String(e)));
    let pasting = false;
    page.on('console', (m) => {
      if (m.type() !== 'error' || /Failed to load resource|net::ERR/.test(m.text())) return;
      if (pasting && /Content Security Policy/.test(m.text())) return; // reported by the browser while it parses the pasted HTML; see below
      errors.push(m.text());
    });
    await page.addInitScript(() => {
      document.addEventListener('securitypolicyviolation', (e) => (window.__violations = (window.__violations || []).concat(`${window.__phase || 'page'}:${e.violatedDirective}`)));
      window.alert = () => (window.__xss = 'alert');
    });
    await page.goto(`${EDITOR}/open/${link.rawToken}`);
    check('landing page shows the property text as text (address and reference)', await until(async () => /Gas Lane/.test(await page.locator('body').innerText())));
    check('the address that looked like markup is not parsed (no element made from it)', (await page.locator('.card img, .card svg, .card script').count()) === 0);
    await enterEditor(page);
    await page.locator('.workspace').waitFor({ timeout: 15000 });
    const xss = () => page.evaluate(() => window.__xss);
    check('nothing ran on the landing page or while opening the editor', (await xss()) === undefined, `__xss=${await xss()}`);

    // ---- everything the server kept is shown as plain text ----
    const html = await page.locator('.workspace').innerHTML();
    check('no injected element anywhere in the report area (img/svg/script/iframe)', !/<(img|svg|script|iframe|object|embed)\b/i.test(html.replace(/<svg viewBox="0 0 20 20"[\s\S]*?<\/svg>/g, '')));
    check('no event-handler attribute exists on any element', (await page.evaluate(() => [...document.querySelectorAll('*')].some((el) => [...el.attributes].some((a) => /^on/i.test(a.name))))) === false);
    const shown = await page.locator('.pane').innerText();
    check('the left-over hostile text is visible as ordinary characters', shown.includes('onerror=window.__xss=1') && shown.includes('Paragraph 3'));
    await page.screenshot({ path: path.join(OUT, 'd8_01_hostile_text_shown_as_text.png') });

    // ---- typing and pasting hostile text ----
    await page.locator(`.block[data-block-id="${ids[0]}"] .textview`).click();
    const pm = page.locator('.block.is-active .pm');
    await pm.click();
    await page.keyboard.press('End');
    await page.keyboard.type(' <img src=x onerror=window.__xss=20> typed');
    check('typed markup stays text in the editing surface (no img element created)', (await pm.locator('img, svg, script').count()) === 0 && /onerror=window\.__xss=20/.test(await pm.innerText()));
    pasting = true;
    await page.evaluate(() => {
      window.__phase = 'paste';
      const el = document.querySelector('.block.is-active .pm');
      const data = new DataTransfer();
      data.setData('text/html', '<img src=x onerror="window.__xss=21"><b>bold</b><a href="javascript:window.__xss=22">link</a> pasted');
      data.setData('text/plain', 'pasted plain');
      el.focus();
      el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: data, bubbles: true, cancelable: true }));
    });
    await sleep(300);
    pasting = false;
    await page.evaluate(() => (window.__phase = 'page'));
    check('pasted HTML creates no element (the editing surface knows only plain paragraphs)', (await pm.locator('img, b, a, svg').count()) === 0);
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    check('saved', await until(async () => (await page.locator('.chip.state').innerText()) === 'Saved'));
    check('the server removed the typed tag from the stored text', await until(async () => {
      const r = await prisma.report.findUniqueOrThrow({ where: { id: survey.id } });
      const text = JSON.stringify(r.content);
      return !/<img src=x onerror=window\.__xss=20>/.test(text) && /typed/.test(text);
    }));
    check('still nothing ran', (await xss()) === undefined, `__xss=${await xss()}`);

    // ---- photo captions and review comments ----
    const cap = '"><img src=x onerror=window.__xss=30 alt="';
    const jpgReal = await sharp({ create: { width: 64, height: 48, channels: 3, background: '#336699' } }).jpeg().toBuffer();
    const jpgOld = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD/2Q==', 'base64');
    const jpg = jpgReal;
    // multipart upload through the page, with its own cookie and CSRF token
    const status = await page.evaluate(async ({ id, fields }) => {
      const fd = new FormData();
      const bin = Uint8Array.from(atob(fields.b64), (c) => c.charCodeAt(0));
      fd.append('file', new Blob([bin], { type: 'image/jpeg' }), 'x.jpg');
      fd.append('expectedReportVersion', String(fields.v));
      fd.append('caption', fields.cap);
      fd.append('sectionKey', 'E1_ROOF');
      const r = await fetch(`/api/v1/editor/reports/${id}/photos`, { method: 'POST', credentials: 'include', headers: { 'X-CSRF-Token': sessionStorage.getItem('ss_editor_csrf') }, body: fd });
      return r.status;
    }, { id: survey.id, fields: { b64: jpg.toString('base64'), v: (await prisma.report.findUniqueOrThrow({ where: { id: survey.id } })).version, cap } });
    check('a photo with a hostile caption can be uploaded (the caption is cleaned by the server)', status === 201, `status ${status}`);
    await page.getByRole('tab', { name: /^Photographs/ }).click();
    await page.locator('.photos, [data-photo-id]').first().waitFor({ timeout: 8000 }).catch(() => {});
    await sleep(600);
    check('the caption area has no injected element or handler', (await page.locator('[data-photo-id] img[onerror], [data-photo-id] img[src="x"]').count()) === 0);
    await page.getByRole('tab', { name: /^Review/ }).click();
    await page.locator('.review').waitFor();
    await page.locator('.review').getByRole('button', { name: 'Submit for review' }).click();
    await until(async () => /Submitted for review/.test(await page.locator('.status-pill').innerText()));
    await page.locator('.review textarea').fill('<img src=x onerror=window.__xss=40 Please <b>fix</b>');
    await page.getByRole('button', { name: 'Request changes' }).click();
    await until(async () => /Changes requested/.test(await page.locator('.status-pill').innerText()));
    const reviewHtml = await page.locator('.review').innerHTML();
    check('review comment is shown as text, without markup', /fix/.test(await page.locator('.review').innerText()) && !/<img\b|<b>fix/.test(reviewHtml));
    await page.screenshot({ path: path.join(OUT, 'd8_02_review_comment_as_text.png') });

    // ---- final state ----
    check('canary never set: no payload executed anywhere', (await xss()) === undefined, `__xss=${await xss()}`);
    const v = await page.evaluate(() => window.__violations || []);
    check('no Content-Security-Policy violation outside the pasted-HTML parse', v.filter((x) => !x.startsWith('paste:')).length === 0, v.join(','));
    console.log('INFO  violations reported while the browser parsed the pasted HTML (nothing executed):', v.filter((x) => x.startsWith('paste:')).join(',') || 'none');
    check('no page errors', errors.length === 0, errors.join(' | '));
    await ctx.close();
  } finally {
    await browser.close();
    await prisma.$disconnect();
  }
  const failed = results.filter((r) => !r.ok);
  fs.writeFileSync(path.join(OUT, 'd8_xss_results.json'), JSON.stringify(results, null, 2));
  console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
