# -*- coding: utf-8 -*-
"""Generate slices/e5_e.json (E5 Windows) for slice.py. Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e5_e.json')
S = 'E5'
MW = '{E_WINDOWS}'
GW = 'group_windows_21'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], sub, start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None, keep_other=False):
    labels = lst(pdf_list)
    return checks(token, label, opts(prefix, labels), other=other, cond=cond)


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': GW, 'order': order, 'after': after}


def cond_dd(token, fid, label='Condition'):
    return dd(token, fid, label, COND5, lower=True)


slices = []

# ───────────── About windows ─────────────
TYPES = ('replacement, original, old, PVCu, timber, old style timber sash, modern PVC sash, '
         'modern timber sash, aluminium, composite, other')
GLAZ = 'single glazing, double glazing, triple glazing, secondary glazing, decorative glazing, other'
slices.append({
    'screen': 'activity_outside_property_windows_aboutwindow', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e5_desc', '{E5_DESCRIPTION}', 'Description: The windows are formed of', 'Glazing: The glazing comprises',
           subs={TYPES: '{WIN_TYPES}'},
           tokens=[ck('{WIN_TYPES}', 'Windows formed of', TYPES, 'e5t_', other=('cb_other_895', 'et_other_220'))]),
        pr('e5_glazing', '{E5_GLAZING}', 'Glazing: The glazing comprises', 'No BS EN:', subs={GLAZ: '{WIN_GLAZING}'},
           tokens=[ck('{WIN_GLAZING}', 'Glazing', GLAZ, 'e5g_', other=('e5g_other', 'e5g_other_text'))]),
        pr('e5_bs_no', '{E5_NO_BS_EN}', 'No BS EN:', 'BS EN noted:', when=['actv_status', 'No BS EN'],
           extra=[{'id': 'actv_status', 'label': 'Safety glass markings', 'type': 'dropdown',
                   'options': ['No BS EN', 'BS EN noted']}]),
        pr('e5_bs_yes', '{E5_BS_EN_NOTED}', 'BS EN noted:', 'Condition: Where visible and operated',
           when=['actv_status', 'BS EN noted']),
        pr('e5_condition', '{E5_CONDITION}', 'Condition: Where visible and operated', 'If very poor is selected',
           subs={COND_LIST: '{WIN_CONDITION}'}, tokens=[cond_dd('{WIN_CONDITION}', 'actv_condition')]),
        pr('e5_very_poor', '{E5_VERY_POOR}', 'If very poor is selected, add this:', 'If replacement window is selected',
           drop='If very poor is selected, add this:', when=['actv_condition', 'Very poor']),
        pr('e5_replacement', '{E5_REPLACEMENT}', 'If replacement window is selected, add this:',
           'If old-style timber sash is selected', drop='If replacement window is selected, add this:',
           when=['e5t_replacement', 'true']),
        pr('e5_old_sash', '{E5_OLD_SASH}', 'If old-style timber sash is selected, add this:', 'Glazing seals:',
           drop='If old-style timber sash is selected, add this:', when=['e5t_old_style_timber_sash', 'true']),
        pr('e5_seals', '{E5_GLAZING_SEALS}', 'Glazing seals:', 'Sill projection:', subs={COND_LIST: '{SEAL_CONDITION}'},
           tokens=[cond_dd('{SEAL_CONDITION}', 'actv_seals', 'Glazing seals condition')]),
    ]})

# ───────────── Sill projection / sill defect ─────────────
SILL_DEF = 'adequate, properly installed, properly drained, cracked, defective'
SILL_DD = {'id': 'actv_projection_type', 'label': 'Sill', 'type': 'dropdown', 'options': ['Sill projection', 'Sill defect']}
slices.append({
    'screen': 'activity_outside_property_windows_sill_projection', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e5_sill', '{E5_SILL_PROJECTION}', 'Sill projection:', 'Sill defect:',
           subs={'properly, fairly, poorly': '{SILL_SEALING}'}, when=['actv_projection_type', 'Sill projection'],
           extra=[SILL_DD],
           tokens=[dd('{SILL_SEALING}', 'actv_condition', 'Sealing around windows', ['Properly', 'Fairly', 'Poorly'],
                      lower=True, cond='actv_projection_type=Sill projection')]),
        pr('e5_sill_defect', '{E5_SILL_DEFECT}', 'Sill defect:', 'Repair windows:', subs={SILL_DEF: '{SILL_DEFECTS}'},
           when=['actv_projection_type', 'Sill defect'],
           tokens=[ck('{SILL_DEFECTS}', 'Windowsill projection', SILL_DEF, 'e5sd_',
                      cond='actv_projection_type=Sill defect')]),
    ]})

# ───────────── Repair windows ─────────────
RLOC = 'lounge, dining room, bedroom, kitchen, other,'
RDEF = ('have damaged lock(s), have missing lock(s), are difficult to open, are badly worn, are rotten, have broken '
        'glass, have failed glazing, are in disrepair, are severely damaged, present a safety or security risk, '
        'have other defects')
slices.append({
    'screen': 'activity_outside_property_windows_repairs_repair_window', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e5_repair', '{E5_REPAIR_WINDOWS}', 'Repair windows:', 'Roof Velux Windows:',
           subs={RLOC: '{REPAIR_LOCATIONS}', RDEF: '{REPAIR_DEFECTS}'},
           tokens=[ck('{REPAIR_LOCATIONS}', 'Windows in', RLOC.rstrip(','), 'e5rl_',
                      other=('cb_other_471', 'et_other_175')),
                   ck('{REPAIR_DEFECTS}', 'Defects', RDEF, 'e5rd_')]),
    ]})

# ───────────── Velux ─────────────
VT = 'roof windows, roof skylights, Velux roof windows, other'
VM = 'timber, PVCu, aluminium, other'
VG = 'double, triple'
slices.append({
    'screen': 'activity_outside_property_windows_velux_window', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e5_velux', '{E5_VELUX}', 'Roof Velux Windows:', 'Condition: Where visible, they appear in good',
           subs={VT: '{VELUX_TYPES}', VM: '{VELUX_MATERIALS}', VG: '{VELUX_GLAZING}'},
           tokens=[ck('{VELUX_TYPES}', 'Type', VT, 'e5vt_', other=('cb_other_629', 'et_other_290')),
                   ck('{VELUX_MATERIALS}', 'Formed in', VM, 'e5vm_', other=('cb_other_610', 'et_other_816')),
                   ck('{VELUX_GLAZING}', 'Glazing', VG, 'e5vg_')]),
        pr('e5_velux_cond', '{E5_VELUX_CONDITION}',
           'Condition: Where visible, they appear in good, reasonable, fair, poor, very poor condition.',
           'Windowsills:', subs={COND_LIST: '{VELUX_CONDITION}'},
           tokens=[cond_dd('{VELUX_CONDITION}', 'actv_condition')]),
    ]})

# ───────────── Windowsills (new screen) ─────────────
SM = 'PVCu, timber, brick, tiles, concrete, other'
S_SILL = 'activity_outside_property_windows_windowsills'
slices.append({
    'screen': S_SILL, 'new_screen': new_screen(S_SILL, 'Windowsills', 6, 'activity_outside_property_windows_velux_window'),
    'rules': [
        pr('e5_windowsills', '{E5_WINDOWSILLS}', 'Windowsills:', 'Condition: Where visible, they appear in good, reasonable, fair, poor, very poor condition. Repairs',
           subs={SM: '{SILL_MATERIALS}'},
           tokens=[ck('{SILL_MATERIALS}', 'Formed in', SM, 'e5sm_', other=('e5sm_other', 'e5sm_other_text'))]),
        pr('e5_windowsills_cond', '{E5_WINDOWSILLS_CONDITION}',
           'Condition: Where visible, they appear in good, reasonable, fair, poor, very poor condition. Repairs',
           'Operation:', subs={COND_LIST: '{SILL_CONDITION}'},
           tokens=[cond_dd('{SILL_CONDITION}', 'actv_condition')]),
    ]})

# ───────────── Operation, defective operation, glazing, timber, condensation ─────────────
S_OP = 'activity_outside_property_windows_operation'
slices.append({
    'screen': S_OP, 'new_screen': new_screen(S_OP, 'Operation', 8, S_SILL),
    'rules': [pr('e5_operation', '{E5_OPERATION}', 'Operation:', 'Defective Operation',
                 subs={'freely, with minor with resistance, with difficulty': '{WIN_OPERATION}'},
                 tokens=[dd('{WIN_OPERATION}', 'actv_operation', 'Windows opened and closed',
                            ['Freely', 'With minor with resistance', 'With difficulty'], lower=True)])]})
DOP = ('stick during operation, fail to close correctly, fail to lock securely, require adjustment, have damaged '
       'hinges, have defective handles, have defective locking mechanisms')
S_DOP = 'activity_outside_property_windows_defective_operation'
slices.append({
    'screen': S_DOP, 'new_screen': new_screen(S_DOP, 'Defective operation', 9, S_OP),
    'rules': [pr('e5_defective_op', '{E5_DEFECTIVE_OPERATION}', 'Defective Operation', 'Failed Glazed Units:',
                 subs={'� stick during operation � fail to close correctly � fail to lock securely '
                       '� require adjustment � have damaged hinges � have defective handles � have '
                       'defective locking mechanisms': '{WIN_DEFECTIVE_OPERATION}.'},
                 tokens=[ck('{WIN_DEFECTIVE_OPERATION}', 'Windows were found to', DOP, 'e5do_')])]})
FG = 'internal condensation, misting, failed seals'
S_FG = 'activity_outside_property_windows_failed_glazed_units'
slices.append({
    'screen': S_FG, 'new_screen': new_screen(S_FG, 'Failed glazed units', 10, S_DOP),
    'rules': [pr('e5_failed_units', '{E5_FAILED_UNITS}', 'Failed Glazed Units:', 'Damaged Glazing:',
                 subs={FG: '{FAILED_UNIT_SIGNS}'},
                 tokens=[ck('{FAILED_UNIT_SIGNS}', 'Units exhibit', FG, 'e5fg_')])]})
DG = 'cracked, broken, chipped, damaged'
S_DG = 'activity_outside_property_windows_damaged_glazing'
slices.append({
    'screen': S_DG, 'new_screen': new_screen(S_DG, 'Damaged glazing', 11, S_FG),
    'rules': [
        pr('e5_damaged_glazing', '{E5_DAMAGED_GLAZING}', 'Damaged Glazing:', 'Hazard:', subs={DG: '{DAMAGED_PANES}'},
           tokens=[ck('{DAMAGED_PANES}', 'Panes are', DG, 'e5dg_')]),
        pr('e5_glazing_hazard', '{E5_GLAZING_HAZARD}', 'Hazard:', 'Timber Windows:', when=['cb_hazard', 'true'],
           extra=[{'id': 'cb_hazard', 'label': 'Hazard', 'type': 'checkbox'}]),
    ]})
TW = 'localised weathering, paint deterioration, minor decay, other'
S_TW = 'activity_outside_property_windows_timber_windows'
slices.append({
    'screen': S_TW, 'new_screen': new_screen(S_TW, 'Timber windows', 12, S_DG),
    'rules': [pr('e5_timber', '{E5_TIMBER_WINDOWS}', 'Timber Windows:', 'Condensation:', subs={TW: '{TIMBER_ISSUES}'},
                 tokens=[ck('{TIMBER_ISSUES}', 'Issues that may occur', TW, 'e5tw_',
                            other=('e5tw_other', 'e5tw_other_text'))])]})
S_CO = 'activity_outside_property_windows_condensation'
slices.append({
    'screen': S_CO, 'new_screen': new_screen(S_CO, 'Condensation', 13, S_TW),
    'rules': [pr('e5_condensation', '{E5_CONDENSATION}', 'Condensation:', 'Fire Trap Risk:',
                 when=['cb_condensation', 'true'],
                 extra=[{'id': 'cb_condensation', 'label': 'Condensation noted', 'type': 'checkbox'}])]})

# ───────────── Fire trap risk ─────────────
FL = 'lounge, dining room, bedroom, study, other room'
FD = 'no opening, a small opening'
slices.append({
    'screen': 'activity_outside_property_windows_repairs_no_fire_escape_risk', 'replace_all': True, 'keep': [],
    'rules': [pr('e5_fire_trap', '{E5_FIRE_TRAP}', 'Fire Trap Risk:', 'Add text to:',
                 subs={FL: '{FIRE_LOCATIONS}', FD: '{FIRE_OPENINGS}'},
                 tokens=[ck('{FIRE_LOCATIONS}', 'Window(s) in', FL, 'e5fl_', other=('cb_other_175', 'et_other_308')),
                         ck('{FIRE_OPENINGS}', 'Windows have', FD, 'e5fo_')])]})

slices.append({'remove_screens': ['activity_outside_property_windows_repairs_failed_glazing_location']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
