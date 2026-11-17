// A6 Limitations, A7 FBS Valuation Matrix (app), A10 Reinstatement Value on the real web app. Screenshots + checks.
const D = 'E:/survey-scriber/tmp/client-edits-2026-11-04/deep/';
const L = require(D + 'lib');
const F = require(D + 'flut');
const { check, note, section, sleep, psql, call, apiLogin } = L;
const OUT = 'E:/survey-scriber/tmp/client-edits-2026-11-17/proof/';
const SHOT = (n) => OUT + n + '.png';
const stamp = String(Date.now()).slice(-6);
const day = (n) => { const d = new Date(); d.setDate(d.getDate() + n); return d.toISOString().slice(0, 10); };
const go = async (page, hash, wait = 4500) => {
  await page.evaluate((h) => { location.hash = h; }, hash);
  await sleep(wait);
  await F.enable(page);
  await sleep(600);
};
const labels = async (page) => (await F.nodes(page)).map((n) => n.label).filter(Boolean);
const joined = async (page) => (await labels(page)).join(' | ').replace(/\s+/g, ' ');

(async () => {
  const browser = await L.openBrowser();
  const tok = (await apiLogin('e2e.field@example.com')).accessToken;
  const me = psql("select id from users where email='e2e.field@example.com'");
  const hour = 13 + (Number(stamp) % 5);
  const vb = (await call('POST', 'scheduling/bookings', tok, {
    surveyorId: me, date: day(Number(stamp) % 700 + 5 + Math.floor(Math.random() * 500)), startTime: `${hour}:00`, endTime: `${hour + 1}:00`, surveyType: 'valuation',
    jobRef: `A6-${stamp}`, clientName: 'Grace Hill', propertyAddress: '1 High St, Leeds, LS1 4AB',
    addressLine: '1 High St', city: 'Leeds', postcode: 'LS1 4AB',
  })).data;
  check('valuation booking made', !!vb.surveyId);
  const V = vb.surveyId;
  const page = await F.openApp(browser);
  await F.login(page, 'e2e.field@example.com');
  await sleep(8000);
  const screen = async (sec, id, wait = 5000) => go(page, `#/survey/${V}/valuation/section/${sec}/screen/${id}`, wait);

  section('A6 Limitations');
  await screen('condition_restrictions', 'val_limitations');
  let s = await joined(page);
  check('Limitations screen has No Restrictions and No Rear Access ticks', s.includes('No Restrictions') && s.includes('No Rear Access'), s.slice(0, 200));
  await F.tap(page, 'No Restrictions', { wait: 800 });
  await F.enable(page);
  await page.screenshot({ path: SHOT('a6_limitations_preview') });
  await F.tap(page, 'No Rear Access', { wait: 800 });
  await page.screenshot({ path: SHOT('a6_limitations_both') });

  section('A10 Reinstatement');
  await screen('valuation_completion', 'valuation');
  await F.scrollTo(page, 'Reinstatement Value');
  await F.enable(page);
  s = await joined(page);
  check('Reinstatement Value field and Higher Reinstatement Value tick are on the Valuation screen', s.includes('Reinstatement Value') && s.includes('Higher Reinstatement Value'), s.slice(-300));
  await F.type(page, /Reinstatement Value/, '517000');
  await sleep(600);
  await F.tap(page, 'Higher Reinstatement Value', { wait: 800 });
  await F.enable(page);
  await page.screenshot({ path: SHOT('a10_reinstatement_preview') });

  section('A7 FBS Valuation Matrix');
  await screen('valuation_completion', 'valuation_matrix');
  s = await joined(page);
  check('the grid has a text box for every cell (row name, column)', ['Address, Comp 1', 'Address, Subject', 'Price/Sqm, Comp 3', 'Amount, Comp 5'].every((x) => s.includes(x)) && s.includes('FBS Valuation Matrix'), s.slice(0, 200));
  await page.screenshot({ path: SHOT('a7_matrix_blank') });
  const boxes = (await F.nodes(page)).filter((n) => n.role === 'textbox' || n.tag === 'input');
  note('text boxes on screen: ' + boxes.length + ' ' + boxes.slice(0, 3).map((b) => b.label).join(' / '));
  await F.type(page, 'Address, Comp 1', 'Flat 3, Riverside Court, 12 High Street, Dartford');
  await F.type(page, 'Price, Comp 2', '455000');
  await page.screenshot({ path: SHOT('a7_matrix_typed') });
  await F.tap(page, 'Save Draft', { wait: 1500 });
  await screen('valuation_completion', 'general_remarks', 3500);
  await screen('valuation_completion', 'valuation_matrix', 5000);
  const vals = (await F.nodes(page)).filter((n) => n.value && String(n.value).length);
  note('after leaving and coming back: read a7_matrix_after_return.png (typed cells must still be there)');
  await page.screenshot({ path: SHOT('a7_matrix_after_return') });

  L.fs.writeFileSync(OUT + 'a6_a10_state.json', JSON.stringify({ V }));
  L.finish();
  await browser.close();
})().catch((e) => { console.error('CRASH', e); L.finish(); process.exit(1); });
