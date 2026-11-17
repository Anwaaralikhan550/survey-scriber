// A2-A5, A8, A9 on the real web app: tick, then the Live Preview shows the client's sentence. Screenshots.
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
const PI = 'property_inspection';

(async () => {
  const browser = await L.openBrowser();
  const tok = (await apiLogin('e2e.field@example.com')).accessToken;
  const me = psql("select id from users where email='e2e.field@example.com'");
  const hour = 13 + (Number(stamp) % 5);
  const vb = (await call('POST', 'scheduling/bookings', tok, {
    surveyorId: me, date: day(Number(stamp) % 700 + 5 + Math.floor(Math.random() * 500)), startTime: `${hour}:00`, endTime: `${hour + 1}:00`, surveyType: 'valuation',
    jobRef: `A29-${stamp}`, clientName: 'Grace Hill', propertyAddress: '1 High St, Leeds, LS1 4AB',
    addressLine: '1 High St', city: 'Leeds', postcode: 'LS1 4AB',
  })).data;
  check('valuation booking made', !!vb.surveyId);
  const V = vb.surveyId;
  const page = await F.openApp(browser);
  await F.login(page, 'e2e.field@example.com');
  await sleep(8000);

  const screen = async (sec, id, wait = 5000) => go(page, `#/survey/${V}/valuation/section/${sec}/screen/${id}`, wait);
  const has = (s, ...xs) => xs.every((x) => s.includes(x));

  section('A2 Oil / LPG Tank');
  await screen(PI, 'val_oil_lpg');
  let s = await joined(page);
  check('screen shows the fuel, tank and place groups', has(s, 'Oil-fired', 'LPG-fired', 'plastic', 'metal', 'front garden', 'side garden', 'rear garden'), s.slice(0, 400));
  await F.tap(page, 'Oil-fired', { wait: 500 });
  await F.tap(page, 'plastic', { wait: 500 });
  await F.tap(page, 'front garden', { wait: 800 });
  await F.enable(page);
  s = await joined(page);
  note('preview (read the picture): Live Preview: the client sentence', s.includes('The property is served by an Oil-fired heating system with a plastic fuel storage tank(s) located at the front garden.'), s.slice(-300));
  await page.screenshot({ path: SHOT('a2_oil_lpg_preview') });
  await F.scrollTo(page, 'other');
  await F.enable(page);
  const others = (await F.nodes(page)).filter((n) => n.label === 'other' && n.role === 'checkbox');
  note('other ticks found: ' + others.length);
  await F.tap(page, 'other', { wait: 800, index: 0 });
  await F.enable(page);
  s = await joined(page);
  check('ticking other opens its text box', /Other \(describe\)/.test(s), s.slice(0, 300));
  await page.screenshot({ path: SHOT('a2_oil_lpg_other_box') });

  section('A3 Electricity: Dated');
  await screen(PI, 'val_electric_material');
  await F.tap(page, 'in the kitchen', { wait: 500 });
  await F.tap(page, 'Dated', { wait: 800 });
  await F.enable(page);
  s = await joined(page);
  check('Dated tick sits next to the meter location', s.indexOf('Dated') > s.indexOf('other') && s.indexOf('Dated') < s.indexOf('Rubber Cable'), s.slice(0, 300));
  note('preview (read the picture): Live Preview carries both sentences', has(s, 'the meter unit is located in the kitchen.', 'The meter unit is dated.'), s.slice(-260));
  await page.screenshot({ path: SHOT('a3_electricity_dated') });

  section('A4 Date of Extension in the Extension sentence');
  await screen('valuation_details', 'general_details', 6000);
  await F.scrollTo(page, 'side');
  await F.tap(page, 'side', { wait: 500 });
  await F.tap(page, 'rear', { wait: 500 });
  await F.type(page, /Age of Extension/, '1995');
  await sleep(800);
  await F.enable(page);
  s = await joined(page);
  note('preview (read the picture): Extension sentence has the year', s.includes('The property has been extended in 1995 to provide side and rear accommodation.'), s.slice(-300));
  await page.screenshot({ path: SHOT('a4_extension_year') });

  section('A5 three roofs');
  await screen(PI, 'val_flat_roof');
  s = await joined(page);
  check('Flat Roof offers mineral felt, rubber membrane, single-ply membrane', has(s, 'mineral felt', 'rubber membrane', 'single-ply membrane'), s.slice(0, 300));
  await F.tap(page, 'rubber membrane', { wait: 500 });
  await F.tap(page, 'single-ply membrane', { wait: 800 });
  await F.enable(page);
  s = await joined(page);
  note('preview (read the picture): Flat roof sentence', s.includes('The flat roof covering is formed in rubber membrane and single-ply membrane.'), s.slice(-250));
  await page.screenshot({ path: SHOT('a5_flat_roof') });
  await screen(PI, 'val_pitched_roof');
  s = await joined(page);
  check('Pitched Roof no longer offers the flat materials', !has(s, 'rubber membrane') && !has(s, 'single-ply membrane') && !has(s, 'mineral felt'), s.slice(0, 300));
  await page.screenshot({ path: SHOT('a5_pitched_roof') });
  await screen(PI, 'val_other_roof');
  await F.tap(page, 'natural slate', { wait: 500 });
  await F.tap(page, 'metal sheeting', { wait: 800 });
  await F.enable(page);
  s = await joined(page);
  note('preview (read the picture): Other roof sentence', s.includes('The other roof covering is formed in natural slate and metal sheeting.'), s.slice(-250));
  await page.screenshot({ path: SHOT('a5_other_roof') });

  section('A8 Rainwater Goods');
  await screen(PI, 'val_rainwater_goods');
  s = await joined(page);
  check('no "associated fittings" tick', !s.includes('associated fittings'), s.slice(0, 300));
  await F.tap(page, 'PVC', { wait: 500 });
  await F.tap(page, 'gutters', { wait: 500 });
  await F.tap(page, 'downpipes', { wait: 800 });
  await F.enable(page);
  s = await joined(page);
  note('preview (read the picture): Rainwater sentence ends with the fixed text', s.includes('The rainwater goods comprise PVC, gutters, downpipes, and associated fittings.'), s.slice(-250));
  await page.screenshot({ path: SHOT('a8_rainwater') });

  section('A9 Significant Valuation Consideration, Timber Defects');
  await screen('condition_restrictions', 'val_sv_timber');
  s = await joined(page);
  check('two ticks Dry Rot and Wet Rot', has(s, 'Extensive Dry Rot', 'Extensive Wet Rot'), s.slice(0, 300));
  await F.tap(page, 'Extensive Dry Rot', { wait: 500 });
  await F.tap(page, 'Extensive Wet Rot', { wait: 800 });
  await F.enable(page);
  s = await joined(page);
  note('preview (read the picture): both print', s.includes('Extensive Dry Rot and Extensive Wet Rot.'), s.slice(-250));
  await page.screenshot({ path: SHOT('a9_timber_defects') });

  L.fs.writeFileSync(OUT + 'a2_a9_state.json', JSON.stringify({ V }));
  L.finish();
  await browser.close();
})().catch((e) => { console.error('CRASH', e); L.finish(); process.exit(1); });
