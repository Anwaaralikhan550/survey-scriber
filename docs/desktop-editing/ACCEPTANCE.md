# Acceptance tests: client spec "Secure Desktop Report Editing" v1.3, section 21

Every line of section 21 is an automated test. The backend half of all fourteen is one file, `backend/test/report-acceptance.e2e-spec.ts`, named AT-01 to AT-14.
Where a line also needs the phone or the browser, that test is named too. Last run: 16 Nov 2026, all green.

Run the backend half: `cd backend && npx jest --config test/jest-e2e.json test/report-acceptance` (Docker test database up, see the gotchas in `docs/DESKTOP-EDITING-PROGRESS.md`).

| # | Spec line (section 21) | Backend test | Also tested in |
|---|---|---|---|
| AT-01 | Two simultaneous create-link requests cannot produce two active links | `report-acceptance` AT-01 (8 at once, one wins, database holds one ACTIVE) | `report-editing` (partial unique index), `report-load` (30 reports x 3 presses) |
| AT-02 | Existing active link blocks new; expired, cancelled, revoked permit replacement | AT-02 (all four cases in one flow) | `report-editing` |
| AT-03 | 72-hour expiry prevents editing; cancellation/revocation immediately block writes | AT-03 (TTL is 72 h; expiry gives LINK_EXPIRED and read-only; cancel and admin revoke give LINK_REVOKED at once) | browser `p20_editor.js` (expired link read-only screen, access-ended screen) |
| AT-04 | New link invalidates prior link/session | AT-04 | `report-editing` |
| AT-05 | Sequential users edit the same report and committed changes are visible to owner and next reviewer | AT-05 (two sessions on one link, owner sync sees both) | `p20_editor.js`, phone `desktop_editing_controller_test.dart` |
| AT-06 | Concurrent stale save returns a conflict and does not overwrite | AT-06 (stale save 409 with server version; two simultaneous saves, exactly one wins) | `report-load` (20 racing writers, no lost update), `p20_editor.js` (conflict dialog, re-apply) |
| AT-07 | All supported paragraph, section, rating, recommendation edits persist | AT-07 (text, rating, recommendation, table, add, move across sections, delete; reload sees all; template field cannot be deleted) | `p20_editor.js` |
| AT-08 | Photo upload, replace, caption, delete, order, section association persist and render correctly | AT-08 (served bytes and dimensions checked) | `report-photos` (EXIF/GPS removal, validation), browser `p21_photos.js`, phone `photo_sync_test.dart` and the real round trip |
| AT-09 | Autosave/manual save states accurately reflect server commitment | AT-09 (a save answers only after commit; retry with the same key is not applied twice; a refused save changes nothing) | browser `p20_editor.js` (Saving/Saved/Unsaved/Failed/Offline/Conflict states, 65 checks) |
| AT-10 | App detects newer cloud version and synchronises without stale overwrite | AT-10 (cloud version visible; blind upload from the phone is refused 409) | phone `desktop_editing_controller_test.dart` (update banner, Synchronise, "Synchronise first"), `desktop_editing_data_test.dart` |
| AT-11 | AI suggestions never auto-apply or invent facts/ratings | AT-11 (ratings and tables refused, report untouched) | `ai-guardrails.spec.ts`, `ai-suggestion.service.spec.ts` (24: nothing applied by the server, rating text rejected, new figures and findings flagged, personal data replaced), browser `p23_ai.js` (nothing applied until Accept) |
| AT-12 | Approval tied to version; content edit invalidates approval | AT-12 | `report-review` (23), browser `p22_review.js` |
| AT-13 | Finalisation generates PDF/Word, locks report and revokes editing | AT-13 (locks, writes refused, link dead, owner can still read the final text) | **PDF and Word from the final content:** phone `test/features/report_editing/final_export_test.dart` (Word text checked, PDF made by the same engine, reopen round, markup escaped); `report-finalise` (18), browser `p24_finalise.js` |
| AT-14 | Owner-only actions and security controls are tested across roles | AT-14 (13 owner routes x nobody / browser session / other surveyor / viewer login; admin allowed) | `report-security` (30), `p25_security_live.js` (19), `p26_xss.js` (17), `p27_nginx.js` (33) |

Notes:

- The PDF and Word files are made **on the phone** by the existing report engine (decision D0 a). The server never renders them. AT-13's "generates PDF/Word" is therefore proved by the phone test above, from the same final content the server holds.
- The PDF test downloads the PDF fonts once (the engine does that in the app too). With no network it reports itself skipped instead of failing.
- Everything is run on a local stack; nothing was run against the live server.
