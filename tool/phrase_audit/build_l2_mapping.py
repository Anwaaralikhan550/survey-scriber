#!/usr/bin/env python3
"""Build the RICS L2 migration mapping matrix:
tool/phrase_audit/reference/l2_mapping.json

For every entry in rics_l2_library.json (the digitised target spec), record the
CURRENT app artifacts that are the migration target for it:
  - the app section letter it belongs to,
  - candidate current tree screen ids in that section,
  - candidate current phrase_texts.json master keys in that section,
  - a migrationStatus (starts "pending"), refined per section-phase.

This is the master checklist / "definition of done" for the rebuild. It is a
living document: each section-phase updates migrationStatus once that section's
spec entries are covered 0-gap by the live bank.

Usage: python tool/phrase_audit/build_l2_mapping.py
"""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REF = Path(__file__).parent / "reference"
SPEC = REF / "rics_l2_library.json"
TREE = ROOT / "assets" / "property_inspection" / "inspection_tree.json"
PHRASES = ROOT / "assets" / "property_inspection" / "phrase_texts.json"
OUT = REF / "l2_mapping.json"

# Which app section letter each spec section maps to. PART1 preamble topics
# live in app Section D (About Property) + A (About Inspection). E/F/G/H/J map
# one-to-one; I -> app Section I.
SPEC_TO_APP_SECTION = {
    "E": "E", "F": "F", "G": "G", "H": "H", "I": "I", "J": "J",
}
PART1_APP_SECTION = "D"  # preamble descriptive block (a few belong to A)


def app_screens_by_section(tree: dict) -> dict[str, list[str]]:
    out: dict[str, list[str]] = defaultdict(list)
    for section in tree.get("sections", []):
        key = section.get("key", "")
        for node in section.get("nodes", []):
            if node.get("type", "screen") == "screen":
                out[key].append(node.get("id", ""))
    return out


def phrase_masters_by_section(phrases: dict) -> dict[str, list[str]]:
    """Group current master phrase keys by the app section their prefix implies.
    Heuristic prefixes seen in phrase_texts.json: {E_..}, {F_..}, {G_..},
    {H_..}, {D_..}, {ISSUE_..}, {RISK_..}, {OVERALL_..}."""
    out: dict[str, list[str]] = defaultdict(list)
    prefix_map = [
        ("{E_", "E"), ("{F_", "F"), ("{G_", "G"), ("{H_", "H"),
        ("{D_", "D"), ("{ISSUE", "I"), ("{RISK", "J"), ("{OVERALL", "O"),
        ("{PARTY", "A"), ("{PARApet", "E"),
    ]
    for k in phrases:
        master = k.split("::")[0]
        for pref, sec in prefix_map:
            if master.upper().startswith(pref.upper()):
                if master not in out[sec]:
                    out[sec].append(master)
                break
    return out


def main() -> int:
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    tree = json.loads(TREE.read_text(encoding="utf-8"))
    phrases = json.loads(PHRASES.read_text(encoding="utf-8"))

    screens = app_screens_by_section(tree)
    masters = phrase_masters_by_section(phrases)

    rows = []
    for e in spec["entries"]:
        kind, key, title = e["kind"], e["key"], e["title"]
        if kind == "part1":
            app_sec = PART1_APP_SECTION
        else:
            app_sec = SPEC_TO_APP_SECTION.get(key[0], key[0])

        # candidate current screens whose id mentions a keyword from the title
        title_words = [w.lower() for w in re.findall(r"[A-Za-z]+", title) if len(w) > 3]
        cand_screens = [
            s for s in screens.get(app_sec, [])
            if any(w in s.lower() for w in title_words)
        ]

        rows.append({
            "specKey": key,
            "specKind": kind,
            "specTitle": title,
            "appSection": app_sec,
            "candidateScreens": cand_screens[:12],
            "candidatePhraseMasters": masters.get(app_sec, [])[:20],
            "crossInjects": e.get("crossInjects", []),
            "specCharLen": e["charLen"],
            "migrationStatus": "pending",   # pending | in_progress | covered | signed_off
            "notes": "",
        })

    mapping = {
        "purpose": "RICS L2 migration checklist: each target-spec entry -> current app artifacts + migrationStatus. Refined per section-phase.",
        "specSource": spec["source"],
        "rowCount": len(rows),
        "byStatus": {"pending": len(rows)},
        "rows": rows,
    }
    OUT.write_text(json.dumps(mapping, indent=2, ensure_ascii=True), encoding="utf-8")
    print(f"Wrote {OUT}  ({len(rows)} rows)")
    # quick per-section tally
    by_sec = defaultdict(int)
    for r in rows:
        by_sec[r["appSection"]] += 1
    print("rows per app section:", dict(sorted(by_sec.items())))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
