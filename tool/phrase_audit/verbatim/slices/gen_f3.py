# -*- coding: utf-8 -*-
"""Generate slices/f3_e.json (F3 Walls and partitions). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f3_e.json')
S = 'F3'
MW = '{F_WALLS_AND_PARTITIONS}'
G = 'group_walls_and_partitions_64'
I_ = 'activity_in_side_property_wap_'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F3_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': G, 'order': order, 'after': after}


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def txt(token, fid, label, cond=None):
    t = {'kind': 'text', 'token': token, 'dropdown': fid, 'field_label': label}
    if cond:
        t['cond'] = cond
    return t


slices = []
WM = 'solid masonry, timber stud partitions, plasterboard partitions, lath and plaster, other'
WF = 'paint, plaster, wallpaper, tiling, timber panelling, textured coating, decorative panelling, other'
slices.append({'screen': 'activity_inside_property_wap_walls', 'replace_all': True, 'keep': [], 'rules': [
    pr('f3_desc', 'DESCRIPTION', 'Description: The walls are formed in', 'Condition: Where visible, the walls and partitions appear',
       subs={WM: '{WALL_CONSTRUCTION}', WF: '{WALL_FINISH}'},
       tokens=[ck('{WALL_CONSTRUCTION}', 'Walls formed in', WM, 'f3m_', other=('cb_other_590', 'et_other_428')),
               ck('{WALL_FINISH}', 'Wall finish comprises', WF, 'f3f_', other=('cb_other_606', 'et_other_427'))]),
    pr('f3_cond', 'CONDITION', 'Condition: Where visible, the walls and partitions appear', 'If lath and plaster is selected',
       subs={COND_LIST: '{WALL_CONDITION}'}, tokens=[dd('{WALL_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
    pr('f3_lath', 'LATH_PLASTER', 'If lath and plaster is selected, add this', 'If textured coating is selected',
       drop='If lath and plaster is selected, add this –', when=['f3m_lath_and_plaster', 'true']),
    pr('f3_textured', 'TEXTURED_COATING', 'If textured coating is selected, add this', 'Minor cracking:',
       drop='If textured coating is selected, add this –', when=['f3f_textured_coating', 'true']),
    pr('f3_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})

# cracks / movement
MV_DD = {'id': 'android_material_design_spinner3', 'label': 'Cracking', 'type': 'dropdown',
         'options': ['Minor cracking', 'Significant cracking', 'Structural Movement']}
slices.append({'screen': I_ + 'movement_cracks', 'replace_all': True, 'keep': [], 'rules': [
    pr('f3_crack_minor', 'MINOR_CRACKING', 'Minor cracking:', 'Significant cracking:',
       when=['android_material_design_spinner3', 'Minor cracking'], extra=[MV_DD]),
    pr('f3_crack_major', 'SIGNIFICANT_CRACKING', 'Significant cracking:', 'Structural Movement:',
       when=['android_material_design_spinner3', 'Significant cracking']),
    pr('f3_movement', 'STRUCTURAL_MOVEMENT', 'Structural Movement:', 'Hollow Plaster:',
       subs={'historic, localised, progressive': '{WALL_MOVEMENT}'}, when=['android_material_design_spinner3', 'Structural Movement'],
       tokens=[ck('{WALL_MOVEMENT}', 'Movement observed', 'historic, localised, progressive', 'f3mv_',
                  cond='android_material_design_spinner3=Structural Movement')]),
]})

# hollow plaster (new)
S_HP = I_ + 'hollow_plaster'
slices.append({'screen': S_HP, 'new_screen': new_screen(S_HP, 'Hollow plaster', 12, I_ + 'movement_cracks'), 'rules': [
    pr('f3_hollow', 'HOLLOW_PLASTER', 'Hollow Plaster:', 'Condensation:', when=['cb_hollow_plaster', 'true'],
       extra=[cb('cb_hollow_plaster', 'Hollow plaster')])]})

# condensation
CL = 'lounge, bedrooms, bathrooms, kitchens, other'
slices.append({'screen': I_ + 'repair_condensation', 'replace_all': True, 'keep': [], 'rules': [
    pr('f3_condensation', 'CONDENSATION', 'Condensation:', 'No Damp:', subs={CL: '{CONDENSATION_AREAS}'},
       tokens=[ck('{CONDENSATION_AREAS}', 'Condensation and mould in', CL, 'f3c_', other=('f3c_other', 'f3c_other_text'))])]})

# dampness
DAMP_DD = {'id': 'damp_status', 'label': 'Dampness', 'type': 'dropdown',
           'options': ['No damp', 'Penetrating damp noted', 'Suspected rising damp']}
SRC_DD = {'id': 'actv_status_91', 'label': 'Source', 'type': 'dropdown', 'options': ['Damp source known', 'Unknown damp source']}
KN = 'actv_status_91=Damp source known'
PEN = 'damp_status=Penetrating damp noted'
CAUSE = 'defective rainwater goods, blocked gullies, leaking pipework, bridged damp-proof course, other'
FIX = ('clearing rainwater goods, repairing defective rainwater goods, unblocking gullies, repairing leaking pipework, '
       'removing any bridging of the damp-proof course, other')
slices.append({'screen': I_ + 'dampness', 'replace_all': True, 'keep': [], 'rules': [
    pr('f3_nodamp', 'NO_DAMP', 'No Damp:', 'Penetrating damp noted:', when=['damp_status', 'No damp'], extra=[DAMP_DD]),
    pr('f3_pen', 'PENETRATING_DAMP', 'Penetrating damp noted:', 'Damp source known:',
       subs={'(type wall location)': '{DAMP_LOCATION}'}, when=['damp_status', 'Penetrating damp noted'],
       tokens=[txt('{DAMP_LOCATION}', 'et_location', 'Wall location', cond=PEN)]),
    pr('f3_known', 'DAMP_SOURCE_KNOWN', 'Damp source known:', 'Repair Damp defect', subs={CAUSE: '{DAMP_CAUSES}'},
       when=['actv_status_91', 'Damp source known'], extra=[dict(SRC_DD, conditionalOn=PEN, conditionalMode='show')],
       tokens=[ck('{DAMP_CAUSES}', 'Dampness likely to result from', CAUSE, 'f3dc_', other=('f3dc_other', 'f3dc_other_text'), cond=KN)]),
    pr('f3_fix', 'DAMP_REPAIR', 'Repair Damp defect', 'Unknown damp source:', subs={FIX: '{DAMP_REPAIRS}'},
       tokens=[ck('{DAMP_REPAIRS}', 'Repairs may include', FIX, 'f3dr_', other=('f3dr_other', 'f3dr_other_text'), cond=KN)]),
    pr('f3_unknown', 'DAMP_SOURCE_UNKNOWN', 'Unknown damp source:', 'Suspected rising damp:', when=['actv_status_91', 'Unknown damp source']),
    pr('f3_rising', 'SUSPECTED_RISING_DAMP', 'Suspected rising damp:', 'Internal Alterations:',
       subs={'(type wall location)': '{DAMP_LOCATION}'}, when=['damp_status', 'Suspected rising damp'],
       tokens=[txt('{DAMP_LOCATION}', 'et_location', 'Wall location', cond='damp_status=Penetrating damp noted|Suspected rising damp')]),
]})

# internal alterations
IA = 'removed, partially removed, altered, new opening created, has been formed'
IAD = 'Distortion, cracking, inadequate support, other'
IA_DD = {'id': 'actv_ia_outcome', 'label': 'Outcome', 'type': 'dropdown', 'options': ['No defects noted', 'Defects noted']}
slices.append({'screen': I_ + 'removed_wall', 'replace_all': True, 'keep': [], 'rules': [
    pr('f3_ia', 'INTERNAL_ALTERATIONS', 'Internal Alterations:', 'No defects noted: No significant defects requiring immediate attention were identified unless otherwise stated below. Routine maintenance appropriate to the building',
       subs={IA: '{IA_STATE}'}, tokens=[ck('{IA_STATE}', 'Internal wall has been', IA, 'f3ia_')]),
    pr('f3_ia_ok', 'ALTERATIONS_NO_DEFECTS',
       'No defects noted: No significant defects requiring immediate attention were identified unless otherwise stated below. Routine maintenance appropriate to the building',
       'Defects noted: An original internal wall', when=['actv_ia_outcome', 'No defects noted'], extra=[IA_DD]),
    pr('f3_ia_defects', 'ALTERATIONS_DEFECTS', 'Defects noted: An original internal wall', 'General Maintenance:',
       subs={'(type in location)': '{IA_LOCATION}', IAD: '{IA_ISSUES}'}, when=['actv_ia_outcome', 'Defects noted'],
       tokens=[txt('{IA_LOCATION}', 'et_ia_location', 'Opening location', cond='actv_ia_outcome=Defects noted'),
               ck('{IA_ISSUES}', 'Issues noted around the altered area', IAD, 'f3iad_', other=('f3iad_other', 'f3iad_other_text'),
                  cond='actv_ia_outcome=Defects noted')]),
]})

slices.append({'screen': 'activity_inside_property_walls_and_partitions_main_screen', 'rules': [
    pr('f3_intro', 'INTRO', 'My inspection was limited by', 'Description: The walls are formed in', first=True,
       when=[RATING[0], RATING[1]], when_any=RATING[2])]})
slices.append({'remove_screens': [I_ + 'repair_wall_repair', I_ + 'repair_sealants', 'activity_inside_property_wap_not_inspected',
                                  I_ + 'repair_removed_wall']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
