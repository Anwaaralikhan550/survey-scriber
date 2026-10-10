# -*- coding: utf-8 -*-
"""Generate slices/f5_e.json (F5 Fireplaces and chimneys). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f5_e.json')
S = 'F5'
MW = '{F_FIREPLACES_AND_CHIMNEYS}'
G = 'group_f5_fireplaces_and_chimneys_69'
I_ = 'activity_in_side_property_fire_places'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F5_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': G, 'order': order, 'after': after}


slices = []
FT = 'open fireplaces, gas fires, electric fires, solid fuel stoves, wood-burning stoves, multi-fuel stoves, decorative fireplaces'
slices.append({'screen': I_, 'set_title': 'Fireplaces', 'replace_all': True, 'keep': [], 'rules': [
    pr('f5_desc', 'DESCRIPTION', 'Description: The property incorporates', 'Condition: Where visible, the fireplace(s)', subs={FT: '{FIREPLACE_TYPES}'},
       tokens=[ck('{FIREPLACE_TYPES}', 'The property incorporates', FT, 'f5t_')]),
    pr('f5_cond', 'CONDITION', 'Condition: Where visible, the fireplace(s)', 'Vented blocked fireplace:', subs={COND_LIST: '{FIREPLACE_CONDITION}'},
       tokens=[dd('{FIREPLACE_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
]})
FL = 'lounge, dining room, bedroom, kitchen, hallway, other'
BL_DD = {'id': 'actv_status', 'label': 'Blocked fireplace', 'type': 'dropdown', 'options': ['Vented', 'Unvented']}
slices.append({'screen': I_ + '_repair_blocked_fireplace', 'replace_all': True, 'keep': [], 'rules': [
    pr('f5_vented', 'VENTED_BLOCKED', 'Vented blocked fireplace:', 'Unvented blocked fireplace:', subs={FL: '{BLOCKED_LOCATIONS}'},
       when=['actv_status', 'Vented'], extra=[BL_DD],
       tokens=[ck('{BLOCKED_LOCATIONS}', 'Fireplace(s) in', FL, 'f5b_', other=('f5b_other', 'f5b_other_text'), cond='actv_status=Vented|Unvented')]),
    pr('f5_unvented', 'UNVENTED_BLOCKED', 'Unvented blocked fireplace:', 'Removed Chimney Breasts:', subs={FL: '{BLOCKED_LOCATIONS}'},
       when=['actv_status', 'Unvented'],
       tokens=[ck('{BLOCKED_LOCATIONS}', 'Fireplace(s) in', FL, 'f5b_', other=('f5b_other', 'f5b_other_text'), cond='actv_status=Vented|Unvented')]),
]})
RB = 'partially removed, removed'
RBL = 'lounge, bedroom, kitchen, bathroom, utility room, hallway, other'
RBD = 'damaged, cracked, distorted, other'
slices.append({'screen': I_ + '_repair_removed_cb', 'replace_all': True, 'keep': [], 'rules': [
    pr('f5_removed', 'REMOVED_CHIMNEY_BREASTS', 'Removed Chimney Breasts:', 'Defects noted:', subs={RB: '{RCB_STATE}'},
       tokens=[ck('{RCB_STATE}', 'Chimney breast has been', RB, 'f5r_')]),
    pr('f5_removed_defects', 'REMOVED_DEFECTS', 'Defects noted:', 'Boiler Flues:', subs={RBL: '{RCB_LOCATIONS}', RBD: '{RCB_DEFECTS}'},
       tokens=[ck('{RCB_LOCATIONS}', 'Chimney breast removed from', RBL, 'f5rl_', other=('f5rl_other', 'f5rl_other_text')),
               ck('{RCB_DEFECTS}', 'Adjacent construction is', RBD, 'f5rd_', other=('f5rd_other', 'f5rd_other_text'))]),
]})
slices.append({'screen': I_ + '_repair_boiler_flue', 'replace_all': True, 'keep': [], 'rules': [
    pr('f5_boiler', 'BOILER_FLUES', 'Boiler Flues:', 'Fireplace defects:', when=['cb_boiler_flue', 'true'],
       extra=[cb('cb_boiler_flue', 'Boiler flues')])]})
B = '•'
FD = ['cracked fire surround', 'damaged hearth', 'loose fireplace components', 'cracked chimney breast',
      'distorted fireplace opening', 'localised damp staining', 'surface deterioration']
S_FD = I_ + '_defects'
slices.append({'screen': S_FD, 'new_screen': new_screen(S_FD, 'Fireplace defects', 14, I_ + '_repair_boiler_flue'), 'rules': [
    pr('f5_defects', 'FIREPLACE_DEFECTS', 'Fireplace defects:', 'Dampness:',
       subs={' '.join(f'{B} {x}' for x in FD): '{FIREPLACE_DEFECT_LIST}.'},
       tokens=[checks('{FIREPLACE_DEFECT_LIST}', 'One or more of the following defects were observed', opts('f5fd_', FD))])]})
S_DP = I_ + '_dampness'
slices.append({'screen': S_DP, 'new_screen': new_screen(S_DP, 'Dampness', 16, S_FD), 'rules': [
    pr('f5_damp', 'DAMPNESS', 'Dampness:', 'General Maintenance:', when=['cb_dampness', 'true'], extra=[cb('cb_dampness', 'Dampness')]),
]})
slices.append({'screen': 'activity_inside_property_fireplaces_main_screen', 'rules': [
    pr('f5_intro', 'INTRO', 'This section relates to visible fireplaces', 'Description: The property incorporates', first=True,
       when=[RATING[0], RATING[1]], when_any=RATING[2]),
    pr('f5_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})
retire = [I_ + x for x in ['_diffrent', '__gas_fire', '__imitation_system', '__wood_burning_stove', '__electric_fire', '__other',
                           '_repair_fire_place', '_repair_damage_grate', '_repair_damage_surround', '_not_inspected']]
slices.append({'remove_screens': retire})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
