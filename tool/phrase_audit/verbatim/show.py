# -*- coding: utf-8 -*-
"""Show a bank key next to its best-matching PDF window.

Usage: python tool/phrase_audit/verbatim/show.py SECTION[,SECTION] KEY [KEY...]
"""
import os
import sys

from rapidfuzz import fuzz

sys.path.insert(0, os.path.dirname(__file__))
from common import clean, load_bank, load_pdf, utf8_stdout  # noqa: E402

utf8_stdout()
bank, pdf = load_bank(), load_pdf()
secs = sys.argv[1].split(',')
for k in sys.argv[2:]:
    b = clean(bank[k])
    best = None
    for s in secs:
        src = clean([e for e in pdf['entries'] if e['key'] == s][0]['rawBlock'])
        al = fuzz.partial_ratio_alignment(b.lower(), src.lower())
        if best is None or al.score > best[1].score:
            best = (s, al, src)
    s, al, src = best
    a, z = max(0, al.dest_start - 60), min(len(src), al.dest_end + 60)
    print(f'### {k}\n  BANK: {b}\n  PDF[{s} {al.score:.0f}]: ...{src[a:z]}...\n')
