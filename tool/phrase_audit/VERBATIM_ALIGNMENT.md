# Verbatim Alignment Pass — Bank ↔ Revised PDF (Surveyscriber Phrase Bank (1).pdf)

Goal: make the phrase bank's **fixed prose** read word-for-word as the client's
revised PDF, while preserving the engine's `{TOKEN}` slots and cross-references.

## Method (why this is not a blind copy)

The PDF is a **spec**, not finished prose. Every candidate difference between a
PDF sentence and the bank was classified before any edit:

| Class | Meaning | Action |
|-------|---------|--------|
| **A** | Genuine fixed-prose wording difference | **Fix to PDF wording** |
| **B** | Bank adds a cross-reference (`(see section i3/j1/j3)`) the PDF omits | **Keep** — removing degrades the report |
| **C** | Bank tokenises what the PDF spells out as an option list | **Keep** — correct by design |
| **D** | PDF sentence is an option menu / bullet list / "If X selected" routing directive | **Keep** — not report prose |
| **HDR** | PDF prepends a field label (`Remote area - …`) to text identical to the bank | **Keep** — label is a header |

A recurring **false-pairing** trap: the gap-finder matches each PDF sentence to
the nearest bank sentence in the whole corpus. When the true counterpart is a
tokenised template (`age of the {ELEMENT}`) or absent, it returns a same-shaped
sentence from an unrelated element (e.g. *ridge tiles* → `{E_MAIN_WALLS}`). Every
edit below was confirmed against the **correct** element's key by reading the
actual bank value first — never applied off the auto-paired key.

Raw gap count across 40 PDF sections at 0.97 similarity: **640**. After
classification the overwhelming majority are B/C/D/HDR (by-design) or false
pairings; the genuine fixed-prose fixes are a modest set.

## Fixes applied this pass (22 sentence-level, verbatim to PDF)

Grammar / agreement:
- `{PARTY_DISCLOSURES_CONFLICT}` — "the one or more person … or the interest" → "one or more persons … or to an interest"
- `{E_RAINWATER_GOODS_ABOUT}::{RWG_ABOUT_CONDITION}` — "performing its functions" → "performing their function"
- `{E_MAIN_WALLS}::{WALL_CONDITION}` — "performing its functions" → "performing their function" (+ verified_variants.json composite synced)
- `{WALL_RENDER_REPAIR_NOW}::{WALL_RENDER_REPAIR_NOW_HAZARD}` — "people that may be nearby" → "people who may be nearby"
- `{E_ROOF_COVERING_ROOF_CONDITION}::{RC_ROOF_CONDITION_INVESTIGATE}` + `{E_RC_DEFLECTION_OTHER}::{DEFLECTION_STRENGTHEN_TIMBER}` — "strengthened any weakened or small timber" → "strengthen any weakened or undersized timber"

Word choice (PDF preference):
- `{E_CHIMNEY_DISREPAIR_REPAIR}::{CHIMNEY_DISREPAIR_REPAIR_SOON}` — "economic … whole of the stack" → "economical … whole stack"; "below the level of the roof and extend the covering over" → "below roof level and extend the roof covering over it"
- `{E_CHIMNEY_FLASHING_REPAIR}::{FLASHING_REPAIR_NOW}` + `{…_SOON}` — "increase the amount of the work" → "increase the extent of the work"
- `{E_ROOF_COVERING_ROOF_CONDITION}::{RC_ROOF_CONDITION_OK}` — "further deflection occur" → "further deflection or distortion occur"
- `{E_RC_FLAT_ROOF_REPAIR}::{REPAIR_NOW}` — "repair or replacing now" → "repair or replacement now"
- `{E_RC_FLAT_ROOF_REPAIR}::{REPAIR_SOON}` — "before deterioration results" → "before further deterioration results"
- `{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}::{DAMP_CHIMNEY}` — "dampness caused by water penetration" → "dampness from water penetration"
- `{F_FLOORS}::{TIMBER_INFESTAION_INVESTIGATE}` — "recommended, as activity" → "recommended where activity"
- `{F_FLOORS}::{FLOOR_REPAIR_SOON}` — "floors of this age, and these" → "floors of this age and construction, and these"
- `{F_FLOORS}::{STANDARD_TEXT_2}` — "could not reasonably be identified" → "could not be identified"
- `{F_FLOORS}::{CREAKING_NOTED}` — "Repairs may be undertaken" → "Repairs should be undertaken"
- `{G_HEATING}::{REPAIR_MINOR_LEAKS}` — "check this now and resolve the situation soon" → "check this now and promptly resolve the situation"
- `{G_HEATING}::{ABOUT_COMMUNAL_HEATING}` — "communal gas heating system" → "communal heating system"

"tested" → PDF's "assessed"/"evaluated":
- `{E_RAINWATER_GOODS_ABOUT}::{RWG_ABOUT_CONDITION}` — "drainage has not been tested" → "…assessed"
- `{E_OUTSIDE_DOORS}::{STANDARD_TEXT}` — "locks, alarms and security systems were not tested" → "…not assessed"
- `{E_OUTSIDE_DOORS}::{WALL_SEALING}` — "effectiveness of locks … has not been tested" → "…not evaluated"
- `{F_FIREPLACES_AND_CHIMNEYS}::{BOILER_FLUE_OBSTRUCTED}` + `{…_OK}` — "The installation has not been tested." → "…not assessed."

All fixes are pure-prose (no token change). Verified: permutation audit
`All tests passed!`, engine + report golden suites green, JSON valid.

## Phase 2 — whole-key alignment (rapidfuzz), all sections

Replaced the sentence-nearest-neighbour method with **whole-key alignment**: each
bank key is scoped to its own PDF section (by vote), aligned to the best PDF
window (rapidfuzz partial-ratio), and word-diffed. Token/option-list chunks and
window-edge fragments are auto-suppressed. This removed the false-pairing risk of
Phase 1 (it even caught a Phase-1 error: `{F_FLOORS}::{CREAKING_NOTED}` had been
changed may→should off a false pairing; PDF says "may", now reverted).

Applied verbatim across **E1–E9, F, G, J2/J3, Construction, Overall opinion,
Parking** (~90 further fixed-prose corrections): section headings
(No repair:, No defects noted:, Creaking floor noted:, No Creaking floor:,
Minor cracking:, Heavy decorative covering:, Largely missing:, Party Wall
Partially missing:, Creaking stairs:, Moisture metre readings:, Install drain
guttering:, Wall Ties defects:, Out of square door/frames:); per-element
maintenance wording (door/conservatory/porch/joinery/window material;
wall→building; guttering; rainwater goods); grammar/word choice
(economical, extent, undersized, assessed/evaluated, older, roofing contractor,
their function, who); Oxford commas (age/type/construction, alterations/repairs,
age/construction/level); punctuation and reworded sentences (out-of-square doors,
retaining walls, trip hazards, damaged stairs).

Engine: widened the poor-ceiling override regex to accept the new
"No defects noted:" heading. Test: updated one report_builder J2 expectation.
verified_variants.json composites synced (external-walls, asbestos,
overall-opinion, moisture-readings).

Commits: c8a2803 (per-element walls/rainwater), e853482 (Section E),
dbad7e0 (F/G/J + Construction/Overall/Parking), plus the final micro-batch.
All gated green each time: permutation audit `All tests passed!`, engine +
report golden suites pass.

## Remaining (by design — NOT defects)

A final full-key sweep shows the residual bank↔PDF differences are all
**by-design**, not verbatim misses:
- **Tokenised option lists**: where the PDF spells out choices
  (`slipped, cracked, broken, other`) the bank carries a `{TOKEN}` the engine
  fills from the surveyor's selection. Matching the PDF literally would dump the
  whole option menu into every report.
- **Intentional cross-references** the bank adds (`(see section I2/J1/J3)`) that
  the PDF omits — kept, because removing them downgrades the report.
- **Generic shared keys** (e.g. `{OTHER_EXTERNAL_AREA}` used for
  carport/balcony/roof-terrace/staircase) where the PDF customises per structure
  but one bank key serves all; left generic ("frame material") pending optional
  tokenisation if the client wants per-structure wording.
- A handful of PDF extraction artifacts (markdown bold markers, line-break
  hyphenation).
