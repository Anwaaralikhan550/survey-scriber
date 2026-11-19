// R4 (Remote Editor v1.4): the reviewer display name in the browser editor, against the real backend, with screenshots.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { prisma, seed, newLink, call, API, gate } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const OUT = 'E:/survey-scriber/tmp/client-edits-2026-11-19/proof';
fs.mkdirSync(OUT, { recursive: true });
let pass = 0;
let fail = 0;
const check = (name, ok, extra = '') => {
  if (ok) pass++;
  else fail++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  ' + extra : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(fn, ms = 9000, step = 150) {
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
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `r4_${name}.png`) });
const stateText = (page) => page.locator('.chip.state').innerText();
const events = (surveyId) => prisma.reportAuditEvent.findMany({ where: { reportId: surveyId, field: 'text', source: 'BROWSER' }, orderBy: { createdAt: 'asc' } });

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const s = await seed();
  const link = await newLink(s.token, s.surveyId);
  const roof = s.content[2];
  const p1 = roof.blocks[0];

  async function newPage() {
    const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await ctx.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(String(e)));
    return { ctx, page, errors };
  }
  async function editFirstParagraph(page, suffix) {
    await page.locator('.sections li button', { hasText: 'E1. Roof coverings' }).click();
    await page.locator(`[data-block-id="${p1.id}"] .textview`).click();
    await page.locator('.pm:focus').waitFor({ timeout: 5000 });
    await page.keyboard.press('End');
    await page.keyboard.type(suffix);
    await until(async () => (await stateText(page)).trim() === 'Saved', 10000);
  }

  // ---- Jane opens the link
  const a = await newPage();
  await a.page.goto(`${EDITOR}/open/${link.rawToken}`);
  const cont = a.page.getByRole('button', { name: 'Continue to the editor' });
  await cont.waitFor({ timeout: 15000 });
  check('landing asks for the name and Continue is not possible without it', (await a.page.getByLabel('Your name').count()) === 1 && (await cont.isDisabled()));
  check('landing says the name is recorded and not verified', /not verified/i.test(await a.page.locator('.name-form').innerText()));
  await a.page.getByLabel('Your name').fill('J');
  await a.page.getByLabel('Your name').blur();
  check('a name that is too short shows the reason and keeps Continue disabled', (await a.page.locator('.name-form .help.bad').count()) === 1 && (await cont.isDisabled()));
  await shot(a.page, '01_landing_name_error');
  await a.page.getByLabel('Your name').fill('a@b.com');
  check('an e-mail address is not accepted as a name', await cont.isDisabled());
  await a.page.getByLabel('Your name').fill('Jane Smith');
  check('a proper name enables Continue', await cont.isEnabled());
  await shot(a.page, '02_landing_name_ok');
  await cont.click();
  await a.page.locator('.workspace').waitFor();
  check('the editor opens with the name in the header', (await a.page.locator('.name-chip').innerText()).includes('Jane Smith'));
  check('no name dialog appears when a name was given', (await a.page.getByRole('dialog').count()) === 0);
  await shot(a.page, '03_workspace_name_chip');
  const reportRow = await call(s.token, 'POST', `/reports/${s.surveyId}/sync`);
  check('the server sees the name on the session', (await prisma.editorSession.findFirstOrThrow({ where: { reportId: s.surveyId }, orderBy: { createdAt: 'desc' } })).reviewerName === 'Jane Smith', String(reportRow.status));

  // ---- Jane edits: the history names her
  await editFirstParagraph(a.page, ' Edited by Jane.');
  let ev = await events(s.surveyId);
  check('the amendment history holds the change with her name, not verified', ev.length === 1 && ev[0].actorName === 'Jane Smith' && ev[0].source === 'BROWSER' && ev[0].afterValue.includes('Edited by Jane.'), JSON.stringify(ev.map((e) => e.actorName)));

  // ---- she changes her name from the header
  await a.page.locator('.name-chip').click();
  const dlg = a.page.getByRole('dialog', { name: 'Change your name' });
  await dlg.waitFor();
  await shot(a.page, '04_change_name_dialog');
  await dlg.getByLabel('Your name').fill('Jane S. Smith');
  await dlg.getByRole('button', { name: 'Save name' }).click();
  await dlg.waitFor({ state: 'detached' });
  check('the header shows the new name', (await a.page.locator('.name-chip').innerText()).includes('Jane S. Smith'));
  await a.page.locator(`[data-block-id="${p1.id}"] .textview, [data-block-id="${p1.id}"] .pm`).first().click();
  await a.page.locator('.pm:focus').waitFor({ timeout: 5000 });
  await a.page.keyboard.press('End');
  await a.page.keyboard.type(' Second edit.');
  await until(async () => (await stateText(a.page)).trim() === 'Saved', 10000);
  ev = await events(s.surveyId);
  check('the next change carries the new name, the first one keeps the old', ev.map((e) => e.actorName).join('|') === 'Jane Smith|Jane S. Smith', ev.map((e) => e.actorName).join('|'));

  // ---- submit for review: the history names her
  await a.page.locator('.chip.review-chip').click();
  await a.page.locator('section.review').getByRole('button', { name: 'Submit for review' }).click();
  await until(async () => /Submitted/i.test(await a.page.locator('.history').innerText()), 8000);
  const hist = await a.page.locator('.history').innerText();
  check('the review history shows who submitted, with "name not verified"', /Jane S\. Smith \(name not verified\)/.test(hist), hist.replace(/\s+/g, ' ').slice(0, 160));
  await shot(a.page, '05_review_history_name');

  // ---- Omar opens the same link in another browser: asked for his own name
  const b = await newPage();
  await b.page.goto(`${EDITOR}/open/${link.rawToken}`);
  await b.page.getByRole('button', { name: 'Continue to the editor' }).waitFor({ timeout: 15000 });
  check('a second person on the same link is asked for their own name (nothing prefilled)', (await b.page.getByLabel('Your name').inputValue()) === '');
  await b.page.getByLabel('Your name').fill('Omar Khan');
  await b.page.getByRole('button', { name: 'Continue to the editor' }).click();
  await b.page.locator('.workspace').waitFor();
  await b.page.getByRole('button', { name: 'Reload latest' }).click().catch(() => {});
  await sleep(1200);
  await editFirstParagraph(b.page, ' Omar was here.');
  ev = await events(s.surveyId);
  check('the history now has both people by name', ev.map((e) => e.actorName).join('|') === 'Jane Smith|Jane S. Smith|Omar Khan', ev.map((e) => e.actorName).join('|'));
  await shot(b.page, '06_second_person');

  // ---- a session that has no name (an old one) must be asked before anything is edited
  await gate();
  const open = await fetch(API + '/editor/open', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: link.rawToken }) });
  const body = await open.json();
  const cookie = open.headers.get('set-cookie').split(';')[0].split('=');
  const c = await newPage();
  await c.ctx.addCookies([{ name: cookie[0], value: cookie.slice(1).join('='), domain: 'localhost', path: '/api/v1/editor' }]);
  await c.page.addInitScript(([csrf, id]) => {
    sessionStorage.setItem('ss_editor_csrf', csrf);
    sessionStorage.setItem('ss_editor_report', id);
  }, [body.csrfToken, s.surveyId]);
  await c.page.goto(`${EDITOR}/editor`);
  const must = c.page.getByRole('dialog', { name: 'Please enter your name' });
  await must.waitFor({ timeout: 15000 });
  check('a session without a name is asked for one in the editor', true);
  await c.page.keyboard.press('Escape');
  check('the name dialog cannot be dismissed without a name', await must.isVisible());
  check('there is no Cancel button on it', (await must.getByRole('button', { name: 'Cancel' }).count()) === 0);
  await shot(c.page, '07_name_required_dialog');
  await must.getByLabel('Your name').fill('Priya Nair');
  await must.getByRole('button', { name: 'Save name' }).click();
  await must.waitFor({ state: 'detached' });
  check('after the name is given the editor is usable and shows it', (await c.page.locator('.name-chip').innerText()).includes('Priya Nair'));

  check('no script errors on any page', a.errors.length + b.errors.length + c.errors.length === 0, [...a.errors, ...b.errors, ...c.errors].join(' | ').slice(0, 200));
  console.log(`\nTOTAL pass=${pass} fail=${fail}`);
  await browser.close();
  await prisma.$disconnect();
  process.exit(fail ? 1 : 0);
})().catch((e) => {
  console.error('CRASH', e);
  process.exit(1);
});
