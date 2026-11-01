# -*- coding: utf-8 -*-
"""Whole-tree sweep fixes (1 Nov 2026), found by tool/tree_audit/audit_tree.py and
test/features/property_inspection/tree_reachability_test.dart - i.e. the same
defect classes the client reported, in places she had not looked yet.

1. Conditions written "field=A|B" (7 screens): the app splits on "|", so "B" was
   read as a field name and choosing B hid the follow-up boxes (e.g. Repair Tiles
   with "Repair now"). Rewritten to "field=A|field=B" (and "...&x" per branch).
2. Roof Covering layout for the remaining landings:
   Water, Heating, Drainage, Common Services, Garage -> [main group, Repairs];
   Rain Water Goods -> [Rainwater Goods, Repairs, Not inspected];
   Grounds > Other -> [Other, Repairs].
3. Duplicate "Condition Rating" screen on Other Joinery and Finishes removed
   (same as the Roof Covering duplicate the client asked to remove).
4. Empty groups that opened a blank page removed (Repairs of Gas and Oil,
   Water Heating, Walls and Partitions; Inside > Other > Basement; six empty
   structure groups under Other Outside Property > Repairs).
5. "Inadequate lock" pointed to a parent that does not exist; now under
   Outside Doors > Repairs.

Text-level edits only (CRLF and formatting kept). Run from repo root:
  python3 tool/phrase_audit/verbatim/restructure_2026_11_01c.py
"""
import json
import re

TREE = 'assets/property_inspection/inspection_tree.json'
raw = open(TREE, encoding='utf-8', newline='').read()
NL = '\r\n' if '\r\n' in raw else '\n'


def node_span(sid):
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
    """Set a scalar attribute in the node header (before "fields")."""
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
        m = re.search(r'(\r?\n)(\s*)"order":\s*-?\d+', head)
        if not m:
            raise SystemExit('no "order" anchor in ' + sid)
        new_head = head[:m.end()] + ',' + NL + m.group(2) + '"%s": %s' % (key, val) + head[m.end():]
        new_head = new_head.replace(',,' + NL, ',' + NL)
    raw = raw[:s] + new_head + obj[len(head):] + raw[e:]


def move(sid, parent, order=None, header=False):
    set_attr(sid, 'parentId', parent)
    if order is not None:
        set_attr(sid, 'order', order)
    if header:
        set_attr(sid, 'inlinePosition', 'header')


def delete_node(sid):
    global raw
    s, e = node_span(sid)
    after = raw[e:]
    if after.startswith(','):
        k = 1
        while k < len(after) and after[k] in '\r\n ':
            k += 1
        raw = raw[:s] + after[k:]
    else:
        before = raw[:s].rstrip()
        assert before.endswith(','), 'no comma around ' + sid
        raw = before[:-1] + after


def insert_group_before(anchor_sid, gid, title, parent, order):
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


# ── 1. "field=A|B" conditions ────────────────────────────────────────────
COND = re.compile(r'("conditionalOn":\s*")(\w+)=([^"|&=]+)\|([^"|&=]+)(?:&(\w+))?(")')


def _fix_condition(m):
    key, a, b, extra = m.group(2), m.group(3), m.group(4), m.group(5)
    if extra:
        expr = '%s=%s&%s|%s=%s&%s' % (key, a, extra, key, b, extra)
    else:
        expr = '%s=%s|%s=%s' % (key, a, key, b)
    return m.group(1) + expr + m.group(6)


raw, n_cond = COND.subn(_fix_condition, raw)
assert n_cond == 49, n_cond

# ── 2. Roof Covering layout for the remaining landings ───────────────────
# Services > Water: [Water (condition + Main Water + Water Tank), Repairs]
insert_group_before('activity_services_water_main_water', 'group_water_100', 'Water', 'group_g3_water_91', 0)
move('activity_services_water_main_screen', 'group_water_100', order=-1, header=True)
move('activity_services_water_main_water', 'group_water_100', order=1)
move('activity_services_water_water_tank', 'group_water_100', order=2)
set_attr('activity_services_water_repair_main_screen', 'order', 3)

# Services > Heating: [Heating (condition + About Heating System), Repairs]
insert_group_before('activity_services_heating_about_heating', 'group_heating_101', 'Heating', 'group_g4_heating_92', 0)
move('activity_services_heating_main_screen', 'group_heating_101', order=-1, header=True)
move('activity_services_heating_about_heating', 'group_heating_101', order=1)
set_attr('activity_services_heating_repair_main_screen', 'order', 2)

# Services > Drainage: [Drainage (condition + Drainage details), Repairs]
insert_group_before('activity_services_drainage', 'group_drainage_102', 'Drainage', 'group_g6_drainage_96', 0)
move('activity_services_drainage_main_screen', 'group_drainage_102', order=-1, header=True)
move('activity_services_drainage', 'group_drainage_102', order=1)
set_attr('group_repairs_97', 'order', 2)

# Services > Common Services: [Common Services (condition + details)]
insert_group_before('activity_services_shared_services', 'group_common_services_103', 'Common Services',
                    'group_g7_common_services_98', 0)
move('activity_services_common_services_main_screen', 'group_common_services_103', order=-1, header=True)
move('activity_services_shared_services', 'group_common_services_103', order=1)

# Grounds > Garage: [Garage (condition + details), Repairs]
insert_group_before('activity_grounds_garage', 'group_garage_104', 'Garage', 'group_h1_garage_50', 0)
move('activity_grounds_garage_main_screen', 'group_garage_104', order=-1, header=True)
move('activity_grounds_garage', 'group_garage_104', order=1)
set_attr('group_repairs_51', 'order', 2)

# Outside > Rain Water Goods: observations into the main group, repairs into a
# Repairs group -> [Rainwater Goods, Repairs, Not inspected]
for i, sid in enumerate(('activity_outside_property_rwg_insufficient_slope',
                         'activity_outside_property_rwg_leakage',
                         'activity_outside_property_rwg_corrosion'), start=10):
    move(sid, 'group_rainwater_goods_14', order=i)
insert_group_before('activity_outside_property_rwg__repair_pipes_gutters', 'group_repairs_105', 'Repairs',
                    'group_e3_rain_water_goods_13', 1)
move('activity_outside_property_rwg__repair_pipes_gutters', 'group_repairs_105', order=1)
set_attr('activity_outside_property_rwg__repair_pipes_gutters', 'title', 'Repair pipes and gutters')
move('activity_outside_property_rwg_defective_connections', 'group_repairs_105', order=2)
set_attr('activity_outside_property_rain_water_goods_not_inspected', 'order', 3)

# Grounds > Other: observations into the "Other" group -> [Other, Repairs]
for i, sid in enumerate(('activity_grounds_shared_access',
                         'activity_grounds_other_private_road',
                         'activity_other_repair_shrinkable_clay'), start=10):
    move(sid, 'group_other_53', order=i)

# ── 3. duplicate Condition Rating screen (E8) ────────────────────────────
delete_node('activity_outside_property_other_joinery_finishes_condition')

# ── 4. empty groups (blank pages) ────────────────────────────────────────
for gid in ('group_repairs_90', 'group_repairs_95', 'group_repairs_65', 'group_basement_84',
            'group_porch_canopy_44', 'group_roof_terrace_45', 'group_balcony_46',
            'group_juliet_balcony_47', 'group_external_stairs_48', 'group_other_49'):
    delete_node(gid)

# ── 5. orphan "Inadequate lock" ──────────────────────────────────────────
move('activity_outside_property_out_side_doors_repairs_inadequate_lock_location', 'group_repairs_25', order=2)

json.loads(raw)
open(TREE, 'w', encoding='utf-8', newline='').write(raw)
print('tree updated; conditions fixed:', n_cond)
