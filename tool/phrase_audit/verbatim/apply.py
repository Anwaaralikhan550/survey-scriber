# -*- coding: utf-8 -*-
"""Count-asserted replacements in phrase_texts.json.

Usage: python tool/phrase_audit/verbatim/apply.py edits.json
edits.json items are either
  [old, new, expected_count]      global raw replacement, or
  {"key": K, "old": o, "new": n}  replacement inside key K only
                                  (must occur exactly once there)
Aborts without writing if any assertion fails or the result is not valid JSON.
"""
import json
import sys

P = 'assets/property_inspection/phrase_texts.json'
BACKSLASH = chr(92)
edits = json.load(open(sys.argv[1], encoding='utf-8'))
raw = open(P, encoding='utf-8', newline='').read()


def key_span(text, key):
    start = text.find('"' + key + '": "')
    if start < 0:
        sys.exit(f'ABORT key not found: {key}')
    i = start + len(key) + 5
    j = i
    while True:
        if text[j] == BACKSLASH:
            j += 2
            continue
        if text[j] == '"':
            return i, j
        j += 1


for e in edits:
    if isinstance(e, dict):
        i, j = key_span(raw, e['key'])
        c = raw[i:j].count(e['old'])
        if c != 1:
            sys.exit(f"ABORT count {c}!=1 in {e['key']}: {e['old'][:80]}")
        raw = raw[:i] + raw[i:j].replace(e['old'], e['new']) + raw[j:]
    else:
        old, new, n = e
        c = raw.count(old)
        if c != n:
            sys.exit(f'ABORT count mismatch ({c}!={n}) for: {old[:90]}')
        raw = raw.replace(old, new)
json.loads(raw)
open(P, 'w', encoding='utf-8', newline='').write(raw)
print(f'applied {len(edits)} edits OK; JSON valid')
