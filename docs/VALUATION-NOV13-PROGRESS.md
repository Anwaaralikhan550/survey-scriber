# VALUATION NOV-13 WORK: PROGRESS + HANDOVER (READ FIRST)

**Status: PLAN LOCKED 14 Nov 2026.** Do not add, drop or shrink a step without the user's say-so. New AI / new context: read this file top to bottom, then `docs/VALUATION-NOV13-PLAN.md` (full locked plan), then continue from **NEXT ACTION** below.

## 1. What the work is
SurveyScriber (Flutter app `E:\survey-scriber`, NestJS `backend/`, portal `tool/phrase_portal`). The client sent changes for the **Valuation module** (Property Valuation report). User (Roman Urdu, caveman style replies, they/them) wants every item done exactly as the client wrote, no skipped step, no shortcut, each item verified with proper tests AND screenshots, then a result report.

Client sources (copies in `docs/client-valuation-2026-11-13/`):
- `Valuation Feed back November 13.docx` (+ `feedback_typed.txt`): typed list of changes and exact new sentences.
- `FBS_Valuation_Report_Section_Bars_Aligned.docx` (+ `sample_report_text.txt`): sample valuation report = the FORMAT reference (section bar colours, cover, sub-heading bars).
- `handwritten_note.png`: client's handwritten note (photo, at the end of the sample docx). Transcript:
  1. General Details: Options, add a text box to "Other".
  2. Construction option: Solid brick/cavity wall, Stud wall, Timber frame, Concrete frame, Other. (CONFLICTS with the typed list; typed list chosen, see decisions).
  3. Age of Extension (Date of Extension).
  4. New Build Property: Remove.
  5. Accommodation Summary: replace with the one in Inspection and generate the same.
  6. Remove Parking locations.
  7. Property Inspection: standardised Condition, good, reasonable, to poor.
  8. Flat roof: remove Partial view and Visibility condition.
  9. Main Wall: Building movement: none / minor movement / significant movement.
  10. Electricity, Mains, Location: Dated.
  11. Gas: OK. Water: OK.
  12. EPC: Remove.
  13. Valuation: Edit / General Remark... (cut off at the photo edge).

## 2. Locked decisions (user answered 14 Nov)
- Construction: use the TYPED list (9 options: traditional masonry, solid wall, cavity wall, timber frame, steel frame, concrete wall, precast concrete panels, system-built, other construction). The handwritten list goes into the client questions.
- Unclear items (Gas OK, Water OK, Electricity Dated, "Valuation Edit General Remarks", sentence for Age of Extension): SKIP, do not guess, put in the client questions docx.
- Overall Condition: replace Good/Average/Poor by Reasonable / Reasonable with repair (client's two sentences). Old surveys with old values keep printing the old wording.
- Valuation screen: keep the other fields (Share, Retention, After Works, Suitable Security, Estimated value); only the amount sentence and Purpose of Valuation (add Staircasing) change.
- Wording: only the client's own words. Never invent sentences.
- Push / APK / live server or live bank publish: ONLY after asking the user.

## 3. How the code works (facts found 14 Nov)
- Valuation sentences are written in Dart: `lib/features/property_valuation/domain/valuation_phrase_engine.dart` (`buildPhrases`, per-screen builders like `_generalDetails` ~636, `_flatRoof` ~1043, `_wallsType` ~1159, `_electricMaterial` ~1638). The bank `assets/property_valuation/phrase_texts.json` (499 `VAL_DRAFT_*`) only recognises/tidies sentences. NO verbatim ledger/gates exist for valuation (those are inspection only), so verification = new exact-text tests + phrase audit test.
- Tree: `assets/property_valuation/valuation_tree.json` (61 dropdowns). `ValuationRepository.bundledVersion` (now 5, `lib/features/property_valuation/data/valuation_repository.dart:15`) MUST be bumped whenever the JSON changes.
- "Other" text box = explicit tree field `<field>_other_text` with `conditionalOn: "<field>=Other"`. `actv_type` (Property Type) has none yet. There is no automatic Other box.
- Report: one `ReportBuilder` (`lib/features/report_export/data/services/report_builder.dart`); valuation sections print in tree order, group headings do not print. Accommodation table: `_buildValuationAccommodationSchedule` (~254, one "Property total" row); inspection uses `_buildAccommodationSchedule` (~209, floor-wise rows from 7 screens `activity_no_of_rooms*`). Renderers: PDF `pdf_generator_service.dart` `_accommodationSchedule` (~1669), DOCX `docx_generator_service.dart` `_writeAccommodationSchedule` (~1018). Colours: `PdfSharedUtils.valuationSectionColors` (`pdf_shared_utils.dart` ~232).
- Removed screens leave orphan answers in the DB. `ValuationAnswerValidator.validateSurvey` validates ALL stored answers, so an orphan can block export: restrict it to the current tree. `legacy_answer_migration.dart` has no valuation entries yet (add them: it is applied on every read in `base_survey_repository.dart`).
- Pinned by tests: `tool/phrase_portal/test.js` (valuation dropdowns == 61 at ~line 106, report_nodes ids ~307, option_rules keys ~328); `test/tool/option_rules_file_test.dart` (regenerate with `UPDATE_OPTION_RULES=1 flutter test test/tool/option_rules_file_test.dart`); `client_edits_2026_11_10_valuation_test.dart` (Other guard); `valuation_report_builder_test.dart`; `report_format_client_edits_test.dart`; `option_labels_report_test.dart`.
- Sample-report colours (from the client docx): cover banner 1461BF; About Inspection 38474F; About Property 1466BF; Outside Property 2E7D33; F Inside Property 9C26B0; G Services FF7000; Restrictions 00786B; Signatures and Property Photos 24566A; sub-heading bars EAF1F4 with bold 24566A text; accommodation header E3F2FD; cover info rows EDEDED / FFFFFF with grey 999999 labels. Section names in the sample: "About Inspection", "About Property", "Outside Property" (no E), "F Inside Property", "G Services", "Restrictions", "Signatures", "Property Photos".

## 4. How to work and verify (each step)
1. Edit tree / engine / tests. Add exact-text tests in `test/features/property_valuation/client_edits_2026_11_13_valuation_test.dart` (every option, Other typed text) and report tests in `test/features/report_export/data/services/`.
2. Commands: `flutter test test/features/property_valuation test/features/report_export test/core --reporter failures-only`; `node --test tool/phrase_portal/test.js`; `dart analyze <files>` (no new errors); end: full `flutter test`.
3. Screenshots (REQUIRED per step): web E2E harness in `tmp/client-edits-2026-11-04` (docker `ss_e2e_pg` port 15432; `run_backend.cmd` :3099; `smtp_sink.js` :2525; `make_test_users.js` waits 21 s between users; `flutter build web --release --dart-define=API_BASE_URL=http://localhost:3099/api/v1` run in the FOREGROUND, serve `build/web` on :4610 with `python -m http.server 4610 --bind 127.0.0.1`; Playwright with `NODE_PATH="$(npm root -g)/@playwright/mcp/node_modules"`, scripts in `deep/` (`lib.js`, `flut.js`, `p9_file6.js` as pattern); unregister service worker/clear cache between builds). Valuation survey via `POST /api/v1/scheduling/bookings` with `surveyType:'valuation'`; open `#/survey/<id>/valuation/section/<sectionKey>/screen/<screenId>`. Drawn dropdown lists are not in the accessibility tree: click by pixel and screenshot. Save proofs to `tmp/client-edits-2026-11-13/proof/<step>_*.png` and LOOK at every picture.
4. Real PDF/Word: a temporary flutter test (template `test/_scratch_valuation_phrase_engine_export.dart`) builds the report with `ReportBuilder` -> `PdfGeneratorService` / `DocxGeneratorService`. Render PDF to PNG with PyMuPDF (`fitz`, `page.get_pixmap(dpi=110).save(...)`). Render DOCX via Word COM (`$w=New-Object -ComObject Word.Application; $d=$w.Documents.Open(path); $d.SaveAs2(pdf,17)`) then PyMuPDF. Web build cannot export PDF (fonts). Delete temporary `test/_scratch_*` files after use.
5. Commit each step: `git add assets lib test tool docs` then commit with the `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` line. Helper: `tmp/client-edits-2026-11-12/commit.sh "message"` (adds assets lib test tool/phrase_audit/verbatim tool/phrase_portal/public; also `git add docs` yourself).
6. Update the PROGRESS table below BEFORE each commit (status, commit hash, checks, proof paths) and rewrite NEXT ACTION.

Gotchas: files often have CRLF (use newline-aware edits; the Edit tool is fine); helper scripts in `tmp/client-edits-2026-11-12/edit.py` (`sub`, `tree_insert_after_field`: inserting after the LAST field of a screen breaks the JSON comma, check `json.loads`); `flutter pub get` can leave the pub cache broken if killed (then `audioplayers` missing and APK build fails: rerun `flutter pub get`, and never copy a stale `app-release.apk`); the pasted user text is not a source: read the real files (images included).

## 5. LOCKED STEPS (full text in `docs/VALUATION-NOV13-PLAN.md`)
Rules: auto-continue after each DONE step, no step skipped, wording only from the client, stop and ask only for push / APK / live.

| Step | Item | Status | Commit | Checks and proof |
|---|---|---|---|---|
| V-1 | Handover md + plan copy + memory note | DONE | (this commit) | docs/VALUATION-NOV13-PROGRESS.md, docs/VALUATION-NOV13-PLAN.md, memory note |
| V0 | Prep, baseline dump and PNGs, harness up, sample docx PNGs | DONE | (see log) | proof/baseline_pdf_p*, baseline_word_p*, sample_word_p*, baseline_general_details.png, baseline_no_of_rooms.png; tests green (46 pass) |
| V1 | Remove Estate type | DONE | see git log | tests V1 group (2); report probe diff = only estate line gone; web screenshot proof/v1v2_general_details.png (no Estate type); bundledVersion 5->6; portal pin 61->60 |
| V2 | Property Type sentence + bedrooms (+ migration) | DONE | see git log | tests V2 group (6 tests: every type, every bedroom, Other typed, flat fields condition, legacy migration + legacy wording); probe: 'The property is a semi-detached house providing three bedrooms.'; screenshots proof/v2_type_1.png (list), v2_other_2.png (Other text box), v2_flat_3.png (flat fields + Live Preview); portal pin 58; option_rules regenerated |
| V3 | Construction (typed 9 options) | DONE | see git log | tests group V3 (6); probe line 'constructed using traditional masonry and cavity wall.'; screenshots proof/v3_1.png (list), v3d_3.png (other construction + text box), v3b_5.png (Live Preview); legacy ticks keep old wording; validator needs text for Other |
| V4 | Year Built sentence | DONE | see git log | tests (year, 7 periods, unknown, year wins); proof/v3_3.png; new dropdown actv_year_band (59 dropdowns now) |
| V5 | Extension + Age of Extension label | DONE | see git log | tests; proof/v3_4.png. Age of Extension prints NO sentence (client gave none): typed value is stored but not printed -> client question 5 |
| V6 | Listed Building sentence | DONE | see git log | test; real Word render proof/v6_word_p2.png shows all new General Details sentences |
| V7 | Remove New Build Property | DONE | see git log | tests V7 (3); validator `validateSurvey(liveScreens:)` ignores orphan screens (export_service passes tree ids); probe: screen gone; screenshots proof/v7v9_* |
| V8 | Accommodation like Inspection + remove Parking locations | DONE | see git log | user chose: ONE screen `no_of_rooms` titled Accommodation with the Inspection floor-screen fields/labels (test compares labels+types with inspection tree), report keeps one 'Property total' row; Parking Location field + 'parking provision' sentences removed; tests V8 (2) |
| V9 | Remove Location & Amenities and Road | DONE | see git log | engine cases/methods + road validator rules removed, tests adapted (road/location tests deleted, export dialog test uses general_details), tests V9 (2); portal pin 55 dropdowns |
| V10 | Standardised Condition | DONE (screenshots pending in batch) | see git log | 29 dropdowns labelled exactly 'Condition' now Good/Reasonable/Fair/Poor/Very poor (ids in tmp/client-edits-2026-11-13/condition_ids.json); Notes box shows for Fair/Poor/Very poor; engine: Good/Reasonable/Poor use the existing sentences, Fair and Very poor print 'The X has/have been assessed as fair/very poor.' (client gave no sentence -> CLIENT QUESTION 8); old Satisfactory/Unsatisfactory keep wording; 'Visibility Condition' and electric 'Age Condition' unchanged (not asked); tests V10 (5, all 29x5 sentences); phrase audit clean (113+ templates added via approve_audit.py); option_rules regenerated |
| V11 | Outside Property sentences (Roof, Rainwater Goods, Chimney, Main Walls, Windows, External Decorations, Floor, Garage, Outbuilding) | TODO | | |
| V12 | Flat roof: remove Partial view and Visibility condition; Main Wall building movement none/minor/significant | TODO | | |
| V13 | Inside Property sentences (Roof Space, Walls, Kitchen, Bathroom, Damp, Damp Source) | TODO | | |
| V14 | Services sentences (Electricity Metre, Gas, Water, Heating, Water Heating) | TODO | | |
| V15 | Overall Condition, remove Other Matters + EPC, Valuation sentence + Purpose (Staircasing) | TODO | | |
| V16 | Every dropdown with Other gets a text box (audit + strict guard test) | TODO | | |
| V17 | Report format = sample (cover, bars, colours, names, order) PDF + Word | TODO | | |
| V18 | Final: bundledVersion, option_rules regen, portal pins, full suites, full web run, PDF/Word PNGs, MATCH.md, client questions docx; then ask user: push / APK / live | TODO | | |

## 6. NEXT ACTION
V11 Outside Property sentences (typed file, exact). The element screens are `val_pitched_roof`/`val_flat_roof`/`val_other_roof` (Roof), `val_rainwater_goods`, `val_chimney_stacks`, `val_walls_type` (Main Walls), `val_external_joinery` (Windows), `val_decorations_ext` (External Decorations/finishes), `val_floor_ext` (Floor), `val_garage`, `val_outbuildings`. For each: make the tree's tick/dropdown options equal the client's list (in his order, 'Other' + text box) and make the engine print the client's sentence with only the selected items ("The roof covering is formed in <selected>." etc.), then "Condition: ..." is already V10. Use the typed file `docs/client-valuation-2026-11-13/feedback_typed.txt` lines 33-42 and the sample report text for how the sentence looks. First read the current screen fields and engine builder of each (tmp probe: python snippet in this file's history or `grep -n "_pitchedRoof\|_rainwater\|_chimneyStacks\|_wallsType\|_externalJoinery\|_decorationsExt\|_floorExt\|_garage\|_outbuildings" lib/features/property_valuation/domain/valuation_phrase_engine.dart`). One commit per element group; add templates with add_templates.py (audit must stay clean: `flutter test test/phrase_audit`).

IMPORTANT valuation rules learned: every sentence the engine emits must match a template in `assets/property_valuation/phrase_texts.json` or `test/phrase_audit/phrase_permutation_audit_test.dart` fails (UNAPPROVED). Add templates with `add_templates.py` (`add([...], 'VAL_N13_Vx')`; `[free text]` / `[number]` are wildcards, need 3+ literal words).

## 6b. FINDING at V0 (changes V17)
The client's sample (Word render, `proof/sample_word_p1..8.png`) is the HOME SURVEY Word layout applied to valuation: cover = blue banner with the company logo at left + "Francis Blackstone Surveyors" / "Property Valuation Report" (no address line, no "Mortgage Valuation Report", no "Professional property valuation report"), shaded info table; header "Property Valuation Report | Valuation - <job ref> | SurveyScriber"; footer "Generated by SurveyScriber | <company> | Page x of y"; each section = full-width coloured banner bar ("About Inspection" slate, "About Property" blue, "Outside Property" green, ...); each element = 2-column table (left shaded cell with bold dark-blue element name, right cell the sentences). Our current valuation Word/PDF (`proof/baseline_*`) uses plain blue headings and no tables. So V17 = reuse the home survey cover/section-banner/element-table renderers for valuation (company name+logo come from company settings already built for the home survey). Section order/names in the sample: About Inspection (General Details), About Property (Accommodation table, Location & Amenities, Road), Outside Property (green), F Inside Property, G Services, Restrictions, Signatures, Property Photos. Location & Amenities and Road are in the sample but the client's typed list says remove them (V9 wins).

## 7. Client questions (running list; build the docx at V18)
8. Condition 'Fair' and 'Very poor': which sentence? (only 'assessed as fair/very poor' is printed now)
1. Construction: handwritten list (Solid brick/cavity wall, Stud wall, Timber frame, Concrete frame, Other) differs from the typed list; which is right?
2. Gas "OK" and Water "OK": what exactly is wanted?
3. Electricity, Mains, Location, "Dated": where does it go (a tick on Mains, or separate)?
4. "Valuation: Edit General Remarks": what to edit? (the photo is cut off)
5. Age of Extension (Date of Extension): the sentence to print.
6. Overall Condition: anything besides the two "Reasonable" sentences?
7. Windows, Heating, Water Heating: should they have a Condition (typed file gives none, the sample shows one for Windows)?

## 8. Log (one line per finished step: date, step, commit, what was checked)
- 14 Nov 2026: plan locked; sources copied to `docs/client-valuation-2026-11-13/`.
- 14 Nov 2026: V7-V9 done (New Build removed; Accommodation = one screen with inspection fields; Parking Location removed; Location&Amenities+Road removed) with tests, audit, option rules regen, portal pin 55.
- 14 Nov 2026: V3-V6 done (General Details: construction, year built, extension, listed building) with tests, audit, screenshots, real Word render.
- 14 Nov 2026: V1 + V2 done (see git log): estate type removed; Property Type list + bedrooms + Other text box + migration; screenshots proof/v1v2_*, v2_*.
- 14 Nov 2026: V0 done: baseline report probe + PNGs, sample docx PNGs, web harness (postgres recreated, backend :3099, web :4610) verified with a valuation screenshot.
