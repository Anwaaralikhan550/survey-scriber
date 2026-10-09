# -*- coding: utf-8 -*-
"""Record hand decisions for ledger rows in ledger_decisions.csv.

  python tool/phrase_audit/verbatim/decide.py --sections E1,E2     # record the
        reviewed proposals (TOKENISED?/FIX/ADD) for OPEN rows in those sections
  python tool/phrase_audit/verbatim/decide.py --set ID DISP "note" # override one row
  python tool/phrase_audit/verbatim/decide.py --done ID [ID...]    # mark FIX/ADD rows DONE-by-fix
Dispositions: FIX ADD TOKENISED HEADING ACCEPT QUERY FIXED ADDED
(FIXED/ADDED = the FIX/ADD work has been applied and verified; counts as done.)
"""
import csv
import os
import sys

from rapidfuzz import fuzz, process

sys.path.insert(0, os.path.dirname(__file__))
from common import ScopedMatcher, load_bank, load_pdf, norm  # noqa: E402

DECISIONS = 'tool/phrase_audit/verbatim/ledger_decisions.csv'
LEDGER = 'tool/phrase_audit/verbatim/ledger.csv'
VALID = {'FIX', 'ADD', 'TOKENISED', 'HEADING', 'ACCEPT', 'QUERY', 'FIXED', 'ADDED'}


def load():
    d = {}
    if os.path.exists(DECISIONS):
        for r in csv.DictReader(open(DECISIONS, encoding='utf-8')):
            d[r['id']] = r
    return d


def save(d):
    with open(DECISIONS, 'w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow(['id', 'disposition', 'note'])
        for r in sorted(d.values(), key=lambda x: x['id']):
            w.writerow([r['id'], r['disposition'], r['note']])


def proposal(score, bank_n):
    if '♦' in bank_n and score >= 60:
        return 'TOKENISED'
    return 'FIX' if score >= 72 else 'ADD'


def main():
    d = load()
    a = sys.argv[1:]
    if a and a[0] == '--set':
        rid, disp, note = a[1], a[2], (a[3] if len(a) > 3 else '')
        assert disp in VALID, disp
        d[rid] = {'id': rid, 'disposition': disp, 'note': note}
    elif a and a[0] == '--done':
        for rid in a[1:]:
            old = d.get(rid, {}).get('disposition', '')
            d[rid] = {'id': rid, 'disposition': 'FIXED' if old != 'ADD' else 'ADDED',
                      'note': 'applied+verified'}
    elif a and a[0] == '--sections':
        secs = set(a[1].split(','))
        rows = list(csv.DictReader(open(LEDGER, encoding='utf-8')))
        sm = ScopedMatcher(load_bank(), load_pdf())
        n = 0
        for r in rows:
            if r['section'] in secs and r['status'] == 'OPEN' and r['id'] not in d:
                score, bank_n, _ = sm.best(norm(r['pdf_sentence']), r['section'])
                disp = proposal(score, bank_n)
                d[r['id']] = {'id': r['id'], 'disposition': disp,
                              'note': f'proposal {score}% reviewed'}
                n += 1
        print(f'recorded {n} proposals')
    else:
        sys.exit(__doc__)
    save(d)


if __name__ == '__main__':
    main()
