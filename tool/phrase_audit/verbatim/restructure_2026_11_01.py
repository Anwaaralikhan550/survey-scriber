# -*- coding: utf-8 -*-
"""Client review fixes (1 Nov 2026): text-level edits of inspection_tree.json.

Keeps CRLF and formatting; only the targeted node objects are touched.

1. Landing-screen arrangement = the Roof Covering pattern: element landing shows
   [Main group, Repairs, Not inspected]; the main (condition-rating/notes) screen
   lives INSIDE the main group as an inline header, first.
2. "Fire Places" -> "Fireplaces", "Wood Work" -> "Woodwork", "Bathroom Fitting" -> "Bathroom Fittings".
3. Repair-timescale dropdowns labelled "Condition" -> "Repair Timescales".
4. Roof Covering: remove the duplicate "Condition" (weathered) screen.

Run from repo root:  python tool/phrase_audit/verbatim/restructure_2026_11_01.py
"""
import json
import re
import sys

TREE = 'assets/property_inspection/inspection_tree.json'
raw = open(TREE, encoding='utf-8', newline='').read()
NL = '\r\n' if '\r\n' in raw else '\n'


def node_span(sid):
    """(start, end) of the node object whose "id" is sid; end is index after '}'."""
    marker = '"id": "%s"' % sid
    if raw.count(marker) != 1:
        raise SystemExit('id %r occurs %dx' % (sid, raw.count(marker)))
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
    raise SystemExit('unbalanced at ' + sid)


def set_attr(sid, key, value):
    """Set a scalar attribute on the node header (before "fields")."""
    global raw
    s, e = node_span(sid)
    obj = raw[s:e]
    head_end = obj.find('"fields"')
    head = obj if head_end < 0 else obj[:head_end]
    val = json.dumps(value) if isinstance(value, str) else str(value)
    pat = re.compile(r'("%s":\s*)("[^"]*"|-?\d+|null)' % re.escape(key))
    if pat.search(head):
        new_head = pat.sub(lambda m: m.group(1) + val, head, count=1)
    else:
        # insert after the "order" line (or "parentId" line), keeping indentation
        m = re.search(r'(\r?\n)(\s*)"order":\s*-?\d+', head)
        if not m:
            m = re.search(r'(\r?\n)(\s*)"parentId":\s*"[^"]*"', head)
        if not m:
            raise SystemExit('no anchor in ' + sid)
        insert_at = m.end()
        new_head = head[:insert_at] + ',' + NL + m.group(2) + '"%s": %s' % (key, val) + head[insert_at:]
        # the anchor line previously ended with ',' only if followed by more keys; normalise
        new_head = new_head.replace(',,' + NL, ',' + NL)
        # if anchor line had no trailing comma we added one; if the next line is '}' the new line must not end with ','
    raw = raw[:s] + new_head + obj[len(head):] + raw[e:]


def move(sid, parent, order=None, header=False):
    set_attr(sid, 'parentId', parent)
    if order is not None:
        set_attr(sid, 'order', order)
    if header:
        set_attr(sid, 'inlinePosition', 'header')


def rename(sid, title):
    set_attr(sid, 'title', title)


def delete_node(sid):
    global raw
    s, e = node_span(sid)
    # remove preceding whitespace + comma (node is never the first in its array here)
    before = raw[:s].rstrip()
    assert before.endswith(','), 'expected a comma before ' + sid
    before = before[:-1]
    after = raw[e:]
    # keep "," + newline + indentation of the next sibling
    raw = before + after


def insert_group_before(anchor_sid, gid, title, parent, order):
    """Insert a new group object right before the anchor node (same array)."""
    global raw
    s, _ = node_span(anchor_sid)
    line_start = raw.rfind(NL, 0, s) + len(NL)
    indent = raw[line_start:s]
    obj = ('{' + NL +
           indent + '  "id": "%s",' % gid + NL +
           indent + '  "title": %s,' % json.dumps(title) + NL +
           indent + '  "type": "group",' + NL +
           indent + '  "parentId": "%s",' % parent + NL +
           indent + '  "order": %d' % order + NL +
           indent + '},' + NL + indent)
    raw = raw[:s] + obj + raw[s:]


def relabel_field(sid, field_id, new_label):
    global raw
    s, e = node_span(sid)
    obj = raw[s:e]
    pat = re.compile(r'("id":\s*"%s",\s*\r?\n\s*"label":\s*)"[^"]*"' % re.escape(field_id))
    if not pat.search(obj):
        raise SystemExit('field %s not found in %s' % (field_id, sid))
    raw = raw[:s] + pat.sub(lambda m: m.group(1) + json.dumps(new_label), obj, count=1) + raw[e:]


# ── 1. landing arrangement (Roof Covering pattern) ─────────────────────────
move('activity_outside_property_chimney_main_screen', 'group_chimney_6', order=-1)
set_attr('activity_outside_property_chimney_not_inspected', 'order', 7)
move('activity_outside_property_outside_doors_main_screen', 'group_outside_doors_24', order=-1)
move('activity_outside_property_conservatory_porch_main_screen', 'group_conservatory_and_porch_27', order=-1)

# E8: new main group holding the header + description screens
insert_group_before('activity_outside_property_other_joinery_and_finishes_repairs',
                    'group_other_joinery_and_finishes_82', 'Other Joinery and Finishes',
                    'group_e8_other_joinery_and_finishes_31', 1)
move('activity_outside_property_other_joinery_and_finishes_main_screen', 'group_other_joinery_and_finishes_82', order=-1, header=True)
for sid in ('activity_outside_property_other_joinery_and_finishes_timber_weathering',
            'activity_outside_property_other_joinery_and_finishes_timber_decay',
            'activity_outside_property_other_joinery_and_finishes_defective_joinery',
            'activity_outside_property_other_joinery_finishes_condition'):
    move(sid, 'group_other_joinery_and_finishes_82')

# E9
move('activity_outside_property_other_main_screen', 'group_other_area_33', order=-1)

# F5 Fireplaces
rename('group_fire_places_70', 'Fireplaces')
move('activity_inside_property_fireplaces_main_screen', 'group_fire_places_70', order=-1)
for sid in ('activity_in_side_property_fire_places_repair_blocked_fireplace',
            'activity_in_side_property_fire_places_repair_removed_cb',
            'activity_in_side_property_fire_places_repair_boiler_flue',
            'activity_in_side_property_fire_places_defects',
            'activity_in_side_property_fire_places_dampness'):
    move(sid, 'group_repairs_71')

# F6 Built In Fittings: new main group
insert_group_before('activity_in_side_property_built_in_fittings',
                    'group_built_in_fittings_83', 'Built In Fittings',
                    'group_f6_built_in_fittings_72', 1)
move('activity_inside_property_built_in_fittings_main_screen', 'group_built_in_fittings_83', order=-1)
move('activity_in_side_property_built_in_fittings', 'group_built_in_fittings_83', order=2)

# F7 Woodwork
rename('group_wood_work_75', 'Woodwork')
rename('activity_in_side_property_wood_work_second', 'Woodwork')
move('activity_inside_property_woodwork_main_screen', 'group_wood_work_75', order=-1)

# F8 Bathroom Fittings
rename('group_bathroom_fitting_78', 'Bathroom Fittings')
move('activity_inside_property_bathroom_fittings_main_screen', 'group_bathroom_fitting_78', order=-1)

# ── 3. "Condition" -> "Repair Timescales" on repair-timescale dropdowns ──────
RELABEL = [
    ('activity_outside_property_repair_flashing', 'android_material_design_spinner4'),
    ('activity_outside_property_roof_repair_tiles', 'actv_condition'),
    ('activity_outside_property_repair_chimney_dish_aerial', 'actv_condition'),
    ('activity_outside_property_chimney_repair_flaunching', 'actv_condition'),
    ('activity_outside_property_repair_chimney_dish_aerial__satellite', 'actv_condition'),
    ('activity_outside_property_roof_repair_flat_roof', 'actv_condition'),
    ('activity_outside_property_rwg__repair_pipes_gutters', 'actv_condition'),
    ('activity_outside_property_rwg_defective_connections', 'actv_condition'),
    ('activity_outside_property_roof_repair_parapet_wall', 'actv_condition'),
    ('activity_outside_property_repair_chimney_pots', 'actv_condition'),
    ('activity_outside_property_roof_repair_valley_gutters', 'actv_condition'),
    ('activity_outside_property_roof_repair_flashing', 'actv_condition'),
    ('activity_outside_property_roof_repair_ridge_tiles', 'actv_condition'),
    ('activity_outside_property_roof_repair_hip_tiles', 'actv_condition'),
    ('activity_outside_property_repair_chimney_repointing', 'actv_condition'),
]
for sid, fid in RELABEL:
    relabel_field(sid, fid, 'Repair Timescales')

# ── 4. Roof Covering duplicate Condition screen ─────────────────────────────
delete_node('outside_property_roof_covering_weathered_layout')

json.loads(raw)  # must still parse
open(TREE, 'w', encoding='utf-8', newline='').write(raw)
print('tree updated')
