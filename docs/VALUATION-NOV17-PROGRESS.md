# Valuation: client answers (17 Nov 2026) + tick box standard. PROGRESS + HANDOVER

**Status: PLAN LOCKED 17 Nov 2026.** Do not add, drop or shrink a step without the user's say-so. New AI / new context: read this file top to bottom, then `docs/VALUATION-NOV13-PROGRESS.md` (the earlier V0-V18 work this builds on), then continue from **NEXT ACTION**.

Sources: client's answers `Client_Questions_Valuation_14Nov2026 (1).docx` (copied to `docs/client-valuation-2026-11-17/`), plus the user's instruction message of 17 Nov (tick boxes, 10 numbered items). Client said "no change" for Q1, Q4, Q6, Q8, Q13 (Q1 yes typed list; Q4 blank; Q6 blank; Q8 yes; Q13 red).

## Rules (same as before, non-negotiable)
1. No step skipped, no weaker check. A step is DONE only when its tests pass AND its screenshots were looked at.
2. Wording only from the client / user's message, exact. Nothing invented.
3. Every sentence the engine emits must match a template in `assets/property_valuation/phrase_texts.json` (`phrase_permutation_audit_test.dart`); add templates with `add_templates.py` (see Nov13 file).
4. `ValuationRepository.bundledVersion` bump whenever the tree changes; regenerate `option_rules.json` / `report_nodes.json` (`UPDATE_OPTION_RULES=1`); portal pin (`tool/phrase_portal/test.js`) follows the new dropdown count.
5. Update this table BEFORE each commit. Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
6. Push, APK, live publish only when the user says so.
7. Old answers must keep printing the old wording (legacy gate) wherever an option or field is replaced.

## Steps (order = the user's numbering)
| Step | What | Done when |
|---|---|---|
| A0 | Prep: copy answers docx, baseline probe of the report text, harness check | baseline files exist |
| A1 | Tick boxes: every single-choice dropdown on Valuation screens becomes on-screen radio-style ticks (one at a time, tap again clears), keys and phrase engine unchanged | widget test per field type, no valuation screen shows a dropdown, screenshots of several screens incl. an Other text box |
| A2 | Gas then Oil/LPG: new tick group + Other text boxes, exact sentence | exact-text tests every option, screenshot |
| A3 | Electricity Metre: one "Dated" tick beside the meter location | test + screenshot |
| A4 | Date of Extension printed inside the Extension sentence | test + real report text |
| A5 | Pitched / Flat / Other roof: three screens, three sentences; flat-roof materials move from Pitched to Flat | tests (each material on the right screen), legacy answers, screenshots |
| A6 | Limitations screen + report block under Restrictions (as the sample) | test + PDF/Word PNG |
| A7 | FBS Valuation Matrix: blank editable comparables table under Valuation, entered by hand in the app and in the desktop browser editor, no generated content | app test + PDF/Word PNG + editor test + screenshot |
| A8 | Rainwater Goods: "and associated fittings" is fixed text at the end, not a tick | test |
| A9 | Significant Valuation Consideration, Timber Defects: two ticks, Extensive Dry Rot and Extensive Wet Rot | test + screenshot |
| A10 | Valuation screen: Reinstatement Value (figures + words) and Higher Reinstatement Value tick, exact sentences | tests (figures/words) + screenshot |
| A11 | Final: all suites, portal tests, phrase audit, client-match table, real PDF + Word, progress update | all green, MATCH table filled |

## Exact texts given
- Q2 Oil/LPG: `The property is served by an Oil-fired / LPG-fired heating system with a plastic, metal, other fuel storage tank(s) located at the front garden, side garden, rear garden, other.` (Other text boxes)
- Q10 FBS Valuation Matrix: blank table, user types data; later same form in the desktop editor.
- Q11: "and associated fittings" is part of the sentence, not a tick. Worktop locations followed by "comprise" stay as they are.
- Q12: two ticks, dry and wet.
- Reinstatement Value: `The reinstatement cost of your home represents the estimated cost of completely rebuilding the property if it is destroyed, for example, by fire. This figure differs from the market value of the property, as it relates solely to the cost of materials and labour required to reconstruct the building to its current form. The estimated reinstatement cost for this property is £517,000 (Words).`
- Higher Reinstatement Value: `The reinstatement cost exceeds the purchase price; this is not unusual and does not indicate an error.`
- Q5: Year Built phrase stays; "Date of Extension: extension sentence" = print the date in the Extension sentence.

## Progress table
| Step | Status | Commit | Checks and proof |
|---|---|---|---|
| A0 | DONE 17 Nov | see git log | answers docx copied to `docs/client-valuation-2026-11-17/Client_Answers_Valuation_17Nov2026.docx`; harness: ss_e2e db migrated, backend :3099 (run_backend.cmd), smtp sink, web build served :4610 |
| A1 | DONE 17 Nov | see git log | new `InlineChoiceGroup` (`inspection_fields.dart`, flag `inlineChoices` on `InspectionFieldInput`, set only by `valuation_screen_page.dart`; Inspection unchanged). Tests `test/features/property_valuation/valuation_tick_boxes_test.dart` (8): all options visible, stores original option text, one at a time, tap again clears, old answer still shown, Inspection still pop-up, EVERY dropdown of the real tree (all 50+) renders as ticks and each tap stores its option. Web proof `tmp/client-edits-2026-11-17/proof/a1_*.png` (General Details Status/Finishes/Carpeted/Valuation Reason as radio ticks, Tenanted unticks Vacant, Pitched Roof Condition ticks + Notes appear), script `p_a1_ticks.js` 6/6 (role=radio, aria-checked). Semantics label duplicate fixed (ExcludeSemantics) |
| A2 | DONE 17 Nov | see git log | new screen `val_oil_lpg` 'Oil / LPG Tank' right after Gas (orders bumped), group G Services in report (`report_builder.dart` services set). Sentence `The property is served by an Oil-fired / LPG-fired heating system with a plastic, metal, other fuel storage tank(s) located at the front garden, side garden, rear garden, other.` built from ticks; Other text boxes; validator: tank/place without fuel, Other without text. Tests group A2 (9). Proof `a2_oil_lpg_preview.png`, `a2_oil_lpg_other_box.png` |
| A3 | DONE 17 Nov | see git log | one `cb_em_dated` 'Dated' tick right after the meter location ticks (before Electric Material). Prints `The meter unit is dated.` (my wording, client gave none: confirm). Tests group A3 (4). Proof `a3_electricity_dated.png` |
| A4 | DONE 17 Nov | see git log | `The property has been extended in 1995 to provide side and rear accommodation.`; year only: `The property has been extended in 1995.` (my wording of where the date goes: confirm). Tests group A4 (6). Proof `a4_extension_year.png` |
| A5 | DONE 17 Nov | see git log | Pitched loses mineral felt/rubber/single-ply (old answers still print); Flat Roof = mineral felt, rubber membrane, single-ply membrane, other + text; Other Roof = whole client roof list + other + name. Sentences: pitched `The roof covering is formed in ...` (unchanged), flat `The flat roof covering is formed in ...`, other `The other roof covering is formed in ...` / `<Name> covering is formed in ...` (flat/other wording follows the pitched pattern: confirm). Old Flat/Other ticks keep old wording. Tests group A5 (7). Proof `a5_flat_roof.png`, `a5_pitched_roof.png`, `a5_other_roof.png` |
| A6 | DONE 17 Nov | see git log | screen `val_limitations` 'Limitations' first in Condition & Restrictions (before Overall Condition), ticks No Restrictions / No Rear Access (ids `cb_lim_*`); engine prints the sample's standard grounds paragraph always plus one paragraph per tick; PDF + Word show it as the Restrictions element box with the two lead notes in bold. Tests group A6 (4) + report tests (Restrictions order, bold lead). Proof `a6_limitations_preview.png`, `a6_limitations_both.png`, real files `a17_pdf_p6.png`, `a17_word_p6.png` (looked at) |
| A7 | DONE 17 Nov | see git log | `ValuationMatrix` (domain), screen `valuation_matrix` after Valuation (one JSON answer `et_matrix_grid`), `ValuationMatrixEditor` grid (wraps long text, no new lines, 102 cells, row names fixed), `ReportDocument.valuationMatrix` (always 17 named rows, blank until typed, never calculated), PDF `_valuationMatrix` + Word `_writeValuationMatrix` after the Valuation section, `ReportBlocksMapper` section `VALUATION_MATRIX` (table block role `matrix`, required) both ways, backend role `matrix` accepted (BEFORE this the phone upload would have been refused), editor shows row names read-only. Tests: `valuation_matrix_test.dart` (12 incl. a regression test for spaces eaten at the end of a word), `valuation_matrix_report_test.dart` (15), backend `report-content.spec.ts` (+4), Chrome `tmp/desktop-editing/p28_matrix.js` 14/14 against the real backend. Proof `a7_matrix_*.png` (app), `a7_editor_*.png` (browser editor), real files `a17_pdf_p7.png`, `a17_word_p7.png` |
| A8 | DONE 17 Nov | see git log | `cb_rw_fittings` tick removed; sentence `The rainwater goods comprise PVC, gutters, downpipes, and associated fittings.` (materials, other text, gutters/downpipes/hoppers, then fixed `, and associated fittings`). Old tick ignored. Tests group A8 (4) + updated V11 and Word report tests. Proof `a8_rainwater.png` |
| A9 | DONE 17 Nov | see git log | `cb_svt_wet` 'Extensive Wet Rot' next to 'Extensive Dry Rot'. `... concerns: Wood-boring Insects, Extensive Dry Rot and Extensive Wet Rot.` Tests group A9 (2) + V19 label list updated. Proof `a9_timber_defects.png` |
| A10 | DONE 17 Nov | see git log | fields `et_reinstatement_value` + `cb_higher_reinstatement` at the end of the Valuation screen; exact client sentences; amount `£517,000 (Five Hundred and Seventeen Thousand Pounds)`. Tests group A10 (5). Proof `a10_reinstatement_preview.png`, real files `a17_pdf_p7.png`, `a17_word_p7.png` |
| A11 | DONE 17 Nov | see git log | `bundledVersion` 6 -> 7; scratch probes removed. Flutter: valuation + report_export + report_editing + tool + property_inspection + phrase_audit suites; phrase audit green (`valuation_matrix` listed as table-only screen); portal 36; option rules/report_nodes regenerated. Backend: unit 33 suites/509 (4 stale sync.service.spec tests fixed: D1 added a report lookup the mock lacked), e2e report-* 8 suites/169, editor unit pass. `tmp/client-edits-2026-11-17/MATCH.md` has the client-item table and the wording I chose (to confirm with the client) |

## NEXT ACTION
ALL STEPS A0-A11 DONE locally 17 Nov (not pushed, no APK, nothing live). Waiting for the user: push, APK, deploy (backend: role `matrix` must be deployed together with the app, otherwise the phone upload of a valuation report is refused), and the client's confirmation of the wording listed in `tmp/client-edits-2026-11-17/MATCH.md`. Phrase templates for new sentences: `tmp/client-edits-2026-11-17/add_a_templates.py` (prefix VAL_N17); audit green after A2-A9; option_rules unchanged (no new dropdown), report_nodes.json regenerated.

## Gotchas
- Live Preview text is drawn on the canvas: not in the accessibility tree. Prove sentences by unit tests; screenshots show the preview.
- Web build ~5 min (`flutter build web --release --dart-define=API_BASE_URL=http://localhost:3099/api/v1`), serve `build/web` with `python -m http.server 4610 --bind 127.0.0.1`; harness backend: `cmd //c E:\survey-scriber	mp\client-edits-2026-11-04
un_backend.cmd` (db ss_e2e, run `npx prisma migrate deploy` with that DATABASE_URL first), `node smtp_sink.js`; `NODE_PATH=$(npm root -g)/@playwright/mcp/node_modules`.
- Scripts in `tmp/client-edits-2026-11-17/`: `patch_a2_a9.py` (tree), `patch_engine_a2_a9.py` (engine), `p_a1_ticks.js`, `p_a2_a9.js`.
- Bash heredocs with quotes break: write scripts with the Write tool. A double backslash in a Python heredoc is collapsed by the tool: use the Edit tool for strings with backslashes (regex `[
]`).
- Flutter web: an extra `Semantics(textField: true)` around a TextField gives a second text-field node in the accessibility layer; use `Semantics(label:)` only.
- A TextField whose parent re-parses a trimmed answer in `didUpdateWidget` eats the space typed at the end of a word: compare in canonical form.
- The sync.service.spec mock needs `report.findUnique` (D1 added a finalised-report check in `SyncService`).
- `ValuationRepository.bundledVersion` still 6: bump to 7 at A11 (tree changed after the v6 build).

## Log
- 17 Nov 2026: plan locked, answers docx read.
- 17 Nov 2026: A6, A7, A10, A11 done (matrix in app, PDF, Word, desktop editor; Limitations; Reinstatement; final suites).
- 17 Nov 2026: A0-A5, A8, A9 done (tests 321 pass in valuation+report_export+tool; phrase audit green; portal 36 pass; web screenshots viewed).
