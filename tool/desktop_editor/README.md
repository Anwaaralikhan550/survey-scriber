# SurveyScriber report editor (secure desktop editing)

Browser editor for the structured report (client spec v1.3). React + Tiptap. It talks only to `/api/v1/editor/*` with an HttpOnly session cookie and a CSRF header; the link token is exchanged once and removed from the address bar.

```
npm install
npm test            # diff logic (node:test)
npm run build       # dist/
npm run dev         # http://localhost:5174, proxies /api to http://localhost:3099 (EDITOR_API_TARGET)
```

The page address a colleague receives is `<EDITOR_BASE_URL>/open/<token>` (backend env `EDITOR_BASE_URL`).

## Deploy notes (done at D8)
- Serve `dist/` as a single-page app (every path returns `index.html`) and proxy `/api/` to the backend on the same host, so the cookie stays first-party.
- Send these headers from the web server (a meta tag cannot): `Content-Security-Policy: ... frame-ancestors 'none'`, `Referrer-Policy: no-referrer`, `X-Robots-Tag: noindex, nofollow, noarchive`, `Cache-Control: no-store` on `index.html`.
- Backend: `CORS_ORIGINS` only needed if the editor is served from a different origin than the API.

## Browser test
`tmp/desktop-editing/p20_editor.js` drives the real backend and this build with Chrome (65 checks, screenshots in `tmp/desktop-editing/proof/`).
