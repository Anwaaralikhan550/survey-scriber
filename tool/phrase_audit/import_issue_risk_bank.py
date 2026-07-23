#!/usr/bin/env python3
"""Import Section I (Legal Issues) and Section J (Risks) approved templates
into the app's phrase bank.

Root cause (Phase 4 investigation): the original migration only ported
tbl_phrases/tbl_sub_phrases into phrase_texts.json. It never touched
tbl_issue_phrase/tbl_sub_issue_phrase/tbl_risk_phrase/tbl_sub_risk_phrase —
so Section I/J screens (`activity_issues_*`, `activity_risks_*`) had NO
approved-bank templates to draw from, and were hand-written from scratch by
the engine's authors. This script imports the subset of legacy issue/risk
sub-phrases that correspond to fields present in the current V2 tree's I/J
screens, using the exact master/sub-code keys from the legacy dump so
`InspectionPhraseEngine._sub()` can address them directly.

Only entries with a clear 1:1 correspondence to a current checkbox/dropdown
group are imported (verified by manual read of tool/phrase_audit/reference/
old_phrase_bank.json sub_issue_phrases / sub_risk_phrases). Entries covering
E/F/G/H per-defect repair narrative (already handled by dedicated handlers
elsewhere in the engine) are intentionally left out of this Phase 4 pass.

Usage:
    python tool/phrase_audit/import_issue_risk_bank.py
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PHRASE_TEXTS = ROOT / "assets" / "property_inspection" / "phrase_texts.json"
BANK = Path(__file__).parent / "reference" / "old_phrase_bank.json"

# (master, sub_code) -> None means "import legacy text verbatim".
IMPORT_KEYS = [
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_BUILDING_REGULATION}"),
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_PLANNING_PERMISSION}"),
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_GLAZED_SECTIONS}"),
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_NEW_BUILD}"),
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_CONVERSION_STATUS_KNOW}"),
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_CONVERSION_STATUS_UNKNOW}"),
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_CONSERVATION}"),
    ("{ISSUE_REGULATIONS}", "{REGULATIONS_LISTED_BUILDING}"),
    ("{ISSUE_GUARANTEES}", "{GUARANTEES_GLAZED_SECTION}"),
    ("{ISSUE_GUARANTEES}", "{GUARANTEES_DPC_TREATMENT}"),
    ("{ISSUE_GUARANTEES}", "{GUARANTEES_REMOVED_WALL}"),
    ("{ISSUE_GUARANTEES}", "{GUARANTEES_BUILDING_WORK}"),
    ("{ISSUE_OTHER_MATTERS}", "{OTHER_MATTERS_FREEHOLD}"),
    ("{ISSUE_OTHER_MATTERS}", "{OTHER_MATTERS_LEASEHOLD}"),
    ("{ISSUE_OTHER_MATTERS}", "{OTHER_MATTERS_RIGHT_OF_WAY}"),
    ("{ISSUE_OTHER_MATTERS}", "{OTHER_SHARED_STACKS_AND_RWG}"),
    ("{ISSUE_OTHER_MATTERS}", "{OTHER_MATTERS_PRIVATE_ROAD}"),
    ("{ISSUE_OTHER_MATTERS}", "{OTHER_MATTERS_PARTY_WALLS}"),
    ("{ISSUE_OTHER_MATTERS}", "{OTHER_MATTERS_TENANTED}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_MOVEMENTS_STATUS_NONE}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_MOVEMENTS_STATUS_NOTED}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_MOVEMENTS_STATUS_INVESTIGATE}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_SUBSIDENCE_STATUS_NONE}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_SUBSIDENCE_STATUS_NOTED}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_SUBSIDENCE_STATUS_INVESTIGATE}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_DAMPNESS_STATUS_NONE}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_DAMPNESS_STATUS_IMPLEMENT_ACTION}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_DAMPNESS_STATUS_INVESTIGATE}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_TIMBER_DEFECT_STATUS_NONE}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_TIMBER_DEFECT_STATUS_NOTED}"),
    ("{RISK_TO_BUILDING}", "{BUILDING_NEAR_BY_TREES}"),
    ("{RISK_TO_OTHER}", "{OTHER_PROXIMITY_AIRPORT}"),
    ("{RISK_TO_OTHER}", "{OTHER_PROXIMITY_TRAIN_STATION}"),
    ("{RISK_TO_OTHER}", "{OTHER_PROXIMITY_TRAIN_LINE}"),
    ("{RISK_TO_OTHER}", "{OTHER_PROXIMITY_MOTORWAY}"),
    ("{RISK_TO_OTHER}", "{OTHER_PROXIMITY_OTHER}"),
    ("{RISK_TO_OTHER}", "{OTHER_REPAIR_IMPROVE}"),
    ("{RISK_TO_OTHER}", "{OTHER_NO_APPLICABLE}"),
]


def clean(text: str) -> str:
    """Strip legacy HTML wrapper tags; keep the same normalize-time cleanup
    the phrase engine already applies to every other bank entry (<p>, smart
    quotes -> plain, stray \xa0)."""
    t = text.strip()
    for tag in ("<p>", "</p>", "<strong>", "</strong>"):
        t = t.replace(tag, "")
    t = t.replace(" ", " ").replace("''", "'").replace("�", "'")
    t = " ".join(t.split())
    return t


def main() -> int:
    bank = json.loads(BANK.read_text(encoding="utf-8"))
    lookup: dict[tuple[str, str], str] = {}
    for entry in bank["sub_issue_phrases"] + bank["sub_risk_phrases"]:
        lookup[(entry["code"], entry["sub_code"])] = entry["text"]

    phrase_texts = json.loads(PHRASE_TEXTS.read_text(encoding="utf-8"))

    added, missing = 0, []
    for master, sub_code in IMPORT_KEYS:
        text = lookup.get((master, sub_code))
        if text is None:
            missing.append((master, sub_code))
            continue
        key = f"{master}::{sub_code}"
        phrase_texts[key] = clean(text)
        added += 1

    if missing:
        print("MISSING from legacy bank (not imported):")
        for m, s in missing:
            print(f"  {m}::{s}")

    # Preserve original key order (new entries appended at the end) and the
    # original formatting (2-space indent, \\uXXXX escapes) so the diff is
    # limited to the actual additions, not a full-file reshuffle.
    PHRASE_TEXTS.write_text(
        json.dumps(phrase_texts, indent=2, ensure_ascii=True, sort_keys=False)
        + "\n",
        encoding="utf-8",
    )
    print(f"Imported {added} Section I/J templates into {PHRASE_TEXTS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
