# -*- coding: utf-8 -*-
"""Generate slices/f2_e.json (F2 Ceilings). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f2_e.json')
S = 'F2'
MW = '{F_CEILINGS}'
G = 'group_ceilings_61'
C_ = 'inside_property_ceilings_'
A_ = 'activity_inside_property_ceilings_'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F2_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None, cap=False):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond, cap=cap)


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': G, 'order': order, 'after': after}


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


slices = []
ML = 'plaster, plasterboard, lath and plaster, other'
FL = 'painted, textured coating, papered, timber-clad, tiled, wallpapered, decorative panelled, other'
ABOUT = C_ + 'about_ceilings'
slices.append({'screen': ABOUT, 'replace_all': True, 'keep': [], 'rules': [
    pr('f2_desc', 'DESCRIPTION', 'Description: The ceilings are formed in', 'Condition: Where visible, the ceilings appear',
       subs={ML: '{CEILING_MATERIALS}', FL: '{CEILING_FINISHES}'},
       tokens=[ck('{CEILING_MATERIALS}', 'Ceilings formed in', ML, 'f2m_', other=('cb_other_406', 'et_other_339')),
               ck('{CEILING_FINISHES}', 'Finishes comprise', FL, 'f2f_', other=('cb_other_388', 'et_other_340'))]),
    pr('f2_cond', 'CONDITION', 'Condition: Where visible, the ceilings appear', 'If lath and plaster is selected',
       subs={COND_LIST: '{CEILING_CONDITION}'},
       tokens=[dd('{CEILING_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
    pr('f2_lath', 'LATH_PLASTER', 'If lath and plaster is selected, add this', 'If textured coating is selected',
       drop='If lath and plaster is selected, add this –',
       when=['f2m_lath_and_plaster', 'true']),
    pr('f2_textured', 'TEXTURED_COATING', 'If textured coating is selected, add this', 'Minor cracking:',
       drop='If textured coating is selected, add this –', when=['f2f_textured_coating', 'true']),
    pr('f2_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})
slices.append({'screen': A_ + 'cracks', 'replace_all': True, 'keep': [], 'rules': [
    pr('f2_crack_minor', 'MINOR_CRACKING', 'Minor cracking:', 'Significant cracking:', when=['actv_cracking', 'Minor cracking'],
       extra=[{'id': 'actv_cracking', 'label': 'Cracking', 'type': 'dropdown', 'options': ['Minor cracking', 'Significant cracking']}]),
    pr('f2_crack_major', 'SIGNIFICANT_CRACKING', 'Significant cracking:', 'Minor unevenness:',
       when=['actv_cracking', 'Significant cracking']),
]})
UN = 'bowing, undulations, unevenness, other'
S_UN = A_ + 'unevenness'
UN_DD = {'id': 'actv_unevenness', 'label': 'Unevenness', 'type': 'dropdown', 'options': ['Minor unevenness', 'Significant unevenness']}
slices.append({'screen': S_UN, 'new_screen': new_screen(S_UN, 'Unevenness', 12, A_ + 'cracks'), 'rules': [
    pr('f2_un_minor', 'MINOR_UNEVENNESS', 'Minor unevenness:', 'Significant unevenness:', subs={UN: '{CEILING_UNEVENNESS}'},
       when=['actv_unevenness', 'Minor unevenness'], extra=[UN_DD],
       tokens=[ck('{CEILING_UNEVENNESS}', 'Noted', UN, 'f2u_', other=('f2u_other', 'f2u_other_text'),
                  cond='actv_unevenness=Minor unevenness|Significant unevenness')]),
    pr('f2_un_major', 'SIGNIFICANT_UNEVENNESS', 'Significant unevenness:', 'Wet water staining:', subs={UN: '{CEILING_UNEVENNESS}'},
       when=['actv_unevenness', 'Significant unevenness'],
       tokens=[ck('{CEILING_UNEVENNESS}', 'Noted', UN, 'f2u_', other=('f2u_other', 'f2u_other_text'),
                  cond='actv_unevenness=Minor unevenness|Significant unevenness')]),
]})
LOC = 'lounge, dining room, bedroom, kitchen, bathroom, other'
SRC = 'loft space, roof, bathroom, floor above, another concealed source'
S_WS = A_ + 'water_staining'
WS_DD = {'id': 'actv_staining', 'label': 'Water staining', 'type': 'dropdown', 'options': ['Wet water staining', 'Dry water staining']}
slices.append({'screen': S_WS, 'new_screen': new_screen(S_WS, 'Water staining', 14, S_UN), 'rules': [
    pr('f2_ws_wet', 'WET_STAINING', 'Wet water staining:', 'Dry water staining:', subs={LOC: '{STAINING_LOCATIONS}', SRC: '{STAINING_SOURCES}'},
       when=['actv_staining', 'Wet water staining'], extra=[WS_DD],
       tokens=[ck('{STAINING_LOCATIONS}', 'Ceiling in', LOC, 'f2wl_', other=('f2wl_other', 'f2wl_other_text'),
                  cond='actv_staining=Wet water staining|Dry water staining'),
               ck('{STAINING_SOURCES}', 'Moisture suspected to originate from', SRC, 'f2ws_', cond='actv_staining=Wet water staining')]),
    pr('f2_ws_dry', 'DRY_STAINING', 'Dry water staining:', 'Polystyrene Ceiling Tiles:', subs={LOC: '{STAINING_LOCATIONS}'},
       when=['actv_staining', 'Dry water staining'],
       tokens=[ck('{STAINING_LOCATIONS}', 'Ceiling in', LOC, 'f2wl_', other=('f2wl_other', 'f2wl_other_text'),
                  cond='actv_staining=Wet water staining|Dry water staining')]),
]})
slices.append({'screen': A_ + 'polystyrene', 'replace_all': True, 'keep': [], 'rules': [
    pr('f2_poly', 'POLYSTYRENE', 'Polystyrene Ceiling Tiles:', 'Heavy decorative covering:', when=['cb_not_inspected', 'true'],
       extra=[cb('cb_not_inspected', 'Polystyrene ceiling tiles')])]})
slices.append({'screen': A_ + 'heavy_paper_lining', 'replace_all': True, 'keep': [], 'rules': [
    pr('f2_heavy', 'HEAVY_COVERING', 'Heavy decorative covering:', 'Ornamental plaster repair:', when=['cb_not_inspected', 'true'],
       extra=[cb('cb_not_inspected', 'Heavy decorative covering')])]})
OP = 'loose, cracked, damaged, unstable, partially missing, other'
slices.append({'screen': A_ + 'repairs_ornamental_plaster', 'replace_all': True, 'keep': [], 'rules': [
    pr('f2_ornamental', 'ORNAMENTAL_PLASTER', 'Ornamental plaster repair:', 'General Maintenance:', subs={OP: '{ORNAMENTAL_DEFECTS}'},
       tokens=[ck('{ORNAMENTAL_DEFECTS}', 'Ornamental plaster is', OP, 'f2o_', other=('f2o_other', 'f2o_other_text'))])]})
slices.append({'screen': A_ + 'main_screen', 'rules': [
    pr('f2_intro', 'INTRO', 'The ceilings have been inspected from within the rooms only', 'Description: The ceilings are formed in',
       first=True, when=[RATING[0], RATING[1]], when_any=RATING[2])]})
slices.append({'remove_screens': [A_ + 'repairs_ceilings', A_ + 'contains_asbestos', A_ + 'not_inspected']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
