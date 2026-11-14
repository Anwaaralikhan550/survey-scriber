// usage: node p11_click.js <tag> <section>:<screen> <x,y>[:wait] ...   (each click is followed by a screenshot <tag>_<n>.png)
// Use scroll with "s<dy>" e.g. s600 to scroll the page by dy pixels, "k:Escape" to press a key, "t:text" to type.
const L = require('./lib');
const F = require('./flut');
const { sleep } = L;
const OUT = L.path.join(L.ROOT, '..', 'client-edits-2026-11-13', 'proof');
const STATE = L.path.join(L.ROOT, '..', 'client-edits-2026-11-13', 'harness_survey.json');
(async () => {
  const [tag, target, ...steps] = process.argv.slice(2);
  const id = JSON.parse(L.fs.readFileSync(STATE, 'utf8')).id;
  const browser = await L.openBrowser();
  const page = await F.openApp(browser);
  await F.login(page, 'e2e.field@example.com');
  await sleep(14000);
  const [sec, screen] = target.split(':');
  await page.evaluate((h) => { location.hash = h; }, `#/survey/${id}/valuation/section/${sec}/screen/${screen}`);
  await sleep(3200);
  await F.enable(page);
  let n = 0;
  for (const st of steps) {
    n += 1;
    if (st.startsWith('s')) { await page.mouse.move(195, 400); await page.mouse.wheel(0, Number(st.slice(1))); }
    else if (st.startsWith('k:')) await page.keyboard.press(st.slice(2));
    else if (st.startsWith('t:')) await page.keyboard.type(st.slice(2));
    else { const [x, y] = st.split(',').map(Number); await page.mouse.click(x, y); }
    await sleep(1600);
    await page.screenshot({ path: L.path.join(OUT, `${tag}_${n}.png`) });
  }
  const words = (await F.nodes(page)).map((x) => x.label).filter(Boolean);
  console.log(words.join(' | ').slice(0, 800));
  await browser.close();
})().catch((e) => { console.error('CRASH', e); process.exit(1); });
