# Client edit list 23 Nov 2026 — progress (LOCKED 24 Nov 2026)

Source: `Downloads/Survey Scriber Edit Nov 23 2026.docx` (6 items). User order (24 Nov): do all 6 in this order, skip nothing,
generate full reports to test, then check the new phrases live. Push / APK / live deploy only on the user's word
(live bank/tree publish was asked for in the last sentence of the 24 Nov request: do it after all 6 pass, then verify live).

| # | Item | Status | Commit | Proof |
|---|------|--------|--------|-------|
| 1 | Main Wall: rendered wall + pebble dash = one "Wall Finished" sentence, after Description, before Condition | DONE | (this commit) | tests client_edits_2026_11_23_test (7), gates, PDF+Word p18/p17 in tmp/client-edits-2026-11-23/report |
| 2 | Lintel: window screen says "window opening", door screen says "door opening" | DONE | (this commit) | tests (4) in client_edits_2026_11_23_test, gates, PDF p24 + Word p23 |
| 3 | Valuation weather: same 8 options as Inspection | DONE | (this commit) | tests (4) client_edits_2026_11_23_valuation_test; valuation + report_export suites 358 green; valuation PDF p2 + Word p2 in tmp/client-edits-2026-11-23/valuation; valuation bundledVersion 8 |
| 4 | Large Outbuilding: every type gets the full set of options | DONE | (this commit) | group of 7 type screens (Large shed..Studio, Other outbuilding) each with structure/roof/floor/doors/condition; old single-screen answers migrate per ticked type; a/an for the type; tests (8) + suites 4529 green; PDF p41 + Word p39 |
| 5 | Outside Doors: Description + material on one line; BS EN paragraph only once | DONE | (this commit) | new rule flag joinAfter; E6_BS_EN_NOTED bank text was doubled (fixed); tests (7); PDF p27 + Word p25 |
| 6 | E8 Other Joinery: inspected/not inspected first, repair last, ordering per client | DONE | (this commit) | order rule in client_paragraph_rules.dart; tests (7) client_edits_2026_11_23_report_test; PDF p31 + Word p29 |

Next action: user runs `node tool/phrase_portal/publish_nov23.js` (admin password) to fix the doubled BS EN sentence on the live bank, then re-check; APK/push only on the user's word.

## Closing checks (24 Nov 2026)
- Full Flutter suite: 5707 pass; the only failures were (a) the valuation phrase audit, fixed by 6 approved weather templates (VAL_N23_0001-6), (b) one UI test (desktop_editing_review_test) that failed under load and passes alone.
- Python gates: T1 0, T7 0, T2 0 foreign; ledger 0 open prose rows. Portal tests 38/38.
- Versions: inspection bundledVersion 13, valuation 8. Lintel Windows has its own bank key (E4_LINTEL_WINDOW); the old E4_LINTEL stays for phones on an older app.
- Live: portal static deployed (BUILD 003eaf0), trees/meta/option rules/report nodes byte-identical to the repo, live page loads with no script errors.
- Live bank v193 has the client's own portal edits; phones use live + bundled keys the live bank lacks. Report built with the LIVE bank (tmp/client-edits-2026-11-23/live_report) shows items 1, 2, 4, 5 (join), 6 right; item 5 BS EN stays doubled until E6_BS_EN_NOTED is published (script above, dry run checked).
- Not done: pushing to GitHub, APK.

## Method per item
tree json + verbatim spec (`inspection_verbatim_spec.dart`) + bank (`phrase_texts.json`) + answer migration
(`legacy_answer_migration.dart`) + tests in `test/features/property_inspection/client_edits_2026_11_23_test.dart`
+ gates (`python tool/phrase_audit/verbatim/gates.py`, flutter gate for property_inspection / report_export / phrase_audit)
+ real report PDF/Word render checked by eye. Bundled tree version bump once at the end.
