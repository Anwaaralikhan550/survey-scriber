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


def rule_ids_for_screen(screen):
    return re.findall(r"VerbatimRule\(\s*'([^']+)',\s*'%s'," % re.escape(screen), spec)


def set_rule_condition(name, screen, when_field):
    """Point one rule at another screen and condition field."""
    global spec
    pat = re.compile(
        r"(VerbatimRule\(\s*'%s',\s*)'[^']+'(,.*?whenField: )'[^']+'" % re.escape(name), re.S)
    spec, n = pat.subn(lambda m: "%s'%s'%s'%s'" % (m.group(1), screen, m.group(2), when_field), spec, count=1)
    if n != 1:
        raise SystemExit('rule not found ' + name)


def move_node_after(sid, after_id):
    global raw
    start, end = node_span(sid)
    obj = raw[start:end]
    remove_span(start, end)
    _, after_end = node_span(after_id)
    line_start = raw.rfind(NL, 0, after_end - len(raw[node_span(after_id)[0]:after_end])) + len(NL)
    indent = raw[line_start:node_span(after_id)[0]]
    raw = raw[:after_end] + ',' + NL + indent + obj + raw[after_end:]


def set_order(sid, order):
    global raw
    start, end = node_span(sid)
    obj = raw[start:end]
    new, n = re.subn(r'("order":\s*)-?\d+', lambda m: m.group(1) + str(order), obj, count=1)
    if n != 1:
        raise SystemExit('no order on ' + sid)
    raw = raw[:start] + new + raw[end:]


def step_t13():
    # Listed Building: keep the standalone screen only.
    remove_node('activity_listed_building')
    for rid in rule_ids_for_screen('activity_listed_building'):
        remove_rule(rid)
    # Area repeats Property Location density and the gardens. The conservation
    # sentence stays, on the conservation tick of Property Location density.
    set_rule_condition('a4_conservation', 'activity_property_location', 'a4_location_0_conservation')
    for sid in ('group_area_4', 'activity_garden', 'activity_parking', 'activity_property_ground_area'):
        remove_node(sid)
    for screen in ('activity_garden', 'activity_parking'):
        for rid in rule_ids_for_screen(screen):
            remove_rule(rid)
    # Ground comes straight after Construction.
    move_node_after('group_ground_3', 'group_construction_2')
    set_order('group_ground_3', 13)


def _options_as_when_any(rule, prefix, count_note):
    global spec
    marker = "  VerbatimRule(%s    '%s'," % (SPEC_NL, rule)
    start = spec.index(marker)
    end_marker = '%s  ),%s' % (SPEC_NL, SPEC_NL)
    end = spec.index(end_marker, start)
    body = spec[start:end]
    ids = re.findall(r"'(%s[a-z_]+)': '" % re.escape(prefix), body) + [prefix + 'other']
    pairs = ', '.join("['%s', 'true']" % i for i in ids)
    spec = spec[:end] + SPEC_NL + '    whenAny: [%s],' % pairs + spec[end:]


def step_t14():
    # The options show without their heading tick, and ticking only an option
    # printed nothing: the client's missing Rear Garden boundaries and Communal Garden.
    _options_as_when_any('rear_type', 'rear_type_0_', '')
    _options_as_when_any('rear_fence', 'rear_fence_0_', '')
    _options_as_when_any('communal_type', 'communal_type_0_', '')
    _options_as_when_any('communal_fence', 'communal_fence_0_', '')


def field_json(indent, fid, label, ftype, conditional=None):
    lines = ['{', '  "id": %s,' % json.dumps(fid), '  "label": %s,' % json.dumps(label)]
    if conditional:
        lines.append('  "type": %s,' % json.dumps(ftype))
        lines.append('  "conditionalOn": %s' % json.dumps(conditional))
    else:
        lines.append('  "type": %s' % json.dumps(ftype))
    lines.append('}')
    return (NL + indent).join(lines)


def replace_field(sid, fid, new_fields):
    """Swap one field for several: [(id, label, type, conditionalOn or None)]."""
    global raw
    start, end = field_span(sid, fid)
    line_start = raw.rfind(NL, 0, start) + len(NL)
    indent = raw[line_start:start]
    text = (',' + NL + indent).join(field_json(indent, *f) for f in new_fields)
    raw = raw[:start] + text + raw[end:]


def replace_in_node(sid, old, new):
    global raw
    start, end = node_span(sid)
    obj = raw[start:end]
    if old not in obj:
        raise SystemExit('%r not on %s' % (old, sid))
    raw = raw[:start] + obj.replace(old, new) + raw[end:]


MOVEMENT_OPTIONS = [
    ('Minor subsidence', 'mv_minor_subsidence'),
    ('Significant subsidence', 'mv_significant_subsidence'),
    ('No structural movement', 'mv_no_structural_movement'),
    ('Normal defects', 'mv_normal_defects'),
    ('Recent defects', 'mv_recent_defects'),
    ('Recurring defects', 'mv_recurring_defects'),
    ('Differential thermal movement', 'mv_differential_thermal_movement'),
    ('Restraint steel rods', 'mv_restraint_steel_rods'),
]


def step_t15():
    global spec
    sid = 'activity_outside_property_main_walls_movements'
    replace_field(sid, 'actv_movement_status',
                  [('label_movement_status', 'Movement status', 'label', None)]
                  + [(tick, label, 'checkbox', None) for label, tick in MOVEMENT_OPTIONS])
    replace_in_node(sid, 'actv_movement_status=Recent defects', 'mv_recent_defects')
    replace_in_node(sid, 'actv_movement_status=Recurring defects', 'mv_recurring_defects')
    for label, tick in MOVEMENT_OPTIONS:
        old = "whenField: 'actv_movement_status',%s    whenValue: '%s'," % (SPEC_NL, label)
        if spec.count(old) != 1:
            raise SystemExit('rule for %s occurs %dx' % (label, spec.count(old)))
        spec = spec.replace(old, "whenField: '%s',%s    whenValue: 'true'," % (tick, SPEC_NL))


def insert_screen_after(after_id, sid, title, parent, order, fields):
    """New screen node right after another: fields [(id, label, type, conditionalOn or None)]."""
    global raw
    start, end = node_span(after_id)
    line_start = raw.rfind(NL, 0, start) + len(NL)
    indent = raw[line_start:start]
    inner = indent + '  '
    fields_indent = inner + '  '
    field_text = (',' + NL + fields_indent).join(field_json(fields_indent, *f) for f in fields)
    obj = NL.join([
        '{',
        inner + '"id": %s,' % json.dumps(sid),
        inner + '"title": %s,' % json.dumps(title),
        inner + '"type": "screen",',
        inner + '"parentId": %s,' % json.dumps(parent),
        inner + '"order": %d,' % order,
        inner + '"fields": [',
        fields_indent + field_text,
        inner + ']',
        indent + '}',
    ])
    raw = raw[:end] + ',' + NL + indent + obj + raw[end:]


def rule_block(name):
    marker = "  VerbatimRule(%s    '%s'," % (SPEC_NL, name)
    if spec.count(marker) != 1:
        raise SystemExit('rule %s occurs %dx' % (name, spec.count(marker)))
    start = spec.index(marker)
    end_marker = '%s  ),%s' % (SPEC_NL, SPEC_NL)
    return start, spec.index(end_marker, start)


def set_rule_screen(name, screen):
    global spec
    start, end = rule_block(name)
    body = spec[start:end]
    new, n = re.subn(r"(VerbatimRule\(\s*'%s',\s*)'[^']+'" % re.escape(name),
                     lambda m: "%s'%s'" % (m.group(1), screen), body, count=1)
    if n != 1:
        raise SystemExit('no screen on ' + name)
    spec = spec[:start] + new + spec[end:]


def set_rule_when(name, pairs):
    """Rule fires when any (field, value) pair holds."""
    global spec
    start, end = rule_block(name)
    body = spec[start:end]
    body = re.sub(r"\s*whenField: '[^']*',", '', body)
    body = re.sub(r"\s*whenValue: '[^']*',", '', body)
    body = re.sub(r"\s*whenAny: \[.*?\]\],", '', body, flags=re.S)
    (field, value), rest = pairs[0], pairs[1:]
    lines = ["    whenField: '%s'," % field, "    whenValue: '%s'," % value]
    if rest:
        lines.append('    whenAny: [%s],' % ', '.join("['%s', '%s']" % p for p in rest))
    spec = spec[:start] + body + SPEC_NL + SPEC_NL.join(lines) + spec[end:]


def remove_conditional(sid, fid):
    global raw
    start, end = field_span(sid, fid)
    obj = raw[start:end]
    new, n = re.subn(r',\s*"conditionalOn":\s*"[^"]*"', '', obj, count=1)
    if n != 1:
        raise SystemExit('no conditionalOn on %s/%s' % (sid, fid))
    raw = raw[:start] + new + raw[end:]


SILL_SCREEN = 'activity_outside_property_windows_sill_projection'
SILL_DEFECT_SCREEN = 'activity_outside_property_windows_sill_defect'
SILL_DEFECTS = [
    ('e5sd_adequate', 'adequate'),
    ('e5sd_properly_installed', 'properly installed'),
    ('e5sd_properly_drained', 'properly drained'),
    ('e5sd_cracked', 'cracked'),
    ('e5sd_defective', 'defective'),
]


def step_t16():
    remove_field(SILL_SCREEN, 'actv_projection_type')
    remove_conditional(SILL_SCREEN, 'actv_condition')
    remove_field(SILL_SCREEN, 'label_sill_defects')
    for fid, _ in SILL_DEFECTS:
        remove_field(SILL_SCREEN, fid)
    insert_screen_after(
        SILL_SCREEN, SILL_DEFECT_SCREEN, 'Sill Defect', 'group_windows_21', 14,
        [('label_sill_defects', 'Windowsill projection', 'label', None)]
        + [(fid, label, 'checkbox', None) for fid, label in SILL_DEFECTS])
    set_rule_when('e5_sill', [('actv_condition', 'Properly'), ('actv_condition', 'Fairly'), ('actv_condition', 'Poorly')])
    set_rule_screen('e5_sill_defect', SILL_DEFECT_SCREEN)
    set_rule_when('e5_sill_defect', [(fid, 'true') for fid, _ in SILL_DEFECTS])


def set_parent(sid, parent):
    global raw
    start, end = node_span(sid)
    obj = raw[start:end]
    new, n = re.subn(r'("parentId":\s*)"[^"]*"', lambda m: m.group(1) + json.dumps(parent), obj, count=1)
    if n != 1:
        raise SystemExit('no parentId on ' + sid)
    raw = raw[:start] + new + raw[end:]


def insert_rule_before(name, rule_text):
    """Add a VerbatimRule entry (written with LF) just before an existing rule."""
    global spec
    start, _ = rule_block(name)
    spec = spec[:start] + rule_text.replace(chr(10), SPEC_NL) + spec[start:]


def token(name, options, other_cb=None, other_text=None):
    lines = ["      VerbatimToken(", "        '%s'," % name, "        options: {"]
    lines += ["          '%s': '%s'," % (k, v) for k, v in options]
    lines.append("        },")
    if other_cb:
        lines.append("        otherCheckbox: '%s'," % other_cb)
        lines.append("        otherText: '%s'," % other_text)
    lines.append("      ),")
    return chr(10).join(lines)


def rule(name, screen, master, sub, tokens, pairs):
    (field, value), rest = pairs[0], pairs[1:]
    lines = ["  VerbatimRule(", "    '%s'," % name, "    '%s'," % screen, "    '%s'," % master,
             "    '%s'," % sub, "    ["] + tokens + ["    ],", "    whenField: '%s'," % field,
             "    whenValue: '%s'," % value]
    if rest:
        lines.append("    whenAny: [%s]," % ', '.join("['%s', '%s']" % p for p in rest))
    lines.append("  ),")
    return chr(10).join(lines) + chr(10)


SHED_REPAIR = 'activity_grounds_other_repair_shed_repair'
CEILINGS_REPAIR = 'activity_inside_property_ceilings_repairs_ceilings'


def step_t18():
    # Shed: the description belongs with the garden; Repairs gets a real Shed Repair.
    set_parent('activity_grounds_other_repair_shed', 'group_other_53')
    set_order('activity_grounds_other_repair_shed', 5)
    start, end = node_span('activity_grounds_other_repair_shed')
    obj = raw[start:end]
    remove_span(start, end)
    _insert_object_after('activity_grounds_other_front_garden', obj)

    shed_types = [('h2rs_timber', 'Timber', 'timber'), ('h2rs_brick', 'Brick', 'brick')]
    shed_defects = [('h2rs_damaged', 'Is damaged', 'is damaged'),
                    ('h2rs_disrepair', 'In disrepair', 'in disrepair'),
                    ('h2rs_unstable', 'Is unstable', 'is unstable')]
    insert_screen_after(
        'activity_grounds_other_repair_fence', SHED_REPAIR, 'Shed Repair', 'group_repairs_54', 4,
        [('label_h2rs_type', 'Shed type', 'label', None)]
        + [(i, l, 'checkbox', None) for i, l, _ in shed_types]
        + [('h2rs_type_other', 'Other', 'checkbox', None),
           ('h2rs_type_other_text', 'Other', 'text', 'h2rs_type_other'),
           ('label_h2rs_defect', 'Defect', 'label', None)]
        + [(i, l, 'checkbox', None) for i, l, _ in shed_defects]
        + [('h2rs_defect_other', 'Other', 'checkbox', None),
           ('h2rs_defect_other_text', 'Other', 'text', 'h2rs_defect_other')])
    insert_rule_before('h2_sheds', rule(
        'h2_shed_repair', SHED_REPAIR, '{H_OTHER}', '{REPAIR_SHED}',
        [token('{OTH_REP_SHED_TYPE}', [(i, v) for i, _, v in shed_types], 'h2rs_type_other', 'h2rs_type_other_text'),
         token('{OTH_REP_SHED_DEF}', [(i, v) for i, _, v in shed_defects], 'h2rs_defect_other', 'h2rs_defect_other_text')],
        [(i, 'true') for i, _, _ in shed_defects] + [('h2rs_defect_other', 'true')]))

    # Ceiling repairs: the screen and its two approved sentences come back.
    rooms = [('lounge', 'Lounge'), ('bedroom', 'Bedroom'), ('kitchen', 'Kitchen'), ('bathroom', 'Bathroom')]
    now_defects = [('f2r_now_badly_cracked', 'Badly cracked', 'badly cracked'),
                   ('f2r_now_very_loose', 'Very loose', 'very loose'),
                   ('f2r_now_stained', 'Stained heavily with damp', 'stained heavily with damp'),
                   ('f2r_now_unstable', 'Unstable and may fall', 'unstable and may fall')]
    soon_defects = [('f2r_soon_missing', 'Missing in places', 'missing in places'),
                    ('f2r_soon_loose', 'Loose', 'loose'),
                    ('f2r_soon_uneven', 'Uneven', 'uneven'),
                    ('f2r_soon_sagging', 'Sagging', 'sagging'),
                    ('f2r_soon_bowed', 'Bowed', 'bowed'),
                    ('f2r_soon_stained', 'Stained', 'stained')]
    fields = [('actv_status', 'Status', 'dropdown', None)]
    for key, status, defects in (('now', 'Repair now', now_defects), ('soon', 'Repair soon', soon_defects)):
        cond = 'actv_status=' + status
        fields.append(('label_f2r_%s_rooms' % key, 'Location', 'label', cond))
        fields += [('f2r_%s_%s' % (key, r), l, 'checkbox', cond) for r, l in rooms]
        fields += [('f2r_%s_room_other' % key, 'Other', 'checkbox', cond),
                   ('f2r_%s_room_other_text' % key, 'Other', 'text', cond + '&f2r_%s_room_other' % key),
                   ('label_f2r_%s_defects' % key, 'Defect', 'label', cond)]
        fields += [(i, l, 'checkbox', cond) for i, l, _ in defects]
        fields += [('f2r_%s_defect_other' % key, 'Other', 'checkbox', cond),
                   ('f2r_%s_defect_other_text' % key, 'Other', 'text', cond + '&f2r_%s_defect_other' % key)]
    insert_screen_after('group_repairs_62', CEILINGS_REPAIR, 'Repair Ceilings', 'group_repairs_62', 2, fields)
    _set_dropdown_options(CEILINGS_REPAIR, 'actv_status', ['Repair now', 'Repair soon'])
    for key, sub, status, defects in (('now', '{REPAIRS_CELLINGS_NOW}', 'Repair now', now_defects),
                                      ('soon', '{REPAIRS_CELLINGS_SOON}', 'Repair soon', soon_defects)):
        upper = key.upper()
        insert_rule_before('f2_ornamental', rule(
            'f2_repair_' + key, CEILINGS_REPAIR, '{F_CEILINGS}', sub,
            [token('{CER_RC_%s_LOCATION}' % upper, [('f2r_%s_%s' % (key, r), l.lower()) for r, l in rooms],
                   'f2r_%s_room_other' % key, 'f2r_%s_room_other_text' % key),
             token('{CER_RC_%s_DEFECT}' % upper, [(i, v) for i, _, v in defects],
                   'f2r_%s_defect_other' % key, 'f2r_%s_defect_other_text' % key)],
            [('actv_status', status)]))


def _insert_object_after(after_id, obj):
    global raw
    start, end = node_span(after_id)
    line_start = raw.rfind(NL, 0, start) + len(NL)
    indent = raw[line_start:start]
    raw = raw[:end] + ',' + NL + indent + obj + raw[end:]


def _set_dropdown_options(sid, fid, options):
    global raw
    start, end = field_span(sid, fid)
    obj = raw[start:end]
    line_start = raw.rfind(NL, 0, start) + len(NL)
    indent = raw[line_start:start]
    new = obj.rstrip('}').rstrip()
    item_indent = indent + '    '
    opts = (',' + NL + item_indent).join(json.dumps(o) for o in options)
    new += ',' + NL + indent + '  "options": [' + NL + item_indent + opts + NL + indent + '  ]' + NL + indent + '}'
    raw = raw[:start] + new + raw[end:]


STEPS = {name[5:]: fn for name, fn in list(globals().items()) if name.startswith('step_')}

if __name__ == '__main__':
    STEPS[sys.argv[1]]()
    json.loads(raw)
    open(TREE, 'w', encoding='utf-8', newline='').write(raw)
    open(SPEC, 'w', encoding='utf-8', newline='').write(spec)
    print('applied', sys.argv[1])
