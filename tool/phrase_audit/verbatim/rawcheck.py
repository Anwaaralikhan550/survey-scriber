# -*- coding: utf-8 -*-
"""Raw-PDF coverage check (independent of the digitised JSON used by ledger.py / gates.py).

Every sentence of the client's PDF (text taken with `pdftotext -layout`) must have a counterpart in the bank:
the best bank sentence, compared after normalisation (labels, "if selected" directives, section pointers, {TOKENS}
and comma option-lists removed on both sides), must reach --min percent similarity.

Usage: python3 tool/phrase_audit/verbatim/rawcheck.py [--pdf PATH] [--min 95] [--show 80]
Exit code 1 when sentences remain below the threshold.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

from rapidfuzz import fuzz, process

sys.path.insert(0, os.path.dirname(__file__))
import gates  # noqa: E402

sys.stdout.reconfigure(encoding='utf-8')
DEFAULT_PDF = r'C:\Users\DELL\Downloads\Surveyscriber Phrase Bank (1).pdf'
BANK = gates.BANK


def pdf_text(path):
    out = os.path.join(tempfile.mkdtemp(), 'pb.txt')
    subprocess.check_call(['pdftotext', '-layout', path, out])
    t = open(out, encoding='utf-8', errors='replace').read()
    t = t.replace('`', "'").replace('**', '').replace('•', ' ')
    t = re.sub(r'-\s*\n\s*(?=[a-z])', '-', t)
    return t


def sentences(t):
    t = re.sub(r'\s+', ' ', t)
    return [s.strip() for s in re.split(r'(?<=[.!?])\s+', t) if len(s.strip()) >= 20]


ACCEPTED = os.path.join(os.path.dirname(__file__), 'rawcheck_accepted.csv')


def accepted_fragments():
    out = []
    try:
        for line in open(ACCEPTED, encoding='utf-8'):
            if line.strip() and not line.startswith('#'):
                out.append(line.split('|')[0].strip().lower())
    except FileNotFoundError:
        pass
    return out


def contained(n, names):
    """A bank/report sentence sits inside the PDF sentence (the PDF row has a heading glued in front of it)."""
    r = process.extractOne(n, names, scorer=fuzz.partial_ratio)
    return bool(r and r[1] >= 97 and len(r[0]) >= 20)


_ACC = accepted_fragments()


def accepted(n, raw=''):
    r = gates.clean(raw).lower()
    return any(f in n or f in r for f in _ACC)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pdf', default=DEFAULT_PDF)
    ap.add_argument('--min', type=float, default=95)
    ap.add_argument('--show', type=int, default=80)
    ap.add_argument('--master', default='', help='master report json (sample_reports/master_report): also check every PDF sentence is RENDERED in it')
    a = ap.parse_args()
    bank = json.load(open(BANK, encoding='utf-8'))
    bank_n = {}
    for k, v in bank.items():
        for s in gates.split(v):
            n = gates.norm(s)
            if len(n) >= 12:
                bank_n.setdefault(n, k)
    names = list(bank_n)
    pdf_s = []
    seen = set()
    for s in sentences(pdf_text(a.pdf)):
        n = gates.norm(s)
        if len(n) >= 12 and n not in seen:
            seen.add(n)
            pdf_s.append((n, s))
    miss = []
    exact = 0
    for n, raw in pdf_s:
        if n in bank_n:
            exact += 1
            continue
        r = process.extractOne(n, names, scorer=fuzz.ratio)
        if r and r[1] >= a.min:
            continue
        if accepted(n, raw) or contained(n, names):
            continue
        miss.append((round(r[1]) if r else 0, raw, bank_n[r[0]] if r else ''))
    rend_miss = []
    if a.master:
        d = json.load(open(a.master, encoding='utf-8'))
        rep = {}
        for b in d['report']:
            for p in b['phrases']:
                for sent in gates.split(p):
                    n = gates.norm(sent)
                    if len(n) >= 12:
                        rep.setdefault(n, 1)
        rnames = list(rep)
        for n, raw in pdf_s:
            if n in rep:
                continue
            r = process.extractOne(n, rnames, scorer=fuzz.ratio)
            if (not r or r[1] < a.min) and not accepted(n, raw) and not contained(n, rnames):
                rend_miss.append((round(r[1]) if r else 0, raw))
        rend_miss.sort()
        print(f'RENDERED in master report: {len(pdf_s) - len(rend_miss)} of {len(pdf_s)} PDF sentences; {len(rend_miss)} not rendered')
        for sc, raw in rend_miss[:a.show]:
            print(f'  {sc:3d} | {raw[:170]}')
    print(f'RAW PDF: {len(pdf_s)} distinct sentences; {exact} exact after normalisation, '
          f'{len(pdf_s) - exact - len(miss)} within {a.min}%, {len(miss)} below')
    miss.sort()
    for sc, raw, k in miss[:a.show]:
        print(f'  {sc:3d} | {raw[:150]}\n        best bank key: {k}')
    sys.exit(1 if miss or rend_miss else 0)


if __name__ == '__main__':
    main()
