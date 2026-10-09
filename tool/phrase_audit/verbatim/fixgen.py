# -*- coding: utf-8 -*-
"""Generate key-scoped edits that replace a bank sentence with the PDF's.

Usage: python tool/phrase_audit/verbatim/fixgen.py OUT.json ID [ID...]
For each reviewed FIX ledger row id, the closest in-section bank sentence
(original case, label removed) is replaced by the PDF sentence (original case,
label removed) inside each in-section key that holds it. "(See Section X -
...)" pointers are kept (decision D1). A row is reported MANUAL when the bank
sentence contains a {TOKEN}, has no in-section key, or is not found exactly
once in the key's raw text. Review OUT.json, then run apply.py on it.
"""
import csv
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from common import (XREF, ScopedMatcher, clean, load_bank, load_pdf,  # noqa: E402
                    master_of, norm, sentences, strip_label, utf8_stdout)

utf8_stdout()
out_path, ids = sys.argv[1], sys.argv[2:]
bank, pdf = load_bank(), load_pdf()
sm = ScopedMatcher(bank, pdf)
rows = {r['id']: r for r in csv.DictReader(
    open('tool/phrase_audit/verbatim/ledger.csv', encoding='utf-8'))}

# norm(sentence) -> {original-case label-stripped sentence: [keys]}
orig = {}
for k, v in bank.items():
    for seg in re.split(r'\\r\\n|<br\s*/?>', str(v)):
        for s in sentences(seg):
            orig.setdefault(norm(s, True), {}).setdefault(
                strip_label(clean(s)), []).append(k)

edits, manual = [], []
for rid in ids:
    r = rows.get(rid)
    if not r:
        manual.append((rid, 'unknown id'))
        continue
    pdf_s = strip_label(clean(r['pdf_sentence']))
    score, bn, key = sm.best(norm(r['pdf_sentence']), r['section'])
    cands = orig.get(bn, {})
    if not cands:
        manual.append((rid, 'no bank sentence'))
        continue
    old, keys = next(iter(cands.items()))
    if '{' in old:
        manual.append((rid, f'token in bank sentence: {old[:80]}'))
        continue
    sec_keys = [k for k in keys if r['section'] in sm.ks.get(master_of(k), ())]
    if not sec_keys:
        manual.append((rid, f'no in-section key {keys[:3]}'))
        continue
    ptr = XREF.search(old)
    new = pdf_s
    if ptr:  # keep the pointer exactly where it was (before the final stop)
        new = re.sub(r'([.!?])$', lambda m: ptr.group(0) + m.group(1), pdf_s)
    for k in sec_keys:
        n = str(bank[k]).count(old)
        if n != 1:
            manual.append((rid, f'{old[:60]!r} occurs {n}x in {k}'))
            continue
        edits.append({'key': k, 'old': old, 'new': new})
        print(f'AUTO {rid} [{r["section"]}] {k}\n   OLD: {old}\n   NEW: {new}')

json.dump(edits, open(out_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(f'\n{len(edits)} key-scoped edits -> {out_path}; {len(manual)} manual:')
for rid, why in manual:
    print(f'  MANUAL {rid}: {why}')
