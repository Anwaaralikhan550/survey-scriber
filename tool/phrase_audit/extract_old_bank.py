#!/usr/bin/env python3
"""Extract the approved phrase bank from the legacy SurveyScriber MySQL dump.

The legacy app (PHP/MariaDB, 2018) stored the approved report language in:
  - tbl_phrases       : 79 master section templates. Placeholders reference
                        sub-phrase codes; ``<br /><br />`` marks paragraph
                        breaks, space-joined codes share one paragraph.
  - tbl_sub_phrases   : 710 approved sentences keyed (phrase_code, sub_code).
  - tbl_issue_phrase / tbl_sub_issue_phrase : Section I issue language.
  - tbl_risk_phrase  / tbl_sub_risk_phrase  : Section J risk language.
  - tbl_inspection_template : report shell template.

This is the ground truth for RICS-report phrase compliance auditing.

Usage:
    python tool/phrase_audit/extract_old_bank.py <path-to-surveyscriber.sql>

Writes: tool/phrase_audit/reference/old_phrase_bank.json (deterministic).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

OUT_PATH = Path(__file__).parent / "reference" / "old_phrase_bank.json"


def split_tuples(values_blob: str) -> list[str]:
    """Split ``(...),(...),(...)`` into row strings, honouring quotes/escapes."""
    rows: list[str] = []
    depth = 0
    cur = ""
    in_str = False
    esc = False
    for ch in values_blob:
        if esc:
            cur += ch
            esc = False
            continue
        if ch == "\\":
            cur += ch
            esc = True
            continue
        if ch == "'":
            in_str = not in_str
            cur += ch
            continue
        if not in_str:
            if ch == "(":
                depth += 1
                if depth == 1:
                    cur = ""
                    continue
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    rows.append(cur)
                    cur = ""
                    continue
        cur += ch
    return rows


def split_fields(row: str) -> list[str]:
    fields: list[str] = []
    cur = ""
    in_str = False
    esc = False
    for ch in row:
        if esc:
            cur += ch
            esc = False
            continue
        if ch == "\\":
            cur += ch
            esc = True
            continue
        if ch == "'":
            in_str = not in_str
            cur += ch
            continue
        if ch == "," and not in_str:
            fields.append(cur.strip())
            cur = ""
            continue
        cur += ch
    fields.append(cur.strip())
    return fields


def unquote(value: str) -> str:
    value = value.strip()
    if value.startswith("'") and value.endswith("'"):
        value = value[1:-1]
    return (
        value.replace("\\'", "'")
        .replace('\\"', '"')
        .replace("\\r\\n", "\n")
        .replace("\\n", "\n")
    )


def extract_table(sql: str, table: str) -> list[list[str]]:
    rows: list[list[str]] = []
    pattern = re.compile(
        r"INSERT INTO `" + re.escape(table) + r"`[^V]*VALUES\s*(.*?);\s*\n",
        re.S,
    )
    for match in pattern.finditer(sql):
        for row in split_tuples(match.group(1)):
            rows.append([unquote(f) for f in split_fields(row)])
    return rows


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    sql_path = Path(sys.argv[1])
    sql = sql_path.read_text(encoding="utf-8", errors="replace")

    phrases = extract_table(sql, "tbl_phrases")
    sub_phrases = extract_table(sql, "tbl_sub_phrases")
    issue = extract_table(sql, "tbl_issue_phrase")
    sub_issue = extract_table(sql, "tbl_sub_issue_phrase")
    risk = extract_table(sql, "tbl_risk_phrase")
    sub_risk = extract_table(sql, "tbl_sub_risk_phrase")
    templates = extract_table(sql, "tbl_inspection_template")

    bank = {
        "source": sql_path.name,
        "note": "Legacy approved phrase bank extracted from 2018 MariaDB dump. "
        "Do not edit by hand; regenerate with extract_old_bank.py.",
        "phrases": [
            {"id": r[0], "code": r[1], "text": r[2]} for r in phrases
        ],
        "sub_phrases": [
            {"id": r[0], "code": r[1], "sub_code": r[2], "text": r[3]}
            for r in sub_phrases
        ],
        "issue_phrases": [
            dict(zip(["id", "code", "text"], r[:3])) for r in issue
        ],
        "sub_issue_phrases": [
            dict(zip(["id", "code", "sub_code", "text"], r[:4])) for r in sub_issue
        ],
        "risk_phrases": [
            dict(zip(["id", "code", "text"], r[:3])) for r in risk
        ],
        "sub_risk_phrases": [
            dict(zip(["id", "code", "sub_code", "text"], r[:4])) for r in sub_risk
        ],
        "templates": [
            dict(zip(["id", "title", "description"], r[:3])) for r in templates
        ],
    }

    counts = {k: len(v) for k, v in bank.items() if isinstance(v, list)}
    expected = {"phrases": 79, "sub_phrases": 710}
    for key, want in expected.items():
        got = counts[key]
        if got != want:
            print(f"WARNING: {key} count {got} != expected {want}")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(
        json.dumps(bank, indent=1, ensure_ascii=False, sort_keys=False),
        encoding="utf-8",
    )
    print(f"Wrote {OUT_PATH}")
    print(json.dumps(counts, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
