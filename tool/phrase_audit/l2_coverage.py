#!/usr/bin/env python3
"""RICS L2 migration coverage reporter (progress meter).

For every element/topic in the digitised target spec (rics_l2_library.json),
measure how much of its approved wording is already present in the LIVE app
phrase bank (assets/property_inspection/phrase_texts.json). This is the
"% of the new library migrated" progress meter that gates each section-phase
(a section is done when its coverage hits ~100% with 0 uncovered sentences).

It is a REPORTER, not a pass/fail test - it always exits 0 and writes:
  tool/phrase_audit/output/l2_coverage.json / .md

Matching is option-slot tolerant: the library writes choices as inline
comma/"or" lists (e.g. "good, reasonable, fair, poor, or very poor") that
become {PLACEHOLDER} slots in the app; those runs are wildcarded before
comparison so a migrated template still matches its spec sentence.

Usage: python tool/phrase_audit/l2_coverage.py
"""
from __future__ import annotations

import difflib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REF = Path(__file__).parent / "reference"
OUTDIR = Path(__file__).parent / "output"
SPEC = REF / "rics_l2_library.json"
PHRASES = ROOT / "assets" / "property_inspection" / "phrase_texts.json"

MIN_SENTENCE_CHARS = 40          # ignore short labels/fragments
MATCH_THRESHOLD = 0.82           # difflib ratio to count a sentence "covered"


def norm(text: str) -> str:
    t = text
    t = t.replace("\\r\\n", " ")
    t = re.sub(r"<br\s*/?>", " ", t, flags=re.I)
    t = re.sub(r"<[^>]+>", "", t)
    t = t.replace("\xa0", " ")
    # app placeholders -> single wildcard token
    t = re.sub(r"\{[A-Za-z0-9_]+\}", "@", t)
    # library inline option-lists ("a, b, c, or d" / "a or b") -> wildcard.
    # Collapse a run of >=2 comma-separated words optionally ending in "or X".
    t = re.sub(r"(?:\b[\w-]+,\s*){2,}(?:or\s+)?[\w-]+", "@", t)
    t = re.sub(r"\b[\w-]+\s+or\s+[\w-]+\b", "@", t)
    t = re.sub(r"(@\s*)+", "@ ", t)          # collapse adjacent wildcards
    t = re.sub(r"\s+", " ", t).strip().lower()
    return t


def spec_sentences(block: str) -> list[str]:
    """Substantive sentences from a spec element block (skip headers/bullets)."""
    # drop bullet lines and the "Add text to: Section.." meta lines
    kept = []
    for ln in block.split("\n"):
        s = ln.strip()
        if not s or s.startswith("•"):
            continue
        if re.match(r"add text to", s, re.I):
            continue
        kept.append(s)
    joined = " ".join(kept)
    parts = re.split(r"(?<=[.!?])\s+", joined)
    out = []
    for p in parts:
        p = p.strip()
        if len(p) >= MIN_SENTENCE_CHARS:
            out.append(p)
    return out


def main() -> int:
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    phrases = json.loads(PHRASES.read_text(encoding="utf-8"))

    # Split every bank value into sentences and normalise each, so a single
    # spec sentence is matched against the closest bank SENTENCE rather than a
    # whole (possibly multi-sentence) template value.
    bank_norm = set()
    for v in phrases.values():
        if not (isinstance(v, str) and v.strip()):
            continue
        cleaned = re.sub(r"<[^>]+>", " ", v.replace("\\r\\n", " "))
        for sent in re.split(r"(?<=[.!?])\s+", cleaned):
            ns = norm(sent)
            if len(ns) >= 12:
                bank_norm.add(ns)
        bank_norm.add(norm(v))  # also keep the whole value
    bank_norm = list(bank_norm)

    per_entry = []
    total_sent = total_cov = 0
    for e in spec["entries"]:
        if e["kind"] not in ("element", "part1"):
            continue
        sents = spec_sentences(e["rawBlock"])
        covered = 0
        uncovered_samples = []
        for s in sents:
            ns = norm(s)
            best = 0.0
            for b in bank_norm:
                r = difflib.SequenceMatcher(None, ns, b).quick_ratio()
                if r < best:
                    continue
                r = difflib.SequenceMatcher(None, ns, b).ratio()
                if r > best:
                    best = r
                if best >= MATCH_THRESHOLD:
                    break
            if best >= MATCH_THRESHOLD:
                covered += 1
            elif len(uncovered_samples) < 3:
                uncovered_samples.append(s[:100])
        total_sent += len(sents)
        total_cov += covered
        per_entry.append({
            "specKey": e["key"],
            "specTitle": e["title"],
            "sentences": len(sents),
            "covered": covered,
            "coveragePct": round(100 * covered / len(sents), 1) if sents else 100.0,
            "uncoveredSamples": uncovered_samples,
        })

    report = {
        "purpose": "Progress meter: % of the RICS L2 target library already present in the live phrase bank.",
        "matchThreshold": MATCH_THRESHOLD,
        "totalSpecSentences": total_sent,
        "totalCovered": total_cov,
        "overallCoveragePct": round(100 * total_cov / total_sent, 1) if total_sent else 0.0,
        "perEntry": per_entry,
    }
    OUTDIR.mkdir(parents=True, exist_ok=True)
    (OUTDIR / "l2_coverage.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=True), encoding="utf-8")

    md = [
        "# RICS L2 migration coverage (progress meter)",
        "",
        f"- Overall: **{report['overallCoveragePct']}%** "
        f"({total_cov}/{total_sent} target sentences present in the live bank)",
        f"- Match threshold: {MATCH_THRESHOLD} (option-slot tolerant)",
        "",
        "| Spec | Title | Covered | Sentences | % |",
        "|---|---|---|---|---|",
    ]
    for r in per_entry:
        md.append(f"| {r['specKey']} | {r['specTitle'][:34]} | {r['covered']} | "
                  f"{r['sentences']} | {r['coveragePct']} |")
    (OUTDIR / "l2_coverage.md").write_text("\n".join(md) + "\n", encoding="utf-8")

    print(f"Overall L2 coverage: {report['overallCoveragePct']}% "
          f"({total_cov}/{total_sent} sentences)")
    print(f"Wrote {OUTDIR / 'l2_coverage.json'} and .md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
