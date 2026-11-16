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
| D1 schema/backend | DOING (read-only study started) | | |
| D2 browser editor | TODO | | |
| D3 app | TODO | | |
| D4 photos | TODO | | |
| D5 review | TODO | | |
| D6 AI | TODO | | |
| D7 finalise + reopen | TODO | | |
| D8 QA/security | TODO | | |

## NEXT ACTION
D1: read `backend/prisma/schema.prisma`, `backend/src/modules/sync/sync.service.ts`, `backend/src/modules/client-portal/magic-link.service.ts`, `backend/src/modules/audit`, `config.service.ts` (baseVersion pattern); then write the Prisma migration (Survey.version, report blocks store, EditLink with partial unique index, ReportVersion history, Review, Media caption/sortOrder/sectionKey) and services; tests in `backend/test` + e2e harness.

## Gotchas
Backend tests need the E2E harness (VALUATION progress section 6c: docker `ss_e2e_pg` :15432, backend :3099). Many files CRLF. Windows shell dislikes big heredocs: use the Write tool.

## Log
- 16 Nov: spec read in full; stack/sync/data facts verified; Track C docx made; plan and D0 locked; plan approved by user.
