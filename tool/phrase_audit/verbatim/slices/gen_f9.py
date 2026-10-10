# -*- coding: utf-8 -*-
"""Generate slices/f9_e.json (F9 Other: communal areas, cellar/basement). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f9_e.json')
S = 'F9'
MW = '{F_OTHER}'
GC = 'group_cellar_83'
CA = 'activity_in_side_property_other_communal_area'
CELL = 'activity_inside_property_other_celler_'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F9_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


slices = []
IC = ('entrance lobby, hallway, landing, staircases, lift lobby, fire lobby, balcony, communal storage, common room, '
      'other internal areas')
PC = 'repairs, general maintenance, redecoration, refurbishment, other remedial works'
CA_DD = {'id': 'actv_status', 'label': 'Communal areas', 'type': 'dropdown',
         'options': ['Not inspected', 'No defects noted', 'Wear and tear noted', 'Poor condition']}
slices.append({'screen': CA, 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_ca_ni', 'COMMUNAL_NOT_INSPECTED', 'Not inspected: Access to the communal areas', 'Description: Internal communal parts',
       when=['actv_status', 'Not inspected'], extra=[CA_DD]),
    pr('f9_ca_desc', 'COMMUNAL_DESCRIPTION', 'Description: Internal communal parts', 'No defects noted:', subs={IC: '{COMMUNAL_PARTS}'},
       tokens=[ck('{COMMUNAL_PARTS}', 'Internal communal parts comprise', IC, 'f9c_', other=('f9c_other', 'f9c_other_text'))]),
    pr('f9_ca_ok', 'COMMUNAL_NO_DEFECTS', 'No defects noted:', 'Wear and tear noted:', when=['actv_status', 'No defects noted']),
    pr('f9_ca_wear', 'COMMUNAL_WEAR', 'Wear and tear noted:', 'Poor condition:', when=['actv_status', 'Wear and tear noted']),
    pr('f9_ca_poor', 'COMMUNAL_POOR', 'Poor condition:', 'Repair: The entry stairs', subs={PC: '{COMMUNAL_REMEDIAL}'},
       when=['actv_status', 'Poor condition'],
       tokens=[ck('{COMMUNAL_REMEDIAL}', 'Areas require', PC, 'f9p_', other=('f9p_other', 'f9p_other_text'),
                  cond='actv_status=Poor condition')]),
]})
RL = 'entry stairs, landing, balcony, hallway, shared lobby, fire lobby, common room, other'
RD = 'worn, damaged, creaking, badly cracked, sloping, missing in places, in disrepair, other'
slices.append({'screen': 'activity_in_side_property_other_repair', 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_repair', 'COMMUNAL_REPAIR', 'Repair: The entry stairs', 'Cellar/Basement Not inspected:',
       subs={RL: '{REPAIR_AREAS}', RD: '{REPAIR_DEFECTS}'},
       tokens=[ck('{REPAIR_AREAS}', 'Areas', RL, 'f9ra_', other=('et_other_609_cb', 'et_other_609')),
               ck('{REPAIR_DEFECTS}', 'Defects', RD, 'f9rd_', other=('f9rd_other', 'f9rd_other_text'))])]})

# ───────────── Cellar / basement (the duplicate "Basement" group is retired) ─────────────
NA = 'restricted access, no access, other'
slices.append({'screen': CELL + 'no_access', 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_cellar_ni', 'CELLAR_NOT_INSPECTED', 'Cellar/Basement Not inspected:', 'Walls: The property incorporates a cellar',
       subs={NA: '{CELLAR_ACCESS}'},
       tokens=[ck('{CELLAR_ACCESS}', 'Could not be inspected due to', NA, 'f9na_', other=('cb_other_704', 'et_other_412'))])]})
CW = 'bricks, stone, loose soil, concrete, other'
CF = 'solid concrete, timber, stone, loose soil, other'
USE_DD = {'id': 'actv_used_as', 'label': 'Use of cellar', 'type': 'dropdown', 'options': ['Not in use', 'In use']}
slices.append({'screen': CELL + 'inspected', 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_cellar_walls', 'CELLAR_WALLS', 'Walls: The property incorporates a cellar', 'Floor: The floor is constructed of',
       subs={CW: '{CELLAR_WALLS}'},
       tokens=[ck('{CELLAR_WALLS}', 'Walls formed in', CW, 'f9cw_', other=('f9cw_other', 'f9cw_other_text'))]),
    pr('f9_cellar_floor', 'CELLAR_FLOOR', 'Floor: The floor is constructed of', 'Condition: Where visible, the cellar appears',
       subs={CF: '{CELLAR_FLOOR}'},
       tokens=[ck('{CELLAR_FLOOR}', 'Floor constructed of', CF, 'f9cf_', other=('f9cf_other', 'f9cf_other_text'))]),
    pr('f9_cellar_cond', 'CELLAR_CONDITION', 'Condition: Where visible, the cellar appears', 'Not in use:',
       subs={COND_LIST: '{CELLAR_CONDITION}'}, tokens=[dd('{CELLAR_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
    pr('f9_cellar_unused', 'CELLAR_NOT_IN_USE', 'Not in use:', 'In use:', when=['actv_used_as', 'Not in use'], extra=[USE_DD]),
    pr('f9_cellar_used', 'CELLAR_IN_USE', 'In use:', 'Unsuitable:', when=['actv_used_as', 'In use']),
]})
UN = 'low headroom, dampness, difficult access, poor ventilation, other limitations'
slices.append({'screen': CELL + 'not_habitable', 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_cellar_unsuitable', 'CELLAR_UNSUITABLE', 'Unsuitable:', 'Flooded:', subs={UN: '{CELLAR_LIMITATIONS}'},
       tokens=[ck('{CELLAR_LIMITATIONS}', 'Should not be regarded as habitable due to', UN, 'f9un_',
                  other=('cb_other_697', 'et_other_427'))])]})
slices.append({'screen': CELL + 'flooded', 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_cellar_flooded', 'CELLAR_FLOODED', 'Flooded:', 'Damp:', subs={'partially, significantly': '{CELLAR_FLOOD_DEGREE}'},
       tokens=[dd('{CELLAR_FLOOD_DEGREE}', 'actv_possible_flooded', 'Flooded', ['Partially', 'Significantly'], lower=True)])]})
DA = 'lower walls, upper walls, throughout the cellar, exposed floor joists, other areas'
slices.append({'screen': CELL + 'damp', 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_cellar_damp', 'CELLAR_DAMP', 'Damp:', 'Waterproofing failure:', subs={DA: '{CELLAR_DAMP_AREAS}'},
       tokens=[ck('{CELLAR_DAMP_AREAS}', 'Dampness noted on', DA, 'f9dm_', other=('cb_others_389', 'et_others_471'))]),
    pr('f9_cellar_waterproofing', 'CELLAR_WATERPROOFING', 'Waterproofing failure:', 'Timber decay:', when=['cb_serious_dump', 'true'],
       extra=[cb('cb_serious_dump', 'Waterproofing failure')]),
]})
slices.append({'screen': CELL + 'joists_decay', 'replace_all': True, 'keep': [], 'rules': [
    pr('f9_cellar_decay', 'CELLAR_TIMBER_DECAY', 'Timber decay:', 'General Maintenance:', when=['cb_joists_decay', 'true'],
       extra=[cb('cb_joists_decay', 'Timber decay')])]})
slices.append({'screen': 'activity_inside_property_other_main_screen', 'rules': [
    pr('f9_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')])]})
slices.append({'remove_screens': [
    CELL + 'no_access__no_access', CELL + 'not_in_use', CELL + 'not_in_use__not_in_use', CELL + 'inspected__used_as',
    CELL + 'not_habitable__not_habitable', CELL + 'flooded__flooded', CELL + 'damp__serious_damp', CELL + 'joists_decay__joists_decay',
    'activity_inside_property_other_not_inspected']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
