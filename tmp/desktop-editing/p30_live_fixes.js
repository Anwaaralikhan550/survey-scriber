// Checks for the fixes found while testing the live editor (23 Nov): redo, same-paragraph conflict choice,
// section indicators, the "not a Word file" note, phone layout (no sideways scroll). Local backend + local editor build.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { prisma, seed, newLink, enterEditor } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const OUT = path.join(__dirname, 'proof');
fs.mkdirSync(OUT, { recursive: true });
const results = [];
const check = (name, ok, extra = '') => {
  results.push(!!ok);
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
const stateText = (page) => page.locator('.chip.state').innerText().then((t) => t.trim());
const shot = (page, n) => page.screenshot({ path: path.join(OUT, `p30_${n}.png`), fullPage: true });

async function open(browser, link, name, viewport = { width: 1440, height: 900 }) {
  const ctx = await browser.newContext({ viewport });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(`${EDITOR}/open/${link.rawToken}`);
  await enterEditor(page, name);
  await page.locator('.workspace').waitFor({ timeout: 15000 });
  return { ctx, page, errors };
}
const goSection = (page, title) => page.locator('.sections li button', { hasText: title }).click();
const typeAtEnd = async (page, blockIndex, text) => {
  await page.locator('.pane .block').nth(blockIndex).locator('.textview').click();
  await page.locator('.pm:focus').waitFor({ timeout: 5000 });
  await page.keyboard.press('End');
  await page.keyboard.type(text);
};

(async () => {
  let browser;
  for (const channel of [process.env.BROWSER_CHANNEL || 'chrome', 'msedge']) {
    try {
      browser = await chromium.launch({ channel, headless: true });
      break;
    } catch {
      /* next */
    }
  }
  if (!browser) throw new Error('no browser');

  // ---------- undo / redo ----------
  {
    const s = await seed();
    const { ctx, page } = await open(browser, await newLink(s.token, s.surveyId), 'Redo Checker');
    await goSection(page, 'A. About the inspection');
    const n = () => page.locator('.pane .block').count();
    const before = await n();
    await page.locator('.pane .block').last().getByRole('button', { name: 'Delete' }).click();
    await page.getByRole('button', { name: 'Delete', exact: true }).last().click();
    check('undo/redo: delete removes the paragraph', await until(async () => (await n()) === before - 1));
    await page.getByRole('button', { name: 'Undo', exact: true }).click();
    check('undo/redo: Undo brings it back', await until(async () => (await n()) === before));
    await page.getByRole('button', { name: 'Redo', exact: true }).click();
    check('undo/redo: Redo removes it again', await until(async () => (await n()) === before - 1));
    await page.getByRole('button', { name: 'Undo', exact: true }).click();
    check('undo/redo: a second Undo brings it back again', await until(async () => (await n()) === before));
    check('undo/redo: Redo is available again after Undo', await until(async () => !(await page.getByRole('button', { name: 'Redo', exact: true }).isDisabled())));
    await page.getByRole('button', { name: 'Redo', exact: true }).click();
    await until(async () => (await n()) === before - 1);
    await page.locator('.pane .block').first().locator('.textview').click();
    await page.locator('.pm:focus').waitFor({ timeout: 5000 });
    await page.keyboard.type('x');
    check('undo/redo: a new edit clears Redo', await until(async () => await page.getByRole('button', { name: 'Redo', exact: true }).isDisabled()));
    await ctx.close();
  }

  // ---------- section indicators and the scope note ----------
  {
    const s = await seed();
    const { ctx, page } = await open(browser, await newLink(s.token, s.surveyId), 'Nav Checker');
    const kind = async (title) => {
      const el = page.locator('.sections li button', { hasText: title }).locator('.status');
      return (await el.getAttribute('class')).replace('status ', '');
    };
    check('nav: a written section with a rating of 2 is complete', (await kind('E1. Roof coverings')) === 'status-complete');
    check('nav: the empty summary section needs attention', (await kind('H. Summary of condition')) === 'status-attention');
    check('nav: the indicator has a text alternative', (await page.locator('.sections li button', { hasText: 'H. Summary' }).locator('.status').getAttribute('aria-label')).includes('Nothing written'));
    await goSection(page, 'E1. Roof coverings');
    await page.locator('.pane .block', { hasText: 'Condition rating' }).locator('select').selectOption('3');
    check('nav: a rating of 3 shows the urgent indicator at once', await until(async () => (await kind('E1. Roof coverings')) === 'status-urgent'));
    check('nav: the scope note says this is not a Word or PDF file', (await page.locator('.scope-note').innerText()).includes('not a Word or PDF file'));
    await shot(page, '01_nav');
    await ctx.close();
  }

  // ---------- two people changed the same paragraph ----------
  for (const choice of ['both', 'theirs', 'mine']) {
    const s = await seed();
    const link = await newLink(s.token, s.surveyId);
    const a = await open(browser, link, 'Person A');
    const b = await open(browser, link, 'Person B');
    await goSection(a.page, 'A. About the inspection');
    await goSection(b.page, 'A. About the inspection');
    // Person A is "theirs": saves first. Person B is "me": still has the old version open when pressing Save.
    await typeAtEnd(a.page, 0, ' THEIRS-WORDING');
    await a.page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    await until(async () => (await stateText(a.page)) === 'Saved');
    await typeAtEnd(b.page, 0, ' MINE-WORDING');
    // B's own autosave must not win the race: press Save at once, before the two-second autosave of B
    await b.page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    await b.page.getByRole('dialog', { name: 'Someone saved a newer version' }).waitFor({ timeout: 8000 });
    await b.page.getByRole('button', { name: 'Reload and re-apply my changes' }).click();
    const dlg = b.page.getByRole('dialog', { name: 'You both changed the same text' });
    check(`overlap(${choice}): re-apply asks first when the same paragraph was changed by both`, await dlg.waitFor({ timeout: 6000 }).then(() => true).catch(() => false));
    if (choice === 'both') {
      const t = await dlg.innerText();
      check('overlap: both versions are shown side by side', t.includes('THEIRS-WORDING') && t.includes('MINE-WORDING') && t.toLowerCase().includes('their version') && t.toLowerCase().includes('my version'));
      await shot(b.page, '02_overlap_dialog');
      await dlg.getByRole('button', { name: 'Back' }).click();
      check('overlap: Back returns to the conflict dialog and nothing is lost', (await b.page.getByRole('dialog', { name: 'Someone saved a newer version' }).count()) === 1);
      await b.page.getByRole('button', { name: 'Reload and re-apply my changes' }).click();
      await b.page.getByRole('dialog', { name: 'You both changed the same text' }).waitFor({ timeout: 6000 });
    }
    if (choice !== 'both') await b.page.getByLabel(choice === 'theirs' ? 'Keep their version' : 'Keep my version').check();
    await b.page.getByRole('button', { name: 'Apply my choices' }).click();
    check(`overlap(${choice}): the save goes through`, await until(async () => (await stateText(b.page)) === 'Saved', 12000));
    const text = (await b.page.locator('.pane').innerText());
    const server = JSON.stringify((await prisma.survey.findUnique({ where: { id: s.surveyId }, select: { id: true } })) && (await (await fetch(`${process.env.API || 'http://localhost:3099/api/v1'}/reports/${s.surveyId}/sync`, { method: 'POST', headers: { Authorization: `Bearer ${s.token}` } })).json()).content);
    if (choice === 'both') check('overlap(both): their wording stays and mine is added as its own paragraph (server holds both)', server.includes('THEIRS-WORDING') && server.includes('MINE-WORDING') && text.includes('THEIRS-WORDING') && text.includes('MINE-WORDING'));
    if (choice === 'theirs') check('overlap(theirs): their wording stays, mine is not saved', server.includes('THEIRS-WORDING') && !server.includes('MINE-WORDING'));
    if (choice === 'mine') check('overlap(mine): my wording is saved on top of theirs', server.includes('MINE-WORDING') && !server.includes('THEIRS-WORDING'));
    await a.ctx.close();
    await b.ctx.close();
  }

  // ---------- phone layout ----------
  {
    const s = await seed();
    const { ctx, page } = await open(browser, await newLink(s.token, s.surveyId), 'Phone Checker', { width: 390, height: 844 });
    const overflow = () => page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
    for (const t of ['A. About the inspection', 'D. About the property', 'E1. Roof coverings', 'E2. Chimney stacks', 'F. Walls', 'H. Summary of condition']) {
      await page.locator('select').first().selectOption({ label: t });
      await sleep(250);
      check(`phone: ${t} fits the screen width`, (await overflow()) <= 0, `overflow ${await overflow()}px`);
    }
    await page.locator('select').first().selectOption({ label: 'E1. Roof coverings' });
    await shot(page, '03_phone_roof');
    const inside = await page.locator('.pane .block button, .pane .block select').evaluateAll((els) => els.every((e) => { const r = e.getBoundingClientRect(); return r.left >= 0 && r.right <= innerWidth; }));
    check('phone: every block button and menu is fully inside the screen', inside);
    check('phone: the tall header scrolls away instead of staying fixed', (await page.locator('.topbar').evaluate((e) => getComputedStyle(e).position)) === 'static');
    await page.getByRole('tab', { name: /Photographs/ }).click();
    check('phone: Photographs tab fits', (await overflow()) <= 0);
    await page.getByRole('tab', { name: /Review/ }).click();
    check('phone: Review tab fits', (await overflow()) <= 0);
    await ctx.close();
  }

  await prisma.$disconnect();
  await browser.close();
  console.log(`\n${results.filter(Boolean).length}/${results.length} checks passed`);
  process.exit(results.every(Boolean) ? 0 : 1);
})().catch((e) => {
  console.error('SCRIPT ERROR', e);
  process.exit(1);
});
