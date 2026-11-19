# Remote Editor v1.4: PROGRESS + HANDOVER

**Status: PLAN LOCKED 19 Nov 2026.** New AI / new context: read `docs/REMOTE-EDITOR-V14-PLAN.md` (locked plan, decisions, rules), `docs/remote-editor-v14/DATA-MAPPING.md`, this file, then continue from **NEXT ACTION**. Earlier work: `docs/DESKTOP-EDITING-PROGRESS.md` (D1-D8 done), `docs/VALUATION-NOV17-PROGRESS.md`.

State at lock: backend with D1-D8 + valuation 17 Nov deployed to the live server on 17 Nov (commit 7ba8e6b, 50 migrations, `sharp` installed); APK v16 built (not installed/tested on a phone); editor site NOT live (no domain/HTTPS/nginx); `GEMINI_API_KEY` not set on the server.

## Progress table
| Step | Status | Commit | Checks and proof |
|---|---|---|---|
| R0 | DONE 19 Nov | see git log | plan locked, spec + client note copied to `docs/remote-editor-v14/`, data-mapping note, this file, memory |
| R1 | DONE 19 Nov | see git log | `report_files` table (+ enums, partial unique indexes: one ORIGINAL per kind, one FINAL per cycle+kind; migration `20261119090000_report_files`, prisma diff clean); `StorageService.storeVerified` (temp file, fsync, rename, read back size + SHA-256) and `checksum` on the existing `LocalStorageService`; `ReportFilesService` + owner routes `POST/GET /reports/:id/files`, `GET /reports/:id/files/:fileId` (type decided from bytes, PDF must end with %%EOF, DOCX recognised by entry names, 60 MB limit `REPORT_FILE_MAX_MB`, ownership/admin only, checksum verified before every download, safe headers); error codes FILE_INVALID 422 / FILE_TOO_LARGE 413 / FILE_EXISTS 409. Tests: unit `report-file-content.spec.ts` (7), e2e `report-files.e2e-spec.ts` (12, uses the real PDF/Word files made by the app), all 9 report e2e suites 181/181, report-editing + media unit 71. No UI in this step, so no screenshots; the real generated PDF/Word round-trip byte for byte in the test |
| R2 | TODO | | |
| R3 | TODO | | |
| R4 | TODO | | |
| R5 | TODO | | |
| R6 | TODO | | |
| R7 | TODO | | |
| R8 | TODO | | |
| R9 | TODO | | |
| R10 | TODO | | |

## NEXT ACTION
R2 (immutable original snapshot, original/final files from the phone). Resume from the first TODO row. NOTE for R9: nginx `client_max_body_size 13m` must be raised to 64m for `/api/v1/reports/*/files`.

## Gotchas (carried over, plus new)
- Local stack for tests: docker `ss_e2e_pg` :15432, DB `ss_desk` for backend e2e (`DATABASE_URL=postgresql://ss:ss_pw@127.0.0.1:15432/ss_desk?schema=public`), `npx jest --config ./test/jest-e2e.json report-`; editor test backend on :3097 + `EDITOR_API_TARGET=http://localhost:3097 npx vite preview` (:5174), Chrome scripts in `tmp/desktop-editing/` (`NODE_PATH="E:\survey-scriber\backend\node_modules;$(npm root -g)\@playwright\mcp\node_modules"`, `API=http://localhost:3097/api/v1`).
- Web harness for Flutter screenshots: see `docs/VALUATION-NOV17-PROGRESS.md` gotchas (ss_e2e db, run_backend.cmd :3099, web build, serve :4610).
- Bash heredoc collapses double backslashes in Python text: use the Edit tool for regexes. Many files are CRLF.
- Server: ssh `-p 2222 -i ~/.ssh/nijahomzs naija@158.69.1.183`; deploy = upload source tgz + dist tgz to `~/deploy-backups`, back up, `sudo -n -u ubuntu /usr/local/bin/surveyscriber-deploy` (npm ci + migrate + build; build fails on dist permissions, so swap the prebuilt local dist), `sudo -n systemctl restart surveyscriber-backend`. ASK THE USER before any server change.

## Log
- 19 Nov 2026: R1 done. Hung e2e runs were caused by stale jest processes from earlier days (kill them, run jest with `--forceExit`).
- 19 Nov 2026: plan written and locked, spec read in full, mapping done.
