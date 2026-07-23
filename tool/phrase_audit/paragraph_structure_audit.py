#!/usr/bin/env python3
"""Audit paragraph composition: legacy master templates vs current renderer.

The legacy bank's 79 master templates encode the report's paragraph grammar:
  - sub-phrase codes separated by spaces  -> same paragraph (sentences merged)
  - ``<br /><br />``                      -> paragraph break

The new app imports these templates (assets/property_inspection/
phrase_texts.json) but the report renderer originally only merged phrases for
a small hardcoded whitelist in report_builder.dart
(`_shouldCondensePhrasesAsParagraph`). Every master template that contains a
multi-code space-joined group and is NOT covered by that whitelist rendered as
one-sentence-per-paragraph — the exact defect the client reported for the
Construction and Porch sections.

STATUS (Phase 2, 2026-07-06): fixed by ParagraphComposer
(lib/features/report_export/data/services/paragraph_composer.dart), which
derives paragraph grouping from the master templates at render time for ALL
sections. The "FRAGMENTED" verdicts below describe the pre-fix whitelist and
now serve as the historical defect register; regression protection lives in
test/features/report_export/paragraph_composer_test.dart.

Usage:
    python tool/phrase_audit/paragraph_structure_audit.py

Reads : assets/property_inspection/phrase_texts.json
Writes: tool/phrase_audit/output/paragraph_structure.json / .md
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PHRASE_TEXTS = ROOT / "assets" / "property_inspection" / "phrase_texts.json"
OUT_DIR = Path(__file__).parent / "output"

# Mirrors report_builder.dart `_shouldCondensePhrasesAsParagraph`.
CONDENSED_SCREEN_HINTS = [
    "activity_outside_property_stacks",
    "outside_property_main_walls",
    "outside_property_windows",
    "outside_property_doors",
]

# Master code -> screens whose phrases feed it (name-similarity heuristic used
# only to judge whitelist coverage; the fix itself will consume master codes).
MASTER_SCREEN_HINTS = {
    "{E_MAIN_WALLS}": "outside_property_main_walls",
    "{E_WINDOWS}": "outside_property_windows",
    "{E_OUTSIDE_DOORS}": "outside_property_doors",
    "{E_CHIMNEY_SINGLE_STACK}": "activity_outside_property_stacks",
    "{E_CHIMNEY_MULTI_STACK}": "activity_outside_property_stacks",
}

BR_SPLIT = re.compile(r"(?:\\r\\n|<br\s*/?>)+", re.I)
CODE = re.compile(r"\{[A-Z0-9_]+\}")


def main() -> int:
    texts = json.loads(PHRASE_TEXTS.read_text(encoding="utf-8"))
    masters = {k: v for k, v in texts.items() if "::" not in k}

    findings = []
    for code, template in sorted(masters.items()):
        paragraphs = []
        for segment in BR_SPLIT.split(template):
            codes = CODE.findall(segment)
            if codes:
                paragraphs.append(codes)
        multi_groups = [g for g in paragraphs if len(g) > 1]
        if not multi_groups:
            continue

        hint = MASTER_SCREEN_HINTS.get(code, "")
        whitelisted = any(h in hint for h in CONDENSED_SCREEN_HINTS) if hint else False

        findings.append(
            {
                "masterCode": code,
                "paragraphGroups": paragraphs,
                "multiSentenceGroups": multi_groups,
                "coveredByCondenseWhitelist": whitelisted,
                "verdict": "OK (whitelisted)"
                if whitelisted
                else "FRAGMENTED (renderer emits one sentence per paragraph)",
            }
        )

    fragmented = [f for f in findings if not f["coveredByCondenseWhitelist"]]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "paragraph_structure.json").write_text(
        json.dumps(
            {
                "mastersWithMultiSentenceParagraphs": len(findings),
                "fragmentedMasters": len(fragmented),
                "whitelistedMasters": len(findings) - len(fragmented),
                "findings": findings,
            },
            indent=1,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    md = [
        "# Paragraph Composition Audit",
        "",
        "Legacy master templates define which approved sentences belong to the",
        "same paragraph (space-joined codes) and where paragraph breaks fall",
        "(`<br/><br/>`). The current renderer only honours this for a 4-screen",
        "whitelist (report_builder.dart `_shouldCondensePhrasesAsParagraph`).",
        "",
        f"- Masters with multi-sentence paragraph groups: **{len(findings)}**",
        f"- Currently rendered correctly (whitelisted): **{len(findings) - len(fragmented)}**",
        f"- Fragmented in current reports: **{len(fragmented)}**",
        "",
        "| Master template | Multi-sentence groups | Verdict |",
        "|---|---|---|",
    ]
    for f in findings:
        groups = "<br>".join(
            " + ".join(g) for g in f["multiSentenceGroups"][:4]
        )
        md.append(f"| `{f['masterCode']}` | {groups} | {f['verdict']} |")
    (OUT_DIR / "paragraph_structure.md").write_text(
        "\n".join(md) + "\n", encoding="utf-8"
    )

    print(
        f"masters with multi-sentence groups: {len(findings)}, "
        f"fragmented: {len(fragmented)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
