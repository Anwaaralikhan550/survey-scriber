# -*- coding: utf-8 -*-
"""Count-asserted raw replacements in phrase_texts.json.

Usage: python tool/phrase_audit/verbatim/apply.py edits.json
edits.json = [[old, new, expected_count], ...]
Aborts without writing if any count differs or the result is not valid JSON.
"""
import json
import sys

P = 'assets/property_inspection/phrase_texts.json'
edits = json.load(open(sys.argv[1], encoding='utf-8'))
raw = open(P, encoding='utf-8', newline='').read()
for old, new, n in edits:
    c = raw.count(old)
    if c != n:
        sys.exit(f'ABORT count mismatch ({c}!={n}) for: {old[:90]}')
for old, new, n in edits:
    raw = raw.replace(old, new)
json.loads(raw)
open(P, 'w', encoding='utf-8', newline='').write(raw)
print(f'applied {len(edits)} edits OK; JSON valid')
