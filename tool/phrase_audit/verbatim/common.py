# -*- coding: utf-8 -*-
"""Shared helpers for the verbatim (PDF -> bank) tooling.

Paths are repo-relative; run every script from the repository root.
"""
import json
import re
import sys

BANK_PATH = 'assets/property_inspection/phrase_texts.json'
PDF_PATH = 'tool/phrase_audit/reference/rics_l2_library_v2.json'

XREF = re.compile(r'\s*\((?:see )?section [a-z]\d[^)]*\)', re.I)
# "Conflict noted:", "Remote area -", "Condition rating 1" style spec labels.
LABEL = re.compile(r"^(?:[A-Za-z][A-Za-z0-9/()' -]{0,45}?)(?::| - | – )\s+(?=[A-Z])")
OPTION_LIST = re.compile(r'(?:[a-z][a-z /()-]+, ){2,}[a-z]')
DIRECTIVE = re.compile(r'is selected|add this|add text|^if the property|if .* selected')
LETTER_MENU = re.compile(r'\b[a-g], [a-g],')


def load_bank():
    return json.load(open(BANK_PATH, encoding='utf-8'))


def load_pdf():
    return json.load(open(PDF_PATH, encoding='utf-8'))


def utf8_stdout():
    sys.stdout.reconfigure(encoding='utf-8')


def clean(t):
    t = str(t).replace('\\r\\n', ' ').replace('\r', ' ').replace('\n', ' ')
    t = re.sub(r'<br\s*/?>', ' ', t, flags=re.I)
    t = re.sub(r'<[^>]+>', ' ', t)
    t = (t.replace(' ', ' ').replace('‘', "'").replace('’', "'")
          .replace('“', '"').replace('”', '"').replace('–', '-')
          .replace('—', '-'))
    t = re.sub(r'(\w)- (\w)', r'\1-\2', t)  # PDF line-break hyphenation
    return re.sub(r'\s+', ' ', t).strip()


def strip_label(s):
    for _ in range(2):
        m = LABEL.match(s)
        if m and len(s) - m.end() > 20:
            s = s[m.end():]
        else:
            break
    return s


def norm(s, bank=False):
    """Normalise for comparison: labels stripped, case folded, tokens -> U+2666.
    For bank text, `(see section ...)` pointers are ignored (decision D1)."""
    s = strip_label(clean(s)).lower()
    if bank:
        s = XREF.sub('', s)
    s = re.sub(r'\{[a-z0-9_]+\}', '♦', s)
    return re.sub(r'\s+', ' ', s).strip()


def sentences(t, min_len=25):
    return [p.strip() for p in re.split(r'(?<=[.!?])\s+', clean(t))
            if len(p.strip()) >= min_len]


def is_menu_or_directive(n):
    return bool(DIRECTIVE.search(n) or OPTION_LIST.search(n) or LETTER_MENU.search(n))


def bank_sentence_index(bank):
    """norm(sentence) -> sorted list of bank keys that contain it."""
    idx = {}
    for k, v in bank.items():
        for seg in re.split(r'\\r\\n|<br\s*/?>', str(v)):
            for s in sentences(seg):
                idx.setdefault(norm(s, True), set()).add(k)
    return {n: sorted(ks) for n, ks in idx.items()}
