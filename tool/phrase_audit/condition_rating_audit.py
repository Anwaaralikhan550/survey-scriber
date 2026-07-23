#!/usr/bin/env python3
"""Condition-rating coverage audit.

The legacy approved bank prints an explicit ``Condition Rating is: {X}.``
sub-phrase in exactly 26 report sections — the authoritative list of where a
condition rating MUST appear. This script checks the current V2 inspection
tree for a condition-rating field in each of those areas and reports
missing/misplaced coverage (client complaint: "condition rating does not
appear in all the places it should, and appears in inconsistent locations").

Usage:
    python tool/phrase_audit/condition_rating_audit.py

Reads : tool/phrase_audit/reference/old_phrase_bank.json
        assets/property_inspection/inspection_tree.json
Writes: tool/phrase_audit/output/condition_rating_audit.json / .md
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BANK = Path(__file__).parent / "reference" / "old_phrase_bank.json"
TREE = ROOT / "assets" / "property_inspection" / "inspection_tree.json"
OUT_DIR = Path(__file__).parent / "output"

# Legacy section code -> keyword(s) identifying the matching V2 screens.
SECTION_KEYWORDS: dict[str, list[str]] = {
    "{E_CONSERVATORY_PORCHES}": ["conservatory_porch", "porch"],
    "{E_MAIN_WALLS_REPAIR}": ["main_walls"],
    "{E_OTHER_JOINERY_AND_FINISHES}": ["joinery"],
    "{E_OTHER}": ["outside_property_other"],
    "{E_OUTSIDE_DOORS}": ["outside_doors", "out_side_doors"],
    "{E_RAINWATER_GOODS_ABOUT}": ["rainwater"],
    "{E_WINDOWS_REPAIR}": ["outside_property_windows"],
    "{F_ABOUT_ROOF_STRUCTURE}": ["roof_structure"],
    "{F_BATHROOM_FITTINGS}": ["bathroom_fittings"],
    "{F_BUILT_IN_FITTINGS}": ["built_in_fittings"],
    "{F_CEILINGS}": ["ceiling"],
    "{F_FIREPLACES_AND_CHIMNEYS}": ["fireplace"],
    "{F_FLOORS}": ["side_property_floors", "inside_property_floors"],
    "{F_OTHER}": ["inside_property_other", "in_side_property_other"],
    "{F_WALLS_AND_PARTITIONS}": ["walls_and_partition", "wap"],
    "{F_WOOD_WORK}": ["woodwork"],
    "{G_COMMON_SERVICES}": ["common_services"],
    "{G_DRAINAGE}": ["drainage"],
    "{G_ELECTRICITY}": ["electricity"],
    "{G_GAS_AND_OIL}": ["gas_oil", "main_gas"],
    "{G_HEATING}": ["services_heating"],
    "{G_WATER_HEATING}": ["water_heating"],
    "{G_WATER}": ["services_water"],
    "{H_GARAGE}": ["garage"],
    "{H_OTHER_AREA}": ["grounds_other"],
    "{H_OTHER}": ["grounds_other"],
}

RATING_FIELD = re.compile(r"condition\s*rating", re.I)


def main() -> int:
    bank = json.loads(BANK.read_text(encoding="utf-8"))
    rating_sections = sorted(
        {
            p["code"]
            for p in bank["sub_phrases"]
            if "condition rating is" in p["text"].lower()
        }
    )

    tree = json.loads(TREE.read_text(encoding="utf-8"))
    sections = tree.get("sections", tree if isinstance(tree, list) else [])

    # screenId -> has condition-rating field?
    screens: dict[str, dict] = {}
    for section in sections:
        for node in section.get("nodes", []):
            if node.get("type") == "group":
                continue
            fields = node.get("fields", [])
            has_rating = any(
                RATING_FIELD.search(f.get("label", ""))
                or RATING_FIELD.search(f.get("id", ""))
                for f in fields
            )
            screens[node.get("id", "")] = {
                "sectionKey": section.get("key", ""),
                "title": node.get("title", ""),
                "hasRating": has_rating,
                "fieldCount": len(fields),
            }

    findings = []
    for code in rating_sections:
        keywords = SECTION_KEYWORDS.get(code, [])
        matched = {
            sid: meta
            for sid, meta in screens.items()
            if any(k in sid for k in keywords)
        }
        with_rating = [s for s, m in matched.items() if m["hasRating"]]
        findings.append(
            {
                "legacySection": code,
                "expectedRating": True,
                "matchedScreens": len(matched),
                "screensWithRating": len(with_rating),
                "status": (
                    "UNMAPPED (manual review)"
                    if not keywords
                    else "MISSING"
                    if matched and not with_rating
                    else "NO_SCREEN_MATCH"
                    if not matched
                    else "OK"
                ),
                "ratingScreens": with_rating[:5],
            }
        )

    total_rating_screens = sum(1 for m in screens.values() if m["hasRating"])

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "condition_rating_audit.json").write_text(
        json.dumps(
            {
                "legacySectionsRequiringRating": len(rating_sections),
                "treeScreensWithRatingField": total_rating_screens,
                "findings": findings,
            },
            indent=1,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    md = [
        "# Condition Rating Coverage Audit",
        "",
        f"Legacy bank requires an explicit condition rating in "
        f"**{len(rating_sections)}** sections. Current tree has "
        f"**{total_rating_screens}** screens with a condition-rating field.",
        "",
        "| Legacy section | Matched screens | With rating | Status |",
        "|---|---|---|---|",
    ]
    for f in findings:
        md.append(
            f"| `{f['legacySection']}` | {f['matchedScreens']} | "
            f"{f['screensWithRating']} | {f['status']} |"
        )
    (OUT_DIR / "condition_rating_audit.md").write_text(
        "\n".join(md) + "\n", encoding="utf-8"
    )

    missing = [f for f in findings if f["status"] in ("MISSING", "NO_SCREEN_MATCH")]
    print(
        f"{len(rating_sections)} legacy sections require rating; "
        f"{len(missing)} flagged missing/unmatched; "
        f"{total_rating_screens} tree screens carry a rating field"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
