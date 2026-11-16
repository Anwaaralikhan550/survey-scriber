// D2 browser test of the desktop editor against the real backend. Screenshots go to ./proof, results to the console.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { prisma, seed, newLink, call, API, gate } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const OUT = path.join(__dirname, 'proof');
fs.mkdirSync(OUT, { recursive: true });
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
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `d2_${name}.png`), fullPage: false });
const stateText = (page) => page.locator('.chip.state').innerText();
const serverReport = async (s) => (await call(s.token, 'POST', `/reports/${s.surveyId}/sync`)).body;
const blockByText = (content, text) => content.flatMap((x) => x.blocks).find((b) => (b.text || '').includes(text) || (b.recommendation || '').includes(text));

// A second colleague through the API (cookie + CSRF), used to create a conflict.
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
      return (await (await fetch(`${API}/editor/reports/${reportId}`, { headers: { Cookie: cookie } })).json());
    },
  };
}

async function openEditor(browser, s, link, viewport = { width: 1440, height: 900 }) {
  const ctx = await browser.newContext({ viewport });
  const page = await ctx.newPage();
  const urls = [];
  page.on('request', (r) => urls.push(r.url()));
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { if (m.type() === 'error' && !/Failed to load resource|net::ERR/.test(m.text())) errors.push(m.text()); });
  await page.goto(`${EDITOR}/open/${link.rawToken}`);
  await page.getByRole('button', { name: 'Continue to the editor' }).waitFor({ timeout: 15000 });
  return { ctx, page, urls, errors };
}

(async () => {
  let browser;
  for (const channel of [process.env.BROWSER_CHANNEL || 'chrome', 'msedge']) {
    try {
      browser = await chromium.launch({ channel, headless: true });
      console.log('browser:', channel);
      break;
    } catch (e) {
      console.log('browser', channel, 'unavailable');
    }
  }
  if (!browser) throw new Error('no browser');
  try {
    // ---------- Screen A and the token rules ----------
    let s = await seed();
    let link = await newLink(s.token, s.surveyId);
    let { ctx, page, urls, errors } = await openEditor(browser, s, link);
    check('A: landing shows branding, reference, property, expiry and a Continue button', (await page.locator('.landing').innerText()).match(/VL1433/) && (await page.locator('.landing').innerText()).match(/54 Gas Lane/) && (await page.locator('.landing').innerText()).match(/works until/));
    check('A: raw token removed from the address bar after the exchange', !page.url().includes(link.rawToken) && page.url().endsWith('/editor'), page.url());
    check('A: apart from the first page load (the link itself), no request URL carried the token', urls.filter((u) => u !== `${EDITOR}/open/${link.rawToken}`).every((u) => !u.includes(link.rawToken)), urls.filter((u) => u.includes(link.rawToken)).length + ' with token');
    check('A: no referrer / noindex / CSP meta tags on the page', (await page.locator('meta[name=referrer]').getAttribute('content')) === 'no-referrer' && (await page.locator('meta[name=robots]').getAttribute('content')).includes('noindex') && (await page.locator('meta[http-equiv="Content-Security-Policy"]').count()) === 1);
    const cookies = await ctx.cookies();
    const ck = cookies.find((c) => c.name === 'ss_editor');
    check('A: session cookie is HttpOnly + SameSite=Strict', ck && ck.httpOnly && ck.sameSite === 'Strict');
    check('A: the cookie is not readable by page script', !(await page.evaluate(() => document.cookie)).includes('ss_editor'));
    await shot(page, '01_screenA_landing');

    // ---------- Screen B workspace ----------
    await page.getByRole('button', { name: 'Continue to the editor' }).click();
    await page.locator('.workspace').waitFor();
    const head = await page.locator('.topbar').innerText();
    check('B: header shows reference, address, type, version, save state, link expiry and Editing', /VL1433/.test(head) && /54 Gas Lane/.test(head) && /Home Survey Level 2/.test(head) && /Version 1/.test(head) && /Saved/.test(head) && /Link:/.test(head) && /Editing/.test(head));
    check('B: left navigation lists all 6 sections', (await page.locator('.sections li button').count()) === 6);
    check('B: SAVE TO SURVEYSCRIBER, Undo, Redo, Reload latest and Exit are present', (await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).count()) === 1 && (await page.getByRole('button', { name: 'Undo' }).count()) === 1 && (await page.getByRole('button', { name: 'Redo' }).count()) === 1 && (await page.getByRole('button', { name: 'Reload latest' }).count()) === 1 && (await page.getByRole('button', { name: 'Exit' }).count()) === 1);
    await shot(page, '02_screenB_workspace');
    await page.locator('.sections li button', { hasText: 'E1. Roof coverings' }).click();
    check('B: choosing a section shows its paragraphs, rating and recommendation', (await page.locator('.pane .block').count()) === 4);
    await shot(page, '03_screenB_roof');

    // ---------- Screen C: edit, autosave ----------
    const roof = s.content[2];
    const p1 = roof.blocks[0];
    await page.locator(`[data-block-id="${p1.id}"] .textview`).click();
    await page.locator(`[data-block-id="${p1.id}"] .pm`).waitFor();
    await page.keyboard.press('End');
    await page.keyboard.type(' Edited in the browser.');
    check('C: typing shows "Unsaved changes"', await until(async () => (await stateText(page)).includes('Unsaved'), 3000));
    await shot(page, '04_screenC_typing_unsaved');
    check('C: autosave reaches "Saved" only after the server confirms', await until(async () => (await stateText(page)).trim() === 'Saved', 9000));
    let rep = await serverReport(s);
    check('C: the server now holds the edit and version 2', blockByText(rep.content, 'Edited in the browser') && rep.version === 2, `v${rep.version}`);
    check('C: block ids are unchanged after the edit', rep.content[2].blocks[0].id === p1.id);
    check('B: header shows Version 2', (await page.locator('.topbar').innerText()).includes('Version 2'));
    await shot(page, '05_screenC_saved');

    // add, reorder, delete with confirmation, undo
    await page.locator(`[data-block-id="${p1.id}"] + .insert button`).click();
    await page.keyboard.type('A new paragraph added by the editor.');
    await page.locator('.pane h1').click();
    check('C: a paragraph can be added after another', (await page.locator('.pane .block').count()) === 5);
    const second = roof.blocks[1];
    const idsOf = () => page.locator('.pane .block').evaluateAll((els) => els.map((e) => e.getAttribute('data-block-id')));
    const before = await idsOf();
    const addedId = before.find((id) => !roof.blocks.some((b) => b.id === id));
    check('C: new paragraph sits right after the one it was added to', before.indexOf(addedId) === before.indexOf(p1.id) + 1 && before.indexOf(second.id) === before.indexOf(addedId) + 1, before.map((x) => x.slice(0, 4)).join(','));
    await page.locator(`[data-block-id="${second.id}"]`).getByRole('button', { name: 'Move up' }).click();
    const order = await idsOf();
    check('C: reorder with the Move up control swaps it above the new paragraph', order.indexOf(second.id) === order.indexOf(addedId) - 1, order.map((x) => x.slice(0, 4)).join(','));
    await page.locator(`[data-block-id="${second.id}"]`).getByRole('button', { name: 'Delete' }).click();
    await page.getByRole('dialog', { name: 'Delete this paragraph?' }).waitFor();
    await shot(page, '06_screenC_delete_confirm');
    await page.getByRole('button', { name: 'Cancel' }).click();
    check('C: Cancel on the delete confirmation keeps the paragraph', (await page.locator('.pane .block').count()) === 5);
    await page.locator(`[data-block-id="${second.id}"]`).getByRole('button', { name: 'Delete' }).click();
    await page.getByRole('button', { name: 'Delete', exact: true }).last().click();
    check('C: delete after confirmation removes it', (await page.locator('.pane .block').count()) === 4);
    await page.getByRole('button', { name: 'Undo' }).click();
    check('C: Undo brings the deleted paragraph back', (await page.locator('.pane .block').count()) === 5);
    await page.keyboard.press('Control+Z');
    await page.keyboard.press('Control+Y');
    const ratingBlock = roof.blocks[2];
    check('C: the required rating cannot be deleted (button disabled)', await page.locator(`[data-block-id="${ratingBlock.id}"]`).getByRole('button', { name: 'Delete' }).isDisabled());
    await page.locator(`[data-block-id="${ratingBlock.id}"] select`).selectOption('3');
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    check('C: SAVE TO SURVEYSCRIBER flushes and shows Saved', await until(async () => (await stateText(page)).trim() === 'Saved', 9000));
    rep = await serverReport(s);
    const rb = rep.content[2].blocks;
    check('C: server has: new paragraph, deleted block restored, moved order, rating 3', rb.some((b) => (b.text || '').includes('new paragraph added')) && rb.some((b) => b.id === second.id) && rb.find((b) => b.id === ratingBlock.id).rating === '3', rb.map((b) => b.type).join(','));
    await shot(page, '07_screenC_after_save');

    // table and recommendation
    await page.locator('.sections li button', { hasText: 'D. About the property' }).click();
    const cell = page.getByLabel('Beds row 1');
    await cell.fill('9');
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    await until(async () => (await stateText(page)).trim() === 'Saved', 9000);
    rep = await serverReport(s);
    check('C: a table cell edit is saved', rep.content[1].blocks[1].table.rows[0][2] === '9');
    await shot(page, '08_screenC_table');

    // ---------- Move to another section ----------
    await page.locator('.sections li button', { hasText: 'E1. Roof coverings' }).click();
    const moveId = rb.find((b) => (b.text || '').includes('new paragraph added')).id;
    await page.locator(`[data-block-id="${moveId}"] select[aria-label="Move to another section"]`).selectOption({ label: 'H. Summary of condition' });
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    await until(async () => (await stateText(page)).trim() === 'Saved', 9000);
    rep = await serverReport(s);
    check('C: a paragraph can be moved to another section and is saved there', rep.content[5].blocks.some((b) => b.id === moveId) && !rep.content[2].blocks.some((b) => b.id === moveId));

    // ---------- Conflict ----------
    const mate = await colleague(link.rawToken);
    const target = rep.content[0].blocks[0];
    const theirs = await mate.patch(s.surveyId, { baseVersion: (await mate.read(s.surveyId)).version, changes: [{ op: 'updateBlock', sectionId: rep.content[0].id, blockId: rep.content[0].blocks[1].id, fields: { text: 'Colleague changed the loft access sentence.' } }] });
    check('Conflict setup: a colleague saved a newer version', theirs.status === 200, `status=${theirs.status} ${JSON.stringify(theirs.body).slice(0, 200)}`);
    await page.locator('.sections li button', { hasText: 'A. About the inspection' }).click();
    await page.locator(`[data-block-id="${target.id}"] .textview`).click();
    await page.keyboard.press('End');
    await page.keyboard.type(' My own addition.');
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    const dlg = page.getByRole('dialog', { name: 'Someone saved a newer version' });
    check('Conflict: a stale save opens the "newer version" explanation, never overwrites', await until(async () => dlg.isVisible(), 8000));
    check("Conflict: the dialog counts only my own change (1), not the colleague's", (await dlg.innerText()).includes("your 1 unsaved change is still here"), (await dlg.innerText()).replace(/\s+/g, " ").slice(0, 160));
    await shot(page, '09_conflict_dialog');
    const afterConflict = await serverReport(s);
    check('Conflict: the colleague change is intact on the server', afterConflict.content[0].blocks[1].text.includes('Colleague changed'));
    check('Conflict: my unsaved change is still on screen', (await page.locator(`[data-block-id="${target.id}"]`).innerText()).includes('My own addition'));
    await page.getByRole('button', { name: 'Reload and re-apply my changes' }).click();
    check('Conflict: re-apply keeps my edit on top of the newer version', await until(async () => (await page.locator(`[data-block-id="${rep.content[0].blocks[1].id}"]`).innerText()).includes('Colleague changed'), 5000));
    check('Conflict: after re-apply the save goes through', await until(async () => (await stateText(page)).trim() === 'Saved', 9000));
    rep = await serverReport(s);
    check('Conflict: server holds both my addition and the colleague change', blockByText(rep.content, 'My own addition') && blockByText(rep.content, 'Colleague changed'));

    // conflict where re-apply is impossible: colleague deletes the paragraph I edit
    const victim = rep.content[0].blocks[1];
    await page.locator(`[data-block-id="${victim.id}"] .textview`).click();
    await page.keyboard.press('End');
    await page.keyboard.type(' Late edit.');
    await mate.patch(s.surveyId, { baseVersion: (await mate.read(s.surveyId)).version, changes: [{ op: 'deleteBlock', sectionId: rep.content[0].id, blockId: victim.id }] });
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    await dlg.waitFor({ timeout: 8000 });
    await page.getByRole('button', { name: 'Reload and re-apply my changes' }).click();
    check('Conflict: when the paragraph was deleted meanwhile, it says the changes cannot be re-applied', await page.getByRole('dialog', { name: 'Your changes could not be re-applied' }).waitFor({ timeout: 5000 }).then(() => true).catch(() => false));
    await shot(page, '10_conflict_cannot_reapply');
    await page.getByRole('button', { name: 'Reload latest version' }).click();
    check('Conflict: reload latest discards my edit and shows the server copy', await until(async () => (await stateText(page)).trim() === 'Saved' && (await page.locator('.pane .block').count()) === 1, 5000), `blocks=${await page.locator('.pane .block').count()} dialogs=${JSON.stringify(await page.locator('.dialog h2').allInnerTexts())} state=${await stateText(page)} section=${await page.locator('.pane h1').innerText()}`);

    // ---------- Offline and network failure ----------
    const first = (await serverReport(s)).content[0].blocks[0];
    await page.locator(`[data-block-id="${first.id}"] .textview`).click();
    await ctx.setOffline(true);
    await page.keyboard.press('End');
    await page.keyboard.type(' Typed while offline.');
    check('Offline: the editor shows offline/unsaved and never claims Saved', await until(async () => /Offline|Unsaved|Save failed/.test(await stateText(page)), 12000), await stateText(page));
    await shot(page, '11_offline');
    check('Offline: nothing saved on the server', !blockByText((await serverReport(s)).content, 'Typed while offline'));
    await ctx.setOffline(false);
    check('Offline: after reconnecting the pending change is saved without loss', await until(async () => (await stateText(page)).trim() === 'Saved', 20000));
    { const r2 = await serverReport(s); check('Offline: the server has the text typed offline', !!blockByText(r2.content, 'Typed while offline'), `v${r2.version} text=${JSON.stringify(r2.content[0].blocks[0].text).slice(-60)} screen=${JSON.stringify((await page.locator(`[data-block-id="${first.id}"]`).innerText()).slice(-50))} state=${await stateText(page)}`); }

    // ---------- Reload with unsaved, Exit with unsaved ----------
    await ctx.setOffline(true);
    await page.keyboard.type(' More.');
    await page.getByRole('button', { name: 'Reload latest' }).click();
    const rl = page.getByRole('dialog', { name: 'Reload the latest version?' });
    check('Reload latest with unsaved edits asks first', await until(async () => rl.isVisible(), 3000));
    await shot(page, '12_reload_confirm');
    await page.getByRole('button', { name: 'Cancel' }).click();
    await page.getByRole('button', { name: 'Exit' }).click();
    const ex = page.getByRole('dialog', { name: 'You have unsaved changes' });
    check('Exit with unsaved edits asks first', await until(async () => ex.isVisible(), 3000));
    await shot(page, '13_exit_confirm');
    await page.getByRole('button', { name: 'Keep editing' }).click();
    check('Keep editing closes the exit dialog and nothing was lost', (await page.locator('.pane').innerText()).includes('More.'));
    let sawBeforeUnload = false;
    page.once('dialog', async (d) => {
      sawBeforeUnload = d.type() === 'beforeunload';
      try {
        await d.dismiss();
      } catch {
        /* already handled */
      }
    });
    await page.close({ runBeforeUnload: true }).catch(() => {});
    await sleep(500);
    check('Closing the tab with unsaved edits triggers the browser warning', sawBeforeUnload);
    await ctx.close();

    // ---------- Exit (clean), keyboard shortcuts ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    ({ ctx, page, urls, errors } = await openEditor(browser, s, link));
    await page.getByRole('button', { name: 'Continue to the editor' }).click();
    await page.locator('.workspace').waitFor();
    await page.locator('.sections li button', { hasText: 'F. Walls' }).click();
    const w = s.content[4].blocks[0];
    await page.locator(`[data-block-id="${w.id}"] .textview`).click();
    await page.keyboard.press('End');
    await page.keyboard.type(' Shortcut text.');
    await page.keyboard.press('Control+S');
    check('Ctrl+S saves', await until(async () => (await stateText(page)).trim() === 'Saved', 9000));
    await page.keyboard.type(' Undo me.');
    await page.keyboard.press('Control+Z');
    check('Ctrl+Z undoes the last typing step (and keeps the saved text)', await until(async () => { const t = await page.locator(`[data-block-id="${w.id}"]`).innerText(); return !t.includes('Undo me') && t.includes('Shortcut text'); }, 3000));
    await page.reload();
    await page.locator('.workspace').waitFor({ timeout: 15000 });
    check('Reload of /editor keeps the session and shows the report again', (await page.locator('.topbar').innerText()).includes('VL1433'));
    await page.getByRole('button', { name: 'Exit' }).click();
    check('Exit with nothing unsaved leaves at once', await page.getByRole('heading', { name: 'You have left the editor' }).waitFor({ timeout: 8000 }).then(() => true).catch(() => false));
    await shot(page, '14_exited');
    await page.goto(`${EDITOR}/editor`);
    check('After Exit the old session no longer opens the report', await page.getByRole('heading', { name: 'This link is not valid' }).waitFor({ timeout: 8000 }).then(() => true).catch(() => false));
    check('The same link still works for the next colleague', (await call(s.token, 'GET', `/reports/${s.surveyId}/edit-links/current`)).body.active === true);
    await ctx.close();

    // ---------- Expired mid-session: read-only ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    ({ ctx, page } = await openEditor(browser, s, link));
    await page.getByRole('button', { name: 'Continue to the editor' }).click();
    await page.locator('.workspace').waitFor();
    await prisma.editLink.update({ where: { id: link.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
    await page.reload();
    await page.locator('.workspace').waitFor({ timeout: 15000 });
    check('Expired link: header shows read-only and editing controls are off', (await page.locator('.topbar').innerText()).includes('Link expired, read-only') && (await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).isDisabled()));
    check('Expired link: the header says read-only once, not twice', (await page.locator('.topbar .chip', { hasText: /read-only/i }).count()) === 1);
    check('Expired link: paragraphs are not editable', await page.locator('.pane .textview').first().isDisabled());
    await shot(page, '15_expired_readonly');
    await ctx.close();

    // ---------- Link cancelled mid-session ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    ({ ctx, page } = await openEditor(browser, s, link));
    await page.getByRole('button', { name: 'Continue to the editor' }).click();
    await page.locator('.workspace').waitFor();
    await call(s.token, 'DELETE', `/reports/${s.surveyId}/edit-links/${link.linkId}`);
    await page.locator('.sections li button', { hasText: 'F. Walls' }).click();
    await page.locator(`[data-block-id="${s.content[4].blocks[0].id}"] .textview`).click();
    await page.keyboard.type('x');
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    check('Cancelled link: the next save is refused and the editor says access ended', await page.getByText('Your access to this report has ended').waitFor({ timeout: 9000 }).then(() => true).catch(() => false));
    await shot(page, '16_access_ended');
    await ctx.close();

    // ---------- Finalised ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    await prisma.report.update({ where: { id: s.surveyId }, data: { status: 'FINALISED' } });
    ({ ctx, page } = { ctx: await browser.newContext(), page: null });
    page = await ctx.newPage();
    await page.goto(`${EDITOR}/open/${link.rawToken}`);
    check('Finalised report: opening the link shows the safe "finalised" message', await page.getByRole('heading', { name: 'This report has been finalised' }).waitFor({ timeout: 10000 }).then(() => true).catch(() => false));
    await shot(page, '17_finalised');
    await ctx.close();

    // ---------- Invalid, expired, cancelled links ----------
    ctx = await browser.newContext();
    page = await ctx.newPage();
    await page.goto(`${EDITOR}/open/${'A'.repeat(43)}`);
    check('Invalid link: safe message, no report content', await page.getByRole('heading', { name: 'This link is not valid' }).waitFor({ timeout: 10000 }).then(() => true).catch(() => false) && !(await page.locator('body').innerText()).includes('Roof'));
    await shot(page, '18_invalid_link');
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    await prisma.editLink.update({ where: { id: link.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
    await page.goto(`${EDITOR}/open/${link.rawToken}`);
    check('Expired link: safe "expired" message', await page.getByRole('heading', { name: 'This link has expired' }).waitFor({ timeout: 10000 }).then(() => true).catch(() => false));
    await shot(page, '19_expired_link');
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    await call(s.token, 'DELETE', `/reports/${s.surveyId}/edit-links/${link.linkId}`);
    await page.goto(`${EDITOR}/open/${link.rawToken}`);
    check('Cancelled link: safe "no longer active" message', await page.getByRole('heading', { name: 'This link is no longer active' }).waitFor({ timeout: 10000 }).then(() => true).catch(() => false));
    await ctx.close();

    // ---------- iPad and laptop widths ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    for (const [name, vp] of [['ipad_portrait', { width: 820, height: 1180 }], ['ipad_landscape', { width: 1180, height: 820 }], ['laptop', { width: 1366, height: 768 }]]) {
      s = await seed();
      link = await newLink(s.token, s.surveyId);
      const o = await openEditor(browser, s, link, vp);
      await o.page.getByRole('button', { name: 'Continue to the editor' }).click();
      await o.page.locator('.workspace').waitFor();
      await o.page.locator('.pane .block').first().waitFor();
      const overflow = await o.page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
      check(`Layout ${name}: no horizontal page scroll`, !overflow);
      const gap = await o.page.evaluate(() => { const a = (document.querySelector('.section-select') || document.querySelector('.sections')).getBoundingClientRect(); const b = document.querySelector('.pane').getBoundingClientRect(); return Math.round(b.top - (b.left < a.right && b.top > a.bottom ? a.bottom : b.top)); });
      if (name === 'ipad_portrait') check('Layout ipad_portrait: no empty gap between the section picker and the report', gap < 40, `gap=${gap}px`);
      check(`Layout ${name}: no script errors or console errors`, o.errors.length === 0, o.errors.join(' | ').slice(0, 200));
      await shot(o.page, `20_${name}`);
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
  fs.writeFileSync(path.join(OUT, 'd2_results.json'), JSON.stringify(results, null, 1));
  process.exit(bad.length ? 1 : 0);
})();
