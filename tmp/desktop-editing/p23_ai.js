// D6 browser test of AI wording suggestions (Screen E) against the real backend (Chrome) and a fake Gemini server
// (fake_gemini.js on :4799, backend started with GEMINI_API_BASE_URL). Screenshots: ./proof/d6_*.png
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');
const { prisma, owner, newLink, call } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const FAKE = 'http://127.0.0.1:4799';
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
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `d6_${name}.png`) });

const ids = { a: randomUUID(), b: randomUUID(), c: randomUUID(), d: randomUUID(), e: randomUUID(), rec: randomUUID(), rating: randomUUID(), table: randomUUID() };
const TEXT = {
  a: 'The roof has 12 slipped tiles and the ridge is in poor condition.',
  b: 'Call the vendor on 07700 900123 about access.',
  c: 'The roof WARN has 12 slipped tiles.',
  d: 'BREAK this text about the roof.',
  e: 'DOWN the model is down for this one.',
  rec: 'Have a roofer repair the ridge within 12 months.',
};

async function seedAi() {
  const { user, token } = await owner('desk.ai@example.com');
  await prisma.survey.deleteMany({ where: { userId: user.id, title: 'DESK AI TEST' } });
  const survey = await prisma.survey.create({ data: { title: 'DESK AI TEST', propertyAddress: '54 Gas Lane, Dartford, Kent DA1 4PL', jobRef: 'VL1433', userId: user.id } });
  const para = (id, text) => ({ id, type: 'paragraph', text });
  const content = [
    {
      id: randomUUID(),
      key: 'E1_ROOF',
      title: 'E1. Roof coverings',
      blocks: [
        para(ids.a, TEXT.a),
        para(ids.b, TEXT.b),
        para(ids.c, TEXT.c),
        para(ids.d, TEXT.d),
        para(ids.e, TEXT.e),
        { id: ids.rating, type: 'rating', rating: '2', required: true },
        { id: ids.rec, type: 'recommendation', recommendation: TEXT.rec },
        { id: ids.table, type: 'table', table: { headers: ['Floor', 'Beds'], rows: [['Ground', '0']] } },
      ],
    },
  ];
  const up = await call(token, 'PUT', `/reports/${survey.id}/snapshot`, { reportType: 'L2', content });
  if (up.status !== 200) throw new Error('snapshot failed ' + JSON.stringify(up.body));
  return { token, surveyId: survey.id };
}

async function openEditor(browser, link, viewport = { width: 1440, height: 900 }) {
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

const block = (page, id) => page.locator(`.block[data-block-id="${id}"]`);
const suggestBtn = (page, id) => block(page, id).getByRole('button', { name: 'Suggest wording with AI' });
const dialog = (page) => page.getByRole('dialog', { name: 'AI wording suggestion' });
const serverBlock = async (s, id) => {
  const r = await prisma.report.findUniqueOrThrow({ where: { id: s.surveyId } });
  const b = r.content.flatMap((x) => x.blocks).find((x) => x.id === id);
  return { version: r.version, text: b.text ?? b.recommendation };
};
const audit = (s, action) => prisma.auditLog.findMany({ where: { entityId: s.surveyId, action }, orderBy: { createdAt: 'asc' } });
const prompts = async () => (await fetch(`${FAKE}/__prompts`)).json();

async function ask(page, id, action) {
  await suggestBtn(page, id).click();
  await dialog(page).waitFor();
  await dialog(page).locator(`[data-action="${action}"]`).click();
}
const resultReady = (page) => until(async () => (await dialog(page).getByRole('button', { name: 'Accept' }).count()) > 0, 20000);

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
    await fetch(`${FAKE}/__prompts`, { method: 'DELETE' });
    const s = await seedAi();
    const link = await newLink(s.token, s.surveyId);
    const { ctx, page, errors } = await openEditor(browser, link);

    // ---- where the button is offered ----
    await page.getByRole('heading', { name: 'E1. Roof coverings' }).waitFor();
    for (const k of ['a', 'b', 'c', 'd', 'e', 'rec']) check(`Suggest wording is offered on text block ${k}`, (await suggestBtn(page, ids[k]).count()) === 1);
    check('no AI button on a condition rating', (await suggestBtn(page, ids.rating).count()) === 0);
    check('no AI button on a table', (await suggestBtn(page, ids.table).count()) === 0);
    const v0 = (await serverBlock(s, ids.a)).version;

    // ---- choose an action ----
    await suggestBtn(page, ids.a).click();
    await dialog(page).waitFor();
    check('notice says AI only rewords, can be wrong, never changes ratings', /only rewords[\s\S]*mistakes[\s\S]*Ratings are never changed/.test(await dialog(page).innerText()));
    const labels = await dialog(page).locator('.ai-action strong').allInnerTexts();
    check('five actions offered', labels.length === 5 && labels.includes('Improve wording') && labels.includes('Fix spelling and grammar'), labels.join(', '));
    await shot(page, '01_choose');

    // ---- result: diff, nothing applied yet ----
    await dialog(page).locator('[data-action="IMPROVE"]').click();
    check('result arrives', await resultReady(page));
    const dtext = await dialog(page).innerText();
    check('both texts shown side by side', /your text/i.test(dtext) && /suggestion/i.test(dtext) && dtext.includes(TEXT.a));
    check('the new wording is marked', (await dialog(page).locator('.ai-compare ins').count()) > 0);
    check('no warnings for a faithful rewording', (await dialog(page).locator('.ai-warnings').count()) === 0);
    await shot(page, '02_result');
    let sb = await serverBlock(s, ids.a);
    check('nothing is applied while the dialog is open', sb.text === TEXT.a && sb.version === v0);
    check('the editor text is unchanged too', (await block(page, ids.a).locator('.textview').innerText()) === TEXT.a);

    // ---- reject ----
    await dialog(page).getByRole('button', { name: 'Reject' }).click();
    await until(async () => (await dialog(page).count()) === 0);
    sb = await serverBlock(s, ids.a);
    check('Reject closes the dialog and changes nothing', sb.text === TEXT.a && sb.version === v0 && (await block(page, ids.a).locator('.textview').innerText()) === TEXT.a);
    check('the rejection is logged', await until(async () => (await audit(s, 'AI_SUGGESTION_REJECTED')).length === 1));

    // ---- accept ----
    await ask(page, ids.a, 'IMPROVE');
    await resultReady(page);
    await dialog(page).getByRole('button', { name: 'Accept' }).click();
    await until(async () => (await dialog(page).count()) === 0);
    const suggestionA = 'The roof has 12 slipped tiles, and the ridge is in poor condition.';
    check('Accept puts the suggestion into the paragraph', (await block(page, ids.a).locator('.textview').innerText()) === suggestionA);
    check('and it is saved like any other edit (version moves, text saved)', await until(async () => {
      const x = await serverBlock(s, ids.a);
      return x.text === suggestionA && x.version === v0 + 1;
    }));
    await shot(page, '03_accepted');
    const acc = await audit(s, 'AI_SUGGESTION_ACCEPTED');
    check('acceptance logged with lengths only', acc.length === 1 && acc[0].metadata.finalLength === suggestionA.length && !JSON.stringify(acc[0].metadata).includes('slipped'));
    await page.keyboard.press('Control+z');
    check('Undo brings the old wording back (it is an ordinary edit)', await until(async () => (await block(page, ids.a).locator('.textview').innerText()) === TEXT.a));
    await page.keyboard.press('Control+y');
    await page.waitForTimeout(300);
    await page.getByRole('button', { name: 'SAVE TO SURVEYSCRIBER' }).click();
    await until(async () => (await page.locator('.chip.state').innerText()) === 'Saved');

    // ---- personal data does not reach the model ----
    await fetch(`${FAKE}/__prompts`, { method: 'DELETE' });
    await ask(page, ids.b, 'FORMAL');
    await resultReady(page);
    const sent = (await prompts()).map((p) => p.user).join('\n');
    check('the model got a placeholder, not the phone number', sent.includes('[PHONE_1]') && !sent.includes('07700'));
    const bText = await dialog(page).innerText();
    check('the phone number is back in the suggestion shown to the surveyor', bText.includes('07700 900123'));
    check('and no warning is raised for it', (await dialog(page).locator('.ai-warnings').count()) === 0);
    const p0 = (await prompts())[0];
    check('the model is told to keep facts, never invent ratings', /Do not add any fact/.test(p0.system) && /Never change or invent a condition rating/.test(p0.system) && /Section: E1\. Roof coverings/.test(p0.user));
    await dialog(page).getByRole('button', { name: 'Accept' }).click();
    await until(async () => (await dialog(page).count()) === 0);
    check('accepted wording kept the number', await until(async () => (await serverBlock(s, ids.b)).text === 'Please call the vendor on 07700 900123 about access.'));

    // ---- fact warnings + copy and modify ----
    await ask(page, ids.c, 'IMPROVE');
    await resultReady(page);
    const w = await dialog(page).locator('.ai-warnings').innerText();
    check('new figure is flagged', /New figure: 20/.test(w));
    check('missing figure is flagged', /missing: 12/.test(w));
    check('new severity wording is flagged', /"serious"/.test(w) && /"structural"/.test(w));
    check('the warning asks to check against notes', /Check these against your notes/.test(w));
    await shot(page, '04_warnings');
    await dialog(page).getByRole('button', { name: 'Copy and modify' }).click();
    const area = dialog(page).getByLabel('Edit the suggestion');
    check('Copy and modify opens an editable copy of the suggestion', (await area.inputValue()).includes('serious structural'));
    const mine = 'The roof has 12 slipped tiles at the rear.';
    await area.fill(mine);
    await shot(page, '05_modify');
    await dialog(page).getByRole('button', { name: 'Use my edited version' }).click();
    await until(async () => (await dialog(page).count()) === 0);
    check('own edited version is what gets saved', await until(async () => (await serverBlock(s, ids.c)).text === mine));
    const mod = await audit(s, 'AI_SUGGESTION_ACCEPTED_MODIFIED');
    check('logged as accepted-modified, with the final length', mod.length === 1 && mod[0].metadata.finalLength === mine.length);

    // ---- recommendation block ----
    await ask(page, ids.rec, 'PLAIN');
    await resultReady(page);
    await dialog(page).getByRole('button', { name: 'Accept' }).click();
    await until(async () => (await dialog(page).count()) === 0);
    check('recommendations are suggested for and saved in their own field', await until(async () => (await serverBlock(s, ids.rec)).text === 'A roofer should repair the ridge within 12 months.'));

    // ---- guard: the model tries to write a rating ----
    await ask(page, ids.d, 'IMPROVE');
    await until(async () => (await dialog(page).locator('[role="alert"]').count()) > 0, 20000);
    const g = await dialog(page).locator('[role="alert"]').innerText();
    check('an answer that writes a rating is not shown; the report is untouched', /tried to write a condition rating/.test(g) && /unchanged/.test(g) && (await serverBlock(s, ids.d)).text === TEXT.d);
    await shot(page, '06_guard');
    await dialog(page).getByRole('button', { name: 'Try again' }).click();
    check('Try again returns to the choice of actions', (await dialog(page).locator('.ai-action').count()) === 5);
    await page.keyboard.press('Escape');
    check('Escape closes the dialog', await until(async () => (await dialog(page).count()) === 0));

    // ---- AI down ----
    await ask(page, ids.e, 'IMPROVE');
    await until(async () => (await dialog(page).locator('[role="alert"]').count()) > 0, 40000);
    const down = await dialog(page).locator('[role="alert"]').innerText();
    check('when the AI is down the surveyor is told plainly and can carry on by hand', /not available right now/.test(down) && /unchanged|edit it by hand/.test(down));
    await shot(page, '07_unavailable');
    await dialog(page).getByRole('button', { name: 'Close' }).click();
    check('the text is still editable after a failure', (await block(page, ids.e).locator('.textview').isEnabled()));
    check('failure is logged without text', (await audit(s, 'AI_SUGGESTION_FAILED')).length >= 1);

    // ---- audit trail holds no report text ----
    const rows = await prisma.auditLog.findMany({ where: { entityId: s.surveyId, action: { startsWith: 'AI_SUGGESTION' } } });
    const blob = JSON.stringify(rows.map((r) => r.metadata));
    check('no report text, phone number or answer in any AI audit row', !/slipped|07700|roofer|Please call/.test(blob), `${rows.length} rows`);

    // ---- iPad ----
    await ctx.close();
    const ip = await openEditor(browser, link, { width: 820, height: 1180 });
    await ip.page.getByRole('heading', { name: 'E1. Roof coverings' }).waitFor();
    await suggestBtn(ip.page, ids.rec).click();
    await dialog(ip.page).waitFor();
    await dialog(ip.page).locator('[data-action="SHORTEN"]').click();
    await resultReady(ip.page);
    await shot(ip.page, '08_ipad_portrait');
    check('dialog fits an iPad without sideways scrolling', await ip.page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1));
    await ip.page.keyboard.press('Escape');
    await ip.ctx.close();

    // ---- read-only: finalised ----
    const ro = await openEditor(browser, link); // a session that was open when the owner finalised
    await prisma.report.update({ where: { id: s.surveyId }, data: { status: 'FINALISED' } });
    await ro.page.reload();
    const cont = ro.page.getByRole('button', { name: 'Continue to the editor' });
    await Promise.race([cont.waitFor({ timeout: 8000 }).then(() => cont.click()), ro.page.locator('.workspace').waitFor({ timeout: 8000 })]).catch(() => {});
    await ro.page.locator('.workspace').waitFor({ timeout: 15000 });
    check('finalised report: no AI buttons at all', (await ro.page.locator('button[aria-label="Suggest wording with AI"]').count()) === 0);
    await shot(ro.page, '09_readonly');
    const direct = await ro.page.evaluate(async ({ id, block, csrf }) => {
      const r = await fetch(`/api/v1/editor/reports/${id}/ai/suggest`, { method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf }, body: JSON.stringify({ blockId: block, action: 'IMPROVE', expectedReportVersion: 1 }) });
      return r.status;
    }, { id: s.surveyId, block: ids.a, csrf: await ro.page.evaluate(() => sessionStorage.getItem('ss_editor_csrf')) });
    check('and the server refuses a direct request too', direct === 403, `status ${direct}`);
    await ro.ctx.close();

    check('no page errors', errors.length === 0, errors.join(' | '));
  } finally {
    await browser.close();
    await prisma.$disconnect();
  }
  const failed = results.filter((r) => !r.ok);
  fs.writeFileSync(path.join(OUT, 'd6_results.json'), JSON.stringify(results, null, 2));
  console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
