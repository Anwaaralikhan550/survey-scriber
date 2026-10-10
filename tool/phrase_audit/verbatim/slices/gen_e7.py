# -*- coding: utf-8 -*-
"""Generate slices/e7_e.json (E7 Conservatory and porches). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e7_e.json')
S = 'E7'
MW = '{E_CONSERVATORY_PORCHES}'
BASE = 'activity_outside_property_'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
LOC = 'front, side, rear, other'
WALLS = ('single-glazed, double-glazed, triple-glazed, PVC framed, timber framed, aluminium framed, steel framed, '
         'other')
ROOF = 'glass, polycarbonate sheets, solid insulated panels, roofing tiles, other'
DW = 'single-glazed, double-glazed, triple-glazed, PVC, timber, aluminium, steel-framed'
FLC = 'solid concrete, suspended timber, other'
FLV = 'timber, carpet, tiles, laminated flooring, vinyl, other'


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cond_dd(token, fid='actv_condition'):
    return dd(token, fid, 'Condition', COND5, lower=True)


KINDS = [
    # tag, name, after-anchor, screen id suffixes, text starts
    dict(tag='c', name='Conservatory', aft=None, sfx=dict(loc='', roof='', doors='', floor='', cond='', safety='',
                                                         open='', poor=''),
         loc_start='Conservatory: The conservatory(s) is located', br_start='Building Regulations: The conservatory appears',
         br_end='Porch: The porch(s) located', dw_start='Doors and Windows: The conservatory comprises',
         vp_start='If very poor condition is selected, add this:', cond_end='If very poor condition is selected',
         vp_end='Repair conservatory:'),
    dict(tag='p', name='Porch', aft='Porch: The porch(s) located',
         sfx=dict(loc='__location_and_construction', roof='__roof', doors='__doors', floor='__floor', cond='__condition',
                  safety='__safety_glass_rating', open='__open_to_building', poor='__poor_condition'),
         loc_start='Porch: The porch(s) located', br_start='Building Regulations: The porch appears',
         br_end='Condition rating', dw_start='Doors and Windows: The porch comprises',
         vp_start='If very poor is selected, add this:', cond_end='If very poor is selected', vp_end='Repair porch:'),
]
SCR = dict(loc=BASE + 'conservatory_porch_location_construction', roof=BASE + 'conservatory_porch_roof',
           doors=BASE + 'conservatory_porch_doors', floor=BASE + 'conservatory_porch_floor',
           cond=BASE + 'porch_condition', safety=BASE + 'conservatory_porch_safety_glass_rating',
           open=BASE + 'porch_open_to_building', poor=BASE + 'porch_poor_condition')

slices = []
for k in KINDS:
    t, nm, aft = k['tag'], k['name'], k['aft']
    sid = {key: SCR[key] + k['sfx'][key] for key in SCR}

    def pr(rid, sub, start, end, **kw):
        return para_rule(S, f'e7{t}_{rid}', [MW], f'{{E7_{t.upper()}_{sub}}}', start, end, after=aft, **kw)

    slices.append({'screen': sid['loc'], 'replace_all': True, 'keep': [], 'rules': [
        pr('loc', 'LOCATION', k['loc_start'], 'Roof: The roof is formed in', subs={LOC: '{CP_LOCATIONS}', WALLS: '{CP_WALLS}'},
           tokens=[ck('{CP_LOCATIONS}', f'{nm} located to', LOC, f'e7{t}l_', other=(f'e7{t}l_other', f'e7{t}l_other_text')),
                   ck('{CP_WALLS}', 'Walls comprise', WALLS, f'e7{t}w_', other=(f'e7{t}w_other', f'e7{t}w_other_text'))]),
        pr('bregs', 'BUILDING_REGULATIONS', k['br_start'], k['br_end'], when=['cb_building_regulations', 'true'],
           extra=[{'id': 'cb_building_regulations', 'label': 'Building Regulations', 'type': 'checkbox'}]),
    ]})
    slices.append({'screen': sid['roof'], 'replace_all': True, 'keep': [], 'rules': [
        pr('roof', 'ROOF', 'Roof: The roof is formed in', 'Doors and Windows:', subs={ROOF: '{CP_ROOF_MATERIALS}'},
           tokens=[ck('{CP_ROOF_MATERIALS}', 'Roof formed in', ROOF, f'e7{t}r_', other=(f'e7{t}r_other', f'e7{t}r_other_text'))]),
    ]})
    slices.append({'screen': sid['doors'], 'replace_all': True, 'keep': [], 'rules': [
        pr('doors', 'DOORS_WINDOWS', k['dw_start'], 'Floor: The floor is of', subs={DW: '{CP_DOORS_WINDOWS}'},
           tokens=[ck('{CP_DOORS_WINDOWS}', 'Doors and windows', DW, f'e7{t}d_')]),
    ]})
    slices.append({'screen': sid['floor'], 'replace_all': True, 'keep': [], 'rules': [
        pr('floor', 'FLOOR', 'Floor: The floor is of', 'No BS EN noted:',
           subs={FLC: '{CP_FLOOR_CONSTRUCTION}', FLV: '{CP_FLOOR_COVERING}'},
           tokens=[ck('{CP_FLOOR_CONSTRUCTION}', 'Floor is of', FLC, f'e7{t}fc_', other=(f'e7{t}fc_other', f'e7{t}fc_other_text')),
                   ck('{CP_FLOOR_COVERING}', 'Floor covered with', FLV, f'e7{t}fv_', other=(f'e7{t}fv_other', f'e7{t}fv_other_text'))]),
    ]})
    slices.append({'screen': sid['safety'], 'replace_all': True, 'keep': [], 'rules': [
        pr('bs_no', 'NO_BS_EN', 'No BS EN noted: No visible', 'BS EN noted: Visible', when=['actv_status', 'No BS EN noted'],
           extra=[{'id': 'actv_status', 'label': 'Safety glass markings', 'type': 'dropdown',
                   'options': ['No BS EN noted', 'BS EN noted']}]),
        pr('bs_yes', 'BS_EN_NOTED', 'BS EN noted: Visible', 'Condition: Where visible and operated',
           when=['actv_status', 'BS EN noted']),
    ]})
    slices.append({'screen': sid['cond'], 'replace_all': True, 'keep': [], 'rules': [
        pr('cond', 'CONDITION', 'Condition: Where visible and operated', k['cond_end'], subs={COND_LIST: '{CP_CONDITION}'},
           tokens=[cond_dd('{CP_CONDITION}')]),
        pr('vpoor', 'VERY_POOR', k['vp_start'], k['vp_end'], drop=k['vp_start'], when=['actv_condition', 'Very poor']),
    ]})
    slices.append({'screen': sid['poor'], 'replace_all': True, 'keep': [], 'rules': [
        pr('unstable', 'UNSTABLE', 'Unstable Structure:', 'Building Joint Defects:', when=['cb_not_inspected', 'true'],
           extra=[{'id': 'cb_not_inspected', 'label': 'Unstable structure', 'type': 'checkbox'}]),
    ]})
    slices.append({'screen': sid['open'], 'replace_all': True, 'keep': [], 'rules': [
        pr('joint', 'JOINT_DEFECTS', 'Building Joint Defects:', 'Building Regulations:', when=['cb_not_inspected', 'true'],
           extra=[{'id': 'cb_not_inspected', 'label': 'Building joint defects', 'type': 'checkbox'}]),
    ]})

# ───────────── Repairs: one screen, Conservatory / Porch ─────────────
RC_EL = 'door(s), window(s), glazing, roof, floor, wall(s), rainwater goods, other'
RC_DF = 'cracked, damaged, rotten, leaking, damp, have failed, are misted, present a safety hazard, other'
RP_EL = 'door, window(s), glazing, roof, floor, wall(s), rainwater goods, other'
RP_DF = 'cracked, damaged, rotten, leaking, damp, have failed, are misted over, present a safety hazard, other'
REP_DD = {'id': 'actv_cp', 'label': 'Repair of', 'type': 'dropdown', 'options': ['Conservatory', 'Porch']}


def rep(t, nm, start, el, df, extra):
    c = f'actv_cp={nm}'
    return para_rule(S, f'e7{t}_repair', [MW], f'{{E7_{t.upper()}_REPAIR}}', start, 'Unstable Structure:',
                     subs={el: '{CP_REPAIR_ELEMENTS}', df: '{CP_REPAIR_DEFECTS}'}, when=['actv_cp', nm], extra=extra,
                     tokens=[ck('{CP_REPAIR_ELEMENTS}', f'{nm} elements', el, f'e7{t}re_', other=(f'e7{t}re_other', f'e7{t}re_other_text'), cond=c),
                             ck('{CP_REPAIR_DEFECTS}', 'Defects', df, f'e7{t}rd_', other=(f'e7{t}rd_other', f'e7{t}rd_other_text'), cond=c)])


slices.append({
    'screen': BASE + 'conservatory_porch_repairs', 'replace_all': True, 'keep': [], 'set_title': 'Repair conservatory or porch',
    'rules': [rep('c', 'Conservatory', 'Repair conservatory:', RC_EL, RC_DF, [REP_DD]),
              rep('p', 'Porch', 'Repair porch:', RP_EL, RP_DF, None)]})

# ───────────── Not applicable ─────────────
slices.append({
    'screen': BASE + 'conservatory_porch_not_inspected', 'replace_all': True, 'keep': [],
    'rules': [para_rule(S, 'e7_not_applicable', [MW], '{NOT_INSPECTED_NOT_APPLICABLE}', 'Not Applicable:',
                        'This section applies where', when=['cb_not_applicable', 'true'],
                        extra=[{'id': 'cb_not_applicable', 'label': 'Not applicable', 'type': 'checkbox'}])]})

RETIRE = [BASE + 'conservatory_porch_windows', BASE + 'conservatory_porch_windows__windows',
          'outside_property_conservatory_porch_flashing_layout',
          'outside_property_conservatory_porch_flashing_layout__roof_flashing_with_wall']
RETIRE += [BASE + 'conservatory_porch_repairs__' + x for x in
           ['walls', 'windows', 'door_glazing', 'window_glazing', 'roof_glazing', 'floor', 'rainwater_goods']]
slices.append({'remove_screens': RETIRE})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
