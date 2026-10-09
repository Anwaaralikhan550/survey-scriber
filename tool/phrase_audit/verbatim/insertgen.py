# -*- coding: utf-8 -*-
"""Propose bank-only inserts for missing PDF sentences.

Idea: PDF order == paragraph order. If a missing sentence S directly follows a
PDF sentence P that is already EXACT in bank key K (and S carries no heading of
its own), S belongs right after P inside K. Prints candidates for review and
writes a key-scoped edit file (apply.py format) for the ids you pass with --ids.

  python tool/phrase_audit/verbatim/insertgen.py SECTION[,SECTION]            # list
  python tool/phrase_audit/verbatim/insertgen.py SECTION --ids ID ID --out f.json
"""
import csv
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from common import (LABEL, cnorm, clean, load_bank, norm, sentences,  # noqa: E402
                    strip_label, utf8_stdout)

utf8_stdout()
args = sys.argv[1:]
secs = set(args[0].split(','))
ids = []
out = None
if '--ids' in args:
    i = args.index('--ids') + 1
    while i < len(args) and not args[i].startswith('--'):
        ids.append(args[i])
        i += 1
if '--out' in args:
    out = args[args.index('--out') + 1]

rows = list(csv.DictReader(open('tool/phrase_audit/verbatim/ledger.csv', encoding='utf-8')))
bank = load_bank()
by_sec = {}
for r in rows:
    by_sec.setdefault(r['section'], []).append(r)

# original-case, label-stripped bank sentences per key, in order
orig = {}
for k, v in bank.items():
    for seg in re.split(r'\\r\\n|<br\s*/?>', str(v)):
        for s in sentences(seg):
            orig.setdefault(k, []).append(strip_label(clean(s)))

edits, shown = [], 0
for sec in sorted(secs):
    seq = by_sec.get(sec, [])
    for i, r in enumerate(seq):
        if r['status'] != 'OPEN' or i == 0:
            continue
        if ids and r['id'] not in ids:
            continue
        prev = seq[i - 1]
        raw_s = clean(r['pdf_sentence'])
        has_own_heading = bool(LABEL.match(raw_s)) or raw_s.lower().startswith('add text to')
        if prev['disposition'] != 'EXACT' or not prev['bank_key']:
            continue
        k = prev['bank_key']
        anchor = None
        for cand in orig.get(k, []):
            if norm(cand, True) == norm(prev['pdf_sentence']):
                anchor = cand
                break
        if anchor is None or str(bank[k]).count(anchor) != 1:
            continue
        new_s = strip_label(raw_s)
        shown += 1
        flag = ' [HEADING]' if has_own_heading else ''
        print(f"{r['id']} [{sec}] after {{{k}}}{flag}\n   ANCHOR: {anchor[:150]}\n   INSERT: {new_s[:200]}")
        if ids:
            edits.append({'key': k, 'old': anchor, 'new': anchor + ' ' + new_s})
print(f'\ncandidates: {shown}')
if ids and out:
    import json
    json.dump(edits, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'{len(edits)} edits -> {out}')
