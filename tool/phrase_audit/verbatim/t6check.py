# -*- coding: utf-8 -*-
"""T6 (part 2): every sentence the real pipeline emitted must be a PDF sentence.

Input : tool/phrase_audit/output/t6_report_phrases.json (written by test/phrase_audit/verbatim/t6_report_dump_test.dart)
Output: foreign sentences (not in the PDF) grouped by section/screen. A sentence passes when it matches a PDF sentence
        with similarity >= --min (default 92), after normalising heading labels, pointers, tokens and option lists.
Usage : python tool/phrase_audit/verbatim/t6check.py [--min 92] [--section E1] [--limit 40]
"""
import argparse
import json
import re
import sys
from collections import defaultdict

from rapidfuzz import fuzz, process

sys.stdout.reconfigure(encoding='utf-8')
REF = 'tool/phrase_audit/reference/rics_l2_library_v2.json'
DUMP = 'tool/phrase_audit/output/t6_report_phrases.json'

XREF = re.compile(r'\s*\((?:see )?section [a-z]\d[^)]*\)', re.I)
LABEL = re.compile(r'^(?:[A-Z][\w/()\' -]{1,48}:)\s+')
OPTS = re.compile(r'(?:[a-z][a-z /()-]+, ){2,}[a-z][a-z /()-]+(?:,? (?:or|and) [a-z][a-z /()-]+)?')


def clean(t):
    t = re.sub(r'<br\s*/?>|\\r\\n|\r|\n', ' ', str(t))
    t = re.sub(r'<[^>]+>', ' ', t)
    t = (t.replace(' ', ' ').replace('‘', "'").replace('’', "'").replace('“', '"')
         .replace('”', '"').replace('–', '-').replace('—', '-').replace('�', '-'))
    t = re.sub(r'(\w)- (\w)', r'\1-\2', t)
    return re.sub(r'\s+', ' ', t).strip()


def norm(t):
    t = XREF.sub('', clean(t))
    prev = None
    while prev != t:                 # strip stacked labels ("Condition: No defects noted: ...")
        prev = t
        t = LABEL.sub('', t)
    t = t.lower()
    t = re.sub(r'\{[a-z0-9_]+\}', ' ', t)
    t = OPTS.sub(' ', t)
    return re.sub(r'\s+', ' ', t).strip()


def sentences(t):
    return [p.strip() for p in re.split(r'(?<=[.!?])\s+', clean(t)) if len(p.strip()) > 12]


def legacy_screens():
    """Screen ids whose engine `case` still returns a legacy handler (not const [] / _conditionRatingNotes)."""
    src = open('lib/features/property_inspection/domain/inspection_phrase_engine.dart', encoding='utf-8').read()
    out, pending = set(), []
    for m in re.finditer(r"case '([a-z0-9_]+)':|return ([^;]+);", src):
        if m.group(1):
            pending.append(m.group(1))
        else:
            ret = m.group(2).strip()
            if pending and not (ret.startswith('const []') or ret.startswith('_conditionRatingNotes')):
                out.update(pending)
            pending = []
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--min', type=float, default=92)
    ap.add_argument('--section', default=None)
    ap.add_argument('--limit', type=int, default=40)
    ap.add_argument('--screens', action='store_true', help='use per-screen engine output instead of the assembled report')
    ap.add_argument('--dump', default=DUMP, help='phrase dump json (default: the T6 dump)')
    ap.add_argument('--legacy', action='store_true', help='only screens whose engine case still uses a legacy handler')
    a = ap.parse_args()
    pdf = []
    for e in json.load(open(REF, encoding='utf-8'))['entries']:
        for s in sentences(e.get('rawBlock', '')):
            n = norm(s)
            if len(n) > 10:
                pdf.append(n)
    pdf = list(set(pdf))
    raw = json.load(open(a.dump, encoding='utf-8'))
    dump = raw['screens'] if a.screens else raw['report']
    legacy = legacy_screens() if a.legacy else None
    foreign = defaultdict(list)
    total = ok = 0
    for blk in dump:
        if a.section and blk['section'] != a.section:
            continue
        if legacy is not None and blk['screen'] not in legacy:
            continue
        for ph in blk['phrases']:
            for s in sentences(ph):
                n = norm(s)
                if len(n) < 12:
                    continue
                total += 1
                r = process.extractOne(n, pdf, scorer=fuzz.ratio)
                if r and r[1] >= a.min:
                    ok += 1
                else:
                    foreign[(blk['section'], blk['screen'])].append((round(r[1]) if r else 0, s))
    print(f'T6: {total} emitted sentences, {ok} match the PDF (>= {a.min}), {total - ok} foreign')
    by = defaultdict(int)
    for (sec, scr), v in foreign.items():
        by[sec] += len(v)
    print('foreign by section:', dict(sorted(by.items())))
    shown = 0
    for (sec, scr), v in sorted(foreign.items()):
        for sc, s in v:
            if shown >= a.limit:
                break
            print(f'[{sec}] {scr} ({sc}): {s[:170]}')
            shown += 1


if __name__ == '__main__':
    main()
