#!/usr/bin/env python3
"""Consolidate all phrase-audit outputs into one client-facing edit report.

Merges:
  output/inspection_audit.json      (permutation harness - inspection tree)
  output/valuation_audit.json       (permutation harness - valuation tree)
  output/paragraph_structure.json   (master-template paragraph audit)
  output/condition_rating_audit.json
  output/excel_v5_diff.json

Writes:
  output/EDIT_REPORT.md  - the deliverable requested by the client: a
                           line-by-line register of report-language defects,
                           grouped by defect class, with samples and counts.

Usage:
    python tool/phrase_audit/generate_edit_report.py
"""
from __future__ import annotations

import json
from datetime import date
from pathlib import Path

OUT = Path(__file__).parent / "output"


def load(name: str) -> dict:
    return json.loads((OUT / name).read_text(encoding="utf-8"))


def main() -> int:
    inspection = load("inspection_audit.json")
    valuation = load("valuation_audit.json")
    paragraphs = load("paragraph_structure.json")
    ratings = load("condition_rating_audit.json")
    excel = load("excel_v5_diff.json")

    ins = inspection["summary"]
    val = valuation["summary"]

    md: list[str] = []
    w = md.append

    w("# SurveyScriber Report-Language Edit Report")
    w("")
    w(f"Date: {date.today().isoformat()}")
    w("")
    w("Automated line-by-line audit of every report phrase the app can")
    w("produce, verified against the approved phrase database (legacy 2018")
    w("bank + HB APP Database v5). Produced by the permutation test harness")
    w("(`test/phrase_audit/phrase_permutation_audit_test.dart`), which will")
    w("re-run on every future change to keep the report language compliant.")
    w("")
    w("## 1. Executive summary")
    w("")
    w("| Area | Result |")
    w("|---|---|")
    w(f"| Inspection screens audited | {ins['screensAudited']} |")
    w(f"| Inspection phrases exercised | {ins['phrases']['distinctEmitted']} |")
    w(f"| Inspection phrases matching approved bank | "
      f"{ins['phrases']['approvedLegacyBank']} "
      f"({ins['phrases']['approvedLegacyBank'] * 100 // max(1, ins['phrases']['distinctEmitted'])}%) |")
    w(f"| Inspection phrases NOT from approved bank | "
      f"{ins['phrases']['unapproved']} across "
      f"{ins['bySeverity']['UNAPPROVED']} screens |")
    w(f"| Valuation phrases NOT from approved bank | "
      f"{val['phrases']['unapproved']} of {val['phrases']['distinctEmitted']} "
      f"(valuation engine is not bank-driven at all) |")
    w(f"| Screens producing no phrase at all (gaps) | "
      f"{ins['bySeverity']['GAP']} |")
    w(f"| Screens emitting broken/ungrammatical sentences | "
      f"{ins['bySeverity']['GRAMMAR']} inspection + "
      f"{val['bySeverity']['GRAMMAR']} valuation |")
    w(f"| Unresolved template tokens leaking into report | "
      f"{ins['bySeverity']['PLACEHOLDER_LEAK']} screens |")
    w(f"| Report sections rendered sentence-per-line instead of paragraphs | "
      f"{paragraphs['fragmentedMasters']} of "
      f"{paragraphs['mastersWithMultiSentenceParagraphs']} sections |")
    missing_ratings = [
        f for f in ratings["findings"]
        if f["status"] in ("MISSING", "NO_SCREEN_MATCH")
    ]
    w(f"| Sections missing a condition rating | {len(missing_ratings)} of "
      f"{ratings['legacySectionsRequiringRating']} required |")
    w(f"| Approved phrases updated in Database v5 but absent from app | "
      f"{excel['missingFromBank']} |")
    w("")

    w("## 2. Paragraph structure defects (client examples: Construction, Porch)")
    w("")
    w("The approved database defines which sentences belong together in one")
    w("paragraph. The current report renderer only honours this for 4 areas.")
    w("The following report sections are affected and will be fixed by")
    w("driving paragraph assembly from the database structure itself:")
    w("")
    for f in paragraphs["findings"]:
        if f["coveredByCondenseWhitelist"]:
            continue
        groups = "; ".join(
            " + ".join(c.strip("{}") for c in g)
            for g in f["multiSentenceGroups"][:3]
        )
        w(f"- **{f['masterCode'].strip('{}')}** — sentence groups: {groups}")
    w("")

    w("## 3. Phrases not from the approved database")
    w("")
    w("### 3.1 Inspection")
    w("")
    w("| Screen | Section | Sample non-approved output |")
    w("|---|---|---|")
    shown = 0
    for s in inspection["screens"]:
        if "UNAPPROVED" not in s.get("severities", []):
            continue
        sample = (s.get("unapprovedSamples") or [""])[0]
        sample = sample.replace("|", r"\|")
        if len(sample) > 110:
            sample = sample[:110] + "…"
        w(f"| `{s['screenId']}` | {s['sectionKey']} | {sample} |")
        shown += 1
        if shown >= 40:
            remaining = ins["bySeverity"]["UNAPPROVED"] - shown
            if remaining > 0:
                w(f"| … | … | *(+{remaining} further screens — see "
                  f"inspection_audit.json)* |")
            break
    w("")
    w("### 3.2 Valuation")
    w("")
    w(f"The valuation phrase engine does not read the approved database at")
    w(f"all: {val['phrases']['unapproved']} of "
      f"{val['phrases']['distinctEmitted']} generated phrases have no")
    w("database source. Recommendation: rebuild valuation phrasing on the")
    w("same bank-driven mechanism as inspection.")
    w("")

    w("## 4. Broken sentences and empty-slot defects")
    w("")
    w("Sentences produced with missing values (e.g. *\"it was occupied and")
    w(".\"*, *\"There is a brick to the of the property\"*, *\"are pvc .\"*).")
    w("These occur when a template is emitted although a dependent answer is")
    w("empty. Fix: suppress or reduce the sentence when a slot is empty.")
    w("")
    w("| Screen | Section | Issues | Sample |")
    w("|---|---|---|---|")
    shown = 0
    for s in inspection["screens"] + valuation["screens"]:
        issues = s.get("grammarIssues")
        if not issues:
            continue
        sample = (s.get("grammarSamples") or [""])[0].replace("|", r"\|")
        if len(sample) > 90:
            sample = sample[:90] + "…"
        w(f"| `{s['screenId']}` | {s['sectionKey']} | "
          f"{', '.join(issues[:4])} | {sample} |")
        shown += 1
        if shown >= 40:
            w("| … | … | … | *(full list in audit JSON files)* |")
            break
    w("")

    w("## 5. Screens generating no phrase (gaps)")
    w("")
    for s in inspection["screens"]:
        if "GAP" in s.get("severities", []):
            w(f"- `{s['screenId']}` ({s['sectionKey']}) — "
              f"{s['dataFieldCount']} data fields, no output for any "
              f"permutation")
    w("")

    w("## 6. Condition rating coverage")
    w("")
    w("The approved database requires an explicit condition rating in "
      f"{ratings['legacySectionsRequiringRating']} sections.")
    for f in missing_ratings:
        w(f"- **{f['legacySection'].strip('{}')}** — {f['matchedScreens']} "
          f"matching screens, none carries a condition-rating field "
          f"({f['status']})")
    w("")

    w("## 7. Database v5 reconciliation")
    w("")
    w(f"{excel['missingFromBank']} phrases in HB APP Database v5 have no")
    w("match in the app's current bank — the approved language has been")
    w("revised since the original migration. Each needs client sign-off and")
    w("import (full list: excel_v5_diff.json / .md).")
    w("")

    w("## 8. How this audit stays current")
    w("")
    w("- `flutter test test/phrase_audit/phrase_permutation_audit_test.dart`")
    w("  regenerates sections 3-5 on demand (runs in ~20 s).")
    w("- `python tool/phrase_audit/paragraph_structure_audit.py`,")
    w("  `condition_rating_audit.py`, `excel_v5_diff.py` cover sections 2,")
    w("  6, 7.")
    w("- `python tool/phrase_audit/generate_edit_report.py` rebuilds this")
    w("  document.")
    w("")

    (OUT / "EDIT_REPORT.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(f"Wrote {OUT / 'EDIT_REPORT.md'} ({len(md)} lines)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
