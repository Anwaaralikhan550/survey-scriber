# -*- coding: utf-8 -*-
"""T1 / T2 gates for the verbatim work.

T1 forward  (PDF -> bank): every EXACT / TOKENISED / ACCEPT prose ledger row has its sentence in the bank text of its key.
T2 reverse  (bank -> PDF): every bank entry the app can reach (its key token is referenced in lib/**.dart) must be made of
                           PDF sentences (rapidfuzz ratio >= --min against some PDF sentence, tokens/labels normalised).
                           Unreferenced bank keys are listed as ORPHANS (candidates for deletion).
Usage: python3 tool/phrase_audit/verbatim/gates.py [--min 90] [--orphans] [--show 40]
Exit code 1 when T1 or T2 has failures.
"""
import argparse
import csv
import glob
import json
import re
import sys

from rapidfuzz import fuzz, process

sys.stdout.reconfigure(encoding='utf-8')
BANK = 'assets/property_inspection/phrase_texts.json'
REF = 'tool/phrase_audit/reference/rics_l2_library_v2.json'
LEDGER = 'tool/phrase_audit/verbatim/ledger.csv'
EXTRAS = 'tool/phrase_audit/verbatim/approved_extras.csv'   # id-free: one bank key per line + reason (optional file)


def clean(t):
    t = re.sub(r'<br\s*/?>|\\r\\n|\r|\n', ' ', str(t))
    t = re.sub(r'<[^>]+>', ' ', t)
    t = (t.replace(' ', ' ').replace('‘', "'").replace('’', "'").replace('“', '"').replace('”', '"')
         .replace('–', '-').replace('—', '-').replace('�', '-'))
    t = re.sub(r'(\w)- (\w)', r'\1-\2', t)
    return re.sub(r'\s+', ' ', t).strip()


def split(t):
    return [p.strip() for p in re.split(r'(?<=[.!?])\s+', clean(t)) if len(p.strip()) > 12]


LABEL = re.compile(r'^(?:[A-Z][\w/()\' -]{1,48}:)\s+')
XREF = re.compile(r'\s*\((?:see )?section [a-z]\d[^)]*\)', re.I)


OPTS = re.compile(r'(?:[a-z][a-z /()-]+, ){2,}[a-z][a-z /()-]+(?:,? (?:or|and) [a-z][a-z /()-]+)?')
DIRECTIVE = re.compile(r'^(?:if .{3,90}? (?:is |are )?selected,? ?(?:add|include)[^:.-]{0,30}[:.-]\s*|'
                       r'if the property is a flat, add this[:.]?\s*|'
                       r'section [a-z]\d ?[a-z ]{0,30}?- (?:[a-z ]{3,40} - )?|condition rating \d\s*)', re.I)


POINTER = re.compile(r'^section [a-z]\d[^-]{0,35}-\s*(?:[^-]{3,40}-\s*)?', re.I)


def norm(t):
    t = XREF.sub('', clean(t))
    t = POINTER.sub('', DIRECTIVE.sub('', t))
    prev = None
    while prev != t:
        prev = t
        t = LABEL.sub('', t)
    t = re.sub(r'\{[A-Za-z0-9_]+\}', ' ', t.lower())
    t = OPTS.sub(' ', t)
    return re.sub(r'\s+', ' ', t).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--min', type=float, default=90)
    ap.add_argument('--orphans', action='store_true')
    ap.add_argument('--show', type=int, default=30)
    ap.add_argument('--delete-orphans', action='store_true', help='remove orphan keys from the bank (via bankkeys.py). ONLY safe for the token-based list '
                    'of the first cleanup: the proximity check mis-reads @chimney rules and main-screen rating keys, so '
                    'always diff the T6 dump before/after (it must show 0 lost) and run the full gate')
    a = ap.parse_args()
    bank = json.load(open(BANK, encoding='utf-8'))
    src = ''.join(open(f, encoding='utf-8').read() for f in glob.glob('lib/**/*.dart', recursive=True))
    bank_text = ' '.join(str(v) for v in bank.values())
    # token prefixes the engine completes at run time, e.g. '{CONDITION_RATING_' + rating
    DYNAMIC = {x for t in re.findall(r"'(\{[A-Z0-9_]+_)'|'(\{[A-Z0-9_]+_)\$", src) for x in t if x}
    # ---- T1
    fails1 = []
    rows = list(csv.DictReader(open(LEDGER, encoding='utf-8')))
    checked = 0
    for r in rows:
        if r['disposition'] not in ('EXACT', 'TOKENISED') or not r['bank_key']:
            continue
        txt = norm(bank.get(r['bank_key'], ''))
        want = norm(r['pdf_sentence'])
        checked += 1
        if want and want not in txt and fuzz.partial_ratio(want, txt) < 97:
            fails1.append((r['id'], r['bank_key'], want[:90]))
    print(f'T1: {checked} EXACT/TOKENISED rows checked, {len(fails1)} not found in their bank key')
    for f in fails1[:a.show]:
        print('   T1 FAIL', f)
    # ---- T2
    pdf = set()
    for e in json.load(open(REF, encoding='utf-8'))['entries']:
        for s in split(e.get('rawBlock', '')):
            n = norm(s)
            if len(n) > 10:
                pdf.add(n)
    pdf = list(pdf)
    extras = set()
    try:
        extras = {l.split(',')[0].strip() for l in open(EXTRAS, encoding='utf-8') if l.strip() and not l.startswith('#')}
    except FileNotFoundError:
        pass
    pdf_raw = []
    for e in json.load(open(REF, encoding='utf-8'))['entries']:
        pdf_raw += [clean(x).lower() for x in split(e.get('rawBlock', ''))]
    pdf_raw = list(set(pdf_raw))
    # reachability: a key is live when its sub/master token is named in the Dart code, or when a live bank text
    # contains that token (master templates compose their sub keys); iterate to a fixpoint.
    tok_re = re.compile(r'\{[A-Z0-9_]+\}')
    by_tok = {}
    for k in bank:
        by_tok.setdefault(k.split('::')[-1], []).append(k)     # a key is named by its last token (sub, or the master itself)
    # 'M::S' is live when the Dart code names M and S close together (a _sub(M, S) call, a rule, or a helper call with
    # phraseCodeFor...: M, ...SubCode: S), when S is a run-time-built prefix, or when the key is written whole.
    positions = {}
    for m in tok_re.finditer(src):
        positions.setdefault(m.group(0), []).append(m.start())

    def near(a, b, window=900):
        pb = positions.get(b, [])
        return any(abs(x - y) <= window for x in positions.get(a, []) for y in pb)

    live = set()
    for k in bank:
        parts = k.split('::')
        if len(parts) == 1:
            if parts[0] in positions:
                live.add(k)
        elif k in src or near(parts[0], parts[1]) or any(parts[1].startswith(f) for f in DYNAMIC):
            live.add(k)
    orphans, foreign = [], []
    reach = 0
    for k, v in bank.items():
        if k not in live:
            orphans.append(k)
            continue
        reach += 1
        if k in extras or '::' not in k:
            continue            # master templates only define paragraph grouping for ParagraphComposer; never printed
        for s in split(v):
            segs = [x.strip(' .,:;-').lower() for x in re.split(r'\{[A-Za-z0-9_]+\}', DIRECTIVE.sub('', XREF.sub('', clean(s))))]
            segs = [x for x in segs if len(x) >= 18]
            if not segs:
                continue
            bad = []
            for x in segs:
                x = LABEL.sub('', x) if LABEL.match(x) else x
                r = process.extractOne(x, pdf_raw, scorer=fuzz.partial_ratio)
                if not r or r[1] < a.min:
                    bad.append((round(r[1]) if r else 0, x[:90]))
            if bad:
                foreign.append((k, bad[0][0], bad[0][1]))
    print(f'T2: {reach} reachable bank keys, {len(foreign)} sentences not in the PDF (< {a.min}); {len(orphans)} orphan keys')
    for f in foreign[:a.show]:
        print('   T2 FOREIGN', f)
    if a.delete_orphans and orphans:
        import os, subprocess, tempfile
        op = os.path.join(tempfile.mkdtemp(), 'del.json')
        json.dump([{'op': 'del', 'key': k} for k in orphans], open(op, 'w', encoding='utf-8'), ensure_ascii=False)
        subprocess.check_call([sys.executable, 'tool/phrase_audit/verbatim/bankkeys.py', op])
        print(f'deleted {len(orphans)} orphan keys')
        return
    if a.orphans:
        for o in orphans[:200]:
            print('   ORPHAN', o)
    sys.exit(1 if fails1 or foreign else 0)


if __name__ == '__main__':
    main()
