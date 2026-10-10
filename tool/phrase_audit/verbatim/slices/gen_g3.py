# -*- coding: utf-8 -*-
"""Generate slices/g3_e.json (G3 Water). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (P, add_or_set, checks, dd, lst, opts, para_rule, set_keys)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'g3_e.json')
S = 'G3'
MW = '{G_WATER}'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{G3_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


# ── static text: the plumbing paragraph that closes the block (printed by report_builder via STANDARD_TEXT_2) ──
plumbing, _ = P(S, 'The visible water supply pipework', 'Condition rating')
set_keys([add_or_set('{G_WATER}::{STANDARD_TEXT_2}', plumbing)])

SL = 'under the stairs, under the kitchen sink, in the bathroom, in the hall, in the garage, other'
TL = 'roof space, airing cupboard, kitchen, other'
TM = 'plastic, galvanised steel, asbestos cement, other'
TC = 'reasonable, fair, poor'
TI = 'adequately insulated, inadequately insulated'
DT = 'damaged, not adequately supported, leaking, overflowing, other'
INS = 'actv_g3_tank_insulation'
SC = 'actv_g3_stopcock'
SC_DD = {'id': SC, 'label': 'Stopcock', 'type': 'dropdown', 'options': ['Stopcock found', 'Not found']}

slices = []
slices.append({'screen': 'activity_services_water_main_water', 'replace_all': True, 'keep': [], 'rules': [
    pr('g3_stopcock', 'STOPCOCK', 'Stopcock found:', 'Not found:', subs={SL: '{WATER_STOPCOCK_LOCATION}'},
       when=[SC, 'Stopcock found'], extra=[SC_DD],
       tokens=[ck('{WATER_STOPCOCK_LOCATION}', 'Stopcock located', SL, 'g3s_', other=('g3s_other', 'g3s_other_text'),
                  cond=SC + '=Stopcock found')]),
    pr('g3_not_found', 'STOPCOCK_NOT_FOUND', 'Not found:', 'Lead rising:', when=[SC, 'Not found']),
    pr('g3_lead', 'LEAD_RISING', 'Lead rising:', 'Water tank:', when=['cb_lead_rising', 'true'],
       extra=[cb('cb_lead_rising', 'Lead rising')]),
]})
slices.append({'screen': 'activity_services_water_water_tank', 'replace_all': True, 'keep': [], 'rules': [
    pr('g3_tank', 'WATER_TANK', 'Water tank:', 'Inadequate insulation:',
       subs={TL: '{WATER_TANK_LOCATION}', TM: '{WATER_TANK_MATERIAL}', TC: '{WATER_TANK_CONDITION}',
             TI: '{WATER_TANK_INSULATION}'},
       tokens=[checks('{WATER_TANK_LOCATION}', 'Cold water tank location',
                      [('cb_roof_space', 'roof space'), ('cb_airing_cupboard', 'airing cupboard'),
                       ('cb_kitchen', 'kitchen')], other=('cb_other_289', 'et_other_442')),
               checks('{WATER_TANK_MATERIAL}', 'Cold water tank material',
                      [('cb_plastic', 'plastic'), ('cb_galvanised_steel', 'galvanised steel'),
                       ('cb_asbestos', 'asbestos cement')], other=('cb_other_640', 'et_other_643')),
               dd('{WATER_TANK_CONDITION}', 'actv_condition', 'Tank condition', ['Reasonable', 'Fair', 'Poor'], lower=True),
               dd('{WATER_TANK_INSULATION}', INS, 'Tank and pipework insulation',
                  ['Adequately insulated', 'Inadequately insulated'], lower=True)]),
    pr('g3_inadequate', 'INADEQUATE_INSULATION', 'Inadequate insulation:', 'Damaged tank:',
       when=[INS, 'Inadequately insulated']),
]})
slices.append({'screen': 'activity_services_water_repair_main_screen', 'replace_all': True, 'keep': [], 'rules': [
    pr('g3_damaged', 'DAMAGED_TANK', 'Damaged tank:', 'Missing lid:', subs={DT: '{WATER_TANK_DEFECT}'},
       when=['cb_g3_damaged_tank', 'true'], extra=[cb('cb_g3_damaged_tank', 'Damaged tank')],
       tokens=[ck('{WATER_TANK_DEFECT}', 'Tank defect', DT, 'g3d_', other=('g3d_other', 'g3d_other_text'))]),
    pr('g3_lid', 'MISSING_LID', 'Missing lid:', 'Asbestos cement tank:', when=['cb_no_lid_over_tank', 'true'],
       extra=[cb('cb_no_lid_over_tank', 'Missing lid')]),
    pr('g3_asbestos', 'ASBESTOS_TANK', 'Asbestos cement tank:', 'The visible water supply pipework',
       when=['cb_asbestos_material', 'true'], extra=[cb('cb_asbestos_material', 'Asbestos cement tank')]),
]})
slices.append({'remove_screens': ['activity_services_water_not_inspected', 'activity_services_water_disused_tank',
                                  'activity_services_water_insulation', 'services_water_insulation',
                                  'activity_services_water_repair_asbestos', 'activity_services_water_repair_cover_screen',
                                  'activity_services_water_repair_water_tank_screen']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
