# RICS L2 Master Phrase Library Migration — Status & Continuation Guide

**Read this file first if you are picking up this project cold** (new AI
session, new subscription, new machine, whatever). It tells you what this
work is, what's done, what's left, and exactly how to keep going in the
same style as everything that came before it.

## What this project is

Client (Francis Blackstone Surveyors) sent a 95-page "Master Phrase
Library — RICS Home Survey Level 2" PDF. It is a ground-up rewrite of every
sentence the app's inspection report can produce, replacing the app's
current (already-approved, but pre-L2) phrase bank. The client wants the
app's exported report to reproduce this new library's wording, section by
section, with **zero mistakes** — verified by an automated test harness, a
real generated PDF, and a client sign-off packet, before each section is
considered locked.

The full architecture decision record and phase breakdown is in the plan
file: `C:\Users\DELL\.claude\plans\wise-napping-emerson.md` (if that path
doesn't exist on this machine, everything you need to keep going is also
summarized below — the plan file is the deeper "why", this file is the
"where are we and what do I do next").

Digitised spec (source of truth for wording): `tool/phrase_audit/reference/rics_l2_library.json`.
It has one entry per spec element/section with the raw block text. Load it
and grep for the element key (e.g. `"key": "H5"`) to get the exact spec
wording before writing anything.

## How to resume: the exact user command pattern

The user drives this one element at a time with a short command in
Hindi/Urdu/English, e.g. **"H5 shuru karo"** ("start H5"). When you see a
command like that:

1. Find that element's entry in `rics_l2_library.json` (order/key/title/rawBlock).
2. Find the app screens that actually cover that topic — **do NOT assume
   the app's own screen/group numbering matches the spec's element
   numbering.** It frequently doesn't (see "Hard-won lessons" below). Read
   the relevant `case '...':` branches in
   `lib/features/property_inspection/domain/inspection_phrase_engine.dart`
   to find the real handler and the real bank master(s) it calls via
   `_sub('{MASTER}', '{SUBCODE}')`.
3. Dump the current `phrase_texts.json` text for every relevant
   `{MASTER}::{SUBCODE}` key (a one-off Python snippet, see pattern below).
4. Compare against spec wording. Rewrite only what's genuinely misaligned
   or buggy — don't reword content that's already fine just to "match"
   spec more literally (avoids needless diff, avoids breaking coupled
   logic — see lessons below).
5. Run the **4-Gate cycle** (below) to close the element.
6. Update this file's progress table and the "Next" line at the bottom.

## The 4-Gate cycle (every element must pass all 4 before it's "done")

**Gate 1 — Content rewrite.**
Write a *throwaway* Python script at `tool/phrase_audit/_<elementid>_rewrite.py`
that loads `assets/property_inspection/phrase_texts.json`, for each changed
key checks that every new `{TOKEN}` in the new text is a subset of the old
key's tokens (never invent a token the handler doesn't already substitute),
then writes back with `json.dump(data, f, indent=2, ensure_ascii=True)` —
**`ensure_ascii=True` is required**, not `False`, or you'll re-escape
unrelated pre-existing ` `/smart-quote sequences elsewhere in the file
and create noisy unrelated diffs. Run it, confirm the "N keys changed, N
added" count matches what you intended, then **delete the script** — it's
scratch, not a permanent tool.

If you find a real logic bug in the Dart handler while doing this (not
just wording), fix it in `inspection_phrase_engine.dart` in the same pass.

**Gate 2 — Regression.**
```bash
flutter test test/phrase_audit
```
Must show `All tests passed!` (this includes a permutation audit that
classifies every screen's output as GAP / UNAPPROVED / GRAMMAR /
PLACEHOLDER_LEAK / ENGINE_ERROR — 0 of each, tree-wide, is the bar). Then:
```bash
flutter test test/features/property_inspection test/features/report_export test/phrase_audit
```
Expect **exactly 5 pre-existing failures, always these 5, never more**:
- `email_compose_sheet_test.dart` — 4 failures (send-button icon lookup,
  fails on a clean tree too, unrelated environment issue)
- `inspection_phrase_engine_property_extended_test.dart` — 1 failure
  ("construction roof includes extended roof material...", pre-existing
  from earlier Part 1 preamble work)

If you see MORE than these 5, you broke something — find it before moving
on. If the element has no dedicated parity test yet (check
`test/features/property_inspection/domain/` for an existing
`inspection_phrase_engine_<topic>_parity_test.dart` — some elements already
had a narrow "legacy quirk" test from years ago; those don't count as full
coverage), write one that exercises every branch of every handler you
touched, then re-run the full regression to fold it in.

**Gate 3 — Real-app PDF.**
```bash
flutter test test/_scratch_real_app_pdf.dart
```
This drives the actual `ReportBuilder` + `PdfGeneratorService` pipeline
headlessly and writes a real PDF to
`<scratchpad>/appdocs/reports/*.pdf` (path printed in the test output).
Curated answers for specific screens live in the `_curatedIssues` map near
the top of that file — most screens auto-fill with sensible defaults, but
`_repair_`-named screens are skipped by default unless curated. If the
element you're closing has no curated data and its interesting branches
never fire in the generated PDF, **temporarily add a curated entry, verify
live, then revert it** (comment clearly marks these as TEMP — see git
history on this file for the exact pattern used for H1's and H4's
verification). Never leave a temporary curated change in permanently
unless it was already there before you started — the persistent curated
data is meant to mirror the client's real reference property (e.g. it has
no garage, which is why H1's garage screens are deliberately curated
empty).

Extract text with PyMuPDF and grep for the new wording:
```bash
python -c "
import fitz, glob, os
files = glob.glob('<scratchpad>/appdocs/reports/*.pdf')
f = max(files, key=os.path.getmtime)
doc = fitz.open(f)
text = '\n'.join(p.get_text() for p in doc)
open('scratchpad_pdf_text.txt','w',encoding='utf-8').write(text)
"
```
(Use `python`, not `python3`, on Windows in this environment — PyMuPDF is
only installed under the `python` launcher here. If neither has it, try
`/c/Users/DELL/AppData/Local/Programs/Python/Python314/python.exe`.)

Then run the standard regex sweep across the WHOLE document text (not just
your new section — confirms you didn't regress anything elsewhere):
```python
import re
checks = {
    'n/a leak': re.compile(r'\bn/a\b', re.I),
    'glued period artifact': re.compile(r'[a-z]\.[A-Z][a-z]*:'),
    'garbled is-where/this': re.compile(r'\bis where\b|\bis this\b', re.I),
    'doubled verb': re.compile(r'\b(is|has|are|formed)\s+\1\b', re.I),
    'raw token leak': re.compile(r'\{[A-Z0-9_]+\}'),
    'double space': re.compile(r'  '),
    'dangling lowercase and after period': re.compile(r'\. and\b'),
    'raw slash alternative leak': re.compile(r'\([A-Za-z ]+/[A-Za-z ]+\)'),
}
```
Add a bug-specific check whenever you fix something novel (e.g. a
"duplicated no-repair sentence" check was added when H3's pond bug was
found) — it becomes part of the sweep for every element after that. All
counts must be 0. Delete the scratch `scratchpad_pdf_text.txt` when done.

**Gate 4 — Client sign-off packet.**
Write `<elementid>_signoff.html` to the scratchpad directory, reusing the
exact "warm paper/ink" CSS design system from any prior `*_signoff.html`
file in that directory (copy one wholesale, keep the `<style>` block
byte-identical, only change the body content). Sections every packet has:
meta-row (source/keys-changed/bugs-found/regression), content-rewrite
diffs (old vs new, side by side), bugs-found-and-fixed (if any), content
gaps flagged (if any — no matching input field for a spec sub-topic),
verification-evidence pill strip, approval box with reviewer/date/decision
fields, footer. Publish via the Artifact tool with `favicon: "📋"` (same
emoji every time — this is a series, don't change it).

## Hard-won lessons (read before rewriting anything)

- **App's own section/group numbering does NOT reliably match the spec's
  element numbering.** Confirmed broken past G1 (app's G1-G7 tree groups
  vs spec's G1-G4), and H2's tree group ("H2 Other") turned out to be a
  catch-all whose bank master (`{H_OTHER}`) is shared across content
  belonging to at least 5 different spec elements (H2/H3/H4/H5 and a J-risk
  topic). Always verify which master/handler a screen actually calls
  before assuming its tree location tells you its spec element.
- **A shared bank master can span multiple spec elements — scope your
  rewrite to only the sub-keys that genuinely belong to the element you're
  closing.** Leave the rest byte-identical for whichever future element
  owns it. Document the split clearly in the sign-off packet (see H2, H3,
  H4's packets for the pattern).
- **Content can be owned by a DIFFERENT section entirely.** The cold-water
  storage tank content reachable from "G3 Water" screens is actually
  Section-F content (`{F_ROOF_STRUCTURE_WATER_TANK}`, same master F1's
  `_insideRoofWaterTank` uses) — already closed under F1, don't re-touch it
  from G3.
- **Coupled string-literal logic breaks silently when you reword a
  template it depends on.** Several handlers have hardcoded
  empty-slot-suppression or dangling-conjunction cleanup that does
  `template.replaceAll('<exact old substring>', '...')`. If you reword a
  template with this kind of dependency, update the Dart-side literal
  string in the SAME commit, or the audit harness will immediately flag a
  new GRAMMAR/UNAPPROVED regression (this happened once, in G2 — caught
  same-session, fixed same-session). When a template has this kind of
  coupling and is already worded acceptably, it is often safer to leave it
  completely untouched (done deliberately for H2's Large Outbuilding).
- **When the audit reports UNAPPROVED for text that reads fine and looks
  like genuine approved content**, check whether it's a multi-key,
  single-space-merged composite the audit's per-key regex matcher can't
  verify as a whole, BEFORE assuming a wording bug. Fix: add the full
  combined literal text as a new entry in
  `tool/phrase_audit/reference/verified_variants.json` (documented
  "non-defect merged-composition class", used many times already — see the
  file for the pattern and required fields: `master`, `subCode`,
  `reviewedIn`, `reason`, `template`).
- **Bugs found by actually reading the raw bank JSON, not just sampling
  generated output, have repeatedly turned out to be real** (a hardcoded
  duplicate sentence that could self-contradict the real answer in H3's
  pond text; a copy-pasted wrong-utility noun in G2; a missing "not" that
  reversed a sentence's meaning in G1; a raw unresolved "(this/or that)"
  editorial slash-choice shipped verbatim in G4). Always read the literal
  stored text for every key you touch, don't just trust that it "looks
  fine" from a code review of the handler.
- **Text-extraction tools can lie about rendering.** PyMuPDF's
  `get_text()` misdecoded a correctly-stored curly-quote character as a
  garbled symbol in one case (H3's "'soft' water") — always confirm a
  suspected rendering defect with an actual zoomed pixel render
  (`page.get_pixmap(clip=..., matrix=fitz.Matrix(8,8))`) before concluding
  it's a real bug, not just a text-extraction artifact.
- **Content gaps (spec sub-topic with no matching input field) are
  ALWAYS flagged in the sign-off packet, never silently fabricated new UI
  for.** If closing a gap would require a new always-on tree screen (not
  just rewording an existing one), stop, extend the closest existing real
  trigger point as far as it genuinely goes, and flag the remaining
  limitation explicitly for a client/product decision (see H4's packet for
  the fullest example of this — Ownership disclaimer currently only fires
  on a fence defect, not universally, and that's disclosed, not hidden).
- **Spec doesn't always sub-number the way the app does — sometimes the
  app has numbering the spec never had at all.** Section G had the
  opposite problem (app numbering ≠ spec numbering); Section I has this
  one: spec's "Issues for Your Legal Adviser" is a single flat section
  with ~26 named sub-topics and no I1/I2/I3 split whatsoever — the I1/I2/I3
  convention is purely the app's own pre-existing screen naming (which
  existing cross-inject citations elsewhere in the report already depend
  on). When a "shuru karo" command names a sub-element that doesn't exist
  in the digitised spec, check for this before assuming the spec entry is
  missing — map spec's flat sub-topic list onto whichever existing
  app-numbered screen fits by content instead.
- **When a naive text search for a section heading string returns
  misleading results in extracted PDF text, search for unique wording
  from your OWN rewrite instead.** A `text.find('I1')` search once matched
  a coincidental substring elsewhere in the linear PDF text stream well
  before the real Section I content — grepping for a distinctive phrase
  you just wrote (e.g. a rewritten sentence fragment) is far more reliable
  than searching for short section-heading tokens that can collide with
  unrelated text.
- **A bug found in one template's wording is worth grepping the WHOLE
  document for, not just declaring fixed once the one instance is
  patched.** The "advice"/"advise" word-class error was first found in H5,
  fixed there, then found AGAIN independently in 4 more I1 templates, and
  the Gate 3 sweep for I1 found it a 5th and 6th time in I2/I3 content
  still to come. Each time, only the in-scope instances were fixed and the
  rest flagged for their own element — but it's worth remembering this
  class of bug tends to recur across the legacy bank, so a full-bank grep
  for it may be worth doing once Section J is done and before Phase 3's
  final validation pass.

## Progress table

| Phase | Scope | Status |
|---|---|---|
| Phase 0 | Digitise RICS L2 library + verification rig | ✅ Done |
| Phase 1 | Cross-cutting architecture (condition-rating helper, cross-inject registry, etc.) | ✅ Done |
| Phase 2A | PART 1 preamble (Section A + D) | ✅ Done |
| Phase 2B | Section E, Outside the Property (E1–E9) | ✅ Done, all 9 elements |
| Phase 2C | Section F, Inside the Property (F1–F9) | ✅ Done, all 9 elements |
| Phase 2D | Section G, Services (G1–G4) | ✅ Done, all 4 elements |
| Phase 2E | Section H, Grounds (H1–H5) | ✅ Done, all 5 elements |
| **Phase 2F** | **Sections I + J, Legal Issues + Risks (incl. new J4/J5)** | **✅ Done — Section I (I1–I3) and Section J (J1–J5) both fully migrated.** |
| **Phase 2G-mini** | **Deep-audit fixes: Accommodation Summary, Local Environment (2 orphan screens), E1→I3 cross-inject, E8 bug, Section K UI bug** | **✅ Done (2026-07-27) — see "Deep-audit findings" section below** |
| Phase 2G (remainder) | Open Decisions Register — client review of 28 remaining content gaps | ✅ **Drafted and published (2026-07-27)** — https://claude.ai/code/artifact/e33dac76-7079-4018-87f0-6386f460c30d — awaiting client decisions |
| Phase 3 | End-to-end validation + final sign-off | ⬜ Not started |

## Deep-audit findings (2026-07-27) — verified directly against the client's raw PDF

A full re-verification against `C:\Users\DELL\Downloads\Surveyscriber Phrase Bank.pdf` itself (not just
this file's own summaries) found **3 gaps no prior phase-close had flagged**, and confirmed the
digitised spec (`rics_l2_library.json`) is byte-exact trustworthy on spot-check.

**Note on "Type A" vs "Type B" gaps** (a distinction introduced this session, used going forward):
- **Type A** = content gaps every closed phase already disclosed in its own sign-off (missing
  fields for spec sub-topics — e.g. Section I's ~20-topic gap, F6/F9's clusters). Not new, just
  never previously consolidated into one list.
- **Type B** = gaps found only by this fresh audit, never disclosed anywhere before. There were 3:
  1. Accommodation Summary was a dead bank key; the real rendered table never had spec's intro sentence — **fixed in Phase 2G-mini**.
  2. Local Environment content is split across 3 screens; only 1 was migrated in Phase 2A — **fixed in Phase 2G-mini** (the other 2).
  3. Spec's Commercial premises / Industrial premises / Public house / School checklist items have no field anywhere — **still open**, no safe fix without a new field.

Phase 2G-mini closed items 1 and 2 above, plus 2 pre-flagged Type-A quick wins (E1→I3 shared-chimney
cross-inject, E8 duplicate-screen bug). Full detail, code locations, and verification evidence are in
the private memory file's "Phase 2G-mini" entry (2026-07-27) — read that first if resuming this work.

**Also found and fixed this session**: a separate, UI-layer bug (not phrase-bank) — Section K
(`activity_capture_floor_site_plan_sketches`) was fully defined in the tree with a working phrase
handler, but `inspection_overview_page.dart`'s hardcoded `orderedKeys` list never included `'K'`, so
a surveyor could never open it from the app. Fixed by adding `'K'` to that list and routing it into
the pre-existing (previously always-empty) "Documentation & Completion" card group. Verified via
`flutter analyze` (0 errors) and full regression (525 passing, same 5 known failures).

**Remaining Type A gaps (Section I's 20 topics, F6/F9, H4/H5, the noisy-area/risks-other_
duplicate-content risk, E8's duplicate-screen architecture question, the Commercial/Industrial/Pub/
School missing checklist items) are now compiled into the formal Open Decisions Register** —
published as a client-facing Artifact: https://claude.ai/code/artifact/e33dac76-7079-4018-87f0-6386f460c30d
(28 items, organized by report section, each with exact spec wording, current app behaviour, and
options for the client to choose from). Awaiting client review/decisions before any of these are
acted on.

### Section H detail (complete)

| Element | Status | Real bugs found | Content gaps flagged |
|---|---|---|---|
| H1 Garage | ✅ Closed | 1 — "no garage" text could fire for a garage that simply wasn't inspected | Garage Door, Garage Floor (no fields at all) |
| H2 Permanent Outbuildings | ✅ Closed | 0 (content already clean) | none new — clarified `{H_OTHER}` spans 5 elements, scoped strictly |
| H3 Outside Areas | ✅ Closed | 1 — pond sentence hardcoded "reasonable" then repeated itself with the real answer (self-contradiction risk) | Gates (no field at all), standalone Decking condition |
| H4 Boundaries *(new spec element, no prior screen)* | ✅ Closed | 0 — extended existing Fence-repair screen instead | **Open decision flagged**: Ownership disclaimer only fires on a fence defect, not universally; needs either a new always-on H4 screen or moving the line onto H3's fencing-available branch |
| H5 Shared Areas *(new spec element, no prior screen)* | ✅ Closed | 2 — "advice"/"advise" word-class error; a garbled "garden to the building" phrase | **Open decision flagged, linked to H4's**: screen only covers shared *garden* access, not driveway/parking/pathways; no standalone condition rating either |

**Section H (H1–H5) is fully done.** Sign-off packets:
[H1](https://claude.ai/code/artifact/c37b2032-6833-44e1-bdfc-d293399a9a01) ·
[H2](https://claude.ai/code/artifact/ffebce6e-2b78-4a37-8491-2062d337e8e7) ·
[H3](https://claude.ai/code/artifact/037dde4c-d109-4dbd-8b90-ed75cc7be423) ·
[H4](https://claude.ai/code/artifact/d8fdf863-0643-4b16-9c7e-7dd4fccfcb31) ·
[H5](https://claude.ai/code/artifact/6396ec01-024c-4fb5-be55-e6aecf4d688e)
(these are private Claude Artifact links tied to the account that generated
them — treat the bullet points in this file as the durable record, not the
links, if you can't open them).

Every closed element also got a genuine full-content parity test file
(`test/features/property_inspection/domain/inspection_phrase_engine_<topic>_parity_test.dart`)
where none existed before, or a new one alongside a narrower pre-existing
"legacy quirk" test that didn't cover the whole element.

### ✅ Cross-inject gap in Section I — found and fixed same-day (2026-07-27)

While starting J1, found 2 pre-existing code comments in
`report_builder.dart` documenting a **never-wired cross-inject**: spec
text for E5 (Windows) and E6 (Outside Doors) each say "Add text to:
Section J2 Guarantees - You should ask your legal adviser to confirm
whether the PVC glazed sections to the {windows/doors} were installed by
a contractor registered with FENSA. Enquiries should also be made
regarding any guarantees or warranties for the double glazing." Phase 2B
(Section E work) correctly identified "J2" as almost certainly a typo for
"I2" (Guarantees is I2 everywhere else in the spec; the app has no J2
content at all) and deliberately left it unwired rather than routing it to
the wrong section — but left it marked "deferred to Phase 2F", and it was
missed when I2 was originally closed this session.

**Fixed on the user's request** ("abhi patch kar do I2 mai"): extended the
existing `_legacyDerivedSectionFIssueGuarantees` function in
`report_builder.dart` (already wired to I2's screen for an unrelated F9
damp-guarantee injection — same pattern, extended in place) to also check
`activity_outside_property_windows_aboutwindow`'s `cb_is_replacement` +
`cb_pvc` checkboxes, and `activity_outside_property_out_side_doors_about_doors`'s
`cb_replacement` checkbox (this is the dedicated PVC-material door screen,
so no separate material checkbox needed there). Updated the 2 stale
"deferred" code comments to point at the fix. Added 2 new tests to
`report_builder_test.dart` (positive + negative case). Full regression:
516 passing, same 5 pre-existing failures. Verified live via a temporary
curated real-app PDF regeneration (reverted after use) and a full regex
sweep — all clean. I2's sign-off packet was amended in place (same URL)
with a dated note rather than silently treated as already covered.

### Section I detail (complete, including the cross-inject fix above)

**Structural finding**: the RICS L2 spec has NO I1/I2/I3 numbering — Section
I ("Issues for Your Legal Adviser") is one flat block with ~26 named
sub-topics. The app's own "I1 Regulation" / "I2 Guarantees" / "I3 Other
Matters" screens (and the citations elsewhere in the report that already
say "See Section I1 - Regulations" etc.) are a pre-existing APP convention,
not from spec. Mapped spec's sub-topics onto these 3 screens by content.

| Screen | Status | Real bugs found | Content gaps flagged |
|---|---|---|---|
| I1 Regulation | ✅ Closed | 3 — "advice"/"advise" error (×4 templates), "units of flat" grammar, mismatched quote marks | **Largest gap of the whole migration**: ~20 of spec's ~26 Section I sub-topics have no matching field anywhere in I1/I2/I3 (Electrical/Gas/Heating records, Renewable Energy, Roof/Chimney Alterations, Damp-Proofing, Timber Treatment, insulation types, Asbestos, Flood Risk, Trees, Rights of Way, legal Boundaries, Shared Facilities, Private Roads, Drainage, Leasehold/Freehold, General Legal Enquiries) |
| I2 Guarantees | ✅ Closed | 3 — same "advice"/"advise" bug in all 3 rewritten templates (2 pre-flagged by I1, 1 found fresh) | — |
| I3 Other Matters | ✅ Closed | 2 — "advice"/"advise" error, plus a compounding "on you on" duplication typo | — |

**Section I (I1–I3) is fully done — the "advice"/"advise" bug class (10
instances across H5, I1, I2, I3) is now completely eradicated document-wide,
confirmed via a full-document regex sweep returning zero matches.**
Sign-off packets:
[I1](https://claude.ai/code/artifact/e099d534-25b3-4550-9765-7c3f868c0465) ·
[I2](https://claude.ai/code/artifact/0695340e-a0ca-4437-a5bd-ce0ca106dda6) ·
[I3](https://claude.ai/code/artifact/32967cc0-c1ba-4334-bed7-0dcf3a0a93f6).

## Open product decisions awaiting the client/user (nothing silently decided)

1. **H4 Boundaries / H5 Shared Areas structural gap** (linked — same root
   cause) — H4's Ownership disclaimer only fires on a fence defect, not
   universally; H5's Shared Access screen only covers shared gardens, not
   driveway/parking/pathways, and has no standalone condition rating.
   Fixing either properly likely means a real always-on input screen for
   both; worth deciding together rather than separately.
2. Every "content gap" flagged across every closed element (Garage
   Door/Floor, Gates, standalone Decking, G1's RCD/wiring/socket/lighting +
   6 defect types, G2's Gas Appliances catalog + standalone Pipework
   rating, G3's Water Pressure + supply-type selection, G4's Heating
   Controls, F6's 8-item kitchen gap cluster, F9's 10-item loft/fire-safety
   gap cluster) — these are all places where the RICS L2 spec describes a
   sub-topic the app currently has no input field for at all. None have
   been "fixed" by inventing new screens; they're documented for a future
   product conversation.
3. Whether to eventually build the new H4/H5 (and later J4/J5) sections as
   real dedicated input screens, or keep deriving them from adjacent
   existing screens as done so far — the original plan's Phase 1 called
   this "auto-derive where possible, add real screens only where
   unavoidable," which is the principle applied throughout, but it hasn't
   been revisited with the client since Phase 1 closed.

## Where everything lives

| What | Where |
|---|---|
| Digitised spec (source of truth for wording) | `tool/phrase_audit/reference/rics_l2_library.json` |
| Original architecture plan | `C:\Users\DELL\.claude\plans\wise-napping-emerson.md` |
| Live phrase bank (what actually ships) | `assets/property_inspection/phrase_texts.json` |
| Tree/screens/fields | `assets/property_inspection/inspection_tree.json` |
| Phrase engine (all handlers) | `lib/features/property_inspection/domain/inspection_phrase_engine.dart` |
| Report assembly | `lib/features/report_export/data/services/report_builder.dart`, `pdf_generator_service.dart` |
| Audit harness | `test/phrase_audit/phrase_permutation_audit_test.dart` |
| Audit harness escape hatch for verified-but-unmatchable text | `tool/phrase_audit/reference/verified_variants.json` |
| Real-PDF generation harness | `test/_scratch_real_app_pdf.dart` |
| Per-element parity tests | `test/features/property_inspection/domain/inspection_phrase_engine_*_parity_test.dart` |
| Sign-off packets (HTML, in scratchpad, one per closed element) | `<elementid>_signoff.html`, published as Claude Artifacts (URLs recorded in the private memory file below, and in this session's chat history) |
| Cross-session memory (private, this AI account only — NOT a substitute for this file) | `C:\Users\DELL\.claude\projects\C--Users-DELL\memory\surveyscriber-client-audit.md` |

### Section J detail (complete — J1–J5 all done)

**Structural finding**: app's Section J tree has only 3 real screens — J1
(`activity_risks_risk_to_building_`), an oddly-labelled "J4 Other"
(`activity_risks_other_`), and an unnumbered "Repair or improve the
property" screen. J2 and J3 have NO dedicated screens at all — both are
synthesised at report-assembly time in `report_builder.dart` by reading
data from OTHER sections' screens (H-section grounds screens for J2;
F/E-section defect checkboxes for J3, built in an earlier phase before
this one). This is the established "derive, don't fabricate a new screen"
architecture — follow it for J4/J5 too rather than assuming a new tree
screen is needed.

| Element | Status | Notes |
|---|---|---|
| J1 Risks to the Building | ✅ Closed | Real dedicated screen. 2 bugs fixed: a self-contradicting "nearby trees...but none were seen" sentence, and a Timber-Defect field that only described woodworm despite also covering decay. 3 content gaps flagged (Condensation, Drainage-as-risk, decay/insect distinction). |
| J2 Risks to the Grounds *(new spec element, no prior screen)* | ✅ Closed | **First fully-derived section built this session** — new `_legacyDerivedSectionFRiskToGrounds` function in `report_builder.dart`, sources data from 4 existing H-section grounds screens (topography, nearby-trees, retaining-walls, fence-repair), follows J3's pre-existing derivation pattern exactly. |
| J3 Risks to People | ✅ Closed | Reviewed (not rebuilt) the pre-existing `_legacyDerivedSectionFRiskToPeople` function. 6 grammar/agreement bugs fixed in that function. The same "the include" and "is health and safety hazard" typos then turned up TWICE more, independently: once as the true-source content in 3 `phrase_texts.json` bank keys (used by Section E's own screens, unrelated to J3), and once more inside J1's own `_legacyDerivedSectionFRiskToBuilding` fallback function — a third, separate authoring mistake. All 3 locations fixed; a full-document regex sweep confirmed zero matches only after the 3rd fix. 3 content gaps flagged (Trip Hazards, Electrical/Gas Safety, holistic Staircase condition). |
| J4 Risks to Health *(new spec element, no prior screen)* | ✅ Closed | Confirmed "J4 Other" (airport/train/motorway) has zero overlap with spec's J4 before writing code. New `_legacyDerivedSectionFRiskToHealth` covers all 4 sub-topics (Asbestos, Lead, Mould Growth, Radon) — zero content gaps, a first for a new J-element. Asbestos check spans 14 verified sites across E/F/G/H (3 id-collision false positives correctly excluded). 2 misfiled "(see section J3 Risks)" citations fixed to J4 where content was genuinely health-related (textured-coating asbestos, lead water pipe). Always renders (unlike J1-J3) since spec's own Lead/Radon text has no conditional branch. |
| J5 Risks to the Security of the Property *(new spec element, no prior screen)* | ✅ Closed | New `_legacyDerivedSectionFRiskToSecurity`. External Doors (from E6's existing security-offered field) and Security Systems (from the Communal Area screen's CCTV/gates/entry-system checkboxes) only fire when real data exists — unlike J4's Asbestos/Mould, a specific security-level claim can't safely default to "fine" with zero data. General Advice always fires (no "or" branch in spec). 3 honest gaps flagged: Windows, External Lighting (no fields at all), Overall Risk Assessment (deliberately not derived — risk of contradicting the app's existing Overall Opinion elsewhere in the report). |

**Section J (J1–J5) is fully done.** Sign-off packets:
[J1](https://claude.ai/code/artifact/c97fb458-f88a-4927-b458-577f476c46d8) ·
[J2](https://claude.ai/code/artifact/0de13057-a801-42f0-9441-999694659455) ·
[J3](https://claude.ai/code/artifact/72287937-2d50-4342-99bf-80585649b89d) ·
[J4](https://claude.ai/code/artifact/c59ca732-5e4e-498b-afa7-85adfbad0e05) ·
[J5](https://claude.ai/code/artifact/adde9c43-4660-498d-8bfc-9a0f9ded71ae).

**Sections A/D/E/F/G/H/I/J are now all migrated.** Only Phase 2G (Section K
/ Overall Opinion / Accommodation) and Phase 3 (end-to-end validation +
final sign-off) remain of the entire plan.

**Also fixed this phase**: a cross-inject gap discovered in "closed"
Section I (E5/E6 → I2 PVC-replacement guarantee text, deferred since
Phase 2B and missed when I2 was first closed) — patched into
`_legacyDerivedSectionFIssueGuarantees` on the user's explicit request. See
the private memory file's I2/J1 entries for full detail if you need the
history; the fix itself is done and tested.

## What to do right now

**Phase 2F is done. Sections A/D/E/F/G/H/I/J are all fully migrated.**
Only Phase 2G (Section K / Overall Opinion / Accommodation) and Phase 3
(end-to-end validation + final sign-off) remain.

**Next command to expect: "K shuru karo" (or similar for Phase 2G).**
When it comes:

1. Read Section K's spec entries in `rics_l2_library.json` (grep for
   `"appSection": "K"` or similar — check the actual key names, don't
   assume "K1"/"K2" numbering matches spec any more than J's numbering
   did). Also check whatever spec calls the Overall Opinion / valuation
   summary / accommodation schedule content — this may span multiple
   spec keys outside a strict "K" prefix.
2. **Don't assume any existing screen/section maps to spec by number or
   name** — this has been wrong more often than right across this entire
   migration (G1-G7 vs G1-G4, I1-I3 vs spec's flat block, J4 Other vs
   spec's J4). Read what the app's current K-section / Overall Opinion /
   Accommodation screens actually contain before mapping anything.
3. Note: `_overallOpinion` in `inspection_phrase_engine.dart` already
   exists (Section A) and produces the report's main opinion paragraph —
   check whether spec's "Overall Risk Assessment"-style content (flagged
   as a content gap in J5, see its sign-off packet) should actually live
   here instead, since J5 deliberately deferred building a whole-report
   risk rollup to avoid contradicting this existing opinion text. This is
   a good candidate for the first thing to resolve in Phase 2G.
4. Check whether Phase 2G's content can be DERIVED from existing data or
   needs new tree fields — same decision process as every phase before it.
5. **Check for the "advice"/"advise" bug and its variants here too** even
   though H/I/J are now clean — this bug class recurred repeatedly across
   this migration. Always grep broadly, never assume a fix in one place is
   the only place.
6. Follow the same 4-Gate cycle as every prior element/phase.

After Phase 2G is closed, update the progress table's row to ✅, add a
completion milestone note, then wait for the user's next instruction
before starting Phase 3 (end-to-end validation: full permutation audit
against the new library with 0 gaps, a cross-injection integrity test for
all 36+ "Add text to Section X" behaviours, a full real-app PDF reviewed
page-by-page against the 95-page library, and final client/RICS-assessor
sign-off — see the original plan file for the complete Phase 3 scope).
