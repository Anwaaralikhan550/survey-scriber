# -*- coding: utf-8 -*-
"""Whole-tree structural audit of assets/property_inspection/inspection_tree.json.

Looks for every instance of the defect classes the client reported on 1 Nov 2026
(and related ones), across ALL sections, not only where the client looked:

  L1  element landing does not follow the Roof Covering pattern [main, Repairs, Not inspected]
  L2  main screen (has a "Condition Rating" dropdown) not an inline header of the main group
  L3  Repairs / Not inspected placed in the wrong position on a landing
  L4  more than one "Condition Rating" screen inside one element (duplicate Condition)
  L5  sibling placement differs from the "order" attribute (the app sorts by placement)
  L6  duplicate sibling titles on one page
  D1  dropdown labelled "Condition" that holds repair timescales / sits under Repairs
  D2  dropdown with fewer than 2 options or duplicate options
  T1  title style: spacing, "Fire Places"/"Wood Work", lower-case start, inconsistent
      "Not inspected"/"Not Inspected", visible section code (E8/F5) below the root
  F1  conditionalOn points to a field that does not exist on the screen
  F2  "Other" checkbox with no linked "Other" text field on the screen
  F3  duplicate field id on a screen
  E1  empty group / screen with no answerable field

Writes tool/tree_audit/output/tree_audit.md and .json. Report tool: always exits 0.
Run from repo root:  python3 tool/tree_audit/audit_tree.py
"""
import collections
import json
import os
import re

TREE = 'assets/property_inspection/inspection_tree.json'
OUT = 'tool/tree_audit/output'
t = json.load(open(TREE, encoding='utf-8'))

nodes, sec, pos = [], {}, {}
for s in t['sections']:
    for i, n in enumerate(s['nodes']):
        nodes.append(n)
        sec[n['id']] = s['key']
        pos[n['id']] = i
by = {n['id']: n for n in nodes}
kids = collections.defaultdict(list)          # parent id -> children (placement order)
for n in nodes:
    if n.get('parentId'):
        kids[n['parentId']].append(n)
roots = collections.defaultdict(list)         # section key -> root nodes (placement order)
for n in nodes:
    if not n.get('parentId'):
        roots[sec[n['id']]].append(n)
for k in kids:
    kids[k].sort(key=lambda n: pos[n['id']])

ROOT_TITLES = {s['key']: s['title'] for s in t['sections']}
CODE = re.compile(r'^[A-Z]\d{1,2}\s')
TIMESCALE = re.compile(r'\b(soon|now)\b', re.I)


def strip_code(title):
    return CODE.sub('', title).strip()


def is_repairs(n):
    return n['title'].strip().lower().startswith('repair')


def is_not_inspected(n):
    return n['title'].strip().lower() == 'not inspected'


def has_condition_rating(n):
    return any(f['type'] == 'dropdown' and f['label'].strip().lower() == 'condition rating'
               for f in n.get('fields', []))


def descendants(gid):
    out, stack = [], [gid]
    while stack:
        for c in kids.get(stack.pop(), []):
            out.append(c)
            if c['type'] == 'group':
                stack.append(c['id'])
    return out


def ancestors(nid):
    out, n = [], by.get(by[nid].get('parentId') or '')
    while n:
        out.append(n)
        n = by.get(n.get('parentId') or '')
    return out


def path(nid):
    parts = [strip_code(by[nid]['title'])] + [strip_code(a['title']) for a in ancestors(nid)]
    return ' > '.join([ROOT_TITLES[sec[nid]]] + parts[::-1])


def condition_tokens(field):
    """(controller_field_id, expected_value_or_None) pairs, parsed the way
    inspection_fields.dart evaluates conditionalOn ("a", "a=x", "a&b", "a|!b")."""
    expr = (field.get('conditionalOn') or '').strip()
    if not expr:
        return []
    out = []
    for group in expr.split('|'):
        for tok in group.split('&'):
            tok = tok.strip().lstrip('!').strip()
            if not tok:
                continue
            if '=' in tok:
                k, v = tok.split('=', 1)
                out.append((k.strip(), v.strip().lower()))
            else:
                values = [v.strip().lower() for v in re.split(r'[|,]', field.get('conditionalValue') or '')
                          if v.strip()]
                if values:
                    out += [(tok, v) for v in values]
                else:
                    out.append((tok, None))
    return out


findings = []


def add(code, nid, msg):
    findings.append({'code': code, 'section': sec[nid], 'id': nid, 'path': path(nid), 'msg': msg})


# ---- element landings: groups that carry a Repairs child ---------------------------
landings = [g for g in nodes if g['type'] == 'group' and not is_repairs(g)
            and any(is_repairs(c) for c in kids[g['id']])]
for g in landings:
    ch = kids[g['id']]
    titles = [c['title'] for c in ch]
    first = ch[0]
    if first['type'] != 'group' or is_repairs(first) or is_not_inspected(first):
        add('L1', g['id'], f'landing starts with "{first["title"]}" ({first["type"]}), '
                           f'expected the main group first. Landing = {titles}')
    extra = [c['title'] for c in ch[1:] if not is_repairs(c) and not is_not_inspected(c)]
    if extra:
        add('L1', g['id'], f'extra items besides [main, Repairs, Not inspected]: {extra}. Landing = {titles}')
    reps = [i for i, c in enumerate(ch) if is_repairs(c)]
    nis = [i for i, c in enumerate(ch) if is_not_inspected(c)]
    if nis and reps and nis[0] < reps[0]:
        add('L3', g['id'], f'"Not inspected" placed before Repairs: {titles}')
    if nis and nis[-1] != len(ch) - 1:
        add('L3', g['id'], f'"Not inspected" is not last: {titles}')

    cr = [d for d in descendants(g['id']) if d['type'] == 'screen' and has_condition_rating(d)]
    if len(cr) > 1:
        add('L4', g['id'], 'more than one Condition Rating screen: ' +
            ', '.join(f'"{c["title"]}" ({c["id"]})' for c in cr))
    if not cr:
        add('L2', g['id'], 'element has no Condition Rating screen at all')
    for c in cr:
        parent = by.get(c.get('parentId') or '')
        if c.get('inlinePosition') != 'header':
            add('L2', c['id'], f'condition-rating screen "{c["title"]}" is a separate tile under '
                               f'"{parent["title"] if parent else "-"}", not the inline header of the main group')
        elif parent and parent['id'] == g['id']:
            add('L2', c['id'], 'inline header sits directly on the landing, not inside the main group')

# ---- placement vs order attribute, duplicate titles ---------------------------------
pages = [(pid, ch) for pid, ch in kids.items()] + [(None, ch) for ch in roots.values()]
for pid, ch in pages:
    # inline headers render on top of the page whatever their placement, so they
    # are not tiles and do not take part in tile ordering / duplicate checks
    ch = [c for c in ch if c.get('inlinePosition') != 'header']
    if len(ch) < 2:
        continue
    by_order = [c['id'] for c in sorted(ch, key=lambda c: (c.get('order', 0), pos[c['id']]))]
    by_place = [c['id'] for c in ch]
    anchor = pid or ch[0]['id']
    if by_order != by_place:
        add('L5', anchor, 'app shows ' + str([by[i]['title'] for i in by_place]) +
            ' but "order" says ' + str([by[i]['title'] for i in by_order]))
    seen = collections.Counter(c['title'].strip().lower() for c in ch)
    dups = [k for k, v in seen.items() if v > 1]
    if dups:
        add('L6', anchor, f'duplicate titles {dups} on page {[c["title"] for c in ch]}')

# ---- fields --------------------------------------------------------------------------
for n in nodes:
    if n['type'] != 'screen':
        continue
    fields = n.get('fields', [])
    ids = collections.Counter(f['id'] for f in fields)
    for fid, c in ids.items():
        if c > 1:
            add('F3', n['id'], f'field id "{fid}" appears {c} times')
    fby = {f['id']: f for f in fields}
    for f in fields:
        for key, expected in condition_tokens(f):
            ctl = fby.get(key)
            if ctl is None:
                add('F1', n['id'], f'field "{f["label"]}" ({f["id"]}) depends on "{key}", '
                                   f'which is not on this screen, so it never shows')
                continue
            if expected is None:
                continue
            if ctl['type'] == 'dropdown':
                opts = {str(o).strip().lower() for o in ctl.get('options', [])}
                if expected not in opts:
                    add('F1', n['id'], f'field "{f["label"]}" ({f["id"]}) shows only when "{ctl["label"]}" = '
                                       f'"{expected}", but that dropdown has no such option {sorted(opts)}')
            elif ctl['type'] == 'checkbox' and expected not in ('true', 'false'):
                add('F1', n['id'], f'field "{f["label"]}" ({f["id"]}) expects checkbox "{ctl["label"]}" = "{expected}"')
        if f['type'] != 'dropdown':
            continue
        opts = [str(o).strip() for o in f.get('options', [])]
        if len(opts) < 2:
            add('D2', n['id'], f'dropdown "{f["label"]}" has {len(opts)} option(s): {opts}')
        if len({o.lower() for o in opts}) != len(opts):
            add('D2', n['id'], f'dropdown "{f["label"]}" has duplicate options: {opts}')
        if f['label'].strip().lower() == 'condition':
            if opts and all(TIMESCALE.search(o) for o in opts):
                add('D1', n['id'], f'dropdown labelled "Condition" holds repair timescales {opts}')
            elif any(is_repairs(a) for a in ancestors(n['id'])):
                add('D1', n['id'], f'dropdown labelled "Condition" inside a Repairs group, options {opts}')
    for o in (f for f in fields if f['type'] == 'checkbox' and f['label'].strip().lower() == 'other'):
        if not any(f['type'] == 'text' and any(k == o['id'] for k, _ in condition_tokens(f)) for f in fields):
            add('F2', n['id'], f'"Other" checkbox {o["id"]} has no linked text field')
    if not any(f['type'] != 'label' for f in fields):
        add('E1', n['id'], 'screen has no answerable field')

for g in nodes:
    if g['type'] == 'group' and not kids[g['id']]:
        add('E1', g['id'], 'empty group')

# ---- titles --------------------------------------------------------------------------
ni_variants = collections.Counter(n['title'] for n in nodes if is_not_inspected(n))
for n in nodes:
    ti = n['title']
    if is_not_inspected(n) and len(ni_variants) > 1 and ti != 'Not inspected':
        add('T1', n['id'], f'"{ti}" (spellings in use: {dict(ni_variants)})')
    if ti != ti.strip() or '  ' in ti:
        add('T1', n['id'], f'stray spaces in title "{ti}"')
    if re.search(r'\bFire Places\b|\bWood Work\b', ti, re.I):
        add('T1', n['id'], f'old spelling "{ti}"')
    if ti[:1].islower():
        add('T1', n['id'], f'title starts lower-case "{ti}"')
    if n.get('parentId') and CODE.match(ti) and n.get('inlinePosition') != 'header':
        add('T1', n['id'], f'section code visible in title "{ti}"')

# ---- write ---------------------------------------------------------------------------
ORDER = ['L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'D1', 'D2', 'T1', 'F1', 'F2', 'F3', 'E1']
NAMES = {
    'L1': 'Landing does not follow the Roof Covering pattern',
    'L2': 'Condition rating screen not the inline header of the main group',
    'L3': 'Repairs / Not inspected in the wrong position',
    'L4': 'Duplicate Condition Rating screens in one element',
    'L5': 'App order (placement) differs from the "order" attribute',
    'L6': 'Duplicate titles on one page',
    'D1': 'Repair dropdown still labelled "Condition"',
    'D2': 'Dropdown with too few or duplicate options',
    'T1': 'Title style',
    'F1': 'Conditional field can never appear (missing controller or impossible value)',
    'F2': '"Other" checkbox with no text box',
    'F3': 'Duplicate field id',
    'E1': 'Empty group or screen',
}
SEC_ORDER = 'ADEFGHRKIJO'
findings.sort(key=lambda f: (ORDER.index(f['code']), SEC_ORDER.find(f['section']), f['path']))
os.makedirs(OUT, exist_ok=True)
with open(f'{OUT}/tree_audit.json', 'w', encoding='utf-8') as fh:
    json.dump(findings, fh, indent=1, ensure_ascii=False)
cnt = collections.Counter(f['code'] for f in findings)
lines = ['# Inspection tree audit', '',
         f'Nodes: {len(nodes)} ({sum(n["type"] == "screen" for n in nodes)} screens). '
         f'Element landings checked: {len(landings)}.', '',
         '| Code | Check | Findings |', '|---|---|---|']
lines += [f'| {c} | {NAMES[c]} | {cnt.get(c, 0)} |' for c in ORDER]
for c in ORDER:
    fs = [f for f in findings if f['code'] == c]
    if fs:
        lines += ['', f'## {c}: {NAMES[c]} ({len(fs)})', '']
        lines += [f'- **{f["path"]}** (`{f["id"]}`): {f["msg"]}' for f in fs]
with open(f'{OUT}/tree_audit.md', 'w', encoding='utf-8') as fh:
    fh.write('\n'.join(lines) + '\n')
print('\n'.join(lines[:20]))
