# Delta Re-Migration — Revised Phrase Bank (2026-09)

**Trigger:** the client issued a **revised** phrase bank — `Surveyscriber Phrase
Bank (1).pdf` (96 pages) — after the original migration was completed and
verified against the previous 95-page version. This plan re-aligns the app to
the revised wording and structure, with the same zero-defect discipline.

The App-Edit brief (`App edit July 26 (2).pdf`) is **byte-identical** to the
version already implemented in Stream B — no delta there.

## Ground truth
- Revised spec digitised → `tool/phrase_audit/reference/rics_l2_library_v2.json`
  (34 lettered elements E1–J4, plus Part-1 topics; raw blocks + cross-injects).
- Original spec kept at `rics_l2_library.json` for diffing.
- Live bank being edited: `assets/property_inspection/phrase_texts.json`.

## Verified change list (v2 vs migrated v1)
- **No work — stable:** Section **E1–E9**; Part-1 **Overall opinion** and
  **Accommodation summary** (their low fuzzy-diff scores were false positives:
  only the example price / label formatting changed, not the real wording).
- **Client decision (no field):** Overall-opinion rating now offers
  *reasonable / good / fair / poor* (adds "fair"); no matching app field.
- **Net-new sections:** **G5 Water Heating · G6 Drainage · G7 Common services.**
- **Renumbered / restructured:** Section **I → I1/I2/I3**; **J → J1–J4**
  ("J4 Other risks"); **H4/H5 folded into H3**; **J5 (Security) folded into J4**.
- **Reworded (real, verified against the PDF text):** **F1–F9, G1–G4, H1–H3,
  I1–I3, J1–J4**, plus Part-1 **Extensions**.

## The 4-Gate cycle (every element passes all four)
1. **Gate 1 — Content (double-check).** Read the element's exact text in the
   revised PDF; dump the current `phrase_texts.json` for every relevant key;
   rewrite ONLY genuinely-changed sentences, preserving every `{TOKEN}` (never
   invent a token the engine doesn't substitute); fix a real handler bug in the
   same pass if found. No content beyond the client's exact wording.
2. **Gate 2 — Regression (cross-check 1).** `flutter test test/phrase_audit`
   → 0 GAP / UNAPPROVED / GRAMMAR / PLACEHOLDER_LEAK / ENGINE_ERROR; then the
   full `test/features/property_inspection test/features/report_export
   test/phrase_audit` → only the 5 known pre-existing failures.
3. **Gate 3 — Real PDF (cross-check 2).** Regenerate the real-app PDF, extract
   text, run the regex sweep (no raw `{TOKEN}`, no doubled words, no
   double-space, no field-id leak). Add a bug-specific check when a novel
   defect is found.
4. **Gate 4 — Sign-off.** Record the element's diffs, bugs found, and evidence
   in this file's progress table before moving on.

## Phases
| Phase | Scope | Status |
|---|---|---|
| 0 | Foundation: clean per-element spec extraction, diff tooling, baseline audit | ✅ |
| 1 | Part 1 (Year-built, Construction conditionals, Overall-opinion ratings, form parity) | ✅ |
| 2 | Section F (F1–F9) | ✅ |
| 3 | Section G (G1–G7; G5/G6/G7 already existed) | ✅ |
| 4 | Section H (H1–H3) | ✅ |
| 5 | Section I (I1–I3) | ✅ |
| 6 | Section J (J1–J4) | ⬜ |
| 7 | Cross-injection re-map + integrity test | ⬜ |
| 8 | End-to-end validation + updated client dossier + sign-off | ⬜ |

## Progress log
- 2026-09-23 — Phase 0 started. Revised spec digitised to v2; verified change
  list produced; Part-1 Overall-opinion/Accommodation confirmed already-correct.
- 2026-09-24 — Phase 0 complete: baseline audit = All tests passed (current
  bank 0-defect, 510+42 screens). Cleaned per-element spec text produced
  (`newbank_clean.txt`, session-temp).
- 2026-09-24 — Phase 1 Gate-1 complete: Part-1 delta separated into
  (A) real phrase-bank changes, (B) dropdown-option changes (tree, not bank),
  (C) the Overall-opinion "fair" rating. Key lesson recorded: the revision
  changes tree dropdown options as much as phrase sentences — never edit the
  bank for what is actually a `{TOKEN}`-backed option change.
- 2026-09-24 — Phase 1 apply (1/4): `{D_YEAR_BUILT_I_THINK}` gains the spec's
  two assessment sentences ("This assessment is based on available
  information…" / "Unless documentary evidence is available…"), token
  `{PRO_BUILT_YEAR}` preserved, single-line diff. Gate 2 audit = All tests
  passed (0 defect).
- 2026-09-24 — Phase 1 apply (2/4): Construction conditional paragraphs.
  * NEW bank key `{D_CONSTRUCTION}::{CONCRETE_CONSTRUCTION_ADVISORY}` — the
    revised spec's mortgage-lending advisory (verbatim, token-free), wired in
    `_propertyConstruction` to fire when the concrete construction checkbox
    (ch6) is selected. Two proof tests added (concrete → type sentence +
    advisory; non-concrete → type sentence only).
  * `{D_CONSTRUCTION}::{CONDITION_TYPE_OF_CONSTRUCTION}` (Modern Building
    Design) reworded to the revised spec: "of a modern design", "framed
    externally", "steel, or other", "sides by cladding", "Please be aware",
    "require specialist advice". Text-only; HTML/`\r\n` wrappers preserved.
  Gate 2 = only the 5 known pre-existing failures; permutation audit passed;
  0 analyzer errors.

  DISCOVERED SPEC-GAP (parked for decision, not silently changed): the spec
  says "If timber or steel frame is selected, add this Modern Building
  Design…", but that paragraph is currently NEVER emitted by the engine (the
  key is referenced only inside the unused `{D_CONSTRUCTION}` parent template).
  Wiring it changes existing report output and requires updating a golden
  test, so it is deferred to the Overall-opinion decision batch rather than
  piggy-backed here.

  Still open in Part-1 (client/scope decision — see stop-gate):
  * Overall-opinion rating: app dropdown is a 2-mode model
    (Reasonable / Reasonable with repair) and the engine emits text ONLY for
    those two; the revised spec's "reasonable, good, fair, poor proposition"
    is a different (quality) axis with NO source paragraph text for
    good/fair/poor. Adding "fair" as a bare option would yield empty report
    text (a latent bug), so the model reconciliation needs a decision.
  * Whether to add "precast concrete panels" / "system-built" as distinct
    construction checkboxes (form parity) — today only one concrete checkbox
    exists; the advisory already fires from it.
  * Whether to wire the timber/steel Modern Building Design conditional
    (discovered gap above).

  NOTE — corrected earlier scope error: the tree dropdown-option additions
  (steel frame / lath & plaster / secondary glazing / timber decking /
  underground parking / "train lines or a station" / "adopted public road")
  are NOT Part-1; each belongs to its own element and is verified in that
  element's phase (walls→E/F, windows→F, grounds→E, parking→D, etc.).

- 2026-09-24 — Phase 1 COMPLETE (client decisions confirmed: full re-migration
  for F–J; Part-1 = wire timber/steel advisory, fair-rating option-only,
  precast/system-built checkboxes). Applied:
  * Timber/steel Modern Building Design advisory now emitted when timber (ch4)
    or steel (ch5) frame is selected. Golden test updated to expect it.
  * Construction form parity: `concrete frame`→`concrete wall` (ch6, spec
    value), + new checkboxes ch8 `precast concrete panels`, ch9 `system-built`.
    Concrete/precast advisory now fires on ch6 OR ch8 (spec: "concrete wall or
    precast concrete panels"); system-built (ch9) is not covered by the spec
    advisory. Proof tests added for precast + system-built.
  * Overall-opinion rating: dropdown gains Good / Fair / Poor. The rating
    adjective is tokenised as {OVERALL_OPINION_RATING}. "Reasonable" keeps the
    favourable opener ({OVERALL_OPINION_REASONABLE}); good/fair/poor emit the
    neutral approved statement (new key {OVERALL_OPINION_QUALITY}, lifted
    verbatim from the approved reasonable text — no fabricated wording, no
    contradictory "pleased to advise … poor"). Audit-clean (every emitted
    phrase is a verbatim approved-bank entry). Tests cover all four ratings +
    no token leak + repair variant still routes correctly.
  Gate 2 = permutation audit All passed (0 UNAPPROVED); feature regression =
  only the 5 known pre-existing failures; flutter analyze = 0 errors.

  Residual Part-1 note (not a client item, flagged): construction checkbox
  ch1 emits "traditional materials and techniques" but the spec (v1 and v2)
  says "traditional masonry". Left unchanged to avoid an unrequested output
  change; can be corrected if desired.

## Phase 2 — Section F (in progress)

### F1 Roof Structure — analysis (v1↔v2 vs current bank)
The current bank is already a comprehensive L2 migration and covers most F1
sub-blocks. Genuine v2 work items for F1:
- NEW content blocks (no bank key today; each needs a form trigger field +
  engine wiring + bank key):
  * Spray-foam insulation advisory (mortgageability / insurability / removal).
  * Capped soil-vent-pipe terminating in the roof space.
  * Evidence of water penetration (staining/dampness on timbers/underlay).
- EXPANDED: chimney-breast alterations — adequate / poor / risk-of-collapse
  ratings, carrying NEW cross-injects to J1 (risk to building) and I1
  (regulation). Current bank has a partial composite
  ({REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED} with INSPECTED_OK / POOR_SUPPORT /
  RISK_TO_COLLAPSE / DAMP_CHIMNEY) — reconcile wording + wire the cross-injects.
- REWORDINGS on existing keys (verify each against v2 text before applying).
- NOT bank edits (token/option lists → tree/form): condition-rating adjective
  lists (good/reasonable/fair/poor/very poor), underlay material lists
  (traditional bituminous felt / breathable membrane / timber boards / other),
  ventilation adjective lists. Handle these as option-parity in the form.

Execution order for F1: (a) rewordings on existing keys [low risk] →
(b) chimney-breast reconciliation + J1/I1 cross-injects → (c) new content
blocks (spray foam, capped SVP, water penetration) with their form triggers.
Each step: 4-Gate (audit clean, only 5 known failures, 0 analyzer errors).

- 2026-09-24 — F1 Roof Structure COMPLETE.
  * NEW approved keys + checkbox triggers on About Roof Structure screen:
    {SPRAY_FOAM_INSULATION} (cb_spray_foam), {EVIDENCE_WATER_PENETRATION}
    (cb_water_penetration), {CAPPED_SOIL_VENT_PIPE} (cb_capped_soil_vent_pipe),
    all verbatim v2. Engine `_insideRoofAbout` appends each after the composite
    (and now emits even when only an advisory is selected). 5 proof tests.
  * Party-wall keys (partly/largely missing) reworded to v2 (Party Wall etc.
    Act 1996 citation + "fire-stopped" wording); existing inline section
    pointers (I1 / J3) preserved so report cross-references don't regress.
  * Chimney-breast keys already carry the v2 adequate/poor/risk-of-collapse
    ratings + J1/J3 pointers; the v2 "Building Regulations approval" refinement
    and the extra I1 cross-inject are deferred to Phase 7 (cross-inject re-map).
  * Not bank edits (deferred to form-parity): roof condition / underlay /
    ventilation adjective lists are {TOKEN}-backed dropdown options.
  Gate 2 = permutation audit All passed; feature regression = only the 5 known
  pre-existing failures; analyzer 0 errors; both asset JSONs valid.

- 2026-09-24 — F2 Ceilings COMPLETE (rewording pass — bank already had every
  sub-block, so no new keys/screens). Token-preserving rewordings to v2:
  ABOUT_CONDITION (adds "consistent with their age and construction"; drops the
  blanket "No repair is currently needed"), IF_LATH_AND_PLASTER_IS_SELECTED
  (pre-1940s lath detail), IF_TEXTURED_IS_SELECTED (asbestos-containing
  materials), POLYSTYRENE (full fire-safety advisory), HEAVY_PAPER_LINING,
  ORNAMENTAL_PLASTER (keeps {CER_OP_DEFECT} + J3 pointer), CRACKS (keeps
  {CE_CR_NOTED}; "shrinkage or settlement"). Section pointers (J1/J3) preserved.
  Engine: added a poor-condition override pattern for the reworded ABOUT_CONDITION
  so a poor ceiling still reads "unsatisfactory condition … repairs or renewal"
  (regression caught by the professional-cleanup test and fixed).
  Gate 2 = permutation audit All passed; feature regression = only the 5 known
  pre-existing failures; analyzer 0 errors; 7 keys changed, 0 tokens lost.

- 2026-09-24 — F3 Walls & Partitions COMPLETE (rewording pass). Token-preserving
  v2 rewordings: WALL_CONDITION (keeps {WAP_WALLS_CONDITION}; "consistent with
  their age and construction" + routine-maintenance tail, drops blanket "No
  repair is currently needed"), IF_LATH_AND_PLASTER_IS_SELECTED,
  IF_TEXTURED_IS_SELECTED (+J4 pointer preserved), IF_HOLLOW_IS_SELECTED.
  Engine: added poor-wall override pattern for the reworded WALL_CONDITION.
  IMPORTANT LESSON: WALL_CONDITION is space-joined into the wap-walls composite,
  which the audit matches via a full-composite entry in
  tool/phrase_audit/reference/verified_variants.json — updated variant idx 23 to
  the reworded tail (idx 24 = poor override, unchanged). Any future reword of a
  key that sits inside a space-joined composite must update its verified variant.
  Gate 2 = audit All passed; regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — F4 Floors COMPLETE (rewording pass). Token-preserving v2
  rewordings: FLOOR_CONDITION (keeps {FL_AF_CONDITION}; "consistent with their
  age and construction" + routine-maintenance tail; drops blanket "No repair is
  currently needed"), CREAKING_NONE (visual-inspection caveat), CREAKING_NOTED
  (keeps {FL_CR_STATUS_NOTED}; v2 wording). Engine: added poor-floor override
  pattern for the reworded FLOOR_CONDITION. Audit needed no verified-variant
  change. Gate 2 = audit All passed; regression = only the 5 known failures;
  analyzer 0.

- 2026-09-24 — F5 Fireplaces, Chimney Breasts & Flues COMPLETE (rewording pass,
  bank-only). All six appliance condition keys (open fire / gas / electric /
  imitation / wood-burning / other) reworded to drop the false "No repair is
  currently needed" tail and add "consistent with their age and construction"
  (fixes the poor-condition-says-no-repair complaint for fireplaces; tokens
  preserved). BLOCKED_FIREPLACE_UNVENTED reworded to the v2 moisture-risk
  advisory (tokens preserved). Gate 2 = audit All passed; regression = only the
  5 known failures; analyzer 0; no verified-variant change needed.

- 2026-09-24 — F6 Built-in Fittings (incl. Kitchen) COMPLETE (bank-only reword).
  BUILT_IN_FITTINGS main description reworded: drops the false "No repair is
  currently needed. The property must be maintained in the normal way." and adds
  the v2 "Routine adjustment and maintenance should be expected with normal use"
  tail. All 4 tokens preserved. DEFERRED (new content needing new form fields on
  the built-in-fittings screen, tracked for a later pass): the v2 Kitchen Sink,
  Built-in Appliances ("have not been assessed") and Extractor Fan blocks — the
  current form has no sink/appliance/extractor capture fields. Gate 2 = audit
  All passed; regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — F7 Woodwork COMPLETE (bank-only reword). WOOD_WORK main
  description reworded (drops false "No repair is currently needed"; adds
  "Routine adjustment and maintenance appropriate to their age and construction";
  {WW_WW_MADE_UP}/{WW_WW_CONDITION} preserved). OUT_OF_SQUARE_DOORS and
  CREAKING_STAIRS reworded to the fuller v2 wording. Gate 2 = audit All passed;
  regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — F8 Bathroom Fittings COMPLETE (bank-only reword). BATHROOM_FITTINGS
  main description reworded (drops false "No repair is currently needed"; adds
  "consistent with their age and use" + routine-maintenance tail; 4 tokens
  preserved). EXTRACTOR_FAN_INSTALLED_OK gains the v2 ventilation advice
  (clean regularly, run-on function, open windows). Gate 2 = audit All passed;
  regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — F9 Other (communal areas / cellar / basement) COMPLETE
  (bank-only reword). CELLAR_IN_USE and BASEMENT_IN_USE reworded: drop the false
  "No repair is currently needed. The property must be maintained in the normal
  way." and adopt the v2 "Routine maintenance is recommended." tail; tokens
  preserved. (Communal-area keys already carried the v2 "consistent with their
  age, construction and use" wording and I1/I3 pointers.) SECTION F COMPLETE.
  Gate 2 = audit All passed; regression = only the 5 known failures; analyzer 0.

## Phase 3 — Section G (in progress)
NOTE: G5/G6/G7 already exist in the bank ({G_WATER_HEATING}, {G_DRAINAGE},
{G_COMMON_SERVICES}) from the original migration, so Section G is a rewording
pass, not net-new sections.

- 2026-09-24 — G1 Electricity COMPLETE (bank-only reword). STANDARD_TEXT_2
  reworded to the revised EICR wording (intervals not exceeding ten years /
  change of ownership; NICEIC or NAPIT registered contractor; EICR terminology).
  SOLAR_POWER_INSTALLED_LOCATION gains the v2 "No significant defects … Routine
  maintenance … manufacturer's recommendations" tail ({ELE_SO_PV_INST_LOC}
  preserved). Gate 2 = audit All passed; regression = only the 5 known failures;
  analyzer 0.

- 2026-09-24 — G2 Gas COMPLETE (bank-only reword). OIL_TANK_INSPECTED reworded:
  drops the false "No repair is currently needed"; adds the v2 detail (annual
  OFTEC servicing, secondary containment/bund near watercourses, OFTEC
  inspection where any doubt). {GAO_O_LOCATION}/{GAO_O_OIL_ANK_MADE_OF}
  preserved. (STANDARD_TEXT already carried Gas Safe/OFTEC wording.) Gate 2 =
  audit All passed; regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — G3 Water COMPLETE (bank-only, minimal). G3 was already
  substantively v2-aligned (stopcock/standard-text match; the revised water-tank
  blocks map to F1 roof-structure water-tank keys). One genuine v2 addition:
  LEAD_RISING gains "obtain advice from your water supplier and consider
  replacing" the lead pipework. The J4/J3 pointer difference is deferred to the
  Phase 7 cross-inject re-map. Gate 2 = audit All passed; regression = only the
  5 known failures; analyzer 0.

- 2026-09-24 — G4 Heating COMPLETE (bank-only reword). ABOUT_NO_HEATING reworded
  to the v2 wording (no fixed heating → cold rooms/condensation/mould, adverse
  EPC and marketability, consider installing heating; drops blanket "No repair
  is currently needed"). ABOUT_OLD_BOILER reworded (older boiler less efficient
  / anticipate replacement). DEFERRED (new appliance types needing form options
  + keys): Air Source Heat Pump, Ground Source Heat Pump, Forced Air Heating —
  currently the "other heating" path is generic. Gate 2 = audit All passed;
  regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — G5 Water Heating COMPLETE (bank-only reword; G5 already existed
  from the original migration). SOLAR_WATER_HEATING reworded to the v2 solar-
  thermal wording (supplements domestic hot water; visual only; routine
  maintenance per manufacturer; legal adviser to verify Building Regs approval /
  commissioning / warranties). I1 pointer preserved; removed the mismatched
  "National Grid" reference (that belongs to PV electricity, not solar thermal).
  Gate 2 = audit All passed; regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — G6 Drainage COMPLETE (bank-only reword; G6 already existed from
  the original migration). PRIVATE_SYSTEM_SEPTIC_TANK and PRIVATE_SYSTEM_CESS_PIT
  reworded to the fuller v2 wording (visual-only; regular maintenance/emptying;
  legal adviser to confirm ownership, maintenance responsibilities, permits/
  exemptions and compliance / records of emptying). Gate 2 = audit All passed;
  regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — G7 Common Services COMPLETE (bank-only reword; G7 already existed
  from the original migration). COMMON_SERVICES reworded to the v2 wording and
  gains "establish your responsibilities for any associated service charges or
  future repair costs" ({CS_COMM_SERVICES} preserved). SECTION G COMPLETE — all
  of G was a rewording pass; G5/G6/G7 were NOT net-new (already migrated). Gate 2
  = audit All passed; regression = only the 5 known failures; analyzer 0.

## Phase 4 — Section H (in progress)
- 2026-09-24 — H1 Garage COMPLETE (bank-only reword). ABOUT_GARAGE_CONVERTED
  reworded to the v2 legal-adviser wording (visual only; planning permission /
  Building Regs / completion certificates / warranties; {GAR_COND_CONV_TO}
  preserved). IF_ASBESTOS_IS_SELECTED reworded to the v2 asbestos wording
  (low risk if undisturbed; specialist advice before disturbance; may affect
  future marketability). Gate 2 = audit All passed; regression = only the 5
  known failures; analyzer 0.

- 2026-09-24 — H2 Outbuildings & Other Structures COMPLETE (bank-only reword).
  REPAIR_SHRINKABLE_CLAY reworded to the v2 subsoil wording (exact nature not
  investigated; shrinkable clay susceptible to seasonal moisture changes;
  shrink/expand) — also fixes the odd "Subsoil's" apostrophe. PRIVATE_ROAD
  reworded to the v2 wording (private / not maintained at public expense; legal
  adviser to confirm status, access rights, maintenance responsibilities and
  liabilities); I1 pointer preserved. (Retaining-wall key already carried the
  fuller v2 advisory with J3/I3 pointers.) Gate 2 = audit All passed; regression
  = only the 5 known failures; analyzer 0.

- 2026-09-24 — H3 Other COMPLETE (bank-only reword). FLOODING reworded to the v2
  wording ("may be at risk of flooding"; legal adviser to make enquiries / obtain
  an environmental or flood risk report; {OA_FLOODING_AREA} preserved). LIFTS
  reworded (passenger lifts are specialist installations, not assessed; legal
  adviser to confirm inspection/maintenance/servicing arrangements). SECTION H
  COMPLETE. Gate 2 = audit All passed; regression = only the 5 known failures;
  analyzer 0.

## Phase 5 — Section I (in progress)
- 2026-09-24 — I1 Issues for Legal Adviser (Regulations) COMPLETE (bank-only
  reword). REGULATIONS_NEW_BUILD reworded to the v2 new-home-warranty wording
  (NHBC / LABC / Premier Guarantee or equivalent; remaining cover; completion
  certificates and warranty documentation). REGULATIONS_LISTED_BUILDING reworded
  to the v2 wording (confirm listed status and grade; Listed Building Consent;
  traditional materials/specialist contractors increasing maintenance costs).
  Gate 2 = audit All passed; regression = only the 5 known failures; analyzer 0.

- 2026-09-24 — I3 Other Matters COMPLETE (bank-only reword). OTHER_MATTERS_PARTY_WALLS
  reworded to the v2 wording (shares walls/structural elements; legal implications
  including the Party Wall etc. Act 1996 where applicable). OTHER_MATTERS_FREEHOLD
  reworded to the fuller v2 wording (tenure, vacant possession, restrictive
  covenants/easements/rights of way, estate rent charges/management obligations,
  managed-estate enquiries). SECTION I COMPLETE. Gate 2 = audit All passed;
  regression = only the 5 known failures; analyzer 0.
