# -*- coding: utf-8 -*-
"""Client review follow-up (1 Nov 2026, found in the Chrome end-to-end test).

The section page orders tiles by their placement in inspection_tree.json
(displayOrder = array index), not by the "order" attribute. E9 "Other Outside
Property" therefore showed [Repairs, Other Area]. Move the "Other Area" group
object in front of its Repairs sibling so the landing reads [Other Area, Repairs].

Run from repo root:  python tool/phrase_audit/verbatim/restructure_2026_11_01b.py
"""
import json

TREE = 'assets/property_inspection/inspection_tree.json'
raw = open(TREE, encoding='utf-8', newline='').read()
NL = '\r\n' if '\r\n' in raw else '\n'


def node_span(sid):
    marker = '"id": "%s"' % sid
    assert raw.count(marker) == 1, sid
    i = raw.index(marker)
    start = raw.rfind('{', 0, i)
    depth, j, in_str = 0, start, False
    while j < len(raw):
        c = raw[j]
        if in_str:
            if c == '\\':
                j += 1
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    return start, j + 1
        j += 1
    raise SystemExit('unbalanced ' + sid)


def move_before(sid, anchor_sid):
    """Cut the object `sid` (with its trailing comma) and paste it before `anchor_sid`."""
    global raw
    s, e = node_span(sid)
    obj = raw[s:e]
    after = raw[e:]
    if after.startswith(','):
        # ",<newline><indent>" follows the object: drop it with the object
        k = 1
        while k < len(after) and after[k] in '\r\n ':
            k += 1
        raw = raw[:s] + after[k:]
    else:
        # last element of its array: drop the ",<newline><indent>" before it
        before = raw[:s].rstrip()
        assert before.endswith(','), 'no comma around ' + sid
        raw = before[:-1] + after
    a, _ = node_span(anchor_sid)
    line_start = raw.rfind(NL, 0, a) + len(NL)
    indent = raw[line_start:a]
    raw = raw[:a] + obj + ',' + NL + indent + raw[a:]


move_before('group_other_area_33', 'group_repairs_42')

json.loads(raw)
open(TREE, 'w', encoding='utf-8', newline='').write(raw)
print('tree updated')
