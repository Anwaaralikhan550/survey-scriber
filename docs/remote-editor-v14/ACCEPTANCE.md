# Remote Editor v1.4: acceptance map (spec section 20)

Every acceptance line of the client's v1.4 specification, the automated tests that prove it, and the result of the last full run (19 Nov 2026, local stack: PostgreSQL 16 in Docker, backend on Node, Chrome, real nginx in Docker).
Test files are in `backend/test/` (e2e, run with `npx jest --config ./test/jest-e2e.json report-`), `backend/src/modules/report-editing/*.spec.ts` (unit), `test/features/report_editing/` (Flutter) and `tmp/desktop-editing/p2x_*.js` (Chrome).
Test names below are the `it(...)` titles; the first words are enough to find them.

| # | Spec 20 line | Where it is proved |
|---|---|---|
| 1 | Only one active 72-hour link per report; revoke/expire/finalise prevents editing; replacement link only after invalidation | `report-acceptance` AT-01 (two simultaneous creates), AT-02 (active link blocks; expired/cancelled/revoked allow a replacement), AT-03 (72 h, cancel and revoke block at once), AT-04 (new link ends the old and its sessions); `report-editing` "the database itself refuses a second ACTIVE link (partial unique index)", "creates a link that expires in 72 hours and stores only the token hash", "finalisation locks everything"; `report-finalise` "locks the report ... and ends every link and session" |
| 2 | Original snapshot/files never change after any desktop edit, mobile sync or finalisation | `report-original` "after a desktop edit and a later upload from the phone", "after approval, finalising and reopening", "the database refuses to change it, to delete it on its own, or to empty the table", "a changed row would be noticed: the checksum no longer matches"; `report-files` "the original is written once", "the database itself allows only one original per kind", "a file whose stored bytes were tampered with is not served"; `report-archive` round trip: "the original is intact and still immutable" after a restore |
| 3 | One current edited report; a successful save increments the version and the audit captures before/after | `report-editing` "saves, raises the version, and the owner sees it on sync and latest", "keeps one snapshot per version"; `report-audit` "a browser save records the field, the value before and after, the version, the session and the source", "one batch with several changes: every change is an event of the same version", "the history cannot be changed or deleted"; unit `report-audit.spec.ts` (`diffContent`) |
| 4 | Two sessions: first save succeeds; the stale second receives 409 and its unsaved changes remain recoverable | `report-editing` "a stale save returns 409 VERSION_CONFLICT and does not overwrite", "two simultaneous saves on the same version: exactly one wins"; `report-acceptance` AT-05, AT-06; browser: `p20_editor.js` conflict screen ("your 1 unsaved change is still here"; the stale save never overwrites; 65/65) |
| 5 | Phone unsent changes are not silently overwritten; a stale mobile push is rejected and surfaced | `report-sync` "after a computer edit a stale push is refused with a code and the cloud version", "a stale update is refused with 409" (REST path the phone really uses), "deleting is held back the same way", "lists the amended sections and blocks"; Flutter `desktop_editing_conflicts_test.dart` (9: three-way conflict dialog per screen, held-back banner, nothing overwritten silently) |
| 6 | Idempotent retries apply changes once | `report-editing` "a retried save with the same idempotency key is applied once"; `report-audit` "a retried save ... is recorded once"; `report-sync` "a batch that went through stays idempotent ... applies once" and "a batch that was refused is judged again" |
| 7 | Photo upload/caption/order/section changes round-trip; replacing edited media preserves original media; signature actions audited | `report-acceptance` AT-08 (upload, replace, caption, delete, order, section); `report-media` "the old picture stays on the volume and in the database and points to the new one", "the browser deleting a photo keeps the file too", "a picture ... only marked deleted", "a signature is kept as well, and the deletion is audited", "serves the bytes of a replaced or deleted picture to the owner and an admin", drawing tests (kept with the photo, survives replacement); Flutter `photo_sync_test.dart` (incl. drawings sent at send time), `desktop_editing_photos_controller_test.dart`; browser `p21_photos.js` (49/49) |
| 8 | Approval bound to version; a later edit invalidates approval; finalisation locks and revokes the link | `report-review` "a decision must name the current version", "a text edit after the reviewer approved: approval invalid", "a text edit after the owner approved: both approvals invalid", "a photo change, a new phone upload and a restore do the same"; `report-finalise` "is bound to the approved version", "an approval that a later change withdrew cannot be finalised", "locks the report, records the final version, and ends every link and session"; `report-acceptance` AT-12, AT-13; browser `p22_review.js` (39/39), `p24_finalise.js` (20/20) |
| 9 | Final PDF/DOCX generated by Flutter and stored separately from the original files | `report-files` "a final document is refused before the report is finalised, then stored per edit cycle with the final version", "the database itself allows only one original per kind" (ORIGINAL and FINAL are separate rows and folders); Flutter `report_document_uploader_test.dart` (snapshot, then ORIGINAL PDF/DOCX while version 1, FINAL per cycle after finalise), `final_export_test.dart` (the Word report is made from the final content) |
| 10 | Archive includes manifest, checksums, original/final documents, structured data, media and audit; tampered ZIP rejected | `report-archive` export: "has the layout of spec 14.1", "the manifest lists every other file with its SHA-256 and size, and is signed", "contains the pictures themselves", "carries the original snapshot with its checksum, the field history with the reviewer name, every version"; refusals: picture/document/report data changed, manifest rewritten (signature), owner changed, unexpected file, traversal, missing file, ZIP bomb; unit `report-archive.spec.ts` (35: paths, bombs, lying sizes, duplicate names, schema version, signature); Flutter `report_archive_test.dart` (download verified against the server SHA-256) |
| 11 | Restore recreates a usable structured report; UUID collision does not overwrite an existing record | `report-archive` "a draft report comes back as it was" and "a finalised report ..." (data, pictures byte for byte, original immutable, documents, history marked imported, restored marker), "the restored draft can be edited and exported again; a restored final report stays locked", "UUID collision: the report still exists, so nothing is overwritten", "a picture id that already belongs to another report is a collision too, and writes nothing", "another user cannot restore it (ownership)" |
| 12 | Completed warnings at days 30/45/55 and purge eligibility at day 60; draft warnings at days 20/25/28 and purge eligibility at day 30 | unit `retention.spec.ts` (41: every day of both tables, late job sends one warning, deadlines, `startsAt`); `report-retention` "day 30, 45 and 55 send the three warnings, each once", "day 20, 25 and 28 each send one warning ... the last says Final warning", "a finalised report on day 59 stays; on day 61 files go first, then the report; only a tombstone ... is left", "a draft is removed on day 31, not on day 29" |
| 13 | Meaningful draft activity resets inactivity; active workflows/legal holds block purge; backup expiry is documented | `report-retention` "meaningful activity restarts the 30 days and clears the warnings; merely viewing does not", "a review in progress or finalising, however old, is never purged", "a live edit link protects an old draft", "a held report is never purged, however old", "new activity after the job queued the report stops the purge", "on release ... a grace period starts"; backup expiry: `DEPLOY-NOTES.md` section 5 (30-day rolling, server-admin tasks, old-dump list with must-delete-by dates) |

## Section 21: the decisions and the places they are met

| Area | Decision | Where |
|---|---|---|
| Original files | DOCX stored as well as PDF, ORIGINAL and FINAL | `report-files`, `report_document_uploader_test.dart` |
| Editable data mapping | blocks with stable ids on one current report, no second answer store | `docs/remote-editor-v14/DATA-MAPPING.md` |
| Reviewer identity | no account; the link holder types a display name, shown as "(name not verified)"; owner actions stay on the logged-in owner | `report-reviewer-name` e2e (reviewer name), `p29_name.js` (19/19), `desktop_editing_review_test.dart` |
| Archive | self-contained signed ZIP with media binaries; supported schema versions = [1] | `report-archive.ts` (`SUPPORTED_ARCHIVE_SCHEMAS`), unit "unsupported archive schema" |
| Retention holds | Admin and Manager place and release; reason 3-500; audited; owner told | `report-retention` legal hold group; Flutter `report_retention_test.dart` |
| Backups | 30-day rolling off-server encrypted; code only provides the policy text, the retention report and the old-dump list | `DEPLOY-NOTES.md` sections 5 and 6 |

## Last full run (21 Nov 2026, final, on the code that is live)

Local stack: PostgreSQL 16 in Docker, backend on Node, Chrome, real nginx in Docker earlier (19 Nov). The same code is live on the server (checked 21 Nov: health, security headers, editor site, wrong-link answer, no token in the nginx log, backup decrypts).

| Suite | Result |
|---|---|
| Backend unit (`npx jest src`) | 38 suites, 606 tests pass |
| Backend e2e (`report-*`, 16 suites) | 301 tests; 300 pass in the full run, the one other is `report-load` (3 s limit, timing under load) which passes alone 3/3 |
| Flutter, whole project (`flutter test`) | 5482 pass, 0 fail (4 skipped) |
| Editor (`npm test`, build) | 0 fail, built |
| Chrome editor scripts | p20 65/65, p21 49/49 (3 runs), p22 39/39, p23 46/46, p24 20/20, p26 17/17, p28 14/14, p29 19/19 |

Found and fixed in this run: two quick changes on different photos (for example two section moves) were sent at the same moment and the second got a false 409 "newer changes". The editor now sends photo changes one at a time (`usePhotos.js`). A failed run before the fix showed it; three clean runs after.
Backend e2e suites outside `report-*` do not compile on `import * as request from 'supertest'`. This is old and not caused by this work.

## Live editor walk-through, 23 Nov 2026 (real link on editor.surveyscriber.com, desktop, iPad, phone width)

Found by hand on the live site and fixed, each with a check in `tmp/desktop-editing/p30_live_fixes.js` (32 checks) and `tool/desktop_editor/test/diff.test.js` (16 tests):

| Finding | Fix |
|---|---|
| Redo did nothing (the text to come back to was read after Undo had already put the old text back) | Undo and Redo read their stacks from refs |
| Two people changed the same paragraph: the second person's "re-apply" silently replaced the first person's text (spec 11: never silently overwrite) | A choice dialog shows both versions: keep theirs, keep mine, or keep both (mine added as a new paragraph). Nothing is applied until chosen |
| After "keep theirs" the save chip stayed on "Unsaved changes" with nothing to save | State is Saved when no change is left to send |
| On a phone the block toolbar pushed the page wider than the screen; the tall header covered a third of the screen | Toolbar wraps; header scrolls away on phones |
| Spec 8 "completion and attention indicators" in section navigation, and "show that the browser edits structured content, not a Word file" were missing | Per-section indicator (complete / needs attention / rating 3) with text alternative; a note above every section |
| Two quick photo changes could give a false 409 | Photo changes are sent one at a time (21 Nov) |

Not testable on the live site without the owner login: finalise, reopen, owner approval, archive, retention (covered by the backend and app suites above). AI suggestions answer "not available right now" on live until a `GEMINI_API_KEY` is set on the server.

