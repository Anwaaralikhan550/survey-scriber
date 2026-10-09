# -*- coding: utf-8 -*-
"""Show one PDF section next to every bank key that belongs to it.

Usage: python tool/phrase_audit/verbatim/section.py E5 [--open]
  --open  list only the bank keys that contain an OPEN ledger row's closest match
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from common import (ScopedMatcher, clean, load_bank, load_pdf, master_of,  # noqa: E402
                    utf8_stdout)

utf8_stdout()
sec = sys.argv[1]
bank, pdf = load_bank(), load_pdf()
sm = ScopedMatcher(bank, pdf)
block = [e for e in pdf['entries'] if e['key'] == sec][0]['rawBlock']
print(f'===== PDF {sec} =====')
print(re.sub(r'\s+', ' ', clean(block)))
print(f'\n===== BANK keys belonging to {sec} =====')
for k in sorted(bank):
    if sec in sm.ks.get(master_of(k), ()):
        v = re.sub(r'\s+', ' ', re.sub(r'<br\s*/?>|\\r\\n|</?p>|</?strong>|</?span[^>]*>', ' ', bank[k]))
        print(f'\n## {k}\n   {v.strip()}')
