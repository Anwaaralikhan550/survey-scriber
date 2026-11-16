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
| D2 browser editor | TODO | | |
| D3 app | TODO | | |
| D4 photos | TODO | | |
| D5 review | TODO | | |
| D6 AI | TODO | | |
| D7 finalise + reopen | TODO | | |
| D8 QA/security | TODO | | |

## NEXT ACTION
D2 (browser editor React + Tiptap in `tool/desktop_editor`, screens A-H, D0 b and f; also add editor origin to backend CORS with credentials). [D1 was:] read `backend/prisma/schema.prisma`, `backend/src/modules/sync/sync.service.ts`, `backend/src/modules/client-portal/magic-link.service.ts`, `backend/src/modules/audit`, `config.service.ts` (baseVersion pattern); then write the Prisma migration (Survey.version, report blocks store, EditLink with partial unique index, ReportVersion history, Review, Media caption/sortOrder/sectionKey) and services; tests in `backend/test` + e2e harness.

## D1 design notes (decisions made while coding)
- Report id = survey id. Models: Report (content Json = Section[]/ContentBlock[], version, status), ReportVersion (snapshot per version, idempotencyKey), EditLink (token hash, one ACTIVE per report via partial unique index in migration SQL only), EditorSession (cookie + csrf hashes), Review. Version lives on Report, not Survey (the survey stays the phone's record).
- Phone uploads the structured report with `PUT /reports/:id/snapshot` (baseVersion required after the first upload; stale -> 409 VERSION_CONFLICT). Sync push does NOT change reports; instead push is refused (`REPORT_FINALISED`) for a survey whose report is FINALISING/FINALISED.
- Expired link or finalised report mid-session: browser can read (readOnly flag), cannot write. Cancel/revoke/new link: sessions cut at once.
- Errors return the spec code in the `error` field (global filter keeps `error`, drops `code`).
- Test DB: `ss_desk` inside docker `ss_e2e_pg` (postgresql://ss:ss_pw@127.0.0.1:15432/ss_desk). Run e2e with env as in the E2E harness (JWT secrets, SMTP sink) and DATABASE_URL pointing at ss_desk.
- prisma commands hang ~minutes on this machine: run in background.

## Gotchas
Backend tests need the E2E harness (VALUATION progress section 6c: docker `ss_e2e_pg` :15432, backend :3099). Many files CRLF. Windows shell dislikes big heredocs: use the Write tool.

## Log
- 16 Nov: D1 coded, migration verified on fresh DB `ss_desk`, e2e 33/33 + unit 10/10 green. Fixed TestAppModule drift (4 modules missing) so e2e boots. Docker Desktop had to be started by hand.
- 16 Nov: spec read in full; stack/sync/data facts verified; Track C docx made; plan and D0 locked; plan approved by user.
