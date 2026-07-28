# Phrase Audit Toolkit

**Working on the RICS L2 Master Phrase Library migration (Phase 2)?
Read [`PHASE_2_RICS_L2_MIGRATION_STATUS.md`](PHASE_2_RICS_L2_MIGRATION_STATUS.md)
first** — it has current progress, the exact 4-gate process, and every
hard-won lesson from the sections already closed.

Automated compliance auditing of the report language produced by the
inspection/valuation phrase engines, verified against the client's approved
phrase database. Built in response to client QA feedback (2026-07): phrases
missing / not from the approved bank, sentences not merged into paragraphs,
condition ratings missing, and grammar defects in generated reports.

## Ground-truth sources (not committed)

| Source | What it is |
|---|---|
| `surveyscriber.sql` | 2018 MariaDB dump of the legacy app. Tables `tbl_phrases` (79 master section templates) + `tbl_sub_phrases` (710 approved sentences) are the approved bank. |
| `HB APP Database_v_5.xlsx` | Client's current Excel phrase master (revised since the original migration). |

Both live outside the repo (client IP). The extracted reference JSON is
committed at `reference/old_phrase_bank.json`.

## Components

| Tool | Purpose | Output |
|---|---|---|
| `extract_old_bank.py <sql>` | Parse legacy dump → `reference/old_phrase_bank.json` | reference bank |
| `test/phrase_audit/phrase_permutation_audit_test.dart` | Drive both phrase engines through systematic answer permutations for every tree screen; classify output: GAP / UNAPPROVED / GRAMMAR / PLACEHOLDER_LEAK / ENGINE_ERROR | `output/inspection_audit.json`, `output/valuation_audit.json`, `output/audit_summary.md` |
| `paragraph_structure_audit.py` | Compare master-template paragraph grammar vs renderer's condense whitelist | `output/paragraph_structure.*` |
| `condition_rating_audit.py` | Check the 26 sections that require a condition rating against the V2 tree | `output/condition_rating_audit.*` |
| `excel_v5_diff.py <xlsx>` | Diff Database v5 phrases vs current in-app bank | `output/excel_v5_diff.*` |
| `generate_edit_report.py` | Consolidate everything into the client deliverable | `output/EDIT_REPORT.md` |
| `test/phrase_audit/valuation_phrase_catalog_generator.dart` | RICS sign-off support: catalog every distinct sentence the valuation engine can produce, with a sign-off checkbox per line, for a RICS-qualified assessor to review (see "Valuation phrase bank has no approved source" below) | `output/valuation_phrase_catalog.md`, `output/valuation_phrase_catalog.json` |

## Full run

```bash
python tool/phrase_audit/extract_old_bank.py path/to/surveyscriber.sql
flutter test test/phrase_audit/phrase_permutation_audit_test.dart
python tool/phrase_audit/paragraph_structure_audit.py
python tool/phrase_audit/condition_rating_audit.py
python tool/phrase_audit/excel_v5_diff.py "path/to/HB APP Database_v_5.xlsx"
python tool/phrase_audit/generate_edit_report.py
flutter test test/phrase_audit/valuation_phrase_catalog_generator.dart
```

The permutation test is an audit reporter — it always passes; findings land
in `output/`. Re-run after any change to the phrase engines, the trees, or
`phrase_texts.json` to prevent regressions.

## Valuation phrase bank has no approved source

Phase 6 investigation (grep of `surveyscriber.sql` + full dump of every sheet
in `HB APP Database_v_5.xlsx`) confirmed the legacy app had no standalone
Valuation Survey type at all — it was a Home Buyer Report with a small
valuation-opinion addendum (Section K). The new app's 42-screen valuation
feature was authored fresh for this project with no legacy precedent, so
`UNAPPROVED` counts against it are a category error, not a defect: there is
no bank to compare it to, and this tool will not fabricate one.

`valuation_phrase_catalog_generator.dart` produces the real next step: a
review-ready document listing every distinct sentence the engine can
currently generate, with a sign-off checkbox per line, for the client or a
RICS-qualified assessor to formally approve, revise, or reject. Run it,
hand `output/valuation_phrase_catalog.md` to that reviewer, and treat their
annotations as the new approved source for a future import pass (mirroring
`import_issue_risk_bank.py`'s pattern for the inspection side).

## Classification notes

- **UNAPPROVED** — emitted phrase matches no template in either the legacy
  bank or `phrase_texts.json` (placeholders wildcarded; templates with fewer
  than 3 literal words are excluded from matching to avoid false approvals).
- **GRAMMAR** — pattern-detected defects: doubled words, empty-slot fragments
  ("to the of the property"), dangling slots ("covered in ."), ellipsis
  fillers ("..."), lowercase sentence starts, double spaces.
- **GAP** — screen has data fields but produced no phrase under any
  permutation.
- Raw echoes of free-text input and the standard "Not inspected" fallback are
  exempt from bank matching.
