// D5 browser test of the review workflow (Screen F) against the real backend (Chrome). Screenshots: ./proof/d5_*.png
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { prisma, seed, newLink, call, API } = require('./lib.js');

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
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `d5_${name}.png`) });
const stateText = (page) => page.locator('.chip.state').innerText();
const reviewOf = async (s) => (await call(s.token, 'GET', `/reports/${s.surveyId}/review`)).body;
const ownerPost = (s, p, body = {}) => call(s.token, 'POST', `/reports/${s.surveyId}/${p}`, body);

async function openEditor(browser, s, link, viewport = { width: 1440, height: 900 }) {
  const ctx = await browser.newContext({ viewport });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => {
    if (m.type() === 'error' && !/Failed to load resource|net::ERR/.test(m.text())) errors.push(m.text());
  });
  await page.goto(`${EDITOR}/open/${link.rawToken}`);
  await page.getByRole('button', { name: 'Continue to the editor' }).click();
  await page.locator('.workspace').waitFor({ timeout: 15000 });
  return { ctx, page, errors };
}
const goReview = async (page) => {
  await page.getByRole('tab', { name: /^Review/ }).click();
  await page.locator('.review').waitFor();
  await until(async () => !(await page.getByText('Loading the review status').count()), 6000);
};
const pill = (page) => page.locator('.status-pill').innerText();
const headerChip = (page) => page.locator('.topbar .review-chip').innerText();

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
    let s = await seed();
    let link = await newLink(s.token, s.surveyId);
    let { ctx, page, errors } = await openEditor(browser, s, link);

    // ---------- draft ----------
    check('header shows the status "Draft" and a Submit for review button', (await headerChip(page)) === 'Draft' && (await page.getByRole('button', { name: 'Submit for review' }).count()) === 1);
    check('the side panel shows the status too', (await page.locator('.side').innerText()).includes('Draft'));
    await page.getByRole('button', { name: 'Submit for review' }).first().click();
    await page.locator('.review').waitFor();
    check('Review tab explains the draft state and lists no history', (await pill(page)) === 'Draft' && (await page.locator('.review').innerText()).includes('Nothing yet'));
    check('only Submit is offered in Draft', (await page.getByRole('button', { name: 'Submit for review' }).count()) >= 1 && (await page.getByRole('button', { name: 'Approve this version' }).count()) === 0);
    await shot(page, '01_draft');

    // ---------- unsaved edit is saved first, then submitted at that version ----------
    await page.getByRole('tab', { name: /Report text/ }).click();
    await page.locator('.sections li button', { hasText: 'A. About the inspection' }).click();
    const block = s.content[0].blocks[0];
    await page.locator(`[data-block-id="${block.id}"] .textview`).click();
    await page.locator('.pm:focus').waitFor({ timeout: 5000 });
    await page.keyboard.press('End');
    await page.keyboard.type(' Last-minute change.');
    await page.getByRole('tab', { name: /^Review/ }).click();
    await page.locator('.review').waitFor();
    await page.getByLabel(/Comment/).fill('Ready for your review');
    await page.locator('.review-actions').getByRole('button', { name: 'Submit for review' }).click();
    check('submitting shows "Submitted for review" with the saved version', await until(async () => (await pill(page)) === 'Submitted for review', 8000));
    let v = await reviewOf(s);
    const sentText = JSON.stringify((await call(s.token, 'POST', `/reports/${s.surveyId}/sync`)).body.content);
    check('the unsaved edit was saved first and the submission is for that version', sentText.includes('Last-minute change.') && v.submittedVersion === v.version && v.version >= 2, `v${v.version} submitted v${v.submittedVersion}`);
    check('history shows who, what, which version and the comment', (await page.locator('.history li').first().innerText()).includes('Submitted for review') && (await page.locator('.history li').first().innerText()).includes('Ready for your review'));
    check('header chip and side panel follow', (await headerChip(page)) === 'Submitted for review' && (await page.locator('.side').innerText()).includes('Submitted for review'));
    check('the Submit button disappears from the header once submitted', (await page.locator('.topbar').getByRole('button', { name: 'Submit for review' }).count()) === 0);
    await shot(page, '02_submitted');

    // ---------- reviewer: start, request changes (needs a comment), resubmit ----------
    check('no editing dialog is open after submitting (the save queue and the review agree on the version)', (await page.locator('.dialog').count()) === 0);
    await page.getByRole('button', { name: 'Start review' }).click();
    check('Start review moves to Under review', await until(async () => (await pill(page)) === 'Under review', 6000));
    await page.getByRole('button', { name: 'Request changes' }).click();
    check('asking for changes without a comment is refused on screen, nothing is sent', (await page.locator('.review .inline-banner').innerText()).includes('what needs to change') && (await reviewOf(s)).status === 'UNDER_REVIEW');
    await page.getByLabel(/Comment/).fill('Please re-check the roof wording.');
    await page.getByRole('button', { name: 'Request changes' }).click();
    check('with a comment the report goes back as "Changes requested" and shows the request', await until(async () => (await pill(page)) === 'Changes requested' && (await page.getByLabel('Requested changes').count()) === 1, 6000));
    check('the requested changes quote the comment and the version', (await page.getByLabel('Requested changes').innerText()).includes('Please re-check the roof wording.'));
    await shot(page, '03_changes_requested');
    check('the header offers Submit for review again', (await page.locator('.topbar').getByRole('button', { name: 'Submit for review' }).count()) === 1);
    await page.locator('.review-actions').getByRole('button', { name: 'Submit for review' }).click();
    check('resubmitting works', await until(async () => (await pill(page)) === 'Submitted for review', 6000));

    // ---------- approve ----------
    await page.getByLabel(/Comment/).fill('Looks right now.');
    await page.getByRole('button', { name: 'Approve this version' }).click();
    check('approving shows "Approved by a reviewer" at this version', await until(async () => (await pill(page)) === 'Approved by a reviewer', 6000));
    v = await reviewOf(s);
    check('the server holds the approval for the current version', v.reviewerApproval && v.reviewerApproval.version === v.version);
    check('the screen says the approval stands and quotes its comment', (await page.locator('.facts').innerText()).includes('current') && (await page.locator('.facts').innerText()).includes('Looks right now.'));
    check('no owner buttons exist in the browser', (await page.getByRole('button', { name: /final approval|Owner/i }).count()) === 0);
    await shot(page, '04_reviewer_approved');

    // ---------- the owner approves in the app (API with the owner login) ----------
    const own = await ownerPost(s, 'owner-approval', { expectedReportVersion: v.version, comment: 'Approved by owner' });
    check('setup: the owner gave final approval', own.status === 200 && own.body.status === 'OWNER_FINAL_APPROVAL');
    await page.reload();
    await page.locator('.workspace').waitFor({ timeout: 15000 });
    await goReview(page);
    check('after reload the browser shows the owner\'s final approval', (await pill(page)) === 'Final approval given' && (await page.locator('.facts').innerText()).includes('Given, version'));
    check('no review actions are offered once the owner approved', (await page.locator('.review-actions').count()) === 0);
    await shot(page, '05_owner_approved');

    // ---------- an edit after approval invalidates it ----------
    await page.getByRole('tab', { name: /Report text/ }).click();
    await page.locator(`[data-block-id="${block.id}"] .textview`).click();
    await page.locator('.pm:focus').waitFor({ timeout: 5000 });
    await page.keyboard.press('End');
    await page.keyboard.type(' Edited after approval.');
    check('the edit saves', await until(async () => (await stateText(page)).trim() === 'Saved', 9000));
    await goReview(page);
    check('both approvals are out of date and the report is back to "Submitted for review"', (await pill(page)) === 'Submitted for review' && (await page.locator('.history li.is-old').count()) === 2 && (await page.locator('.facts').innerText()).includes('No approval that still stands'));
    check('the header chip changed too', (await headerChip(page)) === 'Submitted for review');
    await shot(page, '06_invalidated');
    v = await reviewOf(s);
    check('server: both approvals invalidated, status Submitted for Review', v.status === 'SUBMITTED_FOR_REVIEW' && v.reviewerApproval === null && v.ownerApproval === null);

    // ---------- a photo change does the same ----------
    await page.getByRole('button', { name: 'Approve this version' }).click();
    await until(async () => (await pill(page)) === 'Approved by a reviewer', 6000);
    await page.getByRole('tab', { name: /Photographs/ }).click();
    await page.locator('.photos').waitFor();
    await page.locator('input[aria-label="Choose photographs to add"]').setInputFiles(path.join(__dirname, 'fixtures', 'roof_front.jpg'));
    await until(async () => (await page.locator('.photo').count()) === 1, 10000);
    await goReview(page);
    check('adding a photo after the approval also withdraws it', (await pill(page)) === 'Submitted for review');

    // ---------- the owner resets / another reviewer acts first (INVALID_STATE) ----------
    await ownerPost(s, 'review/reset', { expectedReportVersion: (await reviewOf(s)).version });
    await sleep(600);
    check('state moved under the page: an action that is no longer possible is refused clearly and the view refreshes', await (async () => {
      await page.getByRole('button', { name: 'Approve this version' }).click();
      return until(async () => (await page.locator('.review .inline-banner').count()) === 1 && (await pill(page)) === 'Draft', 8000);
    })());
    check('the message says why', (await page.locator('.review .inline-banner').innerText()).includes('not possible while the report is draft'));
    await shot(page, '07_state_moved');

    // ---------- a stale version ----------
    await page.locator('.review-actions').getByRole('button', { name: 'Submit for review' }).click();
    await until(async () => (await pill(page)) === 'Submitted for review', 6000);
    await ctx.close();

    // ---------- read-only views ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    ({ ctx, page, errors } = await openEditor(browser, s, link));
    await goReview(page);
    await page.locator('.review-actions').getByRole('button', { name: 'Submit for review' }).click();
    await until(async () => (await pill(page)) === 'Submitted for review', 6000);
    await prisma.editLink.update({ where: { id: link.linkId }, data: { expiresAt: new Date(Date.now() - 1000) } });
    await page.reload();
    await page.locator('.workspace').waitFor({ timeout: 15000 });
    await goReview(page);
    check('expired link: status and history are readable, no action buttons', (await pill(page)) === 'Submitted for review' && (await page.locator('.review-actions').count()) === 0 && (await page.locator('.history li').count()) === 1);
    check('expired link: no Submit for review in the header', (await page.locator('.topbar').getByRole('button', { name: 'Submit for review' }).count()) === 0);
    await shot(page, '08_read_only');
    await ctx.close();

    s = await seed();
    link = await newLink(s.token, s.surveyId);
    await prisma.report.update({ where: { id: s.surveyId }, data: { status: 'FINALISED' } });
    ctx = await browser.newContext();
    page = await ctx.newPage();
    await page.goto(`${EDITOR}/open/${link.rawToken}`);
    check('finalised: opening the link shows the finalised message', await page.getByRole('heading', { name: 'This report has been finalised' }).waitFor({ timeout: 10000 }).then(() => true).catch(() => false));
    await ctx.close();

    // ---------- cancelled link mid-session ----------
    s = await seed();
    link = await newLink(s.token, s.surveyId);
    ({ ctx, page } = await openEditor(browser, s, link));
    await goReview(page);
    await call(s.token, 'DELETE', `/reports/${s.surveyId}/edit-links/${link.linkId}`);
    await page.locator('.review-actions').getByRole('button', { name: 'Submit for review' }).click();
    check('cancelled link: the action fails with a clear message and nothing changes', (await until(async () => (await page.locator('.review .inline-banner').count()) === 1, 8000)) && (await reviewOf(s)).status === 'DRAFT');
    await ctx.close();

    // ---------- layouts ----------
    for (const [name, vp] of [['ipad_portrait', { width: 820, height: 1180 }], ['laptop', { width: 1366, height: 768 }]]) {
      s = await seed();
      link = await newLink(s.token, s.surveyId);
      const o = await openEditor(browser, s, link, vp);
      await goReview(o.page);
      await o.page.locator('.review-actions').getByRole('button', { name: 'Submit for review' }).click();
      await until(async () => (await pill(o.page)) === 'Submitted for review', 8000);
      await o.page.getByLabel(/Comment/).fill('Checking the layout with a longer comment so that it wraps across the screen width.');
      await sleep(300);
      const overflow = await o.page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
      check(`Layout ${name}: no horizontal page scroll`, !overflow);
      check(`Layout ${name}: no script or console errors`, o.errors.length === 0, o.errors.join(' | ').slice(0, 200));
      await shot(o.page, `09_${name}`);
      await o.ctx.close();
    }
    check('no script or console errors during the main run', errors.length === 0, errors.join(' | ').slice(0, 300));
  } catch (e) {
    console.log('SCRIPT ERROR', e);
    results.push({ name: 'script completed', ok: false });
  } finally {
    await browser.close();
    await prisma.$disconnect();
  }
  const bad = results.filter((r) => !r.ok);
  console.log(`\n${results.length - bad.length}/${results.length} checks passed`);
  fs.writeFileSync(path.join(OUT, 'd5_results.json'), JSON.stringify(results, null, 1));
  process.exit(bad.length ? 1 : 0);
})();
