# -*- coding: utf-8 -*-
"""Generate slices/f7_e.json (F7 Woodwork). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f7_e.json')
S = 'F7'
MW = '{F_WOODWORK}'
G = 'group_wood_work_75'
I_ = 'activity_in_side_property_wood_work'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F7_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None, cap=False):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond, cap=cap)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


slices = []
JI = ('internal doors, door frames, skirting boards, architraves, staircases, balustrades, handrails, window boards, '
      'timber cladding, wardrobe(s), cupboards, built-in joinery, other')
slices.append({'screen': I_ + '_second', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_desc', 'DESCRIPTION', 'Description: The joinery items comprise', 'Condition: Where visible and operated', subs={JI: '{JOINERY_ITEMS}'},
       tokens=[ck('{JOINERY_ITEMS}', 'Joinery items comprise', JI, 'f7i_', other=('cb_other_410', 'et_other_800'))]),
    pr('f7_cond', 'CONDITION', 'Condition: Where visible and operated', 'Defect noted:', subs={COND_LIST: '{JOINERY_CONDITION}'},
       tokens=[dd('{JOINERY_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
]})
DE = ('doors, locks, door frames, skirting boards, architraves, the staircase, balustrades, handrails, window boards, '
      'timber cladding, cupboards, built-in joinery, other timber fittings')
DD_ = 'worn, loose, poorly fitted, damaged, inadequately secured, missing, affected by decay, other'
slices.append({'screen': 'activity_in_side_property_ww_wood_work_repair', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_defect', 'DEFECT_NOTED', 'Defect noted:', 'Door operation:', subs={DE: '{JOINERY_ELEMENTS}', DD_: '{JOINERY_DEFECTS}'},
       tokens=[ck('{JOINERY_ELEMENTS}', 'Joinery elements including', DE, 'f7e_', other=('f7e_other', 'f7e_other_text')),
               ck('{JOINERY_DEFECTS}', 'Found to be', DD_, 'f7d_', other=('f7d_other', 'f7d_other_text'))])]})
OP_DD = {'id': 'actv_door_operation', 'label': 'Doors opened and closed', 'type': 'dropdown',
         'options': ['Freely', 'With resistance', 'With difficulty']}
slices.append({'screen': I_ + '_door_sampling', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_door_op', 'DOOR_OPERATION', 'Door operation:', 'If with minor resistance',
       subs={'freely, with resistance, with difficulty': '{DOOR_OPERATION}'},
       tokens=[dd('{DOOR_OPERATION}', 'actv_door_operation', 'Doors opened and closed', ['Freely', 'With resistance', 'With difficulty'],
                  lower=True)]),
    pr('f7_door_op_add', 'DOOR_OPERATION_ADDON', 'If with minor resistance, or with difficulty is selected, add this.',
       'Out of square door/frames:', drop='If with minor resistance, or with difficulty is selected, add this.',
       when=['actv_door_operation', 'With resistance'], when_any=[['actv_door_operation', 'With difficulty']]),
]})
OS_DD = {'id': 'actv_status', 'label': 'Distorted doors and frames', 'type': 'dropdown', 'options': ['Out of square door/frames', 'Investigate']}
slices.append({'screen': I_ + '_out_of_square_doors', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_oos', 'OUT_OF_SQUARE', 'Out of square door/frames:', 'Investigate:', when=['actv_status', 'Out of square door/frames'], extra=[OS_DD]),
    pr('f7_investigate', 'INVESTIGATE', 'Investigate:', 'Creaking stairs:', when=['actv_status', 'Investigate']),
]})
CS_DD = {'id': 'actv_status', 'label': 'Staircase', 'type': 'dropdown', 'options': ['Creaking stairs', 'Repair now']}
slices.append({'screen': I_ + '_creaking_stairs', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_creak', 'CREAKING_STAIRS', 'Creaking stairs:', 'Repair now:', when=['actv_status', 'Creaking stairs'], extra=[CS_DD]),
    pr('f7_creak_now', 'CREAKING_STAIRS_NOW', 'Repair now:', 'Rocking handrails:', when=['actv_status', 'Repair now']),
]})
slices.append({'screen': I_ + '_rocking_handrails', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_rocking', 'ROCKING_HANDRAILS', 'Rocking handrails:', 'No handrails:', when=['cb_rocking_handrails', 'true'],
       extra=[cb('cb_rocking_handrails', 'Rocking handrails')])]})
slices.append({'screen': I_ + '_open_threads', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_open_risers', 'NO_HANDRAILS', 'No handrails:', 'Wood-Boring Insects:', when=['cb_open_threads', 'true'],
       extra=[cb('cb_open_threads', 'Open risers (no handrails)')])]})
WP = 'staircase, floorboards, skirting, under stairs, cupboards, other timber'
slices.append({'screen': I_ + '_repair_infestation', 'replace_all': True, 'keep': [], 'rules': [
    pr('f7_wb', 'WOOD_BORING', 'Wood-Boring Insects:', 'General Maintenance:',
       subs={'minor, significant': '{WB_SEVERITY}', 'active, historic': '{WB_ACTIVITY}', WP: '{WB_PARTS}', '(type in location)': '{WB_LOCATION}'},
       tokens=[ck('{WB_SEVERITY}', 'Evidence', 'minor, significant', 'f7s_'),
               ck('{WB_ACTIVITY}', 'Activity', 'active, historic', 'f7a_'),
               ck('{WB_PARTS}', 'In parts of the', WP, 'f7p_', other=('f7p_other', 'f7p_other_text')),
               {'kind': 'text', 'token': '{WB_LOCATION}', 'dropdown': 'et_wb_location', 'field_label': 'Location'}])]})
slices.append({'screen': 'activity_inside_property_woodwork_main_screen', 'rules': [
    pr('f7_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')])]})
slices.append({'remove_screens': [
    'activity_in_side_property_cupboards', I_, I_ + '_damaged_lock', I_ + '_damaged_lock__damaged_lock',
    I_ + '_repair_balusters', I_ + '_repair_damp_timber', I_ + '_not_inspected', I_ + '_glazed_internal_doors']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
