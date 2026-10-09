# -*- coding: utf-8 -*-
"""Generate slices/g5_e.json (G5 Water heating). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (checks, lst, opts, para_rule, set_keys)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'g5_e.json')
S = 'G5'
MW = '{G_WATER_HEATING}'
SCREEN = 'activity_services_water_heating_gas_heating'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{G5_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


# The old STANDARD_TEXT_2 ("I cannot confirm whether the system is covered by a service contract ...") is not in the PDF.
set_keys([{'op': 'del', 'key': '{G_WATER_HEATING}::{STANDARD_TEXT_2}'}])

BT = 'combination boiler, conventional boiler, sealed boiler system, electrical boiler, oil-fired boiler, other'
LOC = 'airing cupboard, kitchen, utility room, bedroom, garage, loft, other'

slices = [
    {'screen': SCREEN, 'set_title': 'About Water Heating', 'replace_all': True, 'keep': [], 'rules': [
        pr('g5_not_found', 'NOT_FOUND', 'Not found.', 'Communal water heating:', when=['cb_wh_not_found', 'true'],
           extra=[cb('cb_wh_not_found', 'Water heating not found')]),
        pr('g5_communal', 'COMMUNAL', 'Communal water heating:', 'Water heating:', when=['cb_wh_communal', 'true'],
           extra=[cb('cb_wh_communal', 'Communal water heating')]),
        pr('g5_boiler', 'WATER_HEATING', 'Water heating:', 'Electric Immersion:',
           subs={BT: '{HEAT_WATER_BOILER_TYPE}', LOC: '{HEAT_WATER_BOILER_LOCATION}'},
           when=['cb_wh_boiler', 'true'], extra=[cb('cb_wh_boiler', 'Water heating (boiler)')],
           tokens=[ck('{HEAT_WATER_BOILER_TYPE}', 'Hot water provided by', BT, 'g5b_', other=('g5b_other', 'g5b_other_text')),
                   ck('{HEAT_WATER_BOILER_LOCATION}', 'Installed in the', LOC, 'g5bl_', other=('g5bl_other', 'g5bl_other_text'))]),
        pr('g5_immersion', 'ELECTRIC_IMMERSION', 'Electric Immersion:', 'Poor cylinder insulation:', subs={LOC: '{HEAT_CYLINDER_LOCATION}'},
           when=['cb_wh_immersion', 'true'], extra=[cb('cb_wh_immersion', 'Electric immersion')],
           tokens=[ck('{HEAT_CYLINDER_LOCATION}', 'Cylinder located in the', LOC, 'g5c_', other=('g5c_other', 'g5c_other_text'))]),
        pr('g5_poor_ins', 'POOR_CYLINDER_INSULATION', 'Poor cylinder insulation:', 'Point-of-use:',
           when=['cb_poor_cylinder_condition', 'true'], extra=[cb('cb_poor_cylinder_condition', 'Poor cylinder insulation')]),
        pr('g5_point_of_use', 'POINT_OF_USE', 'Point-of-use:', 'Solar water heating:', when=['cb_wh_point_of_use', 'true'],
           extra=[cb('cb_wh_point_of_use', 'Point-of-use')]),
        pr('g5_solar', 'SOLAR_WATER_HEATING', 'Solar water heating:', 'Condition rating', when=['cb_wh_solar', 'true'],
           extra=[cb('cb_wh_solar', 'Solar water heating')]),
    ]},
    {'remove_screens': ['activity_water_heating_communal_hot_water', 'activity_services_water_heating_electric_heating',
                        'activity_services_water_heating_cylinder', 'activity_services_water_heating_repair_leaking_cylinder',
                        'activity_services_water_heating_repair_loose_panels', 'activity_services_water_heating_not_inspected']},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
