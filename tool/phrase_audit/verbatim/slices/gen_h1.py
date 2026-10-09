# -*- coding: utf-8 -*-
"""Generate slices/h1_e.json (H1 Garage). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (checks, dd, lst, opts, para_rule)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'h1_e.json')
S = 'H1'
MW = '{H_GARAGE}'
ABOUT = 'activity_grounds_garage'
REPAIR = 'activity_grounds_garage_garage_repair'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{H1_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def oth(p):
    return (p + 'other', p + 'other_text')


CV = 'habitable accommodation, an office, a workshop, other'
DE = 'a garage in a block of garages, an attached, a detached, an integral, garage, undercroft, other'
WA = 'single skin brick, cavity brick, block, prefabricated concrete, timber frame, steel frame, other'
RT = 'pitched, flat, lean-to, other'
RC = ('clay tiles, concrete tiles, slates, felt sheets, asbestos sheets, rubber membrane, single-ply membrane, '
      'GRP fibreglass, asphalt, metal sheets, plastic sheets, other')
FL = 'concrete, stone, other'
DO = 'manually, electrically operated up-and-over, roller shutter, side-hinged door, rear or side door, other'
DM = 'steel, timber, aluminium, uPVC, GRP (fibreglass), other'
MI = ('a leaking roof, cracked walls, rotten window frame(s), cracked glazing, a cracked floor, damaged door(s), '
      'other defects')
SI = ('a badly leaking roof, badly cracked or unstable walls, beetle infestation, damaged glazing, a badly cracked floor, '
      'door(s) in disrepair, other significant defects')
ASB = 'cb_corrugated_asbestos_sheets'   # id kept: report_builder's property-wide asbestos summary reads it
rc_opts = [(ASB, l) if l == 'asbestos sheets' else (i, l) for i, l in opts('h1rc_', lst(RC))]
COND = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_W = [['actv_condition', c] for c in COND[1:]]

slices = [
    {'screen': ABOUT, 'replace_all': True, 'keep': [], 'rules': [
        pr('h1_no_garage', 'NO_GARAGE', 'No garage:', 'Not Inspected:', when=['cb_h1_no_garage', 'true'],
           extra=[cb('cb_h1_no_garage', 'No garage')]),
        pr('h1_not_inspected', 'NOT_INSPECTED', 'Not Inspected:', 'Converted garage:', when=['cb_h1_not_inspected', 'true'],
           extra=[cb('cb_h1_not_inspected', 'Not inspected')]),
        pr('h1_converted', 'CONVERTED', 'Converted garage:', 'Shared Garage Access:', subs={CV: '{H1_CONVERTED_TO}'},
           when=['cb_h1_converted', 'true'], extra=[cb('cb_h1_converted', 'Converted garage')],
           tokens=[ck('{H1_CONVERTED_TO}', 'Converted into', CV, 'h1cv_', other=oth('h1cv_'))]),
        pr('h1_shared', 'SHARED_ACCESS', 'Shared Garage Access:', 'Description:', when=['cb_shared_access', 'true'],
           extra=[cb('cb_shared_access', 'Shared garage access')]),
        pr('h1_description', 'DESCRIPTION', 'Description:', 'Walls:', subs={DE: '{H1_GARAGE_TYPE}'},
           when=['cb_h1_description', 'true'], extra=[cb('cb_h1_description', 'Garage description')],
           tokens=[ck('{H1_GARAGE_TYPE}', 'Garage type', DE, 'h1d_', other=oth('h1d_'))]),
        pr('h1_walls', 'WALLS', 'Walls:', 'Roof:', subs={WA: '{H1_WALLS}'}, when=['cb_h1_walls', 'true'],
           extra=[cb('cb_h1_walls', 'Garage walls')],
           tokens=[ck('{H1_WALLS}', 'Walls constructed of', WA, 'h1w_', other=oth('h1w_'))]),
        pr('h1_roof', 'ROOF', 'Roof:', 'Garage Floor:', subs={RT: '{H1_ROOF_TYPE}', RC: '{H1_ROOF_COVER}'},
           when=['cb_h1_roof', 'true'], extra=[cb('cb_h1_roof', 'Garage roof')],
           tokens=[ck('{H1_ROOF_TYPE}', 'Roof construction', RT, 'h1rt_', other=oth('h1rt_')),
                   checks('{H1_ROOF_COVER}', 'Roof covered with', rc_opts, other=oth('h1rc_'))]),
        pr('h1_floor', 'FLOOR', 'Garage Floor:', 'Garage Doors:', subs={FL: '{H1_FLOOR}'}, when=['cb_h1_floor', 'true'],
           extra=[cb('cb_h1_floor', 'Garage floor')],
           tokens=[ck('{H1_FLOOR}', 'Floor constructed of', FL, 'h1f_', other=oth('h1f_'))]),
        pr('h1_doors', 'DOORS', 'Garage Doors:', 'Condition:', subs={DO: '{H1_DOOR_TYPE}', DM: '{H1_DOOR_MATERIAL}'},
           when=['cb_h1_doors', 'true'], extra=[cb('cb_h1_doors', 'Garage doors')],
           tokens=[ck('{H1_DOOR_TYPE}', 'Door operation / type', DO, 'h1do_', other=oth('h1do_')),
                   ck('{H1_DOOR_MATERIAL}', 'Door material', DM, 'h1dm_', other=oth('h1dm_'))]),
        pr('h1_condition', 'CONDITION', 'Condition:', 'No defects noted:',
           subs={'good, reasonable, fair, poor, very poor': '{H1_CONDITION}'},
           when=['actv_condition', COND[0]], when_any=COND_W,
           tokens=[dd('{H1_CONDITION}', 'actv_condition', 'Garage condition', COND, lower=True)]),
        pr('h1_no_defects', 'NO_DEFECTS_NOTED', 'No defects noted:', 'If felt sheets is selected',
           when=['cb_h1_no_defects', 'true'], extra=[cb('cb_h1_no_defects', 'No defects noted')]),
        pr('h1_felt', 'FELT_ROOF', 'Flat felt roofs have', 'If asbestos sheet is selected', when=['h1rc_felt_sheets', 'true']),
        pr('h1_asbestos', 'ASBESTOS_ROOF', 'The roof covering material appears to contain asbestos', 'Minor defects:',
           when=[ASB, 'true']),
    ]},
    {'screen': REPAIR, 'set_title': 'Garage Defects', 'replace_all': True, 'keep': [], 'rules': [
        pr('h1_minor', 'MINOR_DEFECTS', 'Minor defects:', 'Significant defects:', subs={MI: '{H1_MINOR_DEFECTS}'},
           when=['cb_h1_minor', 'true'], extra=[cb('cb_h1_minor', 'Minor defects')],
           tokens=[ck('{H1_MINOR_DEFECTS}', 'Minor defects noted', MI, 'h1mi_', other=oth('h1mi_'))]),
        pr('h1_significant', 'SIGNIFICANT_DEFECTS', 'Significant defects:', 'Safety hazard:',
           subs={SI: '{H1_SIGNIFICANT_DEFECTS}'}, when=['cb_h1_significant', 'true'],
           extra=[cb('cb_h1_significant', 'Significant defects')],
           tokens=[ck('{H1_SIGNIFICANT_DEFECTS}', 'Significant defects noted', SI, 'h1si_', other=oth('h1si_'))]),
        pr('h1_safety', 'SAFETY_HAZARD', 'Safety hazard:', 'Condition rating', when=['cb_is_safety_hazard', 'true'],
           extra=[cb('cb_is_safety_hazard', 'Safety hazard')]),
    ]},
    {'remove_screens': ['activity_grounds_garage_roof_timber_repair', 'activity_grounds_garage_safety_hazard_repair',
                        'activity_grounds_garage_not_inspected']},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
