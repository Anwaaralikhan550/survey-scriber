# -*- coding: utf-8 -*-
"""Generate slices/g4_e.json (G4 Heating). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (P, add_or_set, checks, lst, opts, para_rule, set_keys)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'g4_e.json')
S = 'G4'
MW = '{G_HEATING}'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{G4_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


# ── static text: the unlabelled servicing / records paragraph between Room heaters and Old boiler ──
general, _ = P(S, 'Any inspection, servicing or repair', 'Old boiler:')
set_keys([add_or_set('{G_HEATING}::{STANDARD_TEXT_2}', general)])

BT = 'combination boiler, conventional boiler, sealed boiler system, electrical boiler, oil-fired boiler, other'
BL = 'kitchen, utility room, bedroom, under the stairs, garage, other'
EM = 'radiators, underfloor heating pipes, ceiling vents, wall vents, other'
EL = 'oil-filled, electric storage, individual room electric, other'
FA = 'utility room, loft, garage, cupboard, basement, other'
HP = 'kitchen, utility room, garage, other'
RI = 'radiator(s), pipework'
RL = 'lounge, bedroom, bathroom, other'
RD = 'leaking, damaged, other'

slices = []
slices.append({'screen': 'activity_services_heating_about_heating', 'replace_all': True, 'keep': [], 'rules': [
    pr('g4_no_heating', 'NO_HEATING', 'No heating:', 'Heating not found:', when=['cb_no_heating', 'true'],
       extra=[cb('cb_no_heating', 'No heating')]),
    pr('g4_not_found', 'HEATING_NOT_FOUND', 'Heating not found:', 'Communal heating:',
       when=['cb_heating_not_found', 'true'], extra=[cb('cb_heating_not_found', 'Heating not found')]),
    pr('g4_communal', 'COMMUNAL_HEATING', 'Communal heating:', 'Boiler:', when=['cb_communal_heating', 'true'],
       extra=[cb('cb_communal_heating', 'Communal heating')]),
    pr('g4_boiler', 'BOILER', 'Boiler:', 'Heat emitters:', subs={BT: '{HEAT_BOILER_TYPE}', BL: '{HEAT_BOILER_LOCATION}'},
       when=['cb_boiler_present', 'true'], extra=[cb('cb_boiler_present', 'Boiler')],
       tokens=[ck('{HEAT_BOILER_TYPE}', 'Boiler type', BT, 'g4b_', other=('g4b_other', 'g4b_other_text')),
               ck('{HEAT_BOILER_LOCATION}', 'Boiler installed in', BL, 'g4l_', other=('g4l_other', 'g4l_other_text'))]),
    pr('g4_emitters', 'HEAT_EMITTERS', 'Heat emitters:', 'Room heaters:', subs={EM: '{HEAT_EMITTERS}'},
       when=['cb_connected_to_radiator', 'true'], extra=[cb('cb_connected_to_radiator', 'Heat emitters')],
       tokens=[ck('{HEAT_EMITTERS}', 'Boiler connected to', EM, 'g4e_', other=('g4e_other', 'g4e_other_text'))]),
    pr('g4_room_heaters', 'ROOM_HEATERS', 'Room heaters:', 'Any inspection, servicing or repair', subs={EL: '{HEAT_ROOM_HEATERS}'},
       when=['cb_room_heaters', 'true'], extra=[cb('cb_room_heaters', 'Room heaters')],
       tokens=[ck('{HEAT_ROOM_HEATERS}', 'Room heaters', EL, 'g4r_', other=('g4r_other', 'g4r_other_text'))]),
    pr('g4_old_boiler', 'OLD_BOILER', 'Old boiler:', 'Repair:', when=['cb_old_boiler', 'true'],
       extra=[cb('cb_old_boiler', 'Old boiler')]),
    pr('g4_forced_air', 'FORCED_AIR', 'Forced Air Heating:', 'Air Source Heat Pump:', subs={FA: '{HEAT_FORCED_AIR_LOCATION}'},
       when=['cb_forced_air', 'true'], extra=[cb('cb_forced_air', 'Forced air heating')],
       tokens=[ck('{HEAT_FORCED_AIR_LOCATION}', 'Main unit located in', FA, 'g4f_', other=('g4f_other', 'g4f_other_text'))]),
    pr('g4_ashp', 'AIR_SOURCE_HEAT_PUMP', 'Air Source Heat Pump:', 'Ground Source Heat Pump:',
       subs={HP: '{HEAT_ASHP_INTERNAL_LOC}', 'front/side/rear': '{HEAT_ASHP_EXTERNAL_LOC}'},
       when=['cb_air_source_heat_pump', 'true'], extra=[cb('cb_air_source_heat_pump', 'Air source heat pump')],
       tokens=[ck('{HEAT_ASHP_INTERNAL_LOC}', 'Internal unit located in', HP, 'g4ai_', other=('g4ai_other', 'g4ai_other_text')),
               checks('{HEAT_ASHP_EXTERNAL_LOC}', 'External unit located to the',
                      [('g4ae_front', 'front'), ('g4ae_side', 'side'), ('g4ae_rear', 'rear')])]),
    pr('g4_gshp', 'GROUND_SOURCE_HEAT_PUMP', 'Ground Source Heat Pump:', 'Condition rating', subs={HP: '{HEAT_GSHP_INTERNAL_LOC}'},
       when=['cb_ground_source_heat_pump', 'true'], extra=[cb('cb_ground_source_heat_pump', 'Ground source heat pump')],
       tokens=[ck('{HEAT_GSHP_INTERNAL_LOC}', 'Internal unit located in', HP, 'g4gi_', other=('g4gi_other', 'g4gi_other_text'))]),
]})
slices.append({'screen': 'activity_services_heating_repair_main_screen', 'replace_all': True, 'keep': [], 'rules': [
    pr('g4_repair', 'REPAIR', 'Repair:', 'Forced Air Heating:',
       subs={RI: '{HEAT_REPAIR_ITEM}', RL: '{HEAT_REPAIR_LOCATION}', RD: '{HEAT_REPAIR_DEFECT}'},
       when=['cb_g4_repair', 'true'], extra=[cb('cb_g4_repair', 'Repair')],
       tokens=[ck('{HEAT_REPAIR_ITEM}', 'Leaking item', RI, 'g4ri_'),
               ck('{HEAT_REPAIR_LOCATION}', 'Located in the', RL, 'g4rl_', other=('g4rl_other', 'g4rl_other_text')),
               ck('{HEAT_REPAIR_DEFECT}', 'Defect', RD, 'g4rd_', other=('g4rd_other', 'g4rd_other_text'))]),
]})
slices.append({'remove_screens': ['activity_services_heating_not_inspected', 'activity_services_heating_radiators',
                                  'activity_services_heating_other_heating', 'activity_services_heating_old_boiler']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
