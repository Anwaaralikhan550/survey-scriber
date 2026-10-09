# -*- coding: utf-8 -*-
"""Build the PDF -> bank ledger and print the verbatim scoreboard.

Usage (from repo root):
  python tool/phrase_audit/verbatim/ledger.py            # write ledger.csv + summary
  python tool/phrase_audit/verbatim/ledger.py --check    # exit 1 if any row is OPEN

Dispositions (auto-proposed here, confirmed by hand in ledger_decisions.csv):
  EXACT       PDF sentence found word-for-word in the bank       -> DONE
  MENU        option list / directive / letter menu (not prose)  -> DONE (mechanical)
  NEAR        >=95% match, needs a hand decision                 -> OPEN
  UNRESOLVED  <95% (differs, tokenised or missing)               -> OPEN
Hand decisions (FIX / ADD / TOKENISED / HEADING / QUERY / ACCEPT) are read from
tool/phrase_audit/verbatim/ledger_decisions.csv (id,disposition,note) and win
over the auto proposal.
"""
import csv
import hashlib
import os
import re
import sys

from rapidfuzz import fuzz, process

sys.path.insert(0, os.path.dirname(__file__))
from common import (ScopedMatcher, bank_case_index, bank_sentence_index,  # noqa: E402
                    cnorm, is_menu_or_directive, load_bank, load_pdf, norm,
                    sentences, utf8_stdout)

LEDGER = 'tool/phrase_audit/verbatim/ledger.csv'
DECISIONS = 'tool/phrase_audit/verbatim/ledger_decisions.csv'
DONE_BY_HAND = {'ACCEPT', 'HEADING', 'TOKENISED', 'FIXED', 'ADDED'}  # reviewed / applied


def row_id(section, sentence):
    return hashlib.sha1(f'{section}|{sentence}'.encode('utf-8')).hexdigest()[:10]


def load_decisions():
    out = {}
    if os.path.exists(DECISIONS):
        for r in csv.DictReader(open(DECISIONS, encoding='utf-8')):
            out[r['id']] = r
    return out


SPEC = 'lib/features/property_inspection/domain/inspection_verbatim_spec.dart'
BS = chr(92)  # backslash, avoids escaping trouble in the patterns below
_LIT = re.compile(r"pdf:\s*((?:'(?:[^'" + BS + BS + r"]|" + BS + BS + r".)*'\s*)+),")
_MORE = re.compile(r'pdfMore:\s*\[(.*?)\]\s*,', re.S)
_ONE = re.compile(r"'((?:[^'" + BS + BS + r"]|" + BS + BS + r".)*)'")


def spec_pdf_sentences():
    """PDF option-list sentences declared by verbatim rules (Dart source)."""
    if not os.path.exists(SPEC):
        return set()
    src = open(SPEC, encoding='utf-8').read()
    out = set()
    for m in _LIT.finditer(src):
        text = ''.join(x.replace(BS + "'", "'") for x in _ONE.findall(m.group(1)))
        out.add(norm(text))
    for m in _MORE.finditer(src):
        for lit in _ONE.findall(m.group(1)):
            out.add(norm(lit.replace(BS + "'", "'")))
    return out


def build():
    bank = load_bank()
    pdf = load_pdf()
    idx = bank_sentence_index(bank)
    sm = ScopedMatcher(bank, pdf)
    cidx = bank_case_index(bank)
    decisions = load_decisions()
    ruled = spec_pdf_sentences()
    seen_pdf = set()
    rows = []
    for e in pdf['entries']:
        for s in sentences(e['rawBlock']):
            n = norm(s)
            rid = row_id(e['key'], s)
            key, score = '', 0
            if n in ruled or is_menu_or_directive(n):
                # option list / directive: its options must be implemented in the
                # form exactly as the PDF lists them (plan T3). Not verified yet.
                disp, status = 'MENU', 'UNVERIFIED'
                if n in ruled:
                    status = 'VERIFIED'  # implemented by a rule + generated T3/T5 tests
                    seen_pdf.add(n)
            elif n in idx and any(c[1:] == cnorm(s)[1:] for c in cidx[n]):
                # exact incl. capitals and punctuation (first letter may differ)
                disp, status, key, score = 'EXACT', 'DONE', idx[n][0], 100
            elif n in idx:
                disp, status, key, score = 'UNRESOLVED', 'OPEN', idx[n][0], 99  # case/punctuation only
            else:
                score, _, key = sm.best(n, e['key'])
                disp = 'NEAR' if score >= 95 else 'UNRESOLVED'
                status = 'OPEN'
            # J-layer injection rows are verified by a hand test (report_builder_test).
            if disp == 'MENU' and rid in decisions and decisions[rid]['disposition'] == 'TESTED':
                status = 'VERIFIED'
            # A hand decision applies only while the row is not already exact.
            if rid in decisions and disp not in ('EXACT', 'MENU'):
                d = decisions[rid]
                disp = d['disposition']
                status = 'DONE' if disp in DONE_BY_HAND else 'OPEN'
            rows.append([rid, e['key'], s, disp, key, score, status])
    missing = ruled - seen_pdf
    if missing:
        print('WARNING: rule pdf text not found as an option-list row in the PDF:')
        for m in sorted(missing):
            print('   ', m[:120])
    return rows


def main():
    utf8_stdout()
    rows = build()
    with open(LEDGER, 'w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow(['id', 'section', 'pdf_sentence', 'disposition',
                    'bank_key', 'score', 'status'])
        w.writerows(rows)
    prose = [r for r in rows if r[3] != 'MENU']  # option lists are tracked separately
    by = {}
    for r in prose:
        by[r[3]] = by.get(r[3], 0) + 1
    open_rows = [r for r in rows if r[6] == 'OPEN']
    unverified = [r for r in rows if r[6] == 'UNVERIFIED']
    verified = [r for r in rows if r[6] == 'VERIFIED']
    print(f'ledger rows: {len(rows)}  (prose {len(prose)}, menu/directive {len(rows)-len(prose)})')
    for k in sorted(by):
        print(f'  {k:11} {by[k]:5}  {by[k]*100/len(prose):5.1f}%')
    print(f'OPEN prose rows: {len(open_rows)}   |   UNVERIFIED option-list rows (T3): {len(unverified)}  (VERIFIED by rules: {len(verified)})')
    secs = {}
    for r in open_rows:
        secs[r[1]] = secs.get(r[1], 0) + 1
    print('OPEN by section:', dict(sorted(secs.items())))
    if '--check' in sys.argv and (open_rows or unverified):
        sys.exit(1)


if __name__ == '__main__':
    main()
