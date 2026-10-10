# -*- coding: utf-8 -*-
"""Generate slices/e9_e.json (E9 Other outside property). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e9_e.json')
S = 'E9'
MW = '{E_OTHER_AREA}'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
P_ = 'activity_outside_property_other_'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])

# structure index -> group
STRUCT = ['carport', 'porch', 'terrace', 'balcony', 'juliet', 'stairs', 'other']


def sid(kind, i):
    """Screen id of element `kind` in structure group i (0=carport .. 6=other)."""
    base = {'construction': ('activity_outside_property_other_other_external', '__construction'),
            'roof': (P_ + 'other_roof', '__roof'),
            'wall': (P_ + 'other_wall', '__wall_construction'),
            'floor': (P_ + 'floors', '__floor'),
            'drains': (P_ + 'drains', '__drains'),
            'handrails': (P_ + 'handrails', '__handrails'),
            'overloaded': (P_ + 'overloaded', '__overloaded'),
            'noglass': (P_ + 'no_safety_glass', '__no_safety_glass'),
            'condition': ('activity_out_side_other_external_area_condition', '__condition'),
            'r_wall': (P_ + 'repairs_wall', '__wall'),
            'r_roof': (P_ + 'repairs_roof', '__roof'),
            'r_floor': (P_ + 'repairs_floor', '__floor'),
            'r_drains': (P_ + 'repairs_drains', '__drains'),
            'r_rails': (P_ + 'repairs_hand_rails', '__hand_rails'),
            'r_steps': (P_ + 'repairs_steps_landing', '__steps_landing'),
            'r_decor': (P_ + 'repairs_decorations', '__perished_decorations')}[kind]
    if kind == 'construction':
        b = base[0].replace('activity_outside_property_other_', P_)
        base = (b, base[1])
    root, sfx = base
    if i == 0:
        return root
    if i == 1:
        return root + sfx
    return root + sfx + f'__{i}'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{E9_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cond_dd(token, fid):
    return dd(token, fid, 'Condition', COND5, lower=True)


slices = []
KEEP = {0: ['construction', 'roof', 'wall', 'floor', 'condition'],
        1: ['construction', 'roof', 'condition'],
        2: ['construction', 'roof', 'wall', 'floor', 'drains', 'condition'],
        3: ['construction', 'wall', 'floor', 'drains', 'condition'],
        4: ['construction', 'condition'],
        5: ['construction', 'handrails', 'condition'],
        6: ['construction', 'condition']}

WALLS = 'bricks, timber, steel, glass, aluminium, other'
FLOOR = 'concrete, block paving, tarmac, gravel, other'


def walls_floor(i, after):
    t = STRUCT[i]
    return [
        (f'e9_{t}_walls', 'wall', pr(f'e9_{t}_walls', f'{t.upper()}_WALLS', 'Walls: The walls or balustrades are formed in',
                                      'Floor: The floor is formed in', after=after, subs={WALLS: '{E9_WALL_MATERIALS}'},
                                      tokens=[ck('{E9_WALL_MATERIALS}', 'Walls or balustrades formed in', WALLS, f'e9{i}w_',
                                                 other=(f'e9{i}w_other', f'e9{i}w_other_text'))])),
        (f'e9_{t}_floor', 'floor', pr(f'e9_{t}_floor', f'{t.upper()}_FLOOR', 'Floor: The floor is formed in',
                                       None, after=after, subs={FLOOR: '{E9_FLOOR_FINISH}'},
                                       tokens=[ck('{E9_FLOOR_FINISH}', 'Floor formed in', FLOOR, f'e9{i}f_',
                                                  other=(f'e9{i}f_other', f'e9{i}f_other_text'))])),
    ]


def fix_floor_end(rule, end_text, section_block_after):
    return rule


def rules_for(i):
    """[(kind, rule)] for structure i."""
    t = STRUCT[i]
    out = []
    cap = lambda s: s.upper()  # noqa: E731
    if t == 'carport':
        out.append(('construction', pr('e9_carport', 'CARPORT', 'Carport: The property incorporates', 'Roof: The roof is of',
                                        subs={'timber, steel, aluminium, masonry': '{E9_CARPORT_TYPES}'},
                                        tokens=[ck('{E9_CARPORT_TYPES}', 'Carport', 'timber, steel, aluminium, masonry', 'e90c_')])))
        roof_l1 = 'pitched, flat, lean-to'
        roof_l2 = 'tiles, slates, felt sheet, polycarbonate sheet, metal sheeting, other'
        out.append(('roof', pr('e9_carport_roof', 'CARPORT_ROOF', 'Roof: The roof is of', 'Walls: The walls or balustrades are formed in',
                                after='Carport: The property incorporates',
                                subs={roof_l1: '{E9_ROOF_SHAPE}', roof_l2: '{E9_ROOF_COVERING}'},
                                tokens=[ck('{E9_ROOF_SHAPE}', 'Roof construction', roof_l1, 'e90rs_'),
                                        ck('{E9_ROOF_COVERING}', 'Covered with', roof_l2, 'e90rc_',
                                           other=('e90rc_other', 'e90rc_other_text'))])))
        out.append(('wall', pr('e9_carport_walls', 'CARPORT_WALLS', 'Walls: The walls or balustrades are formed in',
                                'Floor: The floor is formed in', after='Carport: The property incorporates',
                                subs={WALLS: '{E9_WALL_MATERIALS}'},
                                tokens=[ck('{E9_WALL_MATERIALS}', 'Walls or balustrades formed in', WALLS, 'e90w_',
                                           other=('e90w_other', 'e90w_other_text'))])))
        out.append(('floor', pr('e9_carport_floor', 'CARPORT_FLOOR', 'Floor: The floor is formed in', 'Condition: Where visible, the structure appears',
                                 after='Carport: The property incorporates', subs={FLOOR: '{E9_FLOOR_FINISH}'},
                                 tokens=[ck('{E9_FLOOR_FINISH}', 'Floor formed in', FLOOR, 'e90f_',
                                            other=('e90f_other', 'e90f_other_text'))])))
        out.append(('condition', pr('e9_carport_cond', 'CARPORT_CONDITION', 'Condition: Where visible, the structure appears',
                                     'Porch Canopy:', after='Carport: The property incorporates', subs={COND_LIST: '{E9_CONDITION}'},
                                     tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')])))
    elif t == 'porch':
        out.append(('construction', pr('e9_porch', 'PORCH', 'Porch Canopy: The property incorporates', 'Roof: The roof covering comprises',
                                        subs={'timber, steel, concrete, plastic, other': '{E9_PORCH_MATERIALS}'},
                                        tokens=[ck('{E9_PORCH_MATERIALS}', 'Canopy constructed of', 'timber, steel, concrete, plastic, other',
                                                   'e91c_', other=('e91c_other', 'e91c_other_text'))])))
        rl = 'tiles, slates, felt, polycarbonate, plastic, other'
        out.append(('roof', pr('e9_porch_roof', 'PORCH_ROOF', 'Roof: The roof covering comprises', 'Condition: Where visible, the canopy appears',
                                subs={rl: '{E9_ROOF_COVERING}'},
                                tokens=[ck('{E9_ROOF_COVERING}', 'Roof covering comprises', rl, 'e91r_',
                                           other=('e91r_other', 'e91r_other_text'))])))
        out.append(('condition', pr('e9_porch_cond', 'PORCH_CONDITION', 'Condition: Where visible, the canopy appears', 'Juliet Balcony:',
                                     subs={COND_LIST: '{E9_CONDITION}'}, tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')])))
    elif t == 'juliet':
        out.append(('construction', pr('e9_juliet', 'JULIET', 'Juliet Balcony: The property incorporates', 'Condition: Where visible, it appears',
                                        subs={'steel, aluminium, glass, other': '{E9_JULIET_MATERIALS}'},
                                        tokens=[ck('{E9_JULIET_MATERIALS}', 'Juliet balcony formed in', 'steel, aluminium, glass, other',
                                                   'e94c_', other=('e94c_other', 'e94c_other_text'))])))
        out.append(('condition', pr('e9_juliet_cond', 'JULIET_CONDITION', 'Condition: Where visible, it appears', 'Balcony: The property incorporates',
                                     subs={COND_LIST: '{E9_CONDITION}'}, tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')])))
    elif t == 'balcony':
        a = 'Balcony: The property incorporates'
        out.append(('construction', pr('e9_balcony', 'BALCONY', a, 'Walls: The walls or balustrades are formed in',
                                        subs={'timber, steel, concrete, cantilevered': '{E9_BALCONY_TYPES}'},
                                        tokens=[ck('{E9_BALCONY_TYPES}', 'Balcony', 'timber, steel, concrete, cantilevered', 'e93c_')])))
        out.append(('wall', pr('e9_balcony_walls', 'BALCONY_WALLS', 'Walls: The walls or balustrades are formed in',
                                'Floor: The floor is formed in', after=a, subs={WALLS: '{E9_WALL_MATERIALS}'},
                                tokens=[ck('{E9_WALL_MATERIALS}', 'Walls or balustrades formed in', WALLS, 'e93w_',
                                           other=('e93w_other', 'e93w_other_text'))])))
        out.append(('floor', pr('e9_balcony_floor', 'BALCONY_FLOOR', 'Floor: The floor is formed in', 'Drains: The drains are laid with',
                                 after=a, subs={FLOOR: '{E9_FLOOR_FINISH}'},
                                 tokens=[ck('{E9_FLOOR_FINISH}', 'Floor formed in', FLOOR, 'e93f_',
                                            other=('e93f_other', 'e93f_other_text'))])))
        out.append(('drains', pr('e9_balcony_drains', 'BALCONY_DRAINS', 'Drains: The drains are laid with',
                                  'Condition: Where visible, the structure appears', after=a,
                                  subs={'bitumen, felt, concrete, other': '{E9_DRAIN_MATERIALS}',
                                        'well drained, poorly drained, unobstructed, obstructed': '{E9_DRAIN_STATE}'},
                                  tokens=[ck('{E9_DRAIN_MATERIALS}', 'Drains laid with', 'bitumen, felt, concrete, other', 'e93d_',
                                             other=('e93d_other', 'e93d_other_text')),
                                          ck('{E9_DRAIN_STATE}', 'Drains appear', 'well drained, poorly drained, unobstructed, obstructed',
                                             'e93s_')])))
        out.append(('condition', pr('e9_balcony_cond', 'BALCONY_CONDITION', 'Condition: Where visible, the structure appears',
                                     'Roof Terrace:', after=a, subs={COND_LIST: '{E9_CONDITION}'},
                                     tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')])))
    elif t == 'terrace':
        a = 'Roof Terrace: The property incorporates'
        out.append(('construction', pr('e9_terrace', 'TERRACE', a, 'Roof: The roof is of',
                                        subs={'timber, concrete, steel, other': '{E9_TERRACE_MATERIALS}'},
                                        tokens=[ck('{E9_TERRACE_MATERIALS}', 'Structure formed in', 'timber, concrete, steel, other',
                                                   'e92c_', other=('e92c_other', 'e92c_other_text'))])))
        rl1, rl2 = 'pitched, flat, lean-to', 'tiles, slates, felt, polycarbonate, metal sheeting, other'
        out.append(('roof', pr('e9_terrace_roof', 'TERRACE_ROOF', 'Roof: The roof is of', 'Walls: The walls or balustrades are formed in',
                                after=a, subs={rl1: '{E9_ROOF_SHAPE}', rl2: '{E9_ROOF_COVERING}'},
                                tokens=[ck('{E9_ROOF_SHAPE}', 'Roof construction', rl1, 'e92rs_'),
                                        ck('{E9_ROOF_COVERING}', 'Covered with', rl2, 'e92rc_',
                                           other=('e92rc_other', 'e92rc_other_text'))])))
        out.append(('wall', pr('e9_terrace_walls', 'TERRACE_WALLS', 'Walls: The walls or balustrades are formed in',
                                'Floor: The floor is formed in', after=a, subs={WALLS: '{E9_WALL_MATERIALS}'},
                                tokens=[ck('{E9_WALL_MATERIALS}', 'Walls or balustrades formed in', WALLS, 'e92w_',
                                           other=('e92w_other', 'e92w_other_text'))])))
        out.append(('floor', pr('e9_terrace_floor', 'TERRACE_FLOOR', 'Floor: The floor is formed in', 'Drains: The drains are laid with',
                                 after=a, subs={FLOOR: '{E9_FLOOR_FINISH}'},
                                 tokens=[ck('{E9_FLOOR_FINISH}', 'Floor formed in', FLOOR, 'e92f_',
                                            other=('e92f_other', 'e92f_other_text'))])))
        out.append(('drains', pr('e9_terrace_drains', 'TERRACE_DRAINS', 'Drains: The drains are laid with',
                                  'Condition: Where visible, the structure appears', after=a,
                                  subs={'bitumen, felt, concrete or other suitable materials': '{E9_DRAIN_MATERIALS}',
                                        'well drained, poorly drained, unobstructed, obstructed': '{E9_DRAIN_STATE}'},
                                  tokens=[ck('{E9_DRAIN_MATERIALS}', 'Drains laid with', 'bitumen, felt, concrete or other suitable materials'.replace(' or other suitable materials', ''), 'e92d_',
                                             other=('e92d_other', 'e92d_other_text')),
                                          ck('{E9_DRAIN_STATE}', 'Drains appear', 'well drained, poorly drained, unobstructed, obstructed',
                                             'e92s_')])))
        out.append(('condition', pr('e9_terrace_cond', 'TERRACE_CONDITION', 'Condition: Where visible, the structure appears',
                                     'External Staircase:', after=a, subs={COND_LIST: '{E9_CONDITION}'},
                                     tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')])))
    elif t == 'stairs':
        a = 'External Staircase: The property incorporates'
        out.append(('construction', pr('e9_stairs', 'STAIRS', a, 'Element (s):',
                                        subs={'concrete, steel, timber, brick, other': '{E9_STAIR_MATERIALS}'},
                                        tokens=[ck('{E9_STAIR_MATERIALS}', 'Staircase constructed of', 'concrete, steel, timber, brick, other',
                                                   'e95c_', other=('e95c_other', 'e95c_other_text'))])))
        out.append(('handrails', pr('e9_stairs_elements', 'STAIRS_ELEMENTS', 'Element (s):', 'Condition: Where visible, the staircase appears',
                                     subs={'steel, timber, aluminium, other': '{E9_STAIR_ELEMENT_MATERIALS}'},
                                     tokens=[ck('{E9_STAIR_ELEMENT_MATERIALS}', 'Handrails, landing and steps formed in',
                                                'steel, timber, aluminium, other', 'e95e_', other=('e95e_other', 'e95e_other_text'))])))
        out.append(('condition', pr('e9_stairs_cond', 'STAIRS_CONDITION', 'Condition: Where visible, the staircase appears',
                                     'Retaining Walls:', subs={COND_LIST: '{E9_CONDITION}'},
                                     tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')])))
    elif t == 'other':
        a = 'Other External Structures:'
        ol = 'bin stores, cycle stores, garden walls, pergolas, gazebos, covered walkways, storage compounds, other'
        out.append(('construction', pr('e9_other', 'OTHER', a, 'Condition: Where visible, these appear in good, reasonable, fair, poor, very poor condition. Routine',
                                        subs={ol: '{E9_OTHER_STRUCTURES}'},
                                        tokens=[ck('{E9_OTHER_STRUCTURES}', 'Other external structures include', ol, 'e96c_',
                                                   other=('e96c_other', 'e96c_other_text'))])))
        out.append(('condition', pr('e9_other_cond', 'OTHER_CONDITION',
                                     'Condition: Where visible, these appear in good, reasonable, fair, poor, very poor condition. Routine',
                                     'Repairs Roof:', subs={COND_LIST: '{E9_CONDITION}'},
                                     tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')])))
    return out


for i in range(7):
    kept = KEEP[i]
    by_kind = dict(rules_for(i))
    for kind in kept:
        rl = by_kind.get(kind)
        if not rl:
            continue
        slices.append({'screen': sid(kind, i), 'replace_all': True, 'keep': [], 'rules': [rl]})

# fix up: carport floor end marker must end at the next structure heading (Condition ... is next) -- handled above.

# ───────────── Retaining walls (new screens in the "Other" group) ─────────────
RW = 'brick, stone, concrete, gabion, timber'
RWD = 'movement, bulging, instability, damage, other'
G_OTHER = 'group_other_41'
S_RW = P_ + 'retaining_walls'
S_RWD = P_ + 'retaining_walls_defects'
RWC = P_ + 'retaining_walls_condition'
slices.append({
    'screen': S_RW, 'new_screen': {'id': S_RW, 'title': 'Retaining walls', 'parent': G_OTHER, 'order': 30, 'after': sid('condition', 6)},
    'rules': [
        pr('e9_rw', 'RETAINING', 'Retaining Walls: The property incorporates', 'Condition: Where visible, these appear in good, reasonable, fair, poor, very poor condition. No defects',
           subs={RW: '{E9_RW_MATERIALS}'},
           tokens=[ck('{E9_RW_MATERIALS}', 'Retaining walls', RW, 'e9rw_')]),
        pr('e9_rw_cond', 'RETAINING_CONDITION',
           'Condition: Where visible, these appear in good, reasonable, fair, poor, very poor condition. No defects', 'Defects noted:',
           subs={COND_LIST: '{E9_CONDITION}'}, tokens=[cond_dd('{E9_CONDITION}', 'actv_weather_condition')]),
    ]})
slices.append({
    'screen': S_RWD, 'new_screen': {'id': S_RWD, 'title': 'Retaining walls defects', 'parent': G_OTHER, 'order': 31, 'after': S_RW},
    'rules': [pr('e9_rw_defects', 'RETAINING_DEFECTS', 'Defects noted:', 'Other External Structures:',
                 subs={RWD: '{E9_RW_DEFECTS}'},
                 tokens=[ck('{E9_RW_DEFECTS}', 'Evidence of', RWD, 'e9rd_', other=('e9rd_other', 'e9rd_other_text'))])]})

# ───────────── Communal area ─────────────
CA = ('communal entrances, access roads, parking areas, footpaths, landscaped areas, boundary structures, security '
      'gates, CCTV, lighting, bin stores, cycle stores, other facilities')
slices.append({
    'screen': P_ + 'communal_area', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e9_communal', 'COMMUNAL', 'Description: Where applicable, the external communal areas', 'Condition: Where visible, these appear in good',
           subs={CA: '{E9_COMMUNAL}'},
           tokens=[ck('{E9_COMMUNAL}', 'External communal areas', CA.replace(', other facilities', ', other'), 'e9ca_',
                      other=('e9ca_other', 'e9ca_other_text'))]),
        pr('e9_communal_cond', 'COMMUNAL_CONDITION', 'Condition: Where visible, these appear in good', 'Carport:',
           subs={COND_LIST: '{E9_CONDITION}'}, tokens=[cond_dd('{E9_CONDITION}', 'actv_condition')]),
    ]})

# ───────────── Repairs (one set, shared by every structure) ─────────────
R_ROOF_S = 'carport, balcony, canopy, other'
R_ROOF_D = 'missing, slipped, cracked, lifted, in disrepair, leaking, damaged, poorly secured, dilapidated, other'
R_WALL_S = 'balcony, carport, roof terrace, staircase, other'
R_WALL_D = 'are cracked, are damaged, are unstable, have eroded render, other'
R_FLOOR_S = 'balcony, carport, roof terrace, staircase floor'
R_FLOOR_D = 'split, cracked, other'
R_DR_S = 'balcony, carport, roof terrace, staircase, other'
R_DR_D = 'too small, blocked, poorly drained, damaged, other'
R_HR_S = 'balcony, Juliet balcony, terrace, stairs, other'
R_HR_D = 'inadequate, poorly secured, incomplete, loose, corroded, rotten, damaged, other'
R_ST_D = 'split, cracked, partly rotted, rusted, defective'
R_DEC_D = 'peeling, flaking, damaged, other'


def rep(kind, rid, start, end, subs, toks):
    return {'screen': sid(kind, 0), 'replace_all': True, 'keep': [],
            'rules': [pr(rid, rid.upper(), start, end, subs=subs, tokens=toks)]}


slices += [
    rep('r_roof', 'e9_r_roof', 'Repairs Roof:', 'Walls: The balcony, carport',
        {R_ROOF_S: '{E9_R_STRUCTURES}', R_ROOF_D: '{E9_R_DEFECTS}'},
        [ck('{E9_R_STRUCTURES}', 'Roof over', R_ROOF_S, 'e9rr_s_', other=('e9rr_s_other', 'e9rr_s_other_text')),
         ck('{E9_R_DEFECTS}', 'Defects', R_ROOF_D, 'e9rr_d_', other=('e9rr_d_other', 'e9rr_d_other_text'))]),
    rep('r_wall', 'e9_r_wall', 'Walls: The balcony, carport', 'Floor: The floor surface',
        {R_WALL_S: '{E9_R_STRUCTURES}', R_WALL_D: '{E9_R_DEFECTS}'},
        [ck('{E9_R_STRUCTURES}', 'Wall(s) of', R_WALL_S, 'e9rw_s_', other=('e9rw_s_other', 'e9rw_s_other_text')),
         ck('{E9_R_DEFECTS}', 'Defects', R_WALL_D, 'e9rw_d_', other=('e9rw_d_other', 'e9rw_d_other_text'))]),
    rep('r_floor', 'e9_r_floor', 'Floor: The floor surface', 'Drains: The balcony',
        {R_FLOOR_S: '{E9_R_STRUCTURES}', R_FLOOR_D: '{E9_R_DEFECTS}'},
        [ck('{E9_R_STRUCTURES}', 'Floor of', R_FLOOR_S, 'e9rf_s_'),
         ck('{E9_R_DEFECTS}', 'Defects', R_FLOOR_D, 'e9rf_d_', other=('e9rf_d_other', 'e9rf_d_other_text'))]),
    rep('r_drains', 'e9_r_drains', 'Drains: The balcony', 'Handrails: The handrail(s)',
        {R_DR_S: '{E9_R_STRUCTURES}', R_DR_D: '{E9_R_DEFECTS}'},
        [ck('{E9_R_STRUCTURES}', 'Drains of', R_DR_S, 'e9rd_s_', other=('e9rd_s_other', 'e9rd_s_other_text')),
         ck('{E9_R_DEFECTS}', 'Defects', R_DR_D, 'e9rd_d_', other=('e9rd_d_other', 'e9rd_d_other_text'))]),
    rep('r_rails', 'e9_r_rails', 'Handrails: The handrail(s)', 'Metal Stairs:',
        {R_HR_S: '{E9_R_STRUCTURES}', R_HR_D: '{E9_R_DEFECTS}'},
        [ck('{E9_R_STRUCTURES}', 'Handrail(s) of', R_HR_S, 'e9rh_s_', other=('e9rh_s_other', 'e9rh_s_other_text')),
         ck('{E9_R_DEFECTS}', 'Defects', R_HR_D, 'e9rh_d_', other=('e9rh_d_other', 'e9rh_d_other_text'))]),
    rep('r_steps', 'e9_r_steps', 'Metal Stairs:', 'Decorations: The decorations',
        {R_ST_D: '{E9_R_DEFECTS}'}, [ck('{E9_R_DEFECTS}', 'Defects', R_ST_D, 'e9rs_d_')]),
    rep('r_decor', 'e9_r_decor', 'Decorations: The decorations', 'General Maintenance:',
        {R_DEC_D: '{E9_R_DEFECTS}'},
        [ck('{E9_R_DEFECTS}', 'Defects', R_DEC_D, 'e9rn_d_', other=('e9rn_d_other', 'e9rn_d_other_text'))]),
]

# ───────────── Main screen: intro (rating-gated) + general maintenance ─────────────
slices.append({
    'screen': P_ + 'main_screen', 'rules': [
        pr('e9_intro', 'INTRO', 'The inspection was limited to those parts', 'Description: Where applicable, the external communal areas',
           first=True, when=[RATING[0], RATING[1]], when_any=RATING[2]),
        pr('e9_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'If the property is a flat', when=['cb_general_maintenance', 'true'],
           extra=[{'id': 'cb_general_maintenance', 'label': 'General maintenance', 'type': 'checkbox'}]),
    ]})

# ───────────── Retired screens ─────────────
retire = []
for i in range(7):
    for kind in ['construction', 'roof', 'wall', 'floor', 'drains', 'handrails', 'overloaded', 'noglass', 'condition']:
        if kind not in KEEP[i]:
            retire.append(sid(kind, i))
    if i > 0:
        for kind in ['r_wall', 'r_roof', 'r_floor', 'r_drains', 'r_rails', 'r_steps', 'r_decor']:
            retire.append(sid(kind, i))
retire += [P_ + 'not_inspected', P_ + 'overloaded__overloaded__7', P_ + 'no_safety_glass__no_safety_glass__7']
slices.append({'remove_screens': retire})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules,', len(retire), 'retired')
