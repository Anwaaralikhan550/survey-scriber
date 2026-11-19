# Remote Editor v1.4: LOCKED PLAN (19 Nov 2026)

**LOCKED 19 Nov 2026 by the user.** Do not add, drop or shrink a step without the user's say-so. This plan continues `docs/DESKTOP-EDITING-PLAN.md` (spec v1.3, D0-D8, all done and deployed to the backend on 17 Nov). Progress: `docs/REMOTE-EDITOR-V14-PROGRESS.md`. Source: `docs/remote-editor-v14/SurveyScriber_Remote_Editor_Technical_Architecture_and_Implementation_Specification_v1.4.pdf` (text copy `spec-v1.4.txt`), client note `Client_Can_We_Do_This.docx`.

## What v1.4 adds over v1.3 (verified against the repo)
Already built (D1-D8, no rework): one active 72 h link (DB partial unique index), hashed token, session cookie + CSRF + headers + rate limit, `report.version` + 409 + idempotent saves, stable block UUIDs, photo manager (EXIF/GPS stripped, content checked), review bound to version, AI advisory accept/reject, finalise + reopen, final PDF/Word from the phone, 14 acceptance tests + security + load + nginx docs.

New in v1.4 (this plan): immutable original snapshot and original/final files kept apart; field-level audit (before/after); storage abstraction; reviewer display name; stale phone push rejected + changes API + "remote changes available" + conflict screen; original media kept on replace + annotations + signature audit; archive ZIP export and restore; retention (60 d completed, 30 d drafts, warnings, purge, legal hold); editor site deployment + backup policy; the v1.4 section 20 acceptance tests.

## Decisions (client defaults, user told us to proceed 19 Nov)
1. Reviewer identity: the link stays frictionless (no reviewer account). The editor asks the reviewer for a display name when the link is opened; the name is stored on the editor session and written to audit, review and history labelled "name entered by link holder (unverified)". Owner approval/finalise stay on the logged-in owner.
2. Legal hold: Admin and Manager roles may place and release a hold on any report; reason mandatory (3-500 chars), timestamp and actor audited; the owner is told. A held report is never purged (draft or completed).
3. Backups: automated off-server encrypted backups with 30-day rolling retention is a SERVER task (server admin). Our part: code, policy text in the docs, a retention report, and a list of old manual dumps to delete. Backup expiry (30 d) + completed retention (60 d) = removed everywhere within 90 d after finalisation.
Design choices (mine, change only with the user): the original snapshot is a new immutable table (UPDATE blocked by a DB trigger, DELETE only inside the purge job); original files and final files are rows of one `report_files` table (state ORIGINAL | FINAL | ARCHIVE) on the storage abstraction; field audit is derived inside the save transaction (no second source of truth); retention jobs run from a scheduler inside the backend with a manual "run now" for tests; the clock is injectable so the 20/25/28/30 and 30/45/55/60 day rules are tested without waiting.

## Rules (same as the previous plan, non-negotiable)
1. No step skipped, no weaker check. A step is DONE only when its tests pass AND its screenshots/real files were looked at.
2. Auto-continue R1 -> R10; stop only for a decision the user must make, or for push / deploy / APK / live server changes (ask first, every time).
3. Build on the existing Survey/Report/Media tables; no parallel report database; Flutter stays the renderer of final PDF/Word.
4. Update the progress file BEFORE each commit; commit trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
5. Real tests: backend unit + e2e (docker postgres `ss_desk`), Flutter tests, Chrome scripts with screenshots for every editor change, real PDF/Word renders where output changes. Report failures honestly.
6. Never touch production data. Production changes only after the user says so; the deploy procedure is in `docs/remote-editor-v14/DEPLOY-NOTES.md` (made in R9).

## Steps
| Step | What | Done when |
|---|---|---|
| R0 | Plan lock, spec copied, data-mapping note (existing models/modules vs v1.4), progress file, memory | files committed |
| R1 | Storage abstraction + `report_files`: `StorageService` (disk adapter, UUID keys, atomic write, size + SHA-256 verify, authorised read only, outside web root), existing report/photo code moved onto it without changing behaviour; ORIGINAL/FINAL/ARCHIVE file rows, upload/download endpoints for owner | unit + e2e: tamper/size/traversal rejected, photos still pass all photo tests, checksums verified |
| R2 | Immutable original snapshot: table `report_original_snapshots` (schemaVersion, tree + phrase-bank versions, survey type, generatedAt, snapshot JSON, checksum, original file ids), DB trigger blocks UPDATE and non-purge DELETE; captured once at first upload; phone uploads original PDF + DOCX after generating; final PDF + DOCX stored as FINAL at finalise; finalisation records final version + checksums | e2e: original never changes after edits, sync, finalise, reopen; DOCX stored; trigger test with raw SQL |
| R3 | Field-level audit: `report_audit_events` (survey, version, entity, field/block, before, after, actor/session + reviewer name, source, time) written in the save transaction; AI-accepted flagged; owner endpoint to read; media/link/review/finalise events included | e2e: every accepted save has events with before/after, rejected save none, idempotent retry once |
| R4 | Reviewer display name: editor asks on open, stored on session, shown in header, review, history and audit with the "unverified" label; name rules (trim, length, no markup) | Chrome test + screenshots; e2e |
| R5 | Sync: stale phone `/sync/push` for a remotely edited survey is rejected with a code the phone shows (never silent loss); `GET /editor/reports/:id/changes?since=` and owner equivalent; phone "Remote changes available" + conflict resolution screen (keep mine / take desktop / per screen) | e2e + Flutter widget tests + web-harness screenshots |
| R6 | Media: replacing keeps the original binary and record (edited reference points to the new one), annotation metadata kept in cloud and snapshot, signature changes explicit and audited | e2e + Chrome test |
| R7 | Archive: export ZIP (manifest + SHA-256 for every file, original/, final/, audit/, definitions/, README, media binaries); restore with validation (schema, paths, size, ZIP bomb, traversal, checksum, ownership, tamper), UUID collision rejected, imported audit marked, "Restored from archive" flag; phone: Download Complete Archive + Restore | e2e incl. tampered ZIP + collision; round trip export -> restore compares data; Flutter tests; screenshots |
| R8 | Retention: schema + config (60/30 days, warning days 30/45/55 and 20/25/28, upload/archive limits), meaningful-activity timestamp (open does not count), warning jobs (app notice + email), purge job (files first, then rows, tombstone with date/reason/outcome only), legal hold (Admin/Manager, reason, audit, owner notice, blocks purge), idempotent retries | tests with injectable clock for every day in the v1.4 table; hold blocks; purge leaves only the tombstone; screenshots of warnings and hold in the app/portal |
| R9 | Editor site live-ready: build, nginx/TLS notes updated for v1.4, `DEPLOY-NOTES.md` (backend + editor + backup policy + retention report + old-dump list), local run script for the owner's PC, backend env set documented | Docker nginx smoke test (p27 style) 100 %, doc reviewed |
| R10 | v1.4 section 20 acceptance tests all automated (map file `docs/remote-editor-v14/ACCEPTANCE.md`), security + load re-run, full Flutter + backend + portal suites, progress/memory updated | all green, map has no empty row; then ask the user: push / deploy / APK |

## Order of work and why
R1 -> R2 -> R3 first (backend guarantees: original, audit, files) as the spec demands (section 22); R4-R6 build the editor/phone behaviour on them; R7-R8 need the files and audit; R9-R10 close.
