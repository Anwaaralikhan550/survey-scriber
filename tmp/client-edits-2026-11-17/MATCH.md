# Client answers (17 Nov 2026) and the user's list: what was asked, where it is, how it was checked

Tests: `test/features/property_valuation/domain/client_edits_2026_11_17_valuation_test.dart` (A2-A10), `test/features/property_valuation/valuation_tick_boxes_test.dart` (A1), `test/features/property_valuation/valuation_matrix_test.dart` + `test/features/report_export/data/services/valuation_matrix_report_test.dart` (A7, A6 report), backend `report-content.spec.ts`, `tmp/desktop-editing/p28_matrix.js` (desktop editor in Chrome). Pictures: `tmp/client-edits-2026-11-17/proof/`.

| # | Asked | Done | Proof |
|---|---|---|---|
| 1 | Tick boxes instead of pop-up lists in Valuation; one at a time; keys and phrase engine unchanged | `InlineChoiceGroup` (radio-style ticks), used only by the Valuation screen. Same stored text, tap again clears, old answers still show | `valuation_tick_boxes_test.dart` (every dropdown in the real tree); `a1_general_top.png`, `a1_status_tenanted_only.png`, `a1_pitched_condition_fair_notes.png`, `p_a1_ticks.js` |
| Q1 | Typed Construction list is right | no change | - |
| Q2 | Gas, Water phrases stay. Add Oil/LPG after Gas | new screen "Oil / LPG Tank" after Gas, group G Services. Sentence `The property is served by an Oil-fired / LPG-fired heating system with a plastic, metal, other fuel storage tank(s) located at the front garden, side garden, rear garden, other.` from ticks, Other text boxes | tests A2 (9); `a2_oil_lpg_preview.png`, `a2_oil_lpg_other_box.png` |
| Q3 | One Dated tick next to the meter location | `cb_em_dated` "Dated" right after the location ticks. Prints `The meter unit is dated.` (wording is mine) | tests A3; `a3_electricity_dated.png` |
| Q4 | (blank) | no change | - |
| Q5 | Date of Extension inside the Extension sentence | `The property has been extended in 1995 to provide side and rear accommodation.` (year only: `The property has been extended in 1995.`) | tests A4; `a4_extension_year.png` |
| Q6 | (blank) | no change | - |
| Q7 | Three roofs, three sentences | Pitched (`The roof covering is formed in ...`), Flat (`The flat roof covering is formed in ...`, mineral felt, rubber membrane, single-ply membrane, other), Other (`The other roof covering is formed in ...` or `<name> covering is formed in ...`, full roof list). Flat materials left the Pitched screen; old answers print as before | tests A5 (7); `a5_flat_roof.png`, `a5_pitched_roof.png`, `a5_other_roof.png` |
| Q8 | Floor / Garage / Outbuilding / Kitchen and Bathroom as done | no change | - |
| Q9 | Limitations screen under Restrictions | new screen "Limitations" first in Restrictions (before Overall Condition): No Restrictions, No Rear Access ticks. Standard grounds text always, plus a paragraph per tick (the sample's words); lead words in bold | tests A6 (4) + report test; `a6_limitations_preview.png`, `a6_limitations_both.png`, `a17_pdf_p6.png`, `a17_word_p6.png` |
| Q10 | Blank editable FBS Valuation Matrix, by hand in the app and in the desktop editor, nothing generated | screen "FBS Valuation Matrix" (grid: header Best Match, Comp 1-5, Subject; 17 named rows) after Valuation; the table is always in the valuation report (PDF + Word) blank until typed; desktop editor edits it as a table block (row names fixed); the backend accepts the `matrix` role | tests `valuation_matrix_test.dart`, `valuation_matrix_report_test.dart`, `report-content.spec.ts`; `p28_matrix.js` 14/14; `a7_matrix_blank.png`, `a7_matrix_typed.png`, `a7_matrix_after_return.png`, `a7_editor_blank.png`, `a7_editor_filled_saved.png`, `a17_pdf_p7.png`, `a17_word_p7.png` |
| Q11 | "and associated fittings" is fixed text, not a tick | tick removed; `The rainwater goods comprise PVC, gutters, downpipes, and associated fittings.` Worktop sentence unchanged | tests A8; `a8_rainwater.png` |
| Q12 | Timber Defects: Dry Rot and Wet Rot as two ticks | `Extensive Dry Rot`, `Extensive Wet Rot` | tests A9; `a9_timber_defects.png` |
| Q13 | Red bar | no change | - |
| N1 | Reinstatement Value (figures + words) | field on the Valuation screen; `... The estimated reinstatement cost for this property is £517,000 (Five Hundred and Seventeen Thousand Pounds).` | tests A10 (5); `a10_reinstatement_preview.png`, `a17_pdf_p7.png`, `a17_word_p7.png` |
| N2 | Higher Reinstatement Value tick | `The reinstatement cost exceeds the purchase price; this is not unusual and does not indicate an error.` | same |

## Wording I chose (the client gave none): confirm with the client
1. Dated: `The meter unit is dated.`
2. Extension year: `extended in 1995 to provide ...`.
3. Flat and Other roof sentences follow the Pitched pattern.
4. Matrix row "Freatures" in the sample is printed as "Features".
5. Limitations always prints the standard grounds paragraph once the screen has an answer.
6. Reinstatement amount is printed without pence (`£517,000`), as in the example; the purchase price keeps `£460,000.00`.
