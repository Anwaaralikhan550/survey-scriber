# -*- coding: utf-8 -*-
"""Generate slices/e6_e.json (E6 Outside doors) for slice.py. Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e6_e.json')
S = 'E6'
MW = '{E_OUTSIDE_DOORS}'
GD = 'group_outside_doors_24'
ABOUT = 'activity_outside_property_out_side_doors_about_doors'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], sub, start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': GD, 'order': order, 'after': after}


def cond_dd(token, fid, label='Condition'):
    return dd(token, fid, label, COND5, lower=True)


slices = []

DT = 'replacement, original, old, front, rear, side, patio, French, bi-fold, other'
DM = 'timber, PVCu, composite, aluminium, steel, other'
GL = 'single glazing, double glazing, triple glazing, decorative glazing, other'
RATED = [['actv_condition', v] for v in COND5[1:]]
slices.append({
    'screen': ABOUT, 'set_title': 'About doors', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e6_intro', '{STANDARD_TEXT}', 'Only a representative sample of accessible doors',
           'Description: The property incorporates', first=True, when=['actv_condition', 'Good'], when_any=RATED),
        pr('e6_desc', '{E6_DESCRIPTION}', 'Description: The property incorporates', 'The external doors are formed of',
           subs={DT: '{DOOR_TYPES}'},
           tokens=[ck('{DOOR_TYPES}', 'The property incorporates', DT, 'e6t_', other=('cb_other_859', 'et_other_179'))]),
        pr('e6_material', '{E6_MATERIAL}', 'The external doors are formed of', 'Glazing: The glazed sections comprise',
           subs={DM: '{DOOR_MATERIALS}'},
           tokens=[ck('{DOOR_MATERIALS}', 'Formed of', DM, 'e6m_', other=('e6m_other', 'e6m_other_text'))]),
        pr('e6_glazing', '{E6_GLAZING}', 'Glazing: The glazed sections comprise', 'No BS EN noted:',
           subs={GL: '{DOOR_GLAZING}'},
           tokens=[ck('{DOOR_GLAZING}', 'Glazing', GL, 'e6g_', other=('e6g_other', 'e6g_other_text'))]),
        pr('e6_bs_no', '{E6_NO_BS_EN}', 'No BS EN noted:', 'BS EN noted:', when=['actv_status', 'No BS EN noted'],
           extra=[{'id': 'actv_status', 'label': 'Safety glass markings', 'type': 'dropdown',
                   'options': ['No BS EN noted', 'BS EN noted']}]),
        pr('e6_bs_yes', '{E6_BS_EN_NOTED}', 'BS EN noted:', 'Condition: Where visible and operated',
           when=['actv_status', 'BS EN noted']),
        pr('e6_condition', '{E6_CONDITION}', 'Condition: Where visible and operated', 'If very poor is selected',
           subs={COND_LIST: '{DOOR_CONDITION}'}, tokens=[cond_dd('{DOOR_CONDITION}', 'actv_condition')]),
        pr('e6_very_poor', '{E6_VERY_POOR}', 'If very poor is selected, add this:', 'If replacement door is selected',
           drop='If very poor is selected, add this:', when=['actv_condition', 'Very poor']),
        pr('e6_replacement', '{E6_REPLACEMENT}', 'If replacement door is selected, add this:', 'Glazing seals:',
           drop='If replacement door is selected, add this:', when=['e6t_replacement', 'true']),
        pr('e6_seals', '{E6_GLAZING_SEALS}', 'Glazing seals:', 'Repair doors:', subs={COND_LIST: '{DOOR_SEAL_CONDITION}'},
           tokens=[cond_dd('{DOOR_SEAL_CONDITION}', 'actv_seals', 'Glazing seals condition')]),
    ]})

# ───────────── Repair doors ─────────────
RLOC = 'lounge, dining room, bedroom, kitchen, other,'
RDEF = ('have damaged lock(s), have missing lock(s), are difficult to open, are badly worn, are rotten, have broken '
        'glass, have failed glazing, are in disrepair, are severely damaged, present a safety or security risk, '
        'have other defects')
slices.append({
    'screen': 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors', 'set_title': 'Repair doors',
    'replace_all': True, 'keep': [],
    'rules': [
        pr('e6_repair', '{E6_REPAIR_DOORS}', 'Repair doors:', 'Thresholds:',
           subs={RLOC: '{REPAIR_LOCATIONS}', RDEF: '{REPAIR_DEFECTS}'},
           tokens=[ck('{REPAIR_LOCATIONS}', 'Doors in', RLOC.rstrip(','), 'e6rl_', other=('cb_other_337', 'et_other_362')),
                   ck('{REPAIR_DEFECTS}', 'Defects', RDEF, 'e6rd_')]),
    ]})

# ───────────── New screens: thresholds, operation, security, defective operation, timber, patio ─────────────
S_TH = 'activity_outside_property_out_side_doors_thresholds'
slices.append({
    'screen': S_TH, 'new_screen': new_screen(S_TH, 'Thresholds', 4, ABOUT),
    'rules': [pr('e6_thresholds', '{E6_THRESHOLDS}', 'Thresholds:', 'Operation:', subs={COND_LIST: '{THRESHOLD_CONDITION}'},
                 tokens=[cond_dd('{THRESHOLD_CONDITION}', 'actv_condition')])]})
S_OP = 'activity_outside_property_out_side_doors_operation'
slices.append({
    'screen': S_OP, 'new_screen': new_screen(S_OP, 'Operation', 6, S_TH),
    'rules': [pr('e6_operation', '{E6_OPERATION}', 'Operation:', 'Security:',
                 subs={'freely, with resistance, with difficulty': '{DOOR_OPERATION}'},
                 tokens=[dd('{DOOR_OPERATION}', 'actv_operation', 'Doors opened and closed',
                            ['Freely', 'With resistance', 'With difficulty'], lower=True)])]})
LK = 'multi-point locking, mortice locks, cylinder locks, night latches, combination of locking systems'
S_SEC = 'activity_outside_property_out_side_doors_security'
slices.append({
    'screen': S_SEC, 'new_screen': new_screen(S_SEC, 'Security', 8, S_OP),
    'rules': [pr('e6_security', '{E6_SECURITY}', 'Security:', 'Inadequate Lock:',
                 subs={LK: '{DOOR_LOCKS}', 'reasonable, adequate, inadequate': '{DOOR_SECURITY_LEVEL}'},
                 tokens=[ck('{DOOR_LOCKS}', 'Doors are fitted with', LK, 'e6lk_'),
                         dd('{DOOR_SECURITY_LEVEL}', 'actv_seciruty_offered', 'Level of security',
                            ['Reasonable', 'Adequate', 'Inadequate'], lower=True)])]})
ILOC = 'main, rear, side, patio, sliding patio doors, French doors, or bi-fold doors, other door(s)'
ilabels = ['main', 'rear', 'side', 'patio', 'sliding patio doors', 'French doors', 'bi-fold doors']
slices.append({
    'screen': 'activity_outside_property_out_side_doors_repairs_inadequate_lock_location', 'replace_all': True,
    'keep': [], 'set_title': 'Inadequate lock',
    'rules': [pr('e6_inadequate_lock', '{E6_INADEQUATE_LOCK}', 'Inadequate Lock:', 'Defective Operation',
                 subs={ILOC: '{LOCK_LOCATIONS}'},
                 tokens=[checks('{LOCK_LOCATIONS}', 'Locking arrangements to', opts('e6il_', ilabels),
                                other=('cb_other_il', 'et_other_il'))])]})
DOP = ('stick during operation, fail to close correctly, require adjustment, have damaged hinges, have defective '
       'handles, have defective locking mechanisms, be distorted, have localised decay, have damaged frames')
B = '•'
dop_bullets = ' '.join(f'{B} {x.strip()}' for x in DOP.split(', '))
S_DOP = 'activity_outside_property_out_side_doors_defective_operation'
slices.append({
    'screen': S_DOP, 'new_screen': new_screen(S_DOP, 'Defective operation', 10, S_SEC),
    'rules': [pr('e6_defective_op', '{E6_DEFECTIVE_OPERATION}', 'Defective Operation', 'Timber Doors:',
                 subs={dop_bullets: '{DOOR_DEFECTIVE_OPERATION}.'},
                 tokens=[ck('{DOOR_DEFECTIVE_OPERATION}', 'External doors were found to', DOP, 'e6do_')])]})
TD = 'localised weathering, paint deterioration, surface splitting, minor decay'
S_TD = 'activity_outside_property_out_side_doors_timber_doors'
slices.append({
    'screen': S_TD, 'new_screen': new_screen(S_TD, 'Timber doors', 12, S_DOP),
    'rules': [pr('e6_timber', '{E6_TIMBER_DOORS}', 'Timber Doors:', 'Patio and French Doors:', subs={TD: '{TIMBER_DOOR_ISSUES}'},
                 tokens=[ck('{TIMBER_DOOR_ISSUES}', 'Issues that may occur', TD, 'e6td_')])]})
PF = 'sliding patio doors, French doors, bi-fold doors, other similar doors'
S_PF = 'activity_outside_property_out_side_doors_patio_french'
slices.append({
    'screen': S_PF, 'new_screen': new_screen(S_PF, 'Patio and French doors', 14, S_TD),
    'rules': [
        pr('e6_patio', '{E6_PATIO_FRENCH}', 'Patio and French Doors:', 'General Maintenance:', subs={PF: '{PATIO_DOORS}'},
           tokens=[ck('{PATIO_DOORS}', 'The property incorporates', PF, 'e6pf_', other=('e6pf_other', 'e6pf_other_text'))]),
        pr('e6_general', '{E6_GENERAL_MAINTENANCE}', 'General Maintenance:', 'Condition rating',
           when=['cb_general_maintenance', 'true'],
           extra=[{'id': 'cb_general_maintenance', 'label': 'General maintenance', 'type': 'checkbox'}]),
    ]})

# ───────────── Retired screens (single PDF description / repair paragraph replaces them) ─────────────
RETIRE = [
    ABOUT + '__timber', ABOUT + '__steel', ABOUT + '__aluminium', ABOUT + '__other',
    'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__rear_door',
    'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__side_door',
    'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__patio_door',
    'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__garage_door',
    'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__other_door',
    'activity_outside_property_out_side_doors_repairs_failed_glazing_location',
]
slices.append({'remove_screens': RETIRE})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
