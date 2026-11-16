// D7 browser test: finalise while the editor is open, what the browser shows afterwards, then reopen and edit again.
// Real backend + Chrome. Screenshots: ./proof/d7_*.png
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { prisma, seed, newLink, call } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const OUT = path.join(__dirname, 'proof');
fs.mkdirSync(OUT, { recursive: true });
const results = [];
const check = (name, ok, extra = '') => {
  results.push({ name, ok: !!ok });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  ' + extra : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(fn, ms = 10000, step = 150) {
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
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `d7_${name}.png`) });

async function openEditor(browser, link, viewport = { width: 1440, height: 900 }) {
  const ctx = await browser.newContext({ viewport });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => {
    if (m.type() === 'error' && !/Failed to load resource|net::ERR/.test(m.text())) errors.push(m.text());
  });
  await page.goto(`${EDITOR}/open/${link.rawToken}`);
  return { ctx, page, errors };
}
const enter = async (page) => {
  await page.getByRole('button', { name: 'Continue to the editor' }).click();
  await page.locator('.workspace').waitFor({ timeout: 15000 });
};
const problem = (page) => page.locator('h1').first().innerText();

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
    const s = await seed();
    const own = (method, p, body) => call(s.token, method, `/reports/${s.surveyId}/${p}`, body);
    const latest = async () => (await own('GET', 'latest')).body;
    const link1 = await newLink(s.token, s.surveyId);
    const first = await openEditor(browser, link1);
    const { page, errors } = first;
    await enter(page);

    // ---- reviewer approves in the browser, owner approves, owner finalises ----
    await page.getByRole('tab', { name: /^Review/ }).click();
    await page.locator('.review').waitFor();
    await page.locator('.review').getByRole('button', { name: 'Submit for review' }).click();
    await until(async () => /Submitted for review/.test(await page.locator('.status-pill').innerText()));
    await page.getByRole('button', { name: 'Approve this version' }).click();
    check('reviewer approved in the browser', await until(async () => /Approved by a reviewer/.test(await page.locator('.status-pill').innerText())));
    let v = (await latest()).version;
    const early = await own('POST', 'finalise', { expectedReportVersion: v });
    check('finalise is refused before the owner has approved (409 INVALID_STATE)', early.status === 409 && early.body.error === 'INVALID_STATE');
    check('owner approves', (await own('POST', 'owner-approval', { expectedReportVersion: v })).status === 200);

    // ---- the owner finalises while the editor is open with an unsaved edit ----
    await page.getByRole('tab', { name: /^Report text/ }).click();
    const sec = page.locator('.sections button', { hasText: 'E1. Roof coverings' });
    await sec.click();
    const para = page.locator('.block.block-paragraph').first();
    await para.locator('.textview').click();
    const fin = await own('POST', 'finalise', { expectedReportVersion: v });
    check('owner finalises (200, FINALISED, final version = approved version)', fin.status === 200 && fin.body.status === 'FINALISED' && fin.body.finalVersion === v, JSON.stringify(fin.body));
    await page.locator('.block.is-active .pm').click();
    await page.keyboard.type(' A late edit made after the report was finalised.');
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click().catch(() => {});
    check('the late edit is refused: the editor says it can no longer be changed', await until(async () => /can no longer be edited|Read-only|Access ended/i.test(await page.locator('body').innerText()), 15000));
    await shot(page, '01_finalised_while_open');
    const row = await prisma.report.findUniqueOrThrow({ where: { id: s.surveyId } });
    const sectionBlocks = row.content.flatMap((x) => x.blocks);
    check('nothing from the late edit reached the report', !JSON.stringify(sectionBlocks).includes('late edit') && row.status === 'FINALISED' && row.version === v);
    check('the screen turns read-only at once: chip says Finalised, edit tools are gone, Save is off', await until(async () => {
      const top = await page.locator('.topbar').innerText();
      return /Finalised, read-only/.test(top) && (await page.locator('button[aria-label="Suggest wording with AI"]').count()) === 0 && (await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).isDisabled()) && (await page.getByRole('button', { name: 'Add paragraph below' }).count()) === 0;
    }, 8000));

    // ---- reload: the session is gone and the page says the report is finalised ----
    await page.reload();
    await until(async () => (await page.locator('h1').count()) > 0);
    const p1 = await until(async () => /finalised/i.test(await page.locator('body').innerText()), 8000);
    check('reloading shows "This report has been finalised", not a bare error', p1, (await page.locator('body').innerText()).slice(0, 120).replace(/\n/g, ' | '));
    await shot(page, '02_reload_after_final');
    const readViaApi = await page.evaluate(async (id) => (await fetch(`/api/v1/editor/reports/${id}`, { credentials: 'include' })).status, s.surveyId);
    check('the old session cannot read the report any more (403)', readViaApi === 403, `status ${readViaApi}`);
    await first.ctx.close();

    // ---- the old link says finalised ----
    const again = await openEditor(browser, link1);
    check('the old link says the report is finalised', await until(async () => /finalised/i.test(await again.page.locator('body').innerText()), 8000));
    await shot(again.page, '03_old_link_after_final');
    await again.ctx.close();

    // ---- the final text is still readable by the owner (phone Synchronise) ----
    const sync = await own('POST', 'sync');
    check('the owner can still read the final text (sync 200)', sync.status === 200 && JSON.stringify(sync.body).includes('concrete interlocking tiles'));
    const hist1 = (await own('GET', 'finalisations')).body;
    check('history shows round 1 finalised', hist1.finalisations.length === 1 && hist1.finalisations[0].cycle === 1 && hist1.finalisations[0].version === v);

    // ---- reopen, new link, edit again ----
    const reo = await own('POST', 'reopen', { expectedReportVersion: v, reason: 'Client asked for a change to the roof wording' });
    check('reopen: draft, round 2', reo.status === 200 && reo.body.status === 'DRAFT' && reo.body.cycle === 2, JSON.stringify(reo.body));
    const oldLinkStill = await openEditor(browser, link1);
    check('the first link stays dead after reopen (not revived)', await until(async () => /no longer active/i.test(await oldLinkStill.page.locator('body').innerText()), 8000));
    await oldLinkStill.ctx.close();
    const link2 = await newLink(s.token, s.surveyId);
    const second = await openEditor(browser, link2);
    await enter(second.page);
    const chips = await second.page.locator('.topbar .chip').allInnerTexts();
    check('the new session opens a draft that can be edited', chips.some((c) => /Draft/.test(c)) && chips.some((c) => /Editing/.test(c)), chips.join(' | '));
    await second.page.locator('.sections button', { hasText: 'E1. Roof coverings' }).click();
    await second.page.locator('.block.block-paragraph').first().locator('.textview').click();
    await second.page.locator('.block.is-active .pm').click();
    await second.page.keyboard.type(' Second round wording.');
    await second.page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    check('edit is saved in round 2 (version moves up)', await until(async () => (await latest()).version === v + 1));
    await shot(second.page, '04_reopened_editing');
    const hist2 = (await own('GET', 'finalisations')).body;
    check('history keeps round 1 with the reason', hist2.finalisations[0].reopenReason === 'Client asked for a change to the roof wording' && hist2.cycle === 2 && hist2.finalVersion === v);
    const oldVersion = await prisma.reportVersion.findUniqueOrThrow({ where: { reportId_version: { reportId: s.surveyId, version: v } } });
    check('the first final version is still stored unchanged', !JSON.stringify(oldVersion.content).includes('Second round wording'));
    await second.page.getByRole('tab', { name: /^Review/ }).click();
    await second.page.locator('.review').waitFor();
    check('review starts again from Draft with no approval carried over', (await until(async () => /Draft/.test(await second.page.locator('.status-pill').innerText()))) && /No approval that still stands/.test(await second.page.locator('.facts').innerText()) && /Not given/.test(await second.page.locator('.facts').innerText()));
    await shot(second.page, '05_reopened_review');
    check('no page errors', errors.length === 0 && second.errors.length === 0, [...errors, ...second.errors].join(' | '));
    await second.ctx.close();
  } finally {
    await browser.close();
    await prisma.$disconnect();
  }
  const failed = results.filter((r) => !r.ok);
  fs.writeFileSync(path.join(OUT, 'd7_results.json'), JSON.stringify(results, null, 2));
  console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
