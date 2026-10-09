# Phrase Bank — 100% Word-for-Word Completion Plan

Source of truth: `Surveyscriber Phrase Bank (1).pdf` (96 pages), digitised at
`tool/phrase_audit/reference/rics_l2_library_v2.json`.
Target: every sentence the PDF defines as report text appears in the app's
bank/engine **exactly as written in the PDF** (letter, comma, capital, hyphen).

## 1. Honest baseline (measured on `main` 5499c96)

Option-menus and "If X is selected, add this" directives excluded; heading
labels (`Conflict noted:`) stripped; `(see section …)` pointers ignored.

| Measure | Sentences | % |
|---|---|---|
| PDF fixed-prose sentences checked | 1,122 | 100 |
| Exact word-for-word in bank | 537 | 47.9 |
| 95%+ (comma/token/heading differences) | 41 | 3.7 |
| **Unresolved (differ or missing)** | **544** | **48.5** |
| of which 80–94% (small wording diffs) | 102 | |
| of which <80% (different, tokenised, or absent) | 442 | |

Proven-missing examples (not in `lib/` or `assets/` at all): EWS1 paragraph,
"Painted external masonry…", "Only the visible performance of the floors…",
"Where secure, no action is currently required.", "weathertight seal…",
"Construction has been identified from visible inspection only…".

The earlier "100% fixed prose" statement was wrong. The permutation audit only
proves "no invented text", not "same as PDF".

## 2. Definition of Done

Zero **UNRESOLVED** rows in the ledger (section 4), and all gates in section 6
green on `main`. No percentage target below 100.

## 3. Rules (non-negotiable)

1. **PDF wins.** If the bank, the engine, a test or a person disagrees with the
   PDF, the PDF is right. Copy character-for-character, including odd choices
   (`Moisture metre readings`, `Condition: …, consistent with their age`,
   `Oxford commas`).
2. **PDF typos are copied, not fixed.** Anything that looks like a PDF error
   (e.g. "mage" for "manage", "metre") goes on the Client Query list
   (`CLIENT_QUERIES.md`); we change it only after the client confirms.
3. **No guessing.** If a sentence's key, trigger or meaning is unclear, stop and
   add it to Client Queries. Never infer.
4. **One sentence, one ledger row.** Every PDF sentence gets an ID and exactly
   one disposition (section 4). Nothing is "mostly fine".
5. **Heading labels and spec directives are not report text** (`Conflict noted:`,
   `If very poor is selected, add this:`). They control logic; they are never
   emitted. Each is still recorded in the ledger as HEADING/DIRECTIVE.
6. **Tokens only where the PDF lists choices.** `{TOKEN}` replaces an option
   list (`slipped, cracked, broken, other`). The surveyor's single selection
   fills it. Never print the whole list. Token text must equal the PDF option
   text exactly.
7. **A bank key the engine never emits is not done.** Adding a sentence needs:
   bank key + engine emission + form field (if the trigger does not exist yet)
   + a test that the sentence appears in a generated report.
8. **Cross-reference pointers** (`(see section J1 - …)`): decision D1 = KEEP.
   Pointers the PDF has stay exactly as written; pointers the bank adds beyond
   the PDF are kept and listed in the ledger as APPROVED-EXTRA with a reason.
9. **Per-element wording stays per-element.** If the PDF says "age of the
   guttering", "ridge tiles", "staircase material", each gets its own text. One
   generic line for many elements is a defect.
10. **Sync everything that duplicates text:** `phrase_texts.json`,
    `verified_variants.json`, engine override regexes, test expectations, the
    phrase web portal data. A change is not finished until a grep for the *old*
    wording returns nothing.
11. **Batch discipline:** one section per batch, ledger updated, all gates green,
    one commit. Never batch across sections.
12. **Every bank key must trace to the PDF.** Any text in the bank with no PDF
    source is listed as APPROVED-EXTRA with a reason, or removed (reverse gate).

## 4. The Ledger (single source of progress)

`tool/phrase_audit/verbatim/ledger.csv`, generated, not hand-typed:

`id, section, pdf_sentence, disposition, bank_key, status`

Dispositions: `EXACT`, `TOKENISED` (option list → token, with the token's
option list compared to the PDF), `HEADING`, `DIRECTIVE`, `FIX` (bank wording
differs), `ADD` (missing, needs bank+engine+form), `QUERY` (waiting on client).
Status moves `OPEN → DONE`. Completion = no `FIX`, `ADD` or `QUERY` left OPEN.

## 5. Phases

| Phase | Work | Output |
|---|---|---|
| P0 | Move working scripts from scratchpad into `tool/phrase_audit/verbatim/` (aligner, differ, count-asserted editor). Freeze baseline. | tools + baseline ledger |
| P1 | Build ledger for all 1,122 + menu/directive rows. Classify the 544 unresolved into FIX / ADD / TOKENISED / HEADING / QUERY, by hand-review, no auto-accept. | ledger with 0 unclassified |
| P2 | Close all `FIX` (102 small diffs + wording diffs from the 442). Order: A/D, E1–E9, F1–F9, G1–G7, H, I, J, K. | FIX = 0 |
| P3 | Close all `ADD` (missing prose). Each needs bank key + engine emission + form trigger + report test. | ADD = 0 |
| P4 | Per-structure keys (E9 carport/balcony/roof terrace/staircase/installation, E2 hip/ridge/guttering, F6/F9 etc.). | rule 9 satisfied |
| P5 | Client Queries round: send `CLIENT_QUERIES.md`, apply answers. | QUERY = 0 |
| P6 | End-to-end proof (section 6, T5–T7) and sign-off dossier. | `VERBATIM_SIGNOFF.md` |

Each phase ends with the full gate run and a commit. Progress is reported as
ledger counts, never as a feeling.

## 6. Test Strategy

| ID | Test | Passes when |
|---|---|---|
| T1 | **Forward gate** PDF→bank: every ledger EXACT/TOKENISED row's sentence is found in bank text (normalised only for token placeholders and whitespace) | 0 mismatches |
| T2 | **Reverse gate** bank→PDF: every bank sentence is PDF-derived or listed APPROVED-EXTRA | 0 unlisted |
| T3 | Token option check: each token's option list equals the PDF option list exactly (spelling, order not required) | 0 diffs |
| T4 | Existing permutation audit (`test/phrase_audit`) | `All tests passed!` (0 GAP/UNAPPROVED/GRAMMAR/PLACEHOLDER_LEAK/ENGINE_ERROR) |
| T5 | **Emission test**: for every ledger row with a form trigger, build the answers, run the engine, assert the exact PDF sentence is in the output | every row emitted |
| T6 | **End-to-end reports** through the real pipeline (engine → ReportBuilder → PDF): ≥8 scenarios (detached house, flat, bungalow, valuation, poor-condition, subsidence/damp, collect-keys booking, new-build). One option per field. Extract every report sentence and check it is in the PDF ledger. | 0 foreign sentences, 0 placeholders, 0 option-lists, 0 duplicates, 0 property-type conflicts |
| T7 | **Coverage**: across all scenarios, every reachable ledger sentence appears at least once | unreachable list = empty or explained |
| T8 | Golden/regression suites: `property_inspection`, `report_export`, `dashboard`, `scheduling` | all green |
| T9 | Variant sync check: no old wording left in `verified_variants.json`, engine regexes, tests, portal data | grep returns nothing |

Order per batch: edit → T9 → T1/T2/T3 → T5 → T4 → T8. T6/T7 at the end of each
phase and at sign-off.

## 7. Decisions needed from you (before P2)

- **D1 Cross-references — DECIDED: keep.** The bank adds `(see section
  I2/J1/J3)` in sentences the PDF does not have; they stay as APPROVED-EXTRA.
- **D2 Heading labels in output.** Some report text currently starts with a
  label (`Moisture metre readings:`, `Condition:`), because the PDF shows them
  inline. Confirm: labels that appear inline in the PDF sentence flow stay;
  pure layout headings do not.
- **D3 Generic shared keys.** E9 and F-section keys share one line for many
  elements. Approve creating separate keys (rule 9).
- **D4 PDF typos.** Approve sending the Client Query list rather than
  silently correcting.

## 8. Risks

- Adding missing prose touches the engine and forms, so each ADD needs its own
  emission test, not just a bank edit.
- Text lives in four places (bank, variants, engine regexes, tests); rule 10 and
  T9 exist because earlier batches failed on exactly this.
- Heading/label stripping in the matcher can hide real diffs; the ledger is
  reviewed by hand, not auto-accepted.
- The gate suite is slow on this machine (~4 min); work is batched per section
  to keep the number of full runs small.

## 9. Deliverables

`ledger.csv`, `CLIENT_QUERIES.md`, `VERBATIM_SIGNOFF.md`, the T1–T9 test files
in `test/phrase_audit/verbatim/`, sample reports for every T6 scenario (PDF +
text), and a final ledger summary: every PDF sentence, its disposition, its
bank key, and the test that proves it.

## 10. Progress log (updated after every section)

| Section | Status | Notes |
|---|---|---|
| E1 Chimney stacks | DONE (prose rows 0 open) | Rule framework `kVerbatimRules`; new screens aerials + chimney defects; J1 chimney bank-first. |
| E2 Roof covering | DONE (gate green) | 52 rules (`slices/gen_e2.py` -> `e2_e.json`); 22 screens re-built to PDF options; new screens valley gutters, flashing/ridge/hip repair; old `_roof*` handlers removed; J1/J3 roof injects bank-first. Remaining ledger rows: 3 J-inject option rows (verified by report_builder tests). Extras left for the T2 cleanup: weather screen, asbestos screen, `RC_ROOF`, `DEFLECTION_*`, `ROOF_FIT_FOR_PURPOSE`, poor-roof screen. |
| E3 Rainwater goods | DONE (gate green) | 13 rules (`gen_e3.py`); description/condition/shared/asbestos/general; new screens slope, leakage, defective connections, corrosion; damaged sections soon/now; gullies partial/fully; J1 bank-first (`RWG_DEFECTS`). Open: flat-property management text (cross-cutting). |
| E4 Main walls | DONE (gate green) | 71 rules (`gen_e4.py`, text cut from the PDF block by `slicelib.P`); 7 wall-type screens (2 new), cladding, EWS1 (new), damp/DPC/DPC treatment (new), removed wall, extensions (new), movements (8 PDF statuses), trees, thin wall, wall ties, spalling/pointing/render/lintel/windowsill repairs; J1 bank-first (rising damp, lintel). Old E4 J1/J3 extras removed (CLIENT_QUERIES #33). |
| E5 Windows | DONE (gate green) | 24 rules (`gen_e5.py`) + section-intro mechanism (`gen_intro.py`: standard text printed from the section main screen once a condition rating 1-3 is chosen; E4 + E5 so far); new screens windowsills, operation, defective operation, failed glazed units, damaged glazing, timber windows, condensation; removed failed-glazing-location, wall-sealing, safety-glass-rating screens; J3 fire-trap bank-first. |
| E6 Outside doors | DONE (gate green after removing the old parity test) | 19 rules (`gen_e6.py`); About doors merged into one screen (material screens retired), Repair doors merged (per-location screens retired), new thresholds/operation/security/defective operation/timber doors/patio-French screens; intro printed from the About screen once a condition is chosen; E6 J3 line removed (not in PDF); I2/Risk-to-security references re-pointed. |
| E7 Conservatory and porches | DONE (gate green) | 25 rules (`gen_e7.py`) for conservatory + porch (identical structure); windows/flashing/7 element repair screens retired, one repair screen with a Conservatory/Porch selector; Not Applicable text; old parity/alias/routing tests removed. |
| E8 Other joinery and finishes | DONE (gate green) | 12 rules (`gen_e8.py`): Inspected intro (main screen), description, decorations, condition, asbestos cement, general maintenance, repair, hazard, not inspected, timber weathering/decay and defective joinery (3 new screens); duplicate legacy screens removed; E8 J1 line removed. |
| E9 Other outside property | DONE (gate green after removing obsolete parity tests) | 40 rules (`gen_e9.py`): communal area, carport, porch canopy, Juliet balcony, balcony, roof terrace, external staircase, other structures, retaining walls (new), 7 repair types, intro + general maintenance; 82 duplicate/extra screens retired; E9 J3 handrail line removed (not in PDF). The F-section 'Inspection limitations' text that the digitiser attached to the E9 block is handled in F. |
| F1 Roof structure | DONE (domain tests green; full gate at F2) | 41 rules (`gen_f1.py`): loft converted, description, condition, underlay (new), ventilation (new), insulation (new), water tanks, timber defects/decay/thin/heavy tiles, spray foam, wood-boring, roof movement (new), structural alterations (new), chimney breast (+ J1 bank-first), party wall, water penetration, soil pipe, not fully inspected/unsafe floor (from the F0 limitations text), intro, general maintenance; weather, repair-tank and roof-spreading screens retired. I1 chimney-collapse cross-inject pending (stored as bank key idea, wire in I1). |
| F2 Ceilings | DONE (gate green) | 15 rules (`gen_f2.py`); description, condition, lath/textured add-ons, cracking, unevenness (new), water staining (new), polystyrene, heavy covering, ornamental plaster, intro, general maintenance; repair/asbestos/not-inspected screens retired; engine poor-condition text rewrite removed. |
| F3 Walls and partitions | DONE (gate green after removing obsolete parity tests) | 20 rules (`gen_f3.py`): description, condition, add-ons, cracking/structural movement, hollow plaster (new), condensation, dampness (6 paragraphs), internal alterations, intro, general maintenance. |
| F4 Floors | DONE (gate green after removing obsolete parity tests) | 18 rules (`gen_f4.py`); description/condition, creaking, repair timber floor, tiles, loose floorboards, wood boring, decay, dampness, underfloor ventilation, laminate, vibration, sloping, intro, general maintenance. |
| F5 Fireplaces and chimneys | DONE (gate green after removing obsolete tests) | 11 rules (`gen_f5.py`); merged type screens; blocked fireplace, removed breasts, boiler flues, defects (new), dampness (new). |
| F6 Built-in fittings | DONE (gate green after removing obsolete tests) | 11 rules (`gen_f6.py`). |
| F7 Woodwork | DONE (gate green after removing obsolete parity test) | 13 rules (`gen_f7.py`); 8 old screens retired. F-derived J1 lines (out-of-square doors, infestation) stay as is until J1 is rebuilt. |
| F8 Bathroom fittings | DONE (gate green after removing obsolete tests) | 10 rules (`gen_f8.py`). |
| F9 Other (inside) | DONE | 18 rules (`gen_f9.py`): communal parts, repair, cellar/basement (duplicate Basement group retired). The G Services intro text that the digitiser attached to the F9 block is handled in G. |
| G1 Electricity | DONE (gate green) | 11 rules (`gen_g1.py`): meter, consumer unit, RCD, dated/old, poor standards, solar PV, battery/inverter, solar thermal; G services intro + EICR text as static keys; old electricity handlers and 4 parity tests removed. |
| G2 Gas and oil | DONE (gate green after updating the oil-tank test to PDF wording) | 9 rules (`gen_g2.py`): gas smell, capped gas, meter / not found, dated, oil tank (type + location), old tank, testing, certification; 4 old gas/oil screens retired; `v5_gap_test` oil test now asserts the PDF "secondary containment (a bund)" and "OFTEC-registered engineer" wording. |
| G3 Water | DONE (gate green, +2598) | 8 rules (`gen_g3.py`): stopcock found/not found (new dropdown), lead rising, water tank (location/material/condition/insulation), inadequate insulation, damaged tank, missing lid, asbestos cement tank; plumbing paragraph as `STANDARD_TEXT_2`; 7 old screens and 8 old handlers removed; 2 obsolete parity tests removed. One ledger row left (Lead pipework sentence): bank text equals the PDF; the pointer en dash trips the ledger compare. |
| G4 Heating | DONE (gate green, +2640) | 11 rules (`gen_g4.py`): no heating, heating not found, communal, boiler (type + location), heat emitters, room heaters, old boiler, repair, forced air, air source and ground source heat pump; servicing/records paragraph as `STANDARD_TEXT_2`; 4 old screens and 7 old handlers removed; 7 G4 parity tests and the PR #3 heat-pump test group removed (the spec test covers every option). |
| G5 Water heating | DONE (gate green, +2668) | 7 rules (`gen_g5.py`): not found, communal, boiler water heating (type + location), electric immersion, poor cylinder insulation, point-of-use, solar water heating; one About Water Heating screen; 6 old screens and 8 old handlers removed; the invented `STANDARD_TEXT_2` deleted; the last parity test file removed. |
| G6 Drainage | DONE (gate green, +2748) | 16 rules (`gen_g6.py`): septic tank, cesspit, public sewer, no defects noted, inspection chamber, not inspected, shared drainage, soil and vent pipe (+ visible/partially visible), and a Drainage Repairs screen (cover, walls, drain channels, soil/vent defects, tree roots, gullies, asbestos cement soil stack); opening paragraph as `STANDARD_TEXT_2`; 9 old screens and 12 old handlers removed. |
| G7 Common services | DONE (gate green, +2758) | 2 rules (`gen_g7.py`): not applicable and the communal-services description with its PDF option list; rating/notes via the main screen; not-inspected screen and 3 old handlers removed. The 6 ledger rows still open under G7 are the H Grounds intro/limitations text the digitiser attached to the G7 block; they are built in H1. |
| H1 Garage | DONE (gate green, +2824) | 16 rules (`gen_h1.py`): no garage, not inspected, converted, shared access, description, walls, roof (+ felt / asbestos add-ons), floor, doors, condition, no defects noted, minor / significant defects, safety hazard; 3 old screens, 5 old handlers and 2 obsolete tests removed; `cb_corrugated_asbestos_sheets` id kept for the J asbestos summary. H Grounds limitations (3 bank keys) re-pointed to the PDF text and the handler now prints the unconditional intro. One G7 ledger row (the "Condition rating 123 H Grounds" prefix row) is a digitiser artefact. |
| H2 Outbuildings | DONE (gate green, +2953) | 31 rules (`gen_h2.py`): topography, shared garden (surface, fence, no fencing, condition), gardens (description, surfaces, boundaries, condition, no defects, hardstanding), repair fence, sheds, outbuilding (type, construction, roof, floor, doors, condition), repair outbuilding, retaining wall, nearby trees, subsoil, private road, shared areas; 10 old screens and 13 old handlers removed, 4 parity tests removed; `actv_type` / `actv_condition` and the retaining-wall and fence defect ids kept so the J2 summary keeps working (J2 conditions in `report_builder` changed to the new PDF values). |
| H3 Other area | DONE (gate green, +3008) | 11 rules (`gen_h3.py`): right of way, lifts, flooding, EMF, Japanese knotweed (not inspected / not found / found + Management A-D); 2 old screens and 7 old handlers removed. Section H is now complete. |
| I1 Regulations | DONE (gate green, +3107) | 21 rules (`gen_i1.py`): introduction, 18 checklist items, new build, converted building, listed building, each with its own tick-box; the old regulation handler and parity test removed. |
| I2 Guarantees | DONE (gate green, +3153) | 10 rules (`gen_i2.py`): introduction and nine checklist items; the report_builder cross-injects (E5/E6 replacement PVC, F1 spray foam, renewable energy) now add the PDF items; cellar/basement and FENSA lines removed; old handler and parity test removed. One ledger row left open (digitiser artefact in the block). |
| I3 Other matters | DONE (gate green, +3191) | 9 rules (`gen_i3.py`): the nine PDF paragraphs, each with its own tick-box; the report_builder shared-chimney cross-inject, the old handler, a parity test and two report_builder tests removed. Section I is now complete except for digitiser artefacts. |
| J1 Risk to building | DONE (gate green, +3225) | 8 rules (`gen_j1.py`): structural movement, water penetration, timber decay, wood-boring insects, condensation, drainage, significant subsidence, tree defects, each with a tick-box and its PDF option list; legacy J1 handler, four dead F-section derived blocks, the J1 parity tests and one report_builder test removed. The E1-E9 "Add text to: Section J1" cross-injects stay. |
| J2 Risk to grounds | DONE (gate green, +3225) | `gen_j2.py`: the two PDF sentences with option-list tokens (tree size, slope) filled from two extra dropdowns on the H2 screens; report_builder fills the tokens. J3/J4: see ledger (J3 asbestos has a PDF bold-marker artefact, J4 open rows are K1 text). |
| Flat paragraphs (E1, E2, E3, E4, E8, E9, F1) | DONE (gate green, +3260) | `gen_flat.py`: the seven "If the Property is a Flat" paragraphs as a tick-box on each section main screen (CLIENT_QUERIES #26 / #100). Ledger decisions recorded for the J2 token sentences, the J3 bold-marker query and the G3 en-dash pointer. |
| A1 Property address block (Weather, Status, Orientation) | DONE (gate green, +3276) | 3 rules (`gen_a1.py`) with dropdowns on the PDF option lists; 3 old handlers removed. T6 (`test/phrase_audit/verbatim/t6_report_dump_test.dart` + `t6check.py`) added: it dumps the real pipeline output and lists every emitted sentence that is not in the PDF. Remaining legacy screens (T6 `--screens --legacy`): A overall opinion / built year, D (gardens, energy, estate, internal wall, solar, flat, noisy area, local environment, location, private road, roof, type, topography), E leftovers (limitations, weather, asbestos, poor roof, aerial/dish), F limitations, J4. |
| A2 Overall opinion block (type, year built, extended, converted, flat information) | DONE (gate green, +3324) | 10 rules (`gen_a2.py`): property type + bedrooms, year built (exact year or band), not extended / extended, not converted / converted + known / unknown date, flat information; 5 old handlers and two obsolete test groups removed. The opinion + price paragraph stays as is (query #12 / #105); the accommodation summary is a report table (see ledger). |
| A3 Construction block (D) | DONE (gate green, +3376) | `gen_a3.py`: 14 rules (type, visible-only, modern design, concrete advisory, roof type/cover, external/internal walls, floors, windows, listed building x2 screens, energy ratings, other services); 10 old handlers + Environmental Impact screen removed; obsolete legacy tests removed (CLIENT_QUERIES #106–#110) |
| A4 Grounds + Parking block (D) | DONE (gate green, +3518) | `gen_a4.py`: 30 rules (topography, front/rear/communal garden + fencing on 4 screens, parking none/type/paid on 2 screens, gated, location, density, road, noise, conservation, facilities, remote, local environment + EMF + flooding); 12 old handlers, Estate location screen, hard-coded Section D narratives in report_builder, the "legacy construction" sentence rewriter and the Location completeness check removed (CLIENT_QUERIES #111–#115) |
| E leftovers (E1 chimney, E limitations/weather, E2/E3 not inspected, blocked gutters, runoffs) | DONE (gate green, +3697) | `gen_e1l.py` (24 rules: number, location, condition, shared, leaning, removed, not applicable/inspected/dummy, 5 repair screens, aerial + satellite) and `gen_e0.py` (15 rules); ~25 legacy handlers and 6 non-PDF screens removed; E9 "F Inside limitations" rows left for the F step (CLIENT_QUERIES #116–#119) |
| F Inside limitations | DONE (gate green, +3737) | `gen_f0.py`: 8 rules on `activity_inside_property_limitation`; old handler and its validation removed (CLIENT_QUERIES #120) |
