# -*- coding: utf-8 -*-
"""Review OPEN ledger rows: PDF sentence vs the closest bank sentence + word diff.

Usage: python tool/phrase_audit/verbatim/review.py SECTION[,SECTION...] [--all]
Prints a PROPOSAL per row (TOKENISED / FIX / ADD) for a human to confirm in
tool/phrase_audit/verbatim/ledger_decisions.csv (id,disposition,note).
"""
import csv
import difflib
import os
import sys

from rapidfuzz import fuzz, process

sys.path.insert(0, os.path.dirname(__file__))
from common import ScopedMatcher, clean, load_bank, load_pdf, norm, utf8_stdout  # noqa: E402

utf8_stdout()
secs = set(sys.argv[1].split(','))
show_all = '--all' in sys.argv
rows = list(csv.DictReader(open('tool/phrase_audit/verbatim/ledger.csv', encoding='utf-8')))
sm = ScopedMatcher(load_bank(), load_pdf())


def wdiff(a, b):
    aw, bw = a.split(), b.split()
    out = []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, aw, bw, autojunk=False).get_opcodes():
        if tag == 'equal':
            continue
        x, y = ' '.join(aw[i1:i2]), ' '.join(bw[j1:j2])
        out.append((('[-' + x + '-]') if x else '') + (('{+' + y + '+}') if y else ''))
    return out


def proposal(score, pdf_n, bank_n):
    if '♦' in bank_n and score >= 60:
        return 'TOKENISED?'
    if score >= 72:
        return 'FIX'
    return 'ADD'


n_shown = 0
for r in rows:
    if r['section'] not in secs or (r['status'] != 'OPEN' and not show_all):
        continue
    pdf_n = norm(r['pdf_sentence'])
    score, bank_n, key = sm.best(pdf_n, r['section'])
    prop = proposal(score, pdf_n, bank_n)
    if '--focus' in sys.argv and prop == 'ADD' and score < 66:
        hidden = globals().setdefault('_hidden', [0]); hidden[0] += 1
        continue
    n_shown += 1
    compact = '--compact' in sys.argv
    print(f"\n[{r['section']}] {r['id']} {prop} {score}%")
    print(f"  PDF : {clean(r['pdf_sentence'])[:260]}")
    if compact and prop == 'ADD':
        print(f"  ~bank {score}%: {bank_n[:110]}")
        continue
    print(f"  BANK: {bank_n[:260]}  <{key}>")
    print(f"  DIFF: {' '.join(wdiff(bank_n, pdf_n))[:260]}")
print(f'\nrows shown: {n_shown}')
