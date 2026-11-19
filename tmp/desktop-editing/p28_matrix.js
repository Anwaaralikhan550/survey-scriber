// Client 17 Nov 2026 (Q10): the FBS Valuation Matrix is filled by hand in the desktop browser editor. Real backend + Chrome.
// Run: NODE_PATH="E:\survey-scriber\backend\node_modules;$(npm root -g)\@playwright\mcp\node_modules" API=http://localhost:3097/api/v1 \
//      DATABASE_URL=postgresql://ss:ss_pw@127.0.0.1:15432/ss_desk?schema=public node p28_matrix.js
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');
const { prisma, owner, call, newLink } = require('./lib.js');
const { enterEditor } = require('./lib.js');

const EDITOR = process.env.EDITOR_URL || 'http://localhost:5174';
const OUT = 'E:/survey-scriber/tmp/client-edits-2026-11-17/proof';
fs.mkdirSync(OUT, { recursive: true });
let pass = 0;
let fail = 0;
const check = (name, ok, extra = '') => {
  if (ok) pass++; else fail++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  ' + extra : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(fn, ms = 9000, step = 150) {
  const end = Date.now() + ms;
  for (;;) {
    try { const v = await fn(); if (v) return v; } catch { /* retry */ }
    if (Date.now() > end) return false;
    await sleep(step);
  }
}
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `a7_${name}.png`) });

const headers = ['Best Match', 'Comp 1', 'Comp 2', 'Comp 3', 'Comp 4', 'Comp 5', 'Subject'];
const labels = ['Address', 'Date of Trans', 'Price', 'Size / Sqm', 'Bedrooms', 'Condition', 'Compare', 'Type', 'Tenure', 'Price/Sqm', 'Features', 'Adjustment', 'Amount', 'Adjustment', 'Amount', 'Adjustment', 'Amount'];

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const { user, token } = await owner();
  await prisma.survey.deleteMany({ where: { userId: user.id, title: 'MATRIX TEST' } });
  const survey = await prisma.survey.create({ data: { title: 'MATRIX TEST', propertyAddress: '54 Gas Lane, Dartford, Kent DA1 4PL', jobRef: 'VL1433', userId: user.id } });
  const matrixBlock = randomUUID();
  const content = [
    { id: randomUUID(), key: 'valuation_completion/valuation', title: 'Valuation', blocks: [{ id: randomUUID(), type: 'paragraph', role: 'phrase', text: 'Based on an analysis of recent comparable sales for similar properties in the locality, the agreed purchase price of £400,000.00 (Four Hundred Thousand Pounds) appears reasonable in current market conditions.' }] },
    { id: randomUUID(), key: 'VALUATION_MATRIX', title: 'FBS Valuation Matrix', blocks: [{ id: matrixBlock, type: 'table', role: 'matrix', required: true, table: { headers, rows: labels.map((l) => [l, '', '', '', '', '', '']) } }] },
  ];
  const up = await call(token, 'PUT', `/reports/${survey.id}/snapshot`, { reportType: 'L2', content });
  check('the phone can upload the blank matrix (role matrix is accepted)', up.status === 200, JSON.stringify(up.body).slice(0, 160));
  const link = await newLink(token, survey.id);
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('response', (r) => { if (r.url().includes('/api/') && r.status() >= 400) console.log('API', r.status(), r.url().slice(0, 90)); });
  await page.goto(`${EDITOR}/open/${link.rawToken}`);
  if (!(await page.getByRole('button', { name: 'Continue to the editor' }).waitFor({ timeout: 12000 }).then(() => true).catch(() => false))) console.log('LANDING TEXT:', (await page.locator('body').innerText()).slice(0, 300));
  await enterEditor(page);
  await page.locator('.workspace').waitFor();
  check('left navigation lists the matrix as a section', (await page.locator('.sections li button', { hasText: 'FBS Valuation Matrix' }).count()) === 1);
  await page.locator('.sections li button', { hasText: 'FBS Valuation Matrix' }).click();
  await page.locator('.pane table').waitFor();
  const ths = await page.locator('.pane table thead th').allInnerTexts();
  check('header row is Best Match, Comp 1 .. Comp 5, Subject', JSON.stringify(ths.map((x) => x.trim())) === JSON.stringify(headers), ths.join('|'));
  const rowNames = await page.locator('.pane table tbody th.rowname').allInnerTexts();
  check('the 17 row names are shown as fixed text', JSON.stringify(rowNames.map((x) => x.trim())) === JSON.stringify(labels), rowNames.join('|'));
  check('102 empty cells to type in, none for the row names', (await page.locator('.pane table tbody input').count()) === 102 && (await page.locator('.pane table tbody input').evaluateAll((els) => els.every((e) => e.value === ''))));
  check('it is a template field: it can be edited, not deleted', (await page.locator('.pane .block-table .badge').count()) === 1 && (await page.locator('.pane .block-table').getByRole('button', { name: 'Delete' }).isDisabled()));
  await shot(page, 'editor_blank');

  await page.getByLabel('Comp 1 row 1', { exact: true }).fill('12 High Street, Dartford');
  await page.getByLabel('Comp 2 row 3', { exact: true }).fill('£455,000');
  await page.getByLabel('Subject row 6', { exact: true }).fill('Good');
  await page.getByLabel('Subject row 8', { exact: true }).fill('Terrace');
  check('typing shows unsaved changes or the save in progress', await until(async () => /Unsaved|Saving/.test(await page.locator('.chip.state').innerText()), 3000) || (await page.locator('.chip.state').innerText()).trim() === 'Saved');
  check('autosave reaches Saved', await until(async () => (await page.locator('.chip.state').innerText()).trim() === 'Saved', 10000));
  let rep = (await call(token, 'POST', `/reports/${survey.id}/sync`)).body;
  const sec = rep.content.find((s) => s.key === 'VALUATION_MATRIX');
  const blk = sec && sec.blocks[0];
  check('the server holds the typed cells (version went up with each autosave)', rep.version >= 2 && blk && blk.table.rows[0][1] === '12 High Street, Dartford' && blk.table.rows[2][2] === '£455,000' && blk.table.rows[5][6] === 'Good' && blk.table.rows[7][6] === 'Terrace', `v${rep.version}`);
  check('row names, header and role are unchanged on the server', blk && JSON.stringify(blk.table.rows.map((r) => r[0])) === JSON.stringify(labels) && JSON.stringify(blk.table.headers) === JSON.stringify(headers) && blk.role === 'matrix' && blk.id === matrixBlock);
  check('nothing else was filled in: only the 4 typed cells are not empty', blk && blk.table.rows.flatMap((r) => r.slice(1)).filter((c) => c !== '').length === 4);
  await shot(page, 'editor_filled_saved');

  await page.reload();
  await page.locator('.workspace').waitFor({ timeout: 15000 }).catch(() => {});
  if (!(await page.locator('.workspace').count())) {
    await enterEditor(page).catch(() => {});
    await page.locator('.workspace').waitFor({ timeout: 15000 });
  }
  await page.locator('.sections li button', { hasText: 'FBS Valuation Matrix' }).click();
  await page.locator('.pane table').waitFor();
  check('after a reload the typed cells are still there', (await page.getByLabel('Comp 1 row 1', { exact: true }).inputValue()) === '12 High Street, Dartford' && (await page.getByLabel('Subject row 8', { exact: true }).inputValue()) === 'Terrace');

  // a hostile cell is stored as text, nothing runs
  await page.getByLabel('Comp 3 row 11', { exact: true }).fill('<img src=x onerror=alert(1)> hello');
  await until(async () => (await page.locator('.chip.state').innerText()).trim() === 'Saved', 10000);
  rep = (await call(token, 'POST', `/reports/${survey.id}/sync`)).body;
  const hostile = rep.content.find((s) => s.key === 'VALUATION_MATRIX').blocks[0].table.rows[10][3];
  check('markup in a cell is removed, the words stay', hostile.trim() === 'hello', JSON.stringify(hostile));
  check('no script error on the page', errors.length === 0, errors.join(' | ').slice(0, 200));
  console.log(`\nTOTAL pass=${pass} fail=${fail}`);
  await browser.close();
  await prisma.$disconnect();
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error('CRASH', e); process.exit(1); });
