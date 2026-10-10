# -*- coding: utf-8 -*-
"""Generate slices/e8_e.json (E8 Other joinery and finishes). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e8_e.json')
S = 'E8'
MW = '{E_OTHER_JOINERY_AND_FINISHES}'
G = 'group_e8_other_joinery_and_finishes_31'
BASE = 'activity_outside_property_other_joinery_and_finishes_'
MAIN = BASE + 'main_screen'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATED = [['actv_condition', '2'], ['actv_condition', '3']]


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{E8_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': G, 'order': order, 'after': after}


slices = []

MAT = 'timber, PVCu, aluminium, asbestos board, cement board, fibre cement, slates, other'
DEC = 'good, reasonable, fair, weathered, poor'
slices.append({
    'screen': MAIN, 'replace_all': True, 'keep': ['actv_condition'],
    'rules': [
        pr('e8_inspected', 'INSPECTED', 'Inspected:', 'Description: The external eaves-level', first=True,
           when=['actv_condition', '1'], when_any=RATED),
        pr('e8_desc', 'DESCRIPTION', 'Description: The external eaves-level', 'Decorations:', subs={MAT: '{JOINERY_MATERIALS}'},
           tokens=[ck('{JOINERY_MATERIALS}', 'Joinery comprises', MAT, 'e8m_', other=('cb_other_397', 'et_other_393'))]),
        pr('e8_decorations', 'DECORATIONS', 'Decorations:', 'Condition: Where visible, these elements',
           subs={DEC: '{JOINERY_DECORATIONS}'},
           tokens=[dd('{JOINERY_DECORATIONS}', 'actv_decorations', 'Decorations', ['Good', 'Reasonable', 'Fair', 'Weathered', 'Poor'],
                      lower=True)]),
        pr('e8_condition', 'CONDITION', 'Condition: Where visible, these elements', 'Repair:', subs={COND_LIST: '{JOINERY_CONDITION}'},
           tokens=[dd('{JOINERY_CONDITION}', 'actv_joinery_condition', 'Condition', COND5, lower=True)]),
        pr('e8_asbestos', 'ASBESTOS_CEMENT', 'Asbestos Cement Components:', 'Defective Joinery', when=['cb_open_runoffs', 'true'],
           extra=[{'id': 'cb_open_runoffs', 'label': 'Contains asbestos cement components', 'type': 'checkbox'}]),
        pr('e8_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
           extra=[{'id': 'cb_general_maintenance', 'label': 'General maintenance', 'type': 'checkbox'}]),
    ]})

IT = 'fascias, soffits, barge boards, verge clips, timber cladding, other'
LC = 'main building, back addition, extension, bay window, garage, other'
DF = 'rotted, damaged, poorly secured, incomplete, missing, other'
slices.append({
    'screen': BASE + 'repairs', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e8_repair', 'REPAIR', 'Repair:', 'Hazards:', subs={IT: '{JOINERY_ITEMS}', LC: '{JOINERY_LOCATIONS}', DF: '{JOINERY_DEFECTS}'},
           tokens=[ck('{JOINERY_ITEMS}', 'Item', IT, 'e8i_', other=('cb_other_289', 'et_other_178')),
                   ck('{JOINERY_LOCATIONS}', 'Location', LC, 'e8l_', other=('cb_other_269', 'et_other_567')),
                   ck('{JOINERY_DEFECTS}', 'Defect', DF, 'e8d_', other=('cb_other_777', 'et_other_473'))]),
        pr('e8_hazard', 'HAZARD', 'Hazards:', 'Timber Weathering:', when=['cb_safety_hazard', 'true'],
           extra=[{'id': 'cb_safety_hazard', 'label': 'Safety hazard', 'type': 'checkbox'}]),
    ]})

S_NI = BASE.replace('and_finishes_', 'finishes_') + 'not_inspected'
slices.append({
    'screen': 'activity_outside_property_other_joinery_finishes_not_inspected',
    'rules': [pr('e8_not_inspected', 'NOT_INSPECTED', 'Not Inspected:', 'Inspected:', when=['cb_not_inspected', 'true'])]})

S_TW = BASE + 'timber_weathering'
slices.append({
    'screen': S_TW, 'new_screen': new_screen(S_TW, 'Timber weathering', 8, BASE + 'repairs'),
    'rules': [pr('e8_weathering', 'TIMBER_WEATHERING', 'Timber Weathering:', 'Timber Decay:',
                 subs={'minor, moderate, significant': '{WEATHERING_LEVEL}'},
                 tokens=[dd('{WEATHERING_LEVEL}', 'actv_weathering', 'Weathering', ['Minor', 'Moderate', 'Significant'], lower=True)])]})
TDC = 'Localised wet rot, surface decay, timber deterioration'
S_TD = BASE + 'timber_decay'
slices.append({
    'screen': S_TD, 'new_screen': new_screen(S_TD, 'Timber decay', 10, S_TW),
    'rules': [pr('e8_decay', 'TIMBER_DECAY', 'Timber Decay:', 'Asbestos Cement Components:', subs={TDC: '{TIMBER_DECAY_SIGNS}'},
                 tokens=[checks('{TIMBER_DECAY_SIGNS}', 'Observed', opts('e8td_', [x.lower() for x in TDC.split(', ')]), cap=True)])]})
B = '•'
DJ = ['Loose fascias', 'Loose soffits', 'Damaged bargeboards', 'Open joints', 'Defective fixings', 'Weathered decoration',
      'Localised timber decay', 'Distorted joinery', 'Minor impact damage']
S_DJ = BASE + 'defective_joinery'
slices.append({
    'screen': S_DJ, 'new_screen': new_screen(S_DJ, 'Defective joinery', 12, S_TD),
    'rules': [pr('e8_defective', 'DEFECTIVE_JOINERY', 'Defective Joinery', 'If the property is a flat',
                 subs={' '.join(f'{B} {x}' for x in DJ): '{JOINERY_DEFECT_LIST}'},
                 tokens=[checks('{JOINERY_DEFECT_LIST}', 'One or more defects were observed, including',
                                opts('e8dj_', [x.lower() for x in DJ]))])]})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
