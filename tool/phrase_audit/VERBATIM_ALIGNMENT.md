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

## Remaining (needs same per-item treatment, not yet done)

- **Per-element "Routine maintenance appropriate to the {element} material"**: the
  bank pasted "roof covering" / "frame material" / "flooring material" across many
  element keys; the PDF customises per element (guttering, wall, door,
  conservatory, porch, joinery, balcony, staircase, …). Each needs its correct
  per-element word confirmed against that element's PDF block before editing.
- **A? / M tier**: lower-similarity gaps that are either genuinely-absent PDF prose
  (would need adding to the right key) or false pairings — each requires manual
  source-of-truth confirmation.
