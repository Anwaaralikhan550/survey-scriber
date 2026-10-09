# -*- coding: utf-8 -*-
"""T9 helper: find OLD wording of applied edits left in other text stores.

Usage: python tool/phrase_audit/verbatim/oldcheck.py edits.json [edits2.json ...]
Searches verified_variants.json, lib/**/*.dart, test/**/*.dart and the phrase
portal for every edit's `old` sentence (case-insensitive, whitespace-folded).
Any hit must be updated (or justified) before the batch is gated/committed.
"""
import glob
import json
import re
import sys

STORES = (['tool/phrase_audit/reference/verified_variants.json']
          + glob.glob('lib/**/*.dart', recursive=True)
          + glob.glob('test/**/*.dart', recursive=True)
          + glob.glob('tool/phrase_portal/**/*.*', recursive=True))


def fold(t):
    return re.sub(r'\s+', ' ', t).lower()


texts = {p: fold(open(p, encoding='utf-8', errors='ignore').read()) for p in STORES}
hits = 0
for f in sys.argv[1:]:
    for e in json.load(open(f, encoding='utf-8')):
        old = e['old'] if isinstance(e, dict) else e[0]
        o = fold(old)
        for p, t in texts.items():
            if o in t:
                hits += 1
                print(f'HIT {p}\n   {old[:110]}')
print(f'old-wording hits: {hits}')
