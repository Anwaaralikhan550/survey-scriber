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
| 2 | Section F (F1–F9) | ⬜ |
| 3 | Section G (G1–G7, incl. new G5/G6/G7) | ⬜ |
| 4 | Section H (H1–H3) | ⬜ |
| 5 | Section I (I1–I3) | ⬜ |
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
