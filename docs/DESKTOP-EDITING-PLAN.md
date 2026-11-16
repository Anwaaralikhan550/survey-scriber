# Secure Desktop Report Editing: LOCKED plan (16 Nov 2026)

Source: client PDF `SurveyScriber_Secure_Desktop_Editing_Technical_Specification_v1.3_FULL.pdf` (copy the file into `docs/client-desktop-editing/` when convenient). Section numbers below (Sec N) refer to that PDF.
Rules: same as `docs/VALUATION-NOV13-PROGRESS.md` (no skipped step, wording and behaviour only as the spec says, each step has tests + screenshots, update the progress md before every commit, push / deploy / APK / live only when the user asks). Plan changes only with the user's permission.

## Order of work
1. Track C: reply to the client's 5 confirm questions (`docs/client-desktop-editing/Reply_Confirmations_16Nov2026.docx`). DONE 16 Nov.
2. Track A: client answers to the 13 valuation questions (file not received yet; then work per `docs/VALUATION-NOV13-PROGRESS.md`).
3. D0 decisions (locked below), then D1 to D8 in this order, auto-continue.

## D0 locked decisions (user, 16 Nov)
- (a) Structured blocks: when an edit link is created, the report's sections and paragraphs are stored in the cloud as ordered `Section[]` and `ContentBlock[]` with stable UUIDs (spec Sec 4). Reviewer can add, delete, reorder paragraphs (Sec 2.2, Screen C). On Synchronise the phone's `ReportBuilder` builds PDF/Word from those edited blocks.
- (b) Editor stack: React + Tiptap (ProseMirror) in D2, with Undo/Redo, Reload latest, unsaved-exit warning, read-only mode when expired or finalised. The editor serialises to blocks, never raw HTML as the only source (Sec 8).
- (c) Recoverable version history: every save stores a snapshot/history row so the owner can recover an earlier version (Sec 22).
- (d) Reopen: D7 has an explicit owner Reopen action that starts a new editing cycle and new link, and keeps the previous final version and audit (Sec 15).
- (e) Photos: strip EXIF/GPS on upload, keep the mobile app's existing photo annotations (Sec 9).
- (f) Token URL and headers: after token exchange remove the raw token from the URL (`history.replaceState`); HttpOnly + Secure + SameSite cookie, CSRF protection, `Referrer-Policy: no-referrer`, noindex, no third-party scripts on the token page (Sec 5.3, 17).

## Steps (each: Done-when, tests, screenshots)
- D1 Schema/backend (Sec 4, 5, 11, 14, 18; spec Phase 1). Prisma migration: `Survey.version`, `Section/Block` store, `EditLink` (token hash, status, created/expires, partial unique index: one ACTIVE per report), `ReportVersion` history, `Review`, `Media.caption/sortOrder/sectionKey`, audit actions. Services: create link (transaction, FOR UPDATE, 72 h, ACTIVE_LINK_EXISTS), cancel/revoke, new link invalidates old, token to short-lived session, rate limit, no token in logs. Version-checked save (409 VERSION_CONFLICT) and also on phone sync push so stale phone data cannot overwrite newer cloud. Done when: tests for two simultaneous creates, expiry, revoke, stale save 409, owner-only, error codes of Sec 16.
- D2 Browser editor (Sec 7 Screens A-H, 8, 10, 19). `tool/desktop_editor` React + Tiptap. Landing, workspace (header with ref, address, type, version, save state, link expiry, read-only/editing), section nav, paragraph edit/add/delete(confirm, undo)/reorder, autosave 1-3 s + SAVE TO SURVEYSCRIBER, states Saving/Saved/Unsaved/Failed, conflict UX, exit warning. Done when: Playwright run of every screen + screenshots (desktop and iPad width).
- D3 App (Sec 7 Screen H, 12). Generate/Copy/Share/Cancel link, expiry, cloud version vs app version, Synchronise (never push stale over newer; builds from edited blocks). Done when: Flutter tests + web-harness screenshots.
- D4 Photos (Sec 9). Upload, replace (old kept until new succeeds), caption, reorder, section, delete; server validation (extension, MIME, file signature, size, dimensions); EXIF/GPS strip; annotations preserved; MEDIA accepted in sync. Done when: tests + screenshots + render in final report.
- D5 Review workflow (Sec 14, Screen F). Statuses Draft, Submitted for Review, Under Review, Amendments Required, Reviewer Approved, Owner Final Approval, Finalising, Finalised; approvals tied to exact version; any later edit resets approval; server-side role-controlled transitions.
- D6 AI (Sec 13, Screen E). Suggest endpoint on the existing AI module, side-by-side/diff, Accept/Reject/Copy-Modify, fact warning, never auto-apply ratings or findings, log accepted suggestions, minimise personal data sent.
- D7 Finalise and reopen (Sec 15). Owner finalise locks report, records final version, revokes links/sessions, PDF/Word from existing engine, owner downloads in App; explicit Reopen (D0 d).
- D8 QA and security (Sec 17, 19, 21, 22). All 14 acceptance cases of Sec 21 as automated tests, XSS/CSRF/upload checks, cookie and header checks, browser/iPad check, load test, deployment notes.

## Known facts (verified in repo, 16 Nov)
No edit-link feature exists; push is last-write-wins; no report version column; Media has no caption/order; phone builds PDF/Word; reusable: `ClientMagicLink`/`MagicLinkService` hashing pattern, `AuditLog`, status machine, `baseVersion`+409 pattern in `config.service.ts`, `/ai/*`, portal shell. Hosting is local-disk photo storage on one VPS behind nginx.
