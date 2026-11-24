# Client edit list 23 Nov 2026 — progress (LOCKED 24 Nov 2026)

Source: `Downloads/Survey Scriber Edit Nov 23 2026.docx` (6 items). User order (24 Nov): do all 6 in this order, skip nothing,
generate full reports to test, then check the new phrases live. Push / APK / live deploy only on the user's word
(live bank/tree publish was asked for in the last sentence of the 24 Nov request: do it after all 6 pass, then verify live).

| # | Item | Status | Commit | Proof |
|---|------|--------|--------|-------|
| 1 | Main Wall: rendered wall + pebble dash = one "Wall Finished" sentence, after Description, before Condition | DONE | (this commit) | tests client_edits_2026_11_23_test (7), gates, PDF+Word p18/p17 in tmp/client-edits-2026-11-23/report |
| 2 | Lintel: window screen says "window opening", door screen says "door opening" | DONE | (this commit) | tests (4) in client_edits_2026_11_23_test, gates, PDF p24 + Word p23 |
| 3 | Valuation weather: same 8 options as Inspection | DONE | (this commit) | tests (4) client_edits_2026_11_23_valuation_test; valuation + report_export suites 358 green; valuation PDF p2 + Word p2 in tmp/client-edits-2026-11-23/valuation; valuation bundledVersion 8 |
| 4 | Large Outbuilding: every type gets the full set of options | TODO | | |
| 5 | Outside Doors: Description + material on one line; BS EN paragraph only once | TODO | | |
| 6 | E8 Other Joinery: inspected/not inspected first, repair last, ordering per client | TODO | | |

Next action: item 4.

## Method per item
tree json + verbatim spec (`inspection_verbatim_spec.dart`) + bank (`phrase_texts.json`) + answer migration
(`legacy_answer_migration.dart`) + tests in `test/features/property_inspection/client_edits_2026_11_23_test.dart`
+ gates (`python tool/phrase_audit/verbatim/gates.py`, flutter gate for property_inspection / report_export / phrase_audit)
+ real report PDF/Word render checked by eye. Bundled tree version bump once at the end.
