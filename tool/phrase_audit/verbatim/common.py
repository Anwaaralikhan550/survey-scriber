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
LABEL = re.compile(r"^(?:[A-Za-z][A-Za-z0-9/()' -]{0,45}?)(?::|\s-)\s+(?=[A-Z])")
OPTION_LIST = re.compile(r'(?:[a-z][a-z /()-]+, ){2,}[a-z]')
DIRECTIVE = re.compile(r'add this|add text')  # only if still present after stripping
TWO_MENU = re.compile(r'(?:soon|now),? (?:repaired |replaced )?(?:soon|now)\b|\bsoon, now\b')
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


# Spec directives that precede real report prose; the prose after them still
# has to be in the bank, so the directive part is removed rather than the row.
DIR_PREFIX = re.compile(
    r"^(?:if [^:.]{3,100}? (?:is|are) selected\s*[,:]?\s*(?:add|insert)?[^:.]{0,30}?[:–-]\s*"
    r"|if [^:.]{3,100}? selected[,:]\s*"
    r"|if the property is a flat[,:]?\s*(?:add this|add the text below)?[:\s-]*"
    r"|add text to:?\s*section [a-z]\d\s*-\s*[^-]{3,40}-\s*)", re.I)
RATING_HEAD = re.compile(r'^condition rating \d\s+', re.I)


def strip_label(s):
    s = DIR_PREFIX.sub('', s)
    s = RATING_HEAD.sub('', s)
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
    return bool(DIRECTIVE.search(n) or OPTION_LIST.search(n)
                or LETTER_MENU.search(n) or TWO_MENU.search(n) or len(n) < 20)


def bank_sentence_index(bank):
    """norm(sentence) -> sorted list of bank keys that contain it."""
    idx = {}
    for k, v in bank.items():
        for seg in re.split(r'\\r\\n|<br\s*/?>', str(v)):
            for s in sentences(seg):
                idx.setdefault(norm(s, True), set()).add(k)
    return {n: sorted(ks) for n, ks in idx.items()}


# ---------------------------------------------------------------------------
# Section-scoped matching: a bank key is only compared with PDF sentences from
# the section(s) it belongs to, so a missing sentence is never "matched" to a
# similar sentence of a different element (which would wrongly look like FIX).
# ---------------------------------------------------------------------------
def master_of(key):
    return key.split('::')[0]


def key_sections(bank, pdf, min_words=8, cutoff=85):
    """master key -> set of PDF sections it belongs to (by sentence votes)."""
    from collections import Counter, defaultdict
    from rapidfuzz import fuzz, process
    pdf_rows = [(e['key'], norm(s)) for e in pdf['entries'] for s in sentences(e['rawBlock'])]
    pn = [n for _, n in pdf_rows]
    votes = defaultdict(Counter)
    for k, v in bank.items():
        for seg in re.split(r'\r\n|<br\s*/?>', str(v)):
            for s in sentences(seg):
                n = norm(s, True)
                if len(n.split()) < min_words:
                    continue
                r = process.extractOne(n, pn, scorer=fuzz.ratio)
                if r and r[1] >= cutoff:
                    votes[master_of(k)][pdf_rows[r[2]][0]] += 1
    out = {}
    for m, c in votes.items():
        best = c.most_common(1)[0][1]
        out[m] = {s for s, n in c.items() if n >= max(1, best * 0.5)}
    return out


class ScopedMatcher:
    def __init__(self, bank, pdf):
        from rapidfuzz import fuzz, process
        self.fuzz, self.process = fuzz, process
        self.idx = bank_sentence_index(bank)
        self.ks = key_sections(bank, pdf)
        self.by_section = {}
        for n, keys in self.idx.items():
            for k in keys:
                for sec in self.ks.get(master_of(k), ()):
                    self.by_section.setdefault(sec, {}).setdefault(n, []).append(k)

    def best(self, n, section):
        """(score, bank_norm, key) of the closest bank sentence belonging to
        `section`; (0, '', '') if the section has no bank text."""
        cand = self.by_section.get(section)
        if not cand:
            return 0, '', ''
        r = self.process.extractOne(n, list(cand), scorer=self.fuzz.ratio)
        return round(r[1]), r[0], cand[r[0]][0]


def cnorm(s, bank=False):
    """Case-preserving normalisation (labels, pointers and tokens handled like
    norm()) used for the case-/punctuation-sensitive exactness check."""
    s = strip_label(clean(s))
    if bank:
        s = XREF.sub('', s)
    s = re.sub(r'\{[A-Za-z0-9_]+\}', '♦', s)
    return re.sub(r'\s+', ' ', s).strip()


def bank_case_index(bank):
    """norm(sentence) -> set of case-preserving normalised bank sentences."""
    idx = {}
    for k, v in bank.items():
        for seg in re.split(r'\r\n|<br\s*/?>', str(v)):
            for s in sentences(seg):
                idx.setdefault(norm(s, True), set()).add(cnorm(s, True))
    return idx
