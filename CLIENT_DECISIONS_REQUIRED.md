# SurveyScriber — Client Decisions Required

**Prepared for:** Francis Blackstone Surveyors
**Subject:** RICS Home Survey Level 2 — Master Phrase Library implementation
**Date:** 2026-09-05
**Status:** The 95-page phrase library is fully migrated (59/59 elements live, 0 unapproved phrases across 510 screens, 32/35 cross-injections wired). The items below are the **only** outstanding points, and every one of them requires a decision from you before we can act — because each would need a **new question/field added to the surveyor's on-site form** (new UI), and we will not invent survey questions or approved wording on your behalf.

Please mark each item **Add field** / **Leave as-is** / **Discuss**, and return.

---

## How to read this document

Each item has three parts:

1. **Spec reference** — where it appears in your Master Phrase Library.
2. **The gap** — what the library asks for vs. what the app currently captures on site.
3. **Decision for you** — the concrete options, in plain surveying terms.

There are two groups:

- **Group A — Cross-references (3 items):** sentences the library says should be repeated into a Risks/Legal section, but which have no on-site trigger to fire from.
- **Group B — Missing survey questions (25 items):** topics the library describes that the surveyor currently has no field to record on site.

---

# GROUP A — Cross-reference gaps (3)

The library repeats certain defect sentences into a second section (e.g. "Add text to: Section J1 – Risks to the Building"). We have wired **32 of the 35** such cross-references. These 3 cannot be wired because the surveyor has no field to record the triggering observation.

### A1. Main Walls → Section I1 (Regulations): external alterations
- **Spec reference:** Section E4 Main Walls — *"Extensions and alterations… Add text to: Section I1 – Regulations."*
- **The gap:** The library expects the surveyor to record general external alterations (wall removal, new openings, replacement lintels, structural alterations, extension works) on the Main Walls page, and repeat that note into the legal-adviser Regulations section. The app's Main Walls page only records a **removed wall**; broader "extensions & alterations" has no field. (Regulations content is still captured — but from its own dedicated I1 page, not from Main Walls.)
- **Decision for you:** Do you want a dedicated **"External alterations observed"** checklist on the Main Walls page (wall removal / new openings / replacement lintels / structural alterations / extension works), feeding the Regulations section? **Add field / Leave as-is (rely on the existing Regulations page) / Discuss.**

### A2. Roof Coverings → Section J1 (Risk to Building): roof-to-wall flashing
- **Spec reference:** Section E2 Roof Coverings — *"Flashings… at the junction of the roof covering and wall… Add text to: Section J1."*
- **The gap:** The library treats the **roof-covering-to-wall flashing** as its own inspected element. The app currently has only a **chimney** flashing page; there is no separate roof-abutment flashing page to record a defect against.
- **Decision for you:** Add a dedicated **roof-to-wall flashing** condition/defect field under Roof Coverings? **Add field / Leave as-is / Discuss.**

### A3. Main Walls → Section J1 (Risk to Building): tree-related defects
- **Spec reference:** Section E4 Main Walls — *"Trees: Defects noted… Add text to: Section J1 – Risk to Building."*
- **The gap:** The library has two tree outcomes: (a) trees present, no damage; (b) trees present **with observed defects** (cracking/distortion/heave). The app's Nearby-Tree page records **tree size only** and always prints the "no obvious signs of damage" wording. There is no field to record tree-related **defects**, so the (b) risk sentence can never appear.
- **Decision for you:** Add a **"defects associated with trees"** checklist (cracking / distortion / heave / other) to the Nearby-Tree page, feeding Risk to Building? **Add field / Leave as-is / Discuss.**

---

# GROUP B — Missing survey questions (25)

The library describes these topics, but the surveyor has no field to record them on site. The report wording exists and is approved; it simply cannot be triggered until a field is added. None are defects in what the app currently produces — they are **scope decisions** about how much the on-site form should capture.

## Section E — Outside the Property

### B1. Outside Doors — description & security detail *(E6)*
- **Spec reference:** E6 Outside Doors — Thresholds, Operation, Security, General Maintenance.
- **The gap:** The app records door **defects** but not: door **threshold** condition; a standalone **operation** assessment (opens/closes freely / with resistance / with difficulty); the **security** lock-type description (multi-point / mortice / cylinder / night-latch); or a closing General Maintenance note.
- **Decision for you:** Add these four description fields to the Outside Doors page? **Add all / Add some (specify) / Leave as-is / Discuss.**

## Section F — Inside the Property

### B2. Built-in Fittings / Kitchen — description fields *(F6, 8 sub-topics)*
- **Spec reference:** F6 Built-in Fittings (Including Kitchen).
- **The gap:** The library describes kitchen units, worktops, cupboard doors/drawers, hinges & ironmongery, kitchen sink, sink surround/sealant, wall tiling, built-in appliances inventory and extractor fan — the app has no dedicated fields for these descriptive/condition items (it records defects only).
- **Decision for you:** Add a Built-in Fittings description page covering these items? **Add field / Leave as-is / Discuss.**

### B3. Internal "Other" — loft & fire-safety topics *(F9, 10 sub-topics)*
- **Spec reference:** F9 Other (Inside).
- **The gap:** The app's internal-"Other" page covers cellar/basement/communal areas only. The library also names: Loft Storage Area, Roof Access Hatch, Loft Ladder, Internal Cupboards, Internal Ventilation, Internal Alterations, Fire Separation, Means of Escape, General Wear and Tear, and a standing General Maintenance note — none have fields.
- **Decision for you:** Add loft/fire-safety fields to the internal-Other page? **Add field / Leave as-is / Discuss.**

## Section G — Services

### B4. Electricity — protective devices, wiring, sampling & extra defects *(G1)*
- **Spec reference:** G1 Electricity.
- **The gap:** No fields for: RCD/RCBO/surge **protection**; **wiring type**; **socket-outlet** sampling note; **lighting-circuit** note. The 8-item defect list has only 2 matching checkboxes today — 6 defect types have no field (damaged socket outlet, damaged light fitting, missing accessories, older fuse board, loose fittings, insecure consumer unit / amateur alterations).
- **Decision for you:** Add these electrical fields? **Add field / Leave as-is / Discuss.**

### B5. Gas — appliance inventory & pipework rating *(G2)*
- **Spec reference:** G2 Gas.
- **The gap:** No standalone **gas appliance inventory** (boiler / gas fire / hob / oven / other), and no standalone **pipework condition rating** (the app only prints the combined meter-location sentence).
- **Decision for you:** Add these gas fields? **Add field / Leave as-is / Discuss.**

### B6. Water — pressure & supply type *(G3)*
- **Spec reference:** G3 Water.
- **The gap:** No standalone **water-pressure** assessment; no **supply-type** selection (the app assumes mains water throughout — there is no mains / private / other choice).
- **Decision for you:** Add water-pressure and supply-type fields? **Add field / Leave as-is / Discuss.**

### B7. Heating — heating controls *(G4)*
- **Spec reference:** G4 Heating.
- **The gap:** No field for **heating controls** (programmer / room thermostat / thermostatic radiator valves / smart controls).
- **Decision for you:** Add a heating-controls field? **Add field / Leave as-is / Discuss.**

## Section H — Grounds

### B8. Garage — door & floor description *(H1)*
- **Spec reference:** H1 Garage.
- **The gap:** The app records garage door **defects** but not the **door description/operation** (material + opens freely / with resistance / with difficulty) nor the **garage floor** (construction + cracking commentary).
- **Decision for you:** Add garage door & floor description fields? **Add field / Leave as-is / Discuss.**

### B9. Outside Areas — gates & decking *(H3)*
- **Spec reference:** H3 Outside Areas.
- **The gap:** No **garden-gate** field anywhere in the app; and **decking** exists only as one surface-type tick, with no dedicated condition/safety commentary of its own.
- **Decision for you:** Add gate and standalone decking-condition fields? **Add field / Leave as-is / Discuss.**

### B10. Boundaries — universal ownership note & full description *(H4)*
- **Spec reference:** H4 Boundaries.
- **The gap:** The boundary **ownership** disclaimer (which the library frames as universal, regardless of condition) currently only prints when a surveyor logs a **fence defect** — a property with sound boundaries gets no ownership guidance. The library's broader description (walls / hedging / railings, not just fencing) and non-fence defects (cracked/bulging walls, vegetation growth, localised instability) are also unreachable.
- **Decision for you:** Add a standalone always-present **Boundaries** page (description + ownership + defects), or move the ownership note so it prints whenever boundaries are present? **New page / Move the note / Leave as-is / Discuss.**

### B11. Shared Areas — driveway/parking/pathways & condition rating *(H5)*
- **Spec reference:** H5 Shared Areas.
- **The gap:** The Shared Access page covers shared **gardens** only. The library also names shared **driveway, communal parking, and shared pathways** as shared-area types (no field), and expects a **condition rating** for shared areas (none exists).
- **Decision for you:** Add the other shared-area types and a condition rating? **Add field / Leave as-is / Discuss.**

## Section I — Issues for Your Legal Adviser

### B12. Legal-adviser topics with no on-site field *(Section I, ~14 sub-topics)*
- **Spec reference:** Section I "Issues for Your Legal Adviser" — a flat list of ~26 named sub-topics.
- **The gap:** The app's I1/I2/I3 pages already cover Regulations, Guarantees and the main "Other Matters" items. The following library sub-topics, however, have **no matching on-site field** — they can only appear if the surveyor is given somewhere to flag them:
  1. Electrical Installation records (EICR)
  2. Gas Installation servicing records
  3. Heating Installation records / commissioning
  4. Renewable Energy Installations (solar PV / thermal / battery / heat pumps — ownership, guarantees, leases)
  5. Roof Alterations / loft conversion approvals
  6. Chimney Breast Alterations approvals
  7. Damp-Proofing Works guarantees
  8. Timber Treatment guarantees
  9. Cavity Wall Insulation certificates
  10. Spray Foam Insulation (lender implications)
  11. Asbestos surveys / management information
  12. Flood Risk searches
  13. Mining & Ground Stability searches
  14. Trees — Tree Preservation Orders / conservation constraints
  15. Rights of Way & Easements
  16. Boundaries (legal ownership from title)
  17. Shared Facilities (management, service charges, reserve funds)
  18. Private Roads (maintenance liabilities)
  19. Drainage type (mains / private / septic / treatment plant / cesspit)
  20. Leasehold / Freehold specifics (lease term, ground rent, service charge, covenants)
- **Decision for you:** This is the largest single decision. Options: **(a)** add a structured "Legal Matters" checklist page so the surveyor can flag whichever of these apply on site; **(b)** keep the current narrower I1/I2/I3 pages and accept that these topics rely on the legal adviser's own enquiries; **(c)** a middle option — add the highest-value subset (e.g. EICR, drainage type, flood/mining searches, leasehold). **Please indicate (a) / (b) / (c-with-list) / Discuss.**

## Part 1 & Environment

### B13. Local environment — individual hazard checklist items
- **Spec reference:** Part 1, Local environment.
- **The gap:** The library lists specific adverse features — **Commercial premises, Industrial premises, Public house, School** (alongside flooding, railway, EMF, etc. which the app does capture). These four have no individual field.
- **Decision for you:** Add these four environment checkboxes? **Add field / Leave as-is / Discuss.**

### B14. Overall Opinion — proposition rating scale
- **Spec reference:** Part 1, Overall opinion — *"the property represents a reasonable, **good, or poor** proposition."*
- **The gap:** The library offers a three-way rating (reasonable / good / poor). The app's Opinion dropdown offers only **Reasonable** / **Reasonable with repair**, so the "good" and "poor" wording can never be selected.
- **Decision for you:** Add a **good / poor** option to the overall-opinion rating? **Add field / Leave as-is / Discuss.**

---

# GROUP C — Separate approval cycle (not a field decision)

### C1. Valuation survey type has no approved phrase library
- **Reference:** Valuation is a separate survey type in the app.
- **The gap:** The 95-page library covers the **Home Survey Level 2 (inspection)** only. The app's **Valuation** survey type has never had an approved phrase library — the old app had none either. Its wording is currently developer-authored and has not been through an approval process.
- **Decision for you:** Do you want to commission a **Valuation phrase library** (equivalent to this one) for a formal approval cycle? A ready-made catalogue of every sentence the valuation engine can currently produce (501 sentences) is already prepared for your review. **Commission library / Review existing catalogue / Defer / Discuss.**

---

## Summary

| Group | Items | Nature |
|---|---|---|
| A — Cross-reference gaps | 3 | Need a new on-site trigger field |
| B — Missing survey questions | 25 | Need new on-site form fields |
| C — Valuation | 1 | Separate approval cycle |

**Nothing in this list is a fault in the report the app produces today.** Each item is a point where your library describes something the surveyor currently cannot record on site. Once you decide which fields to add, we implement the field + wire the (already-approved) wording, and verify it end-to-end.

Please return this document with your decisions marked.
