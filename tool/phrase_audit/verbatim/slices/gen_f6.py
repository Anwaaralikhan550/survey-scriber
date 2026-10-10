# -*- coding: utf-8 -*-
"""Generate slices/f6_e.json (F6 Built-in fittings). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f6_e.json')
S = 'F6'
MW = '{F_BUILT_IN_FITTINGS}'
G = 'group_f6_built_in_fittings_72'
I_ = 'activity_in_side_property_built_in_fittings'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F6_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': G, 'order': order, 'after': after}


slices = []
WL = 'kitchen, utility room, other'
WT = ('laminate particle board, solid timber, granite, quartz, stone, Corian, compressed composite, marble, steel, '
      'other')
FM = 'timber, vinyl-wrapped timber, laminated MDF, other'
SM = 'stainless steel, ceramic, composite, stone, other'
AP = ('oven, hob, extractor hood, microwave, dishwasher, refrigerator, freezer, washing machine, tumble dryer, '
      'other')
slices.append({'screen': I_, 'replace_all': True, 'keep': [], 'rules': [
    pr('f6_worktops', 'WORKTOPS', 'Worktop(s):', 'Fittings: The', subs={WL: '{WT_ROOMS}', WT: '{WORKTOP_MATERIALS}'},
       tokens=[ck('{WT_ROOMS}', 'Worktops in', WL, 'f6wr_', other=('cb_other_1008', 'et_other_764')),
               ck('{WORKTOP_MATERIALS}', 'Worktops comprise', WT, 'f6wt_', other=('cb_other_672', 'et_other_614'))]),
    pr('f6_fittings', 'FITTINGS', 'Fittings: The', 'Condition: Where visible, they appear', subs={WL: '{FT_ROOMS}', FM: '{FITTING_MATERIALS}'},
       tokens=[ck('{FT_ROOMS}', 'Units in', WL, 'f6fr_', other=('f6fr_other', 'f6fr_other_text')),
               ck('{FITTING_MATERIALS}', 'Units formed in', FM, 'f6fm_', other=('cb_other_343', 'et_other_745'))]),
    pr('f6_cond', 'CONDITION', 'Condition: Where visible, they appear', 'Fittings defects:', subs={COND_LIST: '{FITTING_CONDITION}'},
       tokens=[dd('{FITTING_CONDITION}', 'android_material_design_spinner3', 'Condition', COND5, lower=True)]),
    pr('f6_sink', 'KITCHEN_SINK', 'Kitchen Sink:', 'Sealant defects:', subs={WL: '{SINK_ROOMS}', SM: '{SINK_MATERIAL}', COND_LIST: '{SINK_CONDITION}'},
       tokens=[ck('{SINK_ROOMS}', 'Sink in', WL, 'f6sr_', other=('f6sr_other', 'f6sr_other_text')),
               ck('{SINK_MATERIAL}', 'Sink formed in', SM, 'f6sm_', other=('f6sm_other', 'f6sm_other_text')),
               dd('{SINK_CONDITION}', 'actv_sink_condition', 'Sink condition', COND5, lower=True)]),
    pr('f6_appliances', 'APPLIANCES', 'Built-in Appliances:', 'Extractor Fan:', subs={AP: '{APPLIANCES}'},
       tokens=[ck('{APPLIANCES}', 'The property incorporates', AP, 'f6ap_', other=('f6ap_other', 'f6ap_other_text'))]),
    pr('f6_extractor', 'EXTRACTOR_FAN', 'Extractor Fan:', 'Defects: One or more of the following',
       subs={'operating, not operating': '{EXTRACTOR_STATE}'},
       tokens=[dd('{EXTRACTOR_STATE}', 'actv_extractor', 'Extractor fan', ['Operating', 'Not operating'], lower=True)]),
    pr('f6_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})
slices.append({'screen': I_ + '_repair_fittings', 'replace_all': True, 'keep': [], 'rules': [
    pr('f6_fit_defects', 'FITTINGS_DEFECTS', 'Fittings defects:', 'Kitchen Sink:', when=['cb_fittings_defects', 'true'],
       extra=[cb('cb_fittings_defects', 'Fittings defects')])]})
SD = 'cracked, damaged, moulded, worn, missing'
slices.append({'screen': I_ + '_repair_defective_sealants', 'replace_all': True, 'keep': [], 'rules': [
    pr('f6_sealant', 'SEALANT_DEFECTS', 'Sealant defects:', 'Built-in Appliances:', subs={SD: '{SEALANT_DEFECT_LIST}'},
       tokens=[ck('{SEALANT_DEFECT_LIST}', 'Sealant is', SD, 'f6sd_')])]})
B = '•'
DL = ['damaged cupboard doors', 'loose hinges', 'damaged worktops', 'worn finishes', 'defective sealant', 'cracked wall tiles',
      'damaged plinths', 'water-damaged units', 'misaligned drawers', 'loose handles']
slices.append({'screen': I_ + '_repair_moulding_noted', 'replace_all': True, 'keep': [], 'rules': [
    pr('f6_defects', 'DEFECTS_LIST', 'Defects: One or more of the following', 'General Maintenance:',
       subs={' '.join(f'{B} {x}' for x in DL): '{FITTING_DEFECT_LIST}.'},
       tokens=[checks('{FITTING_DEFECT_LIST}', 'One or more of the following defects were observed', opts('f6dl_', DL))])]})
slices.append({'screen': 'activity_inside_property_built_in_fittings_main_screen', 'rules': [
    pr('f6_intro', 'INTRO', 'The inspection was limited by stored items', 'Worktop(s):', first=True,
       when=[RATING[0], RATING[1]], when_any=RATING[2])]})
slices.append({'remove_screens': [I_ + '_not_inspected', I_ + '_repair_water_seepage']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
