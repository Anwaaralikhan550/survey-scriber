# -*- coding: utf-8 -*-
"""Generate slices/g2_e.json (G2 Gas and oil). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'g2_e.json')
S = 'G2'
MW = '{G_GAS_AND_OIL}'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{G2_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


ML = 'under the stairs, in an outside box, in the kitchen, in the garage, in a communal cupboard, other'
MET_DD = {'id': 'actv_condition', 'label': 'Gas meter', 'type': 'dropdown', 'options': ['Metre', 'Metre not found']}
slices = []
slices.append({'screen': 'activity_services_main_gas', 'replace_all': True, 'keep': [], 'rules': [
    pr('g2_smell', 'GAS_SMELL', 'Gas smell noted:', 'Capped gas:', when=['cb_gas_smell_noted', 'true'],
       extra=[cb('cb_gas_smell_noted', 'Gas smell noted')]),
    pr('g2_capped', 'CAPPED_GAS', 'Capped gas:', 'Metre: There is a mains gas connection', when=['cb_gas_supply_is_capped_off', 'true'],
       extra=[cb('cb_gas_supply_is_capped_off', 'Capped gas')]),
    pr('g2_meter', 'METER', 'Metre: There is a mains gas connection', 'Metre not found:', subs={ML: '{GAS_METER_LOCATION}'},
       when=['actv_condition', 'Metre'], extra=[MET_DD],
       tokens=[ck('{GAS_METER_LOCATION}', 'Meter located', ML, 'g2m_', other=('g2m_other', 'g2m_other_text'),
                  cond='actv_condition=Metre')]),
    pr('g2_meter_nf', 'METER_NOT_FOUND', 'Metre not found:', 'Dated or Old:', when=['actv_condition', 'Metre not found']),
    pr('g2_dated', 'DATED_OR_OLD', 'Dated or Old:', 'Oil tank:', when=['cb_dated_gas', 'true'], extra=[cb('cb_dated_gas', 'Dated or old')]),
]})
TT = 'plastic, metal, other'
TL = 'front garden, side garden, rear garden, other'
slices.append({'screen': 'activity_services_oil', 'replace_all': True, 'keep': [], 'rules': [
    pr('g2_oil', 'OIL_TANK', 'Oil tank:', 'Old tank:', subs={TT: '{OIL_TANK_TYPE}', TL: '{OIL_TANK_LOCATION}'},
       tokens=[ck('{OIL_TANK_TYPE}', 'Fuel storage tank', TT, 'g2t_', other=('g2t_other', 'g2t_other_text')),
               ck('{OIL_TANK_LOCATION}', 'Tank located at the', TL, 'g2l_', other=('g2l_other', 'g2l_other_text'))]),
    pr('g2_old_tank', 'OLD_TANK', 'Old tank:', 'Condition rating', when=['cb_old_tank', 'true'], extra=[cb('cb_old_tank', 'Old tank')]),
]})
slices.append({'screen': 'activity_services_gas_oil_main_screen', 'rules': [
    pr('g2_testing', 'TESTING', 'Testing:', 'Certification:', first=True, when=[RATING[0], RATING[1]], when_any=RATING[2]),
    pr('g2_certification', 'CERTIFICATION', 'Certification:', 'Gas smell noted:', first=True, when=[RATING[0], RATING[1]],
       when_any=RATING[2]),
]})
slices.append({'remove_screens': ['activity_services_gas_oil', 'activity_services_gas_oil_repair_gas_meter',
                                  'activity_services_gas_oil_repair_storage_tank_pipework', 'activity_services_gas_oil_not_inspected']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
