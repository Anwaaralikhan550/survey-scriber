// A stand-in for the Gemini API, for the D6 browser test only. It answers the two calls the backend makes
// (list models, generateContent) with fixed, rule-based rewordings so the test can check the whole flow
// without a real model, and it records every prompt it receives so the test can check what was sent.
// Run: node fake_gemini.js   (listens on 127.0.0.1:4799; the backend is started with GEMINI_API_BASE_URL=http://127.0.0.1:4799)
const http = require('http');

const prompts = [];

function reply(prompt) {
  const text = prompt.split('Text to rewrite:\n')[1] || '';
  if (/DOWN/.test(text)) return { status: 500 };
  if (/BREAK/.test(text)) return { text: 'Condition rating is: 1' };
  if (/WARN/.test(text)) return { text: 'The roof has 20 slipped tiles, which is a serious structural problem. WARN' };
  if (/slipped tiles/.test(text)) return { text: 'The roof has 12 slipped tiles, and the ridge is in poor condition.' };
  if (/roofer/.test(text)) return { text: 'A roofer should repair the ridge within 12 months.' };
  if (/Call/.test(text)) return { text: text.replace('Call', 'Please call') };
  return { text: text.replace(/\bhas\b/, 'features') };
}

http
  .createServer((req, res) => {
    let body = '';
    req.on('data', (c) => (body += c));
    req.on('end', () => {
      const send = (code, obj) => {
        res.writeHead(code, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(obj));
      };
      if (req.method === 'GET' && req.url.startsWith('/__prompts')) return send(200, prompts);
      if (req.method === 'DELETE' && req.url.startsWith('/__prompts')) return send(200, (prompts.length = 0));
      if (req.method === 'GET' && req.url.startsWith('/models')) {
        return send(200, {
          models: ['gemini-2.5-pro', 'gemini-2.5-flash'].map((n) => ({ name: `models/${n}`, supportedGenerationMethods: ['generateContent'] })),
        });
      }
      if (req.method === 'POST' && /:generateContent/.test(req.url)) {
        const parsed = JSON.parse(body);
        const prompt = parsed.contents[0].parts[0].text;
        prompts.push({ system: parsed.systemInstruction?.parts?.[0]?.text, user: prompt });
        const r = reply(prompt);
        if (r.status) return send(r.status, { error: { message: 'boom' } });
        return send(200, { candidates: [{ content: { parts: [{ text: r.text }] }, finishReason: 'STOP' }], usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 10 } });
      }
      send(404, {});
    });
  })
  .listen(4799, '127.0.0.1', () => console.log('fake gemini on 4799'));
