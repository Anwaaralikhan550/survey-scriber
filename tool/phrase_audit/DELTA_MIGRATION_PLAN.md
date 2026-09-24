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
| 0 | Foundation: clean per-element spec extraction, diff tooling, baseline audit | 🟡 In progress |
| 1 | Part 1 (Overall-opinion "fair" decision, Extensions, residual) | ⬜ |
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
  Still open in Part-1: concrete/precast construction paragraph (new key +
  new construction option + wiring), the tree dropdown-option additions
  (steel frame / lath and plaster / secondary glazing / timber decking /
  underground parking / "train lines or a station" / "adopted public road"),
  and the Overall-opinion "fair" rating (per user: add as spec-mandated).
