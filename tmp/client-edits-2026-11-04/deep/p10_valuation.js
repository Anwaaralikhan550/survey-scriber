// Valuation Nov-13: open valuation screens in the real web app and screenshot them.
// usage: node p10_valuation.js <tag> <section>:<screen> [<section>:<screen> ...]
// Proof goes to tmp/client-edits-2026-11-13/proof/<tag>_<screen>.png. Prints the visible words of each screen.
const L = require('./lib');
const F = require('./flut');
const { sleep, psql, call, apiLogin } = L;
const OUT = L.path.join(L.ROOT, '..', 'client-edits-2026-11-13', 'proof');
L.fs.mkdirSync(OUT, { recursive: true });
const STATE = L.path.join(L.ROOT, '..', 'client-edits-2026-11-13', 'harness_survey.json');
const day = (n) => { const d = new Date(); d.setDate(d.getDate() + n); return d.toISOString().slice(0, 10); };

(async () => {
  const [tag, ...targets] = process.argv.slice(2);
  const tok = (await apiLogin('e2e.field@example.com')).accessToken;
  let id;
  if (L.fs.existsSync(STATE)) id = JSON.parse(L.fs.readFileSync(STATE, 'utf8')).id;
  if (!id) {
    const me = psql("select id from users where email='e2e.field@example.com'");
    const stamp = String(Date.now()).slice(-6);
    const b = (await call('POST', 'scheduling/bookings', tok, {
      surveyorId: me, date: day(5 + (Number(stamp) % 40)), startTime: '09:00', endTime: '10:00', surveyType: 'valuation',
      jobRef: `VL${stamp}`, clientName: 'Dan Baker', propertyAddress: '54 Gas Lane, Dartford, Kent, DA2 5TT',
      addressLine: '54 Gas Lane', city: 'Dartford', postcode: 'DA2 5TT',
    })).data;
    id = b.surveyId;
    L.fs.writeFileSync(STATE, JSON.stringify({ id }));
    console.log('created valuation survey', id, JSON.stringify(b).slice(0, 120));
  }
  const browser = await L.openBrowser();
  const page = await F.openApp(browser);
  await F.login(page, 'e2e.field@example.com');
  await sleep(14000);
  for (const t of targets) {
    const [sec, screen] = t.split(':');
    await page.evaluate((h) => { location.hash = h; }, `#/survey/${id}/valuation/section/${sec}/screen/${screen}`);
    await sleep(3200);
    await F.enable(page);
    const words = (await F.nodes(page)).map((n) => n.label).filter(Boolean);
    console.log(`\n[${screen}] ${words.join(' | ').slice(0, 900)}`);
    await page.screenshot({ path: L.path.join(OUT, `${tag}_${screen}.png`) });
  }
  await browser.close();
})().catch((e) => { console.error('CRASH', e); process.exit(1); });
