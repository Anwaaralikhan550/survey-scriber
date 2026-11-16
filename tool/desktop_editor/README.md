# SurveyScriber report editor (secure desktop editing)

Browser editor for the structured report (client spec v1.3). React + Tiptap. It talks only to `/api/v1/editor/*` with an HttpOnly session cookie and a CSRF header; the link token is exchanged once and removed from the address bar.

```
npm install
npm test            # diff logic (node:test)
npm run build       # dist/
npm run dev         # http://localhost:5174, proxies /api to http://localhost:3099 (EDITOR_API_TARGET)
```

The page address a colleague receives is `<EDITOR_BASE_URL>/open/<token>` (backend env `EDITOR_BASE_URL`).

## Deploy
Ready-made nginx files are in `deploy/` (headers incl. `frame-ancestors 'none'` and HSTS, no-store on the app page, token masked in the access log,
rate limit on the token page, `/editor` reload fallback, 13 MB uploads, long timeout for AI, TLS example). The full steps, environment variables,
smoke test and what was verified are in `docs/desktop-editing/DEPLOYMENT.md`. Serve `dist/` and proxy `/api/` to the backend on the **same host** so the cookie stays first-party.

## Browser test
`tmp/desktop-editing/p20_editor.js` drives the real backend and this build with Chrome (65 checks, screenshots in `tmp/desktop-editing/proof/`). The other scripts are listed in `docs/desktop-editing/ACCEPTANCE.md`.
