# -*- coding: utf-8 -*-
"""Generate slices/f8_e.json (F8 Bathroom fittings). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f8_e.json')
S = 'F8'
MW = '{F_BATHROOM_FITTINGS}'
G = 'group_bathroom_fitting_78'
I_ = 'activity_in_side_property_bathroom_fittings'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F8_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


slices = []
RM = 'family bathroom(s), shower room(s), ensuite shower room(s), ensuite bathroom(s), separate toilet(s), utility room'
SW = ('bathtub(s), shower(s), wash hand basin(s), WCs, bidet(s), mains pressure shower, electric shower, thermostatic '
      'shower, shower enclosure, wet room, other')
WF = 'ceramic tiles, stone tiles, water-resistant wall panels, painted plaster, other'
slices.append({'screen': I_ + '_second', 'replace_all': True, 'keep': [], 'rules': [
    pr('f8_desc', 'DESCRIPTION', 'Description: The property incorporates', 'Sanitary ware:', subs={RM + ', other': '{BATH_ROOMS}'},
       tokens=[ck('{BATH_ROOMS}', 'The property incorporates', RM + ', other', 'f8r_', other=('cb_other_653', 'et_other_836'))]),
    pr('f8_sanitary', 'SANITARY_WARE', 'Sanitary ware:', 'Wall finishes:', subs={SW: '{SANITARY_WARE}'},
       tokens=[ck('{SANITARY_WARE}', 'Fitted with', SW, 'f8s_', other=('f8s_other', 'f8s_other_text'))]),
    pr('f8_walls', 'WALL_FINISHES', 'Wall finishes:', 'Condition: Where visible, the bathroom fittings appear', subs={WF: '{BATH_WALL_FINISHES}'},
       tokens=[ck('{BATH_WALL_FINISHES}', 'Wall finishes comprise', WF, 'f8w_', other=('f8w_other', 'f8w_other_text'))]),
    pr('f8_cond', 'CONDITION', 'Condition: Where visible, the bathroom fittings appear', 'Sealants:', subs={COND_LIST: '{BATH_CONDITION}'},
       tokens=[dd('{BATH_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
    pr('f8_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})
slices.append({'screen': I_ + '_sealant', 'replace_all': True, 'keep': [], 'rules': [
    pr('f8_sealants', 'SEALANTS', 'Sealants:', 'Working extractor fan:', subs={COND_LIST: '{SEALANT_CONDITION}'},
       tokens=[dd('{SEALANT_CONDITION}', 'actv_sealant_condition', 'Sealant condition', COND5, lower=True)])]})
FAN_DD = {'id': 'actv_status', 'label': 'Extractor fan', 'type': 'dropdown', 'options': ['Working extractor fan', 'Fan not working']}
slices.append({'screen': I_ + '_extractor_fan', 'replace_all': True, 'keep': [], 'rules': [
    pr('f8_fan_ok', 'FAN_WORKING', 'Working extractor fan:', 'Fan not working:', subs={RM: '{FAN_ROOMS}'},
       when=['actv_status', 'Working extractor fan'], extra=[FAN_DD],
       tokens=[ck('{FAN_ROOMS}', 'Fan(s) installed in', RM, 'f8f_', cond='actv_status=Working extractor fan|Fan not working')]),
    pr('f8_fan_bad', 'FAN_NOT_WORKING', 'Fan not working:', 'Defects: One or more of the following', subs={RM: '{FAN_ROOMS}'},
       when=['actv_status', 'Fan not working'],
       tokens=[ck('{FAN_ROOMS}', 'Fan(s) installed in', RM, 'f8f_', cond='actv_status=Working extractor fan|Fan not working')]),
]})
B = '•'
DL = ['defective sealant', 'cracked sanitary ware', 'damaged wall tiles', 'damaged cubicle/screen', 'loose floor tiles',
      'poor ventilation', 'condensation', 'mould growth', 'water staining', 'damaged fittings', 'damaged bathtub panel',
      'minor plumbing leaks']
slices.append({'screen': I_ + '_repair', 'replace_all': True, 'keep': [], 'rules': [
    pr('f8_defects', 'DEFECTS_LIST', 'Defects: One or more of the following', 'General Maintenance:',
       subs={' '.join(f'{B} {x}' for x in DL): '{BATH_DEFECT_LIST}.'},
       tokens=[checks('{BATH_DEFECT_LIST}', 'One or more of the following defects were observed', opts('f8dl_', DL))])]})
slices.append({'screen': 'activity_inside_property_bathroom_fittings_main_screen', 'rules': [
    pr('f8_intro', 'INTRO', 'The inspection was limited by stored items', 'Description: The property incorporates', first=True,
       when=[RATING[0], RATING[1]], when_any=RATING[2])]})
slices.append({'remove_screens': [I_ + '_extractor_fan__no_extractor_fan_installed', I_ + '_leaking', I_ + '_mould',
                                  I_ + '_wood_rot', 'activity_in_side_property_cubicle_safety_glass_rating',
                                  'activity_in_side_property_bathroom_fitting_not_inspected']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
