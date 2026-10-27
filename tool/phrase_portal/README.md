# Phrase Bank — SurveyScriber admin portal

A static web app for searching and safely editing the RICS L2 phrase bank (the sentence
templates the report is built from) on a proper screen instead of the phone. Saving publishes
the bank to the SurveyScriber server; every phone picks it up on its next start/resume.
No app update, no file editing, no Node process on the server.

## For the admin (client)

1. Open **http://portal.surveyscriber.com** (see "Link" below until DNS/TLS are done).
2. Click **Log in to publish** and sign in with your SurveyScriber **ADMIN** account.
   The password is never stored; the session ends when the tab closes.
3. Pick the bank (Home Survey or Valuation), search a key or sentence, edit, **Save & publish**.
   - The green status line shows the published version and time.
   - Yellow "Not published yet" means phones still use the bank built into the app;
     your first save publishes the complete bank (1,256 inspection phrases / 495 valuation templates).
4. **Token lock**: every `{TOKEN}` is a parameter the report fills in. A save that removes or adds
   a token is blocked; tick **Override token lock** only for a deliberate structural change.

Without logging in the portal is read-only (it shows the published bank).

## Link, DNS and HTTPS (one-time setup)

- The VPS already serves the portal: nginx vhost `portal.surveyscriber.com` ->
  `/var/www/surveyscriber-portal`, with `/api/` proxied to the backend on port 3000.
- **DNS (client, GoDaddy for surveyscriber.com):** add an A record `portal` -> `158.69.1.183`.
  Until then the link does not resolve; for a quick test add to your PC's hosts file:
  `158.69.1.183 portal.surveyscriber.com`.
- **HTTPS (server admin, root):** `certbot --nginx -d portal.surveyscriber.com`. Until TLS exists the
  login travels over plain HTTP; do not use the portal from public Wi-Fi before that.

## Deploy (developer)

```bash
bash tool/phrase_portal/deploy.sh          # test + build dist/ + upload (needs naija SSH key)
bash tool/phrase_portal/deploy.sh --build  # build only
```

The build copies `public/` plus the baseline banks from `assets/property_*/phrase_texts.json` to
`dist/assets/banks/` and uploads everything to the web root. `BUILD` holds the git commit.

## Local development

```bash
node tool/phrase_portal/server.js          # http://localhost:4599, /api/ proxied to the VPS backend
SS_API_ORIGIN=http://localhost:3000 node tool/phrase_portal/server.js   # against a local backend
node --test tool/phrase_portal/test.js     # no install, Node 18+
```

## How it works

- `public/app.js` — UI; `GET /api/v1/config/phrase-bank/:type` (public), `POST /api/v1/admin/config/phrase-bank/upload`
  (admin, whole bank), `POST /api/v1/auth/login|refresh|logout`. Access token refreshes automatically; a 401/403 is
  reported, never silent.
- `public/bank-logic.js` — bank shapes (flat map / `{meta, templates}`), token lock, in-place edit; shared with tests.
- Server side guards (backend): shape validation, idempotent publish (identical content = no new version),
  refuses a bank that lost more than half its phrases, 8 MB cap, audit log entry per publish.
