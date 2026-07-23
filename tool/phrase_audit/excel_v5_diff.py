#!/usr/bin/env python3
"""Diff the client's Excel phrase master (HB APP Database v5) against the
current in-app phrase bank.

The repo's original migration consumed an older "HB APP Database.xlsx". The
client has since supplied v5. This script extracts every phrase text from the
v5 sheet (column H, "Field Texts (Phrases)") and reports which entries have
no match in assets/property_inspection/phrase_texts.json — candidate bank
updates that must be reviewed with the client.

Usage:
    python tool/phrase_audit/excel_v5_diff.py <path-to-HB APP Database_v_5.xlsx>

Writes: tool/phrase_audit/output/excel_v5_diff.json / .md
Requires: openpyxl
"""
from __future__ import annotations

import difflib
import json
import re
import sys
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parents[2]
PHRASE_TEXTS = ROOT / "assets" / "property_inspection" / "phrase_texts.json"
BANK = Path(__file__).parent / "reference" / "old_phrase_bank.json"
OUT_DIR = Path(__file__).parent / "output"

MIN_PHRASE_LEN = 25  # ignore UI hints like "Enter text", bare option echoes
SKIP_PREFIXES = (
    "enter ",
    "select ",
    "add ",
    "if ",
    "http",
)


def normalize(text: str) -> str:
    t = text
    t = t.replace("\\r\\n", " ")
    t = re.sub(r"<br\s*/?>", " ", t, flags=re.I)
    t = re.sub(r"<[^>]+>", "", t)
    t = t.replace(" ", " ").replace("\r", " ").replace("\n", " ")
    t = re.sub(r"\buPVC\b", "PVC", t)
    # Placeholders -> wildcard token. Three notations appear across sources:
    #   {CODE}    - legacy bank / phrase_texts.json
    #   (a/b/c)   - Excel v5 option-slot notation
    #   ...       - free-text ellipsis slots
    t = re.sub(r"\{[A-Za-z0-9_]+\}", "@", t)
    t = re.sub(r"\([^()]*/[^()]*\)", "@", t)
    t = re.sub(r"\(type [^)]*\)", "@", t, flags=re.I)
    t = re.sub(r"\.{3,}", "@", t)
    # A wildcard token can swallow a different number of surrounding literal
    # words between sources (e.g. the app bank spells a fixed "is"/"are" out
    # as its own {IS_ARE} placeholder while the v5 sheet writes it as fixed
    # literal text) - collapse runs of wildcard+whitespace into one so this
    # doesn't shift a word-position-based comparison.
    t = re.sub(r"(@\s*)+", "@ ", t)
    t = re.sub(r"\s+", " ", t).strip().lower()
    return t


def fingerprint(text: str) -> str:
    """Loose fingerprint: first 8 significant words with wildcards removed."""
    words = [w for w in re.split(r"\W+", normalize(text)) if w and w != "@"]
    return " ".join(words[:8])


def best_ratio(text: str, candidates: list[str]) -> float:
    """Best difflib similarity ratio of `text` against any candidate,
    using quick_ratio() as a cheap prefilter before the exact ratio()."""
    best = 0.0
    for cand in candidates:
        sm = difflib.SequenceMatcher(None, text, cand)
        if sm.quick_ratio() < best:
            continue
        r = sm.ratio()
        if r > best:
            best = r
    return best


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    xlsx = Path(sys.argv[1])

    wb = openpyxl.load_workbook(xlsx, read_only=True, data_only=True)
    ws = wb[wb.sheetnames[0]]

    v5_rows = []
    section = field = ""
    for row in ws.iter_rows(min_row=2, values_only=True):
        cells = [str(c).strip() if c is not None else "" for c in row[:8]]
        if cells[0]:
            section = cells[0]
        if cells[1]:
            field = cells[1]
        option, phrase = cells[6], cells[7]
        if len(phrase) < MIN_PHRASE_LEN:
            continue
        if phrase.lower().startswith(SKIP_PREFIXES):
            continue
        v5_rows.append(
            {"section": section, "field": field, "option": option, "phrase": phrase}
        )

    current = json.loads(PHRASE_TEXTS.read_text(encoding="utf-8"))
    legacy = json.loads(BANK.read_text(encoding="utf-8"))

    def split_sentences(norm_text: str) -> list[str]:
        return [s.strip() for s in re.split(r"(?<=[.!?])\s+", norm_text) if s.strip()]

    known_texts: list[str] = []
    known_sentences: list[str] = []
    known_fingerprints = set()
    for text in current.values():
        if isinstance(text, str) and text.strip():
            norm = normalize(text)
            if norm:
                known_texts.append(norm)
                known_sentences.extend(split_sentences(norm))
            known_fingerprints.add(fingerprint(text))
    for group in ("phrases", "sub_phrases", "issue_phrases",
                  "sub_issue_phrases", "risk_phrases", "sub_risk_phrases"):
        for entry in legacy.get(group, []):
            text = entry.get("text", "")
            norm = normalize(text)
            if norm:
                known_texts.append(norm)
                known_sentences.extend(split_sentences(norm))
            known_fingerprints.add(fingerprint(text))
    known_fingerprints.discard("")

    # The 8-word-prefix fingerprint is a fast exact-match prefilter, but it
    # produces false "missing" results whenever a wildcard token swallows a
    # different number of literal words between sources (e.g. the app bank
    # spells out a fixed "is"/"are" as its own {IS_ARE} placeholder while the
    # v5 sheet writes it as fixed literal text) - this shifts the word
    # window even though the underlying sentence is identical. A fuzzy
    # ratio() second pass over the full normalized text catches those.
    RATIO_THRESHOLD = 0.72
    # A v5 row is also often a straight concatenation of two-or-more
    # sentences that already exist SEPARATELY in the app bank (e.g. a garden
    # "type" sentence and its own standalone "boundary fences" sentence,
    # composed together by the handler rather than stored as one phrase) -
    # match candidate sentences individually against known sentence
    # fragments as a second signal before concluding real content is absent.
    SENTENCE_RATIO_THRESHOLD = 0.8
    SENTENCE_COVERAGE_THRESHOLD = 0.8
    candidates = [
        row for row in v5_rows if fingerprint(row["phrase"]) not in known_fingerprints
    ]
    missing = []
    for row in candidates:
        norm = normalize(row["phrase"])
        if best_ratio(norm, known_texts) >= RATIO_THRESHOLD:
            continue
        sentences = split_sentences(norm)
        if sentences:
            matched = sum(
                1 for s in sentences
                if len(s) >= MIN_PHRASE_LEN
                and best_ratio(s, known_sentences) >= SENTENCE_RATIO_THRESHOLD
            )
            considered = sum(1 for s in sentences if len(s) >= MIN_PHRASE_LEN)
            if considered and matched / considered >= SENTENCE_COVERAGE_THRESHOLD:
                continue
        missing.append(row)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "excel_v5_diff.json").write_text(
        json.dumps(
            {
                "v5PhraseRows": len(v5_rows),
                "matchedInBank": len(v5_rows) - len(missing),
                "missingFromBank": len(missing),
                "missing": missing,
            },
            indent=1,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    md = [
        "# Excel v5 vs Current Bank Diff",
        "",
        f"- Phrase rows in v5 sheet: **{len(v5_rows)}**",
        f"- Matched in current/legacy bank: **{len(v5_rows) - len(missing)}**",
        f"- Missing from bank (candidate updates): **{len(missing)}**",
        "",
        "| Section | Field | Option | v5 phrase (start) |",
        "|---|---|---|---|",
    ]
    for row in missing[:60]:
        snippet = row["phrase"][:90].replace("|", r"\|").replace("\n", " ")
        md.append(
            f"| {row['section'][:25]} | {row['field'][:25]} | "
            f"{row['option'][:20]} | {snippet}… |"
        )
    (OUT_DIR / "excel_v5_diff.md").write_text("\n".join(md) + "\n", encoding="utf-8")

    print(
        f"v5 rows: {len(v5_rows)}, matched: {len(v5_rows) - len(missing)}, "
        f"missing: {len(missing)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
