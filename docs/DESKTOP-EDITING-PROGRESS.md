# Desktop Editing: progress (READ FIRST in a new context)

PLAN APPROVED + LOCKED by the user on 16 Nov 2026. No step may be skipped, shortened or replaced by a weaker check. Plan changes only with the user's permission.
Full plan and D0 decisions: `docs/DESKTOP-EDITING-PLAN.md`. Spec: client PDF v1.3 (Downloads). Valuation client work: `docs/VALUATION-NOV13-PROGRESS.md` (Track A, waits for client answers file).

## Rules
- Each step is DONE only when its Done-when in the plan is met, with tests passing and screenshots looked at; proof paths go in the table.
- Update this file (status, commit hash, proof, NEXT ACTION, log) BEFORE every commit and whenever context is getting full.
- Commit each step (Co-Authored-By line). Push / deploy / APK / live publish only when the user asks.
- Auto-continue D1 to D8 without asking. Report failures honestly.

## Status
| Step | Status | Commit | Proof |
|---|---|---|---|
| Track C reply docx (5 confirm questions) | DONE 16 Nov, shown to user | uncommitted | `docs/client-desktop-editing/Reply_Confirmations_16Nov2026.docx` |
| Track A valuation client answers (13 questions) | WAITING for client file (ask user to attach) | | |
| D0 decisions a-f | LOCKED | | `DESKTOP-EDITING-PLAN.md` |
| D1 schema/backend | DONE 16 Nov (sync-regression check pending, see log) | see git log | migration applies from scratch on a fresh DB; `backend/test/report-editing.e2e-spec.ts` 33/33 pass (links, one-active-link incl. DB partial index, 72h expiry, token hash only, cookie flags + headers, CSRF, 409 conflict, simultaneous saves, idempotent retry, add/move/delete blocks, cancel/expiry/finalise locks, history restore, audit without tokens); `report-content.spec.ts` 10/10 pass; logs `tmp/desktop-editing/e2e.log`, `unit.log` |
| D2 browser editor | DONE 16 Nov | see git log | `tool/desktop_editor` (React 18 + Tiptap 3 + Vite). Screens A-H done except F (review, D5) and E (AI, D6). Proof: `tmp/desktop-editing/p20_editor.js` = 65/65 checks against the real backend with Chrome (token removed from URL, HttpOnly/SameSite cookie, no-referrer/noindex/CSP meta, autosave states, SAVE, add/move/delete+confirm+undo, rating/table edits, conflict + re-apply + cannot-re-apply, offline + retry, exit/reload/beforeunload warnings, read-only on expiry, access-ended, finalised, invalid/expired/cancelled links, iPad portrait/landscape + laptop); every screenshot viewed (`tmp/desktop-editing/proof/d2_*.png`); `npm test` in the editor: 10 diff tests; backend unit 11/11 + e2e 36/36 |
| D3 app | TODO | | |
| D4 photos | TODO | | |
| D5 review | TODO | | |
| D6 AI | TODO | | |
| D7 finalise + reopen | TODO | | |
| D8 QA/security | TODO | | |

## NEXT ACTION
D3 Flutter app: Generate/Copy/Share/Cancel link, expiry display, cloud-vs-app version indicator, Synchronise (never push stale over newer), phone uploads the structured report with `PUT /reports/:id/snapshot` and builds PDF/Word from the synced blocks. Start by reading how `ReportDocument` is built (`report_builder.dart`) to define the block mapping (section id/key/title + paragraphs per screen), then the app's survey screens for where the Share-link button goes. [D2 notes below stay valid; old D1 line:] read `backend/prisma/schema.prisma`, `backend/src/modules/sync/sync.service.ts`, `backend/src/modules/client-portal/magic-link.service.ts`, `backend/src/modules/audit`, `config.service.ts` (baseVersion pattern); then write the Prisma migration (Survey.version, report blocks store, EditLink with partial unique index, ReportVersion history, Review, Media caption/sortOrder/sectionKey) and services; tests in `backend/test` + e2e harness.

## D1 design notes (decisions made while coding)
- Report id = survey id. Models: Report (content Json = Section[]/ContentBlock[], version, status), ReportVersion (snapshot per version, idempotencyKey), EditLink (token hash, one ACTIVE per report via partial unique index in migration SQL only), EditorSession (cookie + csrf hashes), Review. Version lives on Report, not Survey (the survey stays the phone's record).
- Phone uploads the structured report with `PUT /reports/:id/snapshot` (baseVersion required after the first upload; stale -> 409 VERSION_CONFLICT). Sync push does NOT change reports; instead push is refused (`REPORT_FINALISED`) for a survey whose report is FINALISING/FINALISED.
- Expired link or finalised report mid-session: browser can read (readOnly flag), cannot write. Cancel/revoke/new link: sessions cut at once.
- Errors return the spec code in the `error` field (global filter keeps `error`, drops `code`).
- Test DB: `ss_desk` inside docker `ss_e2e_pg` (postgresql://ss:ss_pw@127.0.0.1:15432/ss_desk). Run e2e with env as in the E2E harness (JWT secrets, SMTP sink) and DATABASE_URL pointing at ss_desk.
- prisma commands hang ~minutes on this machine: run in background.

## D2 design notes
- Editor state (`src/useEditor.js`): server copy + working copy; pending changes are computed by `diffContent(server, working)` (`src/diff.js`), so undo/redo is just snapshots and a save sends the diff as spec-style ops (updateBlock/addBlock/deleteBlock/moveBlock). Added `atStart` placement to the backend for add/move to index 0.
- Save states: saved / unsaved / saving / failed / offline / conflict / readonly / lost. "Saved" only after the server confirmed and the report was re-read. Retries reuse one idempotency key. A failed save is never repeated automatically; during conflict save is blocked until the user chooses (re-apply or discard).
- Backend additions in D2: `POST /editor/close` (exit ends only that session), editor read includes `property` (reference, address), `X-CSRF-Token` allowed by CORS, open-link rate limits configurable by env `EDITOR_OPEN_LIMIT_PER_SECOND/MINUTE/HOUR` (defaults 3 / 10 / 30 per IP).
- Test server for the browser test: backend `node dist/src/main.js` on :3099 with env from the E2E harness plus raised open limits, DB `ss_desk`; editor `npx vite preview` on :5174 (proxies /api). Playwright uses system Chrome (`channel: 'chrome'`); test JWT secret is `e2e-local-only-access-secret-...` (Prisma loads backend/.env into process.env, so the test must not read JWT_ACCESS_SECRET from env). Space helper requests >= 450 ms: global API limit is 3 requests/s per IP.
- Known gaps by design, done later: photo panel (D4), review/submit button (D5), AI panel (D6); frame-ancestors/CSP headers from nginx (D8).

## Gotchas
Backend tests need the E2E harness (VALUATION progress section 6c: docker `ss_e2e_pg` :15432, backend :3099). Many files CRLF. Windows shell dislikes big heredocs: use the Write tool.

## Log
- 16 Nov: D2 done. Real bugs found by the browser test and fixed: spaces typed right after Add paragraph re-triggered the button; a failed save repeated itself and re-opened the conflict dialog; two saves fired together on SAVE click (blur + click); typing after a save merged into the earlier undo step; conflict dialog counted the colleague's change; duplicate read-only chip; iPad portrait blank gap (grid align-content).
- 16 Nov: D1 coded, migration verified on fresh DB `ss_desk`, e2e 33/33 + unit 10/10 green. Fixed TestAppModule drift (4 modules missing) so e2e boots. Docker Desktop had to be started by hand.
- 16 Nov: spec read in full; stack/sync/data facts verified; Track C docx made; plan and D0 locked; plan approved by user.
