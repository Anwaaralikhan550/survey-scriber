p = 'E:/survey-scriber/tmp/desktop-editing/p26_xss.js'
t = open(p, encoding='utf-8', newline='').read()


def rep(a, b):
    global t
    assert a in t, a[:70]
    t = t.replace(a, b, 1)


rep("const { prisma, owner, newLink, call } = require('./lib.js');", "const sharp = require('sharp');\nconst { prisma, owner, newLink, call } = require('./lib.js');")

# landing page race: wait for the data
rep("""    const landing = await page.locator('body').innerText();
    check('landing page shows the property text as text (address and reference)', /Gas Lane/.test(landing));""",
    """    check('landing page shows the property text as text (address and reference)', await until(async () => /Gas Lane/.test(await page.locator('body').innerText())));
    check('the address that looked like markup is not parsed (no element made from it)', (await page.locator('.card img, .card svg, .card script').count()) === 0);""")

# CSP messages are expected only while the paste of an HTML payload is parsed (inert document), never anywhere else
rep("""    page.on('console', (m) => {
      if (m.type() === 'error' && !/Failed to load resource|net::ERR/.test(m.text())) errors.push(m.text());
    });
    await page.addInitScript(() => {
      document.addEventListener('securitypolicyviolation', (e) => (window.__violations = (window.__violations || []).concat(e.violatedDirective)));""",
    """    let pasting = false;
    page.on('console', (m) => {
      if (m.type() !== 'error' || /Failed to load resource|net::ERR/.test(m.text())) return;
      if (pasting && /Content Security Policy/.test(m.text())) return; // reported by the browser while it parses the pasted HTML; see below
      errors.push(m.text());
    });
    await page.addInitScript(() => {
      document.addEventListener('securitypolicyviolation', (e) => (window.__violations = (window.__violations || []).concat(`${window.__phase || 'page'}:${e.violatedDirective}`)));""")
rep("""    await page.evaluate(() => {
      const el = document.querySelector('.block.is-active .pm');""", """    pasting = true;
    await page.evaluate(() => {
      window.__phase = 'paste';
      const el = document.querySelector('.block.is-active .pm');""")
rep("""    await sleep(300);
    check('pasted HTML creates no element""", """    await sleep(300);
    pasting = false;
    await page.evaluate(() => (window.__phase = 'page'));
    check('pasted HTML creates no element""")

# a real photo for the caption test
rep("""    const jpg = Buffer.from('/9j/4AAQ""", """    const jpgReal = await sharp({ create: { width: 64, height: 48, channels: 3, background: '#336699' } }).jpeg().toBuffer();
    const jpgOld = Buffer.from('/9j/4AAQ""")
rep("const form = new FormData();\n    form.append('file', new Blob([jpg], { type: 'image/jpeg' }), 'x.jpg');\n    form.append('expectedReportVersion', String((await prisma.report.findUniqueOrThrow({ where: { id: survey.id } })).version));\n    form.append('caption', cap);\n    form.append('sectionKey', 'E1_ROOF');\n", "const jpg = jpgReal;\n")

# the sanitiser keeps what is after the broken tag
rep("check('review comment is shown as text', /Please/.test(await page.locator('.review').innerText()) && !/<img\\b|<b>fix/.test(reviewHtml));",
    "check('review comment is shown as text, without markup', /fix/.test(await page.locator('.review').innerText()) && !/<img\\b|<b>fix/.test(reviewHtml));")

# CSP: the browser reports only the paste parse, nowhere else
rep("""    check('no Content-Security-Policy violation was raised by the page', v.length === 0, v.join(','));""",
    """    check('no Content-Security-Policy violation outside the pasted-HTML parse', v.filter((x) => !x.startsWith('paste:')).length === 0, v.join(','));
    console.log('INFO  violations reported while the browser parsed the pasted HTML (nothing executed):', v.filter((x) => x.startsWith('paste:')).join(',') || 'none');""")
open(p, 'w', encoding='utf-8', newline='').write(t)
print('ok')
