# Desktop report editing: deployment and operations

Status: written and checked on 16 Nov 2026 against a local stack (PostgreSQL 16 in Docker, backend on Node, editor behind a real `nginx:1.27-alpine`).
**Nothing here has been deployed.** Pushing, deploying, publishing and building the APK wait for the owner's go-ahead.

## 1. What runs where

| Part | What | Where |
|---|---|---|
| Backend | NestJS (`backend/`), new module `report-editing`, new tables | the existing backend on the VPS (port 3000 behind nginx) |
| Database | PostgreSQL, 2 new migrations (below) | existing database |
| Editor | static React app (`tool/desktop_editor`, `npm run build` gives `dist/`) | its own host name, e.g. `editor.<your-domain>`, served by nginx |
| Phone app | Flutter, menu "Edit on a computer" | next APK (not built yet) |
| Photos | server disk, `MEDIA_LOCAL_ROOT/<reportId>/` (as before) | existing volume; no S3 |

The editor and the API are on **one host name**: nginx serves the editor files and proxies `/api/` to the backend. That keeps the session cookie
`SameSite=Strict` working and means no CORS is needed. If you ever split them, `CORS_ORIGINS` must list the editor origin and both hosts must share a registrable domain.

## 2. Steps, in order

1. **Back up the database** (`pg_dump`). All three migrations only add tables, columns and indexes; nothing existing is changed or dropped.
2. **Migrations**: `cd backend && npx prisma migrate deploy`. New since the last release:
   - `20261116090000_desktop_report_editing` (reports, versions, edit links, editor sessions, reviews, media caption/order/section, the partial unique index that allows one ACTIVE link per report)
   - `20261116120000_report_finalisations` (one row per edit round that was finalised)
   - check: `npx prisma migrate diff --from-url "$DATABASE_URL" --to-schema-datamodel prisma/schema.prisma --exit-code` prints "No difference detected".
3. **Backend**: `npm ci && npx prisma generate && npx nest build`, restart. Set the environment in section 3.
4. **Editor build**: `cd tool/desktop_editor && npm ci && npm run build`. Copy `dist/` to `/var/www/editor`. (`VITE_API_BASE` is not needed; the default `/api/v1` is right behind the same-host proxy.)
5. **nginx**: copy the four files `tool/desktop_editor/deploy/editor-{http,locations,security-headers,proxy}.conf` to `/etc/nginx/snippets/`, add
   `include /etc/nginx/snippets/editor-http.conf;` once inside `http { }`, copy `editor-tls.conf.example` to `/etc/nginx/conf.d/editor.conf`
   and replace `EDITOR_HOST` and the certificate paths. `nginx -t && nginx -s reload`.
6. **TLS**: Let's Encrypt for the editor host (`certbot certonly --webroot` or `--nginx`). HSTS is sent on every answer (`max-age=31536000`); start shorter if you prefer while testing.
7. **DNS**: `editor.<your-domain>` to the VPS.
8. **Backend setting** `EDITOR_BASE_URL=https://editor.<your-domain>` (the links the app shows are built from it).
9. **Smoke test** (section 6).

## 3. Environment (backend)

| Variable | Default | Meaning |
|---|---|---|
| `EDITOR_BASE_URL` | `http://localhost:5174` | public address of the editor; **must be set in production** |
| `EDITOR_LINK_TTL_HOURS` | 72 | how long a link works |
| `EDITOR_SESSION_MINUTES` | 120 | one browser session (never longer than the link) |
| `EDITOR_OPEN_LIMIT_PER_SECOND` / `_MINUTE` / `_HOUR` | 3 / 10 / 30 | token attempts per address; keep the defaults in production |
| `EDITOR_AI_LIMIT_PER_MINUTE` | 12 | AI suggestions per address per minute |
| `GEMINI_API_KEY` | none | without it the AI button answers "not available" and nothing else is affected |
| `GEMINI_API_BASE_URL` | Google's address | only for tests or a proxy |
| `GEMINI_FLASH_MODEL` | `gemini-2.5-flash` | model used for suggestions |
| `MAX_UPLOAD_MB_PHOTO` | 10 | photo size ceiling (multipart ceiling is 12 MB; nginx allows 13 MB) |
| `ALLOWED_MIME_PHOTO` | `image/jpeg,image/png` | add `image/webp` if wanted; the type is decided from the bytes, not the label |
| `MEDIA_LOCAL_ROOT` | `storage` | photo folder |
| `NODE_ENV` | | **`production`** makes the session cookie `Secure` (https only) |
| `CORS_ORIGINS` | | only needed if editor and API are on different hosts |

Trust proxy is already on in `main.ts`, so the rate limits see the real client address from `X-Forwarded-For`.

## 4. What the configuration guarantees (each point is tested, section 7)

- Link token appears **only** in the page path `/open/<token>` and in the POST body to `/api/v1/editor/open`. nginx writes it to its access log as `/open/[token]`;
  the backend never logs it, nor cookies, CSRF tokens, or report text (request-body logging is off on `/editor` and `/reports` in every environment).
- Session cookie `ss_editor`: random, `HttpOnly`, `SameSite=Strict`, path `/api/v1/editor`, `Secure` in production, stored only as a hash.
- Every write needs `X-CSRF-Token` that belongs to that session.
- Headers on every answer: CSP (`frame-ancestors 'none'`, no inline script, no eval), `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy: no-referrer`,
  `Permissions-Policy` (camera, microphone, location off), COOP/CORP `same-origin`, `X-Robots-Tag: noindex`, HSTS. Editor API answers are `Cache-Control: no-store`.
- nginx limit: 10 token attempts per minute per address (burst 5) in front of the backend's own limit.
- Report text is plain text everywhere: tags are removed on the way in, React shows text, the editing surface knows only plain paragraphs, PDF and Word escape it.
- Photos are decoded and re-encoded (EXIF and GPS removed, turned upright); file names from the user are never used for storage; dimension and size limits apply.

## 5. Operations

**Logs and audit.** The `audit_logs` table records (action names): `EDIT_LINK_CREATED/CANCELLED/REVOKED/EXPIRED`, `REPORT_OPENED`, `REPORT_SAVED`, `REPORT_CONFLICT_DETECTED`,
`REPORT_SNAPSHOT_UPLOADED`, `REPORT_SYNCHRONISED`, `REPORT_VERSION_RESTORED`, `EDITOR_SESSION_CLOSED`, `REVIEW_SUBMITTED/STARTED/APPROVED/AMENDMENTS_REQUIRED/RESET/INVALIDATED`,
`OWNER_APPROVED`, `REPORT_FINALISED`, `REPORT_REOPENED`, `PHOTO_UPLOADED/UPDATED/REPLACED/DELETED`, `PHOTOS_ASSIGNED`,
`AI_SUGGESTION_CREATED/ACCEPTED/ACCEPTED_MODIFIED/REJECTED/FAILED/REJECTED_BY_GUARD`. Rows hold ids, versions and lengths, never report text or tokens.
Worth watching: many `AI_SUGGESTION_FAILED` (model down or key wrong), many 429 answers on `/api/v1/editor/open` (someone guessing), repeated `VERSION_CONFLICT` for one report (two people fighting over a paragraph).

**Storage growth.** Every save keeps a full copy of the report in `report_versions` (this is what makes recovery possible). A large report (about 480 KB of text) saved 100 times is about 48 MB.
There is no pruning yet. Suggested rule when needed: keep every version for 30 days, then the last version of each day, and always keep the finalised versions
(`report_finalisations.version`). This is a decision for the owner; nothing deletes anything today.

**Backups.** The database backup already covers all of it. The photo folder must be in the file backup as before.

**Rollback.** The phone and the editor only talk to new endpoints, so rolling the backend back leaves old app versions unaffected. The migrations are additive: leave them in place.
To switch the feature off without a rollback: do not create links (nobody can open anything); to stop an open session at once, cancel the link in the app (sessions end immediately).

**Links.** One live link per report (database rule, not just code). A new link ends the old one and its sessions. Finalising ends every link and session. Expired links stay in the table for the audit trail.

## 6. Smoke test after a deployment (10 minutes)

1. `curl -sI https://editor.<domain>/` shows `Content-Security-Policy` with `frame-ancestors 'none'`, `Strict-Transport-Security`, `Cache-Control: no-store`.
2. `curl -sI http://editor.<domain>/open/x` redirects to https.
3. In the app: open a survey, menu "Edit on a computer", **Generate link**, copy it.
4. Open the link in Chrome: the address bar shows `/editor` (token gone), the report appears, **Editing** chip.
5. Edit a paragraph, **SAVE TO SURVEYSCRIBER**: chip shows *Saved*, version goes up by one.
6. In the app: it says a newer version exists; **Synchronise**; export Word: the edited wording is in.
7. Browser: Review tab, **Submit for review**, then **Approve this version**. App: **Give final approval**, **Finalise report**. The browser turns read-only; the old link says the report is finalised.
8. App: **Reopen report** with a reason; a new link works again.
9. `grep` the nginx access log and the backend log for the token you used: it must not be there (nginx shows `/open/[token]`).

## 7. How this was verified (re-runnable)

| What | Command (from `E:\survey-scriber`) | Result on 16 Nov 2026 |
|---|---|---|
| Backend end-to-end (links, editing, photos, review, finalise, AI, acceptance, security, load) | `cd backend && npx jest --config test/jest-e2e.json test/report-` (needs the Docker test database, see `docs/DESKTOP-EDITING-PROGRESS.md` gotchas) | all pass |
| Backend unit | `cd backend && npx jest src/modules/report-editing` | all pass |
| Editor browser scripts (Chrome, real backend) | `tmp/desktop-editing/p20_editor.js`, `p21_photos.js`, `p22_review.js`, `p23_ai.js`, `p24_finalise.js`, `p26_xss.js` | all pass |
| Live server checks (production rate limits, headers, CORS, no secrets in the log) | `tmp/desktop-editing/p25_security_live.js <backend log file>` | all pass |
| Editor behind a real nginx (headers, caching, hidden files, token masking, clickjacking, uploads, rate limit, full edit) | `tmp/desktop-editing/p27_nginx.js` (docker `nginx:1.27-alpine`, files in `tool/desktop_editor/deploy`) | all pass |
| Phone | `flutter test test/features/report_editing test/app/router/desktop_editing_route_test.dart` | all pass (2 skipped need a live backend) |

Two things the tests found in the deployment files and fixed: a reload at `/editor` returned 404 (now has its own location), and HSTS was missing on locations that set their own headers (now inside the shared snippet).

## 8. Known limits and open items

- Not pushed, not deployed, no APK built, no bank or tree published.
- A bearer link identifies nobody: anyone holding it can edit until it ends. Concurrent editors are handled by version checks, not by a lock (spec section 23).
- The AI uses Google Gemini (existing service). Text sent to it has emails, phone numbers and postcodes replaced by placeholders first, but it is still report wording leaving the server. Tell clients, or leave `GEMINI_API_KEY` unset to switch it off.
- `FINALISING` exists as a status but is not used: finalising is one step because the PDF and Word are made on the phone from the final text.
- Pasting HTML into the editor makes Chrome report a CSP violation while it parses the clipboard in an inert document. Nothing runs and nothing is inserted. It is expected.
- No pruning of old report versions (section 5).
