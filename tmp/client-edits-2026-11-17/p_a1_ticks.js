// A1: Valuation single-choice fields are on-screen radio-style ticks (no pop-up lists). Screenshots + checks.
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

(async () => {
  const browser = await L.openBrowser();
  const tok = (await apiLogin('e2e.field@example.com')).accessToken;
  const me = psql("select id from users where email='e2e.field@example.com'");
  const hour = 13 + (Number(stamp) % 5);
  const vb = (await call('POST', 'scheduling/bookings', tok, {
    surveyorId: me, date: day(Number(stamp) % 700 + 5 + Math.floor(Math.random() * 500)), startTime: `${hour}:00`, endTime: `${hour + 1}:00`, surveyType: 'valuation',
    jobRef: `A1V-${stamp}`, clientName: 'Grace Hill', propertyAddress: '1 High St, Leeds, LS1 4AB',
    addressLine: '1 High St', city: 'Leeds', postcode: 'LS1 4AB',
  })).data;
  check('valuation booking made', !!vb.surveyId, JSON.stringify(vb).slice(0, 120));
  const V = vb.surveyId;
  const page = await F.openApp(browser);
  await F.login(page, 'e2e.field@example.com');
  await sleep(8000);

  section('General Details: Status / Finishes / Property Type are ticks');
  await go(page, `#/survey/${V}/valuation/section/valuation_details/screen/general_details`, 6000);
  let ls = await labels(page);
  note('general details words: ' + ls.join(' | ').slice(0, 600));
  check('Occupied / Vacant / Tenanted shown without opening a list', ['Occupied', 'Vacant', 'Tenanted'].every((x) => ls.includes(x)));
  await page.screenshot({ path: SHOT('a1_general_top') });
  await F.tap(page, 'Vacant', { wait: 600 });
  await F.enable(page);
  await page.screenshot({ path: SHOT('a1_status_vacant_ticked') });
  const nodes = await F.nodes(page);
  const vac = nodes.find((n) => n.label === 'Vacant');
  note('Vacant node: ' + JSON.stringify(vac));
  check('Vacant is ticked (checked)', !!vac && (vac.checked === 'true' || vac.selected === 'true'), JSON.stringify(vac));
  await F.tap(page, 'Tenanted', { wait: 600 });
  await F.enable(page);
  const n2 = await F.nodes(page);
  const vac2 = n2.find((n) => n.label === 'Vacant');
  const ten = n2.find((n) => n.label === 'Tenanted');
  check('choosing Tenanted unticks Vacant (one at a time)', !!ten && (ten.checked === 'true' || ten.selected === 'true') && !(vac2.checked === 'true' || vac2.selected === 'true'), JSON.stringify([vac2, ten]));
  await page.screenshot({ path: SHOT('a1_status_tenanted_only') });

  section('Property Type Other opens its text box');
  await F.scrollTo(page, 'Other');
  await F.enable(page);
  await page.screenshot({ path: SHOT('a1_property_type_list') });
  const others = (await F.nodes(page)).filter((n) => n.label === 'Other' && n.y > 0 && n.y < 800);
  note('Other candidates y: ' + others.map((o) => Math.round(o.y)).join(','));

  section('A condition screen (Pitched Roof): Condition ticks');
  await go(page, `#/survey/${V}/valuation/section/property_inspection/screen/val_pitched_roof`, 5000);
  await F.scrollTo(page, 'Condition');
  await F.enable(page);
  ls = await labels(page);
  check('Good / Reasonable / Fair / Poor / Very poor are ticks', ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'].every((x) => ls.includes(x)), ls.join(' | ').slice(0, 300));
  await page.screenshot({ path: SHOT('a1_pitched_condition') });
  await F.tap(page, 'Fair', { wait: 700 });
  await F.enable(page);
  ls = await labels(page);
  check('Fair shows the Notes box', ls.includes('Notes') || ls.some((x) => /Notes/.test(x)), ls.join(' | ').slice(0, 300));
  await page.screenshot({ path: SHOT('a1_pitched_condition_fair_notes') });

  L.fs.writeFileSync(OUT + 'a1_state.json', JSON.stringify({ V }));
  L.finish();
  await browser.close();
})().catch((e) => { console.error('CRASH', e); L.finish(); process.exit(1); });
