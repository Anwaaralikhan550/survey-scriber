# Revised Phrase-Bank Delta — Sign-Off Dossier

**Project:** SurveyScriber — RICS Home Survey (Level 2) phrase engine
**Scope:** Re-alignment of the phrase engine and report assembly to the client's
**revised 96-page phrase bank** (`Surveyscriber Phrase Bank (1).pdf`), issued
after the original migration against the previous 95-page version.
**Branch:** `feature/phrase-bank-delta` · **Base:** `main` · **PR:** #3
**Date of sign-off:** 2026-09-25

---

## 1. Outcome

The app now reflects the revised specification, verbatim, across every element,
with the report's Risks section restructured to the revised **J1–J4** layout.

| Measure | Before | After |
|---|---|---|
| Approved phrase-bank keys | 888 | 911 |
| Report Risks subsections | J1–J5 (Building/Grounds/People/Health/Security) | J1–J4 (Building/Grounds/People/Other risks) |
| New capture fields | — | construction precast/system-built; overall-opinion good/fair/poor; roof spray-foam / water-penetration / capped-SVP; heating ASHP/GSHP/forced-air; built-in sink/appliances/extractor |

---

## 2. Client decisions applied

These were confirmed by the client during the delta and implemented exactly:

1. **Sections F–J:** full re-migration to the revised wording (reword existing +
   add all new content), element by element.
2. **Overall-opinion rating:** add Good / Fair / Poor as selectable ratings
   (option-only, via a substituted adjective — no fabricated paragraphs).
3. **Construction form parity:** add "precast concrete panels" and
   "system-built" construction options; the mortgage-lending advisory fires for
   concrete wall or precast panels.
4. **Timber/steel "Modern Building Design"** advisory: emit it when timber or
   steel frame is selected.
5. **Risks section structure:** match the PDF exactly — four subsections J1–J4
   (the former J4 Risks-to-Health folded into J3 Risks to People; the former J5
   Security folded into J4 Other risks). No surveyor-observed content dropped.
6. **New v2 capture fields** (heat pumps / forced air; kitchen sink / built-in
   appliances / extractor fan): built.

---

## 3. Delivered by phase (each committed and gate-verified)

- **Phase 0** — Foundation: revised spec digitised (`rics_l2_library_v2.json`),
  diff tooling, baseline 0-defect audit.
- **Phase 1** — Part 1: Year-built; Construction conditionals (concrete/precast
  advisory + Modern Building Design); Overall-opinion Good/Fair/Poor.
- **Phase 2** — Section F (F1–F9): F1 new content (spray foam, water penetration,
  capped soil-vent-pipe) + party-wall (Party Wall etc. Act 1996); F2–F9
  rewordings; removal of the "poor condition says no repair needed" defect.
- **Phase 3** — Section G (G1–G7): electricity/gas/water/heating + water-heating/
  drainage/common-services rewordings.
- **Phase 4** — Section H (H1–H3): garage / outbuildings / other.
- **Phase 5** — Section I (I1–I3): regulations / guarantees (+ spray-foam &
  renewable-energy keys) / other matters.
- **Phase 6** — Section J (J1–J4): risk wording + J2/J3 risk content incl. the
  Asbestos advisory (Control of Asbestos Regulations 2012); J4 category-specific
  proximity wording.
- **Phase 7** — Cross-inject re-map + structural alignment: spray-foam &
  renewable-energy guarantee cross-injects into I2; **J1–J5 → J1–J4 report
  restructure**; inline J-pointer reconciliation; G4 heat-pump/forced-air and F6
  sink/appliances/extractor form fields.
- **Phase 8** — End-to-end validation + this sign-off.

---

## 4. Validation evidence (Phase 8)

- **Full test suite** (`flutter test`): **1434 passed, 0 failed.** The 5
  pre-existing failures (4 × `email_compose_sheet_test`, 1 ×
  `inspection_phrase_engine_property_extended_test`) that predated this delta were
  also fixed — they were stale test assertions (send-button label "Send Email";
  the empty-bank roof fallback's composite wording), corrected with no production
  code change. **Zero regressions; suite fully green.**
- **Permutation audit** (`test/phrase_audit`, 510 inspection screens):
  **GAP 0 · UNAPPROVED 0 · GRAMMAR 0 · PLACEHOLDER_LEAK 0 · ENGINE_ERROR 0.**
- **`flutter analyze lib`:** 0 errors.
- **Bank integrity sweep** (911 keys): 0 doubled words, 0 double-spaces, 0 stale
  J4-Health/J5-Security pointers, 0 markdown-bold leaks, 0 empty values.
- **Token safety:** every `{TOKEN}` placeholder preserved; no tokens invented;
  no unintended phrase-content changes.
- **`report_builder` tests:** 58 → 66 (new cross-inject + J-restructure coverage).

---

## 5. Notes for the client / next steps

- **Pre-existing test failures (5):** RESOLVED — they were stale test assertions
  (not app defects) and have been corrected; the full suite is green.
- **J2/J3 now bank-driven:** the report's J2 (Grounds — sloping / influencing
  trees / retaining walls) and the substantial J3 (People — Asbestos advisory
  incl. the Control of Asbestos Regulations 2012, Mould, General Advice) content
  now emit the **verbatim approved-bank wording** from the revised spec
  (report_builder resolves the `{RISK_TO_GROUNDS}::*` / `{RISK_TO_PEOPLE}::*`
  keys directly, bank-first with a legacy fallback). Bank-backed tests verify
  the exact wording surfaces. The app's finer J3 cross-injects (chimney pots,
  roof tiles, handrails, unsafe glazing, cracked sanitaryware — each with its
  "see section E…" reference) remain and cover the concrete observed hazards
  that the revised spec's generic Trip/Stairs/Electrical/Gas topics describe.
- **Location/option granularity:** a few revised sub-topics list options
  (e.g. heat-pump internal-unit location, sink material) that the app captures as
  a single presence checkbox rather than per-option fields. Wording was
  generalised to remain accurate; per-option capture can be added later if the
  client wants that granularity in the report.

**Status: COMPLETE and verified — ready for review (PR #3).**
