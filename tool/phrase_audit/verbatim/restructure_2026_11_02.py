# -*- coding: utf-8 -*-
"""Client edit list "Survey Scriber Edit Oct 2026.docx" (2 Nov 2026): tree changes.

Each step is what the client wrote, nothing else. Text-level edits only (CRLF and
formatting kept). Run one step from the repo root:
  python3 tool/phrase_audit/verbatim/restructure_2026_11_02.py <step>
"""
import json
import re
import sys

TREE = 'assets/property_inspection/inspection_tree.json'
SPEC = 'lib/features/property_inspection/domain/inspection_verbatim_spec.dart'
raw = open(TREE, encoding='utf-8', newline='').read()
NL = '\r\n' if '\r\n' in raw else '\n'
spec = open(SPEC, encoding='utf-8', newline='').read()
SPEC_NL = '\r\n' if '\r\n' in spec else '\n'


def object_end(text, start):
    depth, j, in_str = 0, start, False
    while j < len(text):
        c = text[j]
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
                    return j + 1
        j += 1
    raise SystemExit('unbalanced object')


def node_span(sid):
    marker = '"id": "%s"' % sid
    hits = [m.start() for m in re.finditer(re.escape(marker), raw)]
    # A node id is never also a field id in the tree, so one hit is expected.
    if len(hits) != 1:
        raise SystemExit('id %r occurs %dx' % (sid, len(hits)))
    start = raw.rfind('{', 0, hits[0])
    return start, object_end(raw, start)


def remove_span(start, end):
    """Remove an object and the comma that belonged to it."""
    global raw
    before = raw[:start].rstrip()
    after = raw[end:]
    stripped = after.lstrip()
    if stripped.startswith(','):
        # object, next -> keep what precedes, drop this object and its comma
        raw = raw[:start].rstrip(' ') + stripped[1:].lstrip('\r\n').lstrip(' ')
        raw = raw[:len(raw)]
        return
    if before.endswith(','):
        # last in the array -> drop the comma before it
        raw = before[:-1] + after
        return
    raw = raw[:start] + after


def remove_node(sid):
    start, end = node_span(sid)
    remove_span(start, end)


def field_span(sid, fid):
    start, end = node_span(sid)
    marker = '"id": "%s"' % fid
    i = raw.find(marker, start, end)
    if i < 0:
        raise SystemExit('field %s not on %s' % (fid, sid))
    fstart = raw.rfind('{', start, i)
    return fstart, object_end(raw, fstart)


def remove_field(sid, fid):
    start, end = field_span(sid, fid)
    remove_span(start, end)


def set_title(sid, title):
    global raw
    start, end = node_span(sid)
    obj = raw[start:end]
    new, n = re.subn(r'("title":\s*)"[^"]*"', lambda m: m.group(1) + json.dumps(title), obj, count=1)
    if n != 1:
        raise SystemExit('no title on ' + sid)
    raw = raw[:start] + new + raw[end:]


def remove_rule(name):
    """Remove one VerbatimRule(...) entry from the spec."""
    global spec
    marker = "  VerbatimRule(%s    '%s'," % (SPEC_NL, name)
    if spec.count(marker) != 1:
        raise SystemExit('rule %s occurs %dx' % (name, spec.count(marker)))
    start = spec.index(marker)
    end_marker = '%s  ),%s' % (SPEC_NL, SPEC_NL)
    end = spec.index(end_marker, start) + len(end_marker)
    spec = spec[:start] + spec[end:]


def step_t11():
    set_title('activity_over_all_openion', 'Overall Opinion')
    set_title('activity_in_side_property_built_in_fittings_repair_moulding_noted', 'Defects')
    remove_field('activity_services_water_heating_gas_heating', 'cb_wh_solar')
    remove_rule('g5_solar')


STEPS = {name[5:]: fn for name, fn in list(globals().items()) if name.startswith('step_')}

if __name__ == '__main__':
    STEPS[sys.argv[1]]()
    json.loads(raw)
    open(TREE, 'w', encoding='utf-8', newline='').write(raw)
    open(SPEC, 'w', encoding='utf-8', newline='').write(spec)
    print('applied', sys.argv[1])
