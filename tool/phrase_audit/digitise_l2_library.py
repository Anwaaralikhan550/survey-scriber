#!/usr/bin/env python3
"""Digitise the client's 95-page RICS Home Survey Level 2 "Master Phrase
Library" (Francis Blackstone Surveyors) into a structured, machine-checkable
spec: tool/phrase_audit/reference/rics_l2_library.json

This is the single source of truth for the phrase-bank rebuild. It preserves
each element's RAW text block verbatim (the ground truth for byte-exact
verification) AND extracts structured metadata (sub-topic labels, cross-section
injections, defect bullet lists, condition-rating definitions) for the
coverage checker.

Input:  the extracted plain text of the library PDF (produced with PyMuPDF).
Output: reference/rics_l2_library.json

Usage:  python tool/phrase_audit/digitise_l2_library.py <library_text.txt>
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

OUT = Path(__file__).parent / "reference" / "rics_l2_library.json"

# Reliable element/section headers, e.g. "E1 Chimney stacks", "F10 ...".
ELEMENT_HDR = re.compile(r"^([EFGHJ])(\d+)\s+(.+?)\s*$")

# Top-level PART 1 preamble topics (these are the D/A descriptive block).
# Order matters: they appear sequentially in the document.
PART1_TOPICS = [
    "Party conflict disclosure",
    "Property address",
    "Weather",
    "Status",
    "Orientation",
    "Overall opinion",
    "Property type",
    "Year built",
    "Extensions",
    "Conversion",
    "Flat information",
    "Accommodation summary",
    "Construction",
    "Listed building",
    "Energy performance",
    "Other services",
    "Grounds",
    "Parking",
    "Location",
    "Facilities",
    "Local environment",
]

# Section-preamble headers (whole-section intros, not numbered elements).
# Matches both dash style ("E - Outside the Property") and bare style
# ("F Inside the Property", "I Issues for Your Legal Adviser", "J Risks").
SECTION_DASH = re.compile(r"^([EFGHIJ])\s*[-]\s+(.+)$")
SECTION_BARE = re.compile(r"^([EFGHIJ])\s+([A-Z].+)$")


def clean(text: str) -> str:
    """Normalise PDF encoding artifacts without changing wording."""
    t = text.replace("�", "'")  # stray replacement char -> apostrophe/dash context
    t = t.replace("–", "-").replace("—", "-")
    t = t.replace("’", "'").replace("‘", "'")
    t = t.replace("“", '"').replace("”", '"')
    t = t.replace("\xa0", " ")
    return t


def extract_cross_injects(block: str):
    """Find every 'Add text to: Section X - ...' instruction in a block."""
    injects = []
    for m in re.finditer(
        r"Add text to:?\s*Section\s+([A-Z]\d?)\s*[–-]*\s*([^\n]*)",
        block,
        re.IGNORECASE,
    ):
        injects.append({"target": m.group(1).upper().strip(), "textStart": m.group(2).strip()[:120]})
    return injects


def extract_bullets(block: str):
    return [ln.strip("• ").strip() for ln in block.split("\n") if ln.strip().startswith("•")]


def extract_condition_defs(block: str):
    """Capture 'Condition rating 1/2/3' definition paragraphs if present."""
    defs = {}
    for n in ("1", "2", "3"):
        m = re.search(
            rf"Condition rating {n}\s*\n(.+?)(?=\nCondition rating |\n[EFGHJ]\d+ |\Z)",
            block,
            re.DOTALL,
        )
        if m:
            defs[n] = " ".join(m.group(1).split())
    return defs


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    raw = clean(Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace"))
    lines = raw.split("\n")

    # Pass 1: locate element headers and PART1 topic boundaries.
    boundaries = []  # (line_index, kind, key, title)
    for i, ln in enumerate(lines):
        s = ln.strip()
        m = ELEMENT_HDR.match(s)
        if m and len(s.split()) <= 8:
            boundaries.append((i, "element", f"{m.group(1)}{m.group(2)}", m.group(3).strip()))
            continue
        ms = SECTION_DASH.match(s)
        if ms and len(s.split()) <= 8:
            boundaries.append((i, "section", ms.group(1), ms.group(2).strip()))
            continue
        # Bare section header (no dash): a lone section letter + Title, not a
        # numbered element (E1..) and short. e.g. "I Issues for Your Legal Adviser".
        mb = SECTION_BARE.match(s)
        if mb and len(s.split()) <= 6 and not re.match(r"^[A-Z]\d", s):
            boundaries.append((i, "section", mb.group(1), mb.group(2).strip()))
            continue
        if s in PART1_TOPICS:
            boundaries.append((i, "part1", s, s))

    # De-duplicate consecutive PART1 topic repeats, keep first occurrence order.
    seen_part1 = set()
    filtered = []
    for b in boundaries:
        if b[1] == "part1":
            if b[2] in seen_part1:
                continue
            seen_part1.add(b[2])
        filtered.append(b)
    boundaries = filtered

    # Pass 2: slice raw blocks between boundaries.
    entries = []
    for idx, (li, kind, key, title) in enumerate(boundaries):
        end = boundaries[idx + 1][0] if idx + 1 < len(boundaries) else len(lines)
        block = "\n".join(lines[li + 1 : end]).strip()
        entries.append(
            {
                "order": idx,
                "kind": kind,
                "key": key,
                "title": title,
                "rawBlock": block,
                "crossInjects": extract_cross_injects(block),
                "defectBullets": extract_bullets(block),
                "conditionDefs": extract_condition_defs(block),
                "charLen": len(block),
            }
        )

    spec = {
        "source": "Surveyscriber Phrase Bank.pdf - Francis Blackstone Surveyors RICS Home Survey Level 2",
        "part1Topics": PART1_TOPICS,
        "entryCount": len(entries),
        "elementCount": sum(1 for e in entries if e["kind"] == "element"),
        "crossInjectCount": sum(len(e["crossInjects"]) for e in entries),
        "entries": entries,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(spec, indent=2, ensure_ascii=True), encoding="utf-8")
    print(f"Wrote {OUT}")
    print(
        f"entries={spec['entryCount']} elements={spec['elementCount']} "
        f"crossInjects={spec['crossInjectCount']}"
    )
    # Show the element inventory for a sanity check.
    for e in entries:
        if e["kind"] in ("element", "section"):
            print(f"  [{e['kind']}] {e['key']:4} {e['title'][:42]:42} ({e['charLen']} chars, {len(e['crossInjects'])} xinj)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
