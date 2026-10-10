# Verbatim phrase bank — sign-off dossier

Branch `feature/verbatim-completion` (not merged to `main`). Source of truth: `Surveyscriber Phrase Bank (1).pdf`
(digitised at `tool/phrase_audit/reference/rics_l2_library_v2.json`). Written 2026-10-10 from the committed state.

## 1. What was measured

| Check | Result | How to re-run |
|---|---|---|
| Ledger (every PDF sentence, one row each) | 1806 rows: 1346 EXACT, 3 TOKENISED, 13 ACCEPT (each with a written reason in `verbatim/ledger_decisions.csv`), 1 QUERY, 0 UNRESOLVED prose rows; 443 menu/directive rows all decided | `python3 tool/phrase_audit/verbatim/ledger.py --check` |
| T1 forward (PDF → bank) | 1349 EXACT/TOKENISED rows, 0 missing from their bank key | `python3 tool/phrase_audit/verbatim/gates.py` |
| T2 reverse (bank → PDF) | 0 sentences in referenced bank keys that are not PDF text (4 porch fixture keys listed in `verbatim/approved_extras.csv`) | same |
| T3 option lists | 406 option-list rows verified by generated rule tests, 0 unverified | ledger.py |
| T5 emission | one generated test group per rule (screen + bank sentence exist, every option emits the exact sentence, several choices join, nothing chosen emits nothing) | `flutter test test/features/property_inspection/domain/inspection_verbatim_spec_test.dart` |
| T6 end to end | the real engine → ReportBuilder path is dumped with one positive option per field; remaining flagged sentences are token-filled versions of PDF option lists or test filler | `flutter test test/phrase_audit/verbatim/t6_report_dump_test.dart`, then `python3 tool/phrase_audit/verbatim/t6check.py` |
| T7 coverage | 1361 ledger sentences with a bank key, 0 whose key is missing or never referenced by code | gates.py |
| T9 old wording | 0 hits of the replaced wording | `python3 tool/phrase_audit/verbatim/oldcheck.py` |
| Full Flutter gate (phrase_audit + property_inspection + report_export + core) | last full run: 3942 tests, all passed (commit `9fd0873`; later commits changed only `gates.py` and docs) | `flutter test test/phrase_audit test/features/property_inspection test/features/report_export test/core` |

## 2. What this does and does not prove

- Proven: every PDF report sentence has a bank key the app can reach, and no reachable bank sentence is outside the PDF.
- Proven for one scenario only: T6 dumps one option per field. Other branches are covered by the per-rule T5 tests, not by an end-to-end report for every combination.
- Not proven: a human reading of every generated report. The earlier sample reports (see session history) were read; the latest changes (sections A3 to K1, J3) have no new sample PDF yet.
- Not proven: the client's intent where the PDF is silent. All such decisions are in `CLIENT_QUERIES.md` (127 numbered items). Until the client answers, the app follows the choice written there.

## 3. Decisions taken without the client (all listed in CLIENT_QUERIES.md)

- Paragraphs with no "if selected" directive are tick-boxes on their screen (not printed by default).
- PDF typos are copied as written (examples: "Topology", "stacks(s)", "health, and safety considerations").
- Overall-opinion price prints as `£390,500.00 [Three Hundred and Ninety Thousand Five Hundred Pounds]` (query #124).
- The Control of Asbestos Regulations text prints without the PDF's `**` bold markers (query #11).
- Text the PDF does not contain was removed (old screens and sentences, listed per section in the queries), for example: Estate location, Poor roof condition, Environmental Impact, "No further comments.", J4 security fold-in, J3 radon/health lines, sketch caption.

## 4. Known limits

- 445 further bank keys are not referenced by the simple token check but a stricter proximity check cannot safely tell which are live (it mis-reads `@chimney` rules and main-screen rating keys). They were left in the bank; they are not emitted (T6 identical before and after the earlier deletions).
- The people-safety / building cross-injection sentences ("Add text to Section J1/J3") are still built in `report_builder.dart` from bank-first phrases; their wording was matched to the PDF by T1/T2 but each is not yet a rule with its own generated test.
- Sections where the client has not confirmed screen structure (K1 defaults, J3 defaults, flat paragraphs) may print less than the client expects by default.

## 5. Before merging to `main`

1. Client reviews `CLIENT_QUERIES.md` and answers or accepts the defaults.
2. Generate one sample report per property type with the final build and read it against the PDF.
3. Run the full Flutter gate once more on the merge commit.
