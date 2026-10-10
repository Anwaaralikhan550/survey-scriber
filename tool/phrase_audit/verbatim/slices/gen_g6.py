# -*- coding: utf-8 -*-
"""Generate slices/g6_e.json (G6 Drainage). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (P, add_or_set, checks, lst, opts, para_rule, set_keys)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'g6_e.json')
S = 'G6'
MW = '{G_DRAINAGE}'
ABOUT = 'activity_services_drainage'
REPAIR = 'activity_services_drainage_repair_chamber_cover'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{G6_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def oth(p):
    return (p + 'other', p + 'other_text')


# ── static text: the unlabelled opening paragraph of the block (printed by report_builder via STANDARD_TEXT_2) ──
intro, _ = P(S, 'Inspection of the accessible inspection chamber', 'Septic Tank:')
set_keys([add_or_set('{G_DRAINAGE}::{STANDARD_TEXT_2}', intro)])

CF = 'blockage, recent blockage, significant defect, other'
SL = 'front, rear, side, other'
SM = 'plastic, cast iron, asbestos cement, other'
CV = 'broken, corroded, poorly secured, other'
CW = 'cracked, crumbling, damaged, other'
DC = 'cracked, poorly formed, partially blocked, other'
SD = 'cracked, damaged, corroded, leaking, inadequately supported, other'
GU = 'partly blocked, damaged, uncovered, completely blocked, other'

slices = [
    {'screen': ABOUT, 'replace_all': True, 'keep': [], 'rules': [
        pr('g6_septic', 'SEPTIC_TANK', 'Septic Tank:', 'Cesspit (Cesspool):', when=['cb_septic_tank', 'true'],
           extra=[cb('cb_septic_tank', 'Septic tank')]),
        pr('g6_cesspit', 'CESSPIT', 'Cesspit (Cesspool):', 'Public Sewer:', when=['cb_cess_pit', 'true'],
           extra=[cb('cb_cess_pit', 'Cesspit (cesspool)')]),
        pr('g6_public', 'PUBLIC_SEWER', 'Public Sewer:', 'No defects noted:', when=['cb_public_system', 'true'],
           extra=[cb('cb_public_system', 'Public sewer')]),
        pr('g6_no_defects', 'NO_DEFECTS_NOTED', 'No defects noted:', 'Inspection Chamber:', when=['cb_dr_no_defects', 'true'],
           extra=[cb('cb_dr_no_defects', 'No defects noted')]),
        pr('g6_chamber', 'INSPECTION_CHAMBER', 'Inspection Chamber:', 'Not Inspected:', subs={CF: '{DRAIN_CHAMBER_FINDING}'},
           when=['cb_dr_chamber', 'true'], extra=[cb('cb_dr_chamber', 'Inspection chamber')],
           tokens=[ck('{DRAIN_CHAMBER_FINDING}', 'Chamber finding', CF, 'g6cf_', other=oth('g6cf_'))]),
        pr('g6_not_inspected', 'NOT_INSPECTED', 'Not Inspected:', 'Shared Drainage:', when=['cb_dr_not_inspected', 'true'],
           extra=[cb('cb_dr_not_inspected', 'Not inspected')]),
        pr('g6_shared', 'SHARED_DRAINAGE', 'Shared Drainage:', 'Soil and Vent Pipe:', when=['cb_shared', 'true'],
           extra=[cb('cb_shared', 'Shared drainage')]),
        pr('g6_svp', 'SOIL_AND_VENT_PIPE', 'Soil and Vent Pipe:', 'Visible/Partially Visible:',
           subs={SL: '{DRAIN_SVP_LOCATION}', SM: '{DRAIN_SVP_MATERIAL}'},
           when=['cb_dr_svp', 'true'], extra=[cb('cb_dr_svp', 'Soil and vent pipe')],
           tokens=[ck('{DRAIN_SVP_LOCATION}', 'Visible at the', SL, 'g6sl_', other=oth('g6sl_')),
                   checks('{DRAIN_SVP_MATERIAL}', 'Constructed of',
                          [('cb_material_plastic_pipe', 'plastic'), ('cb_material_cast_iron', 'cast iron'),
                           ('cb_material_asbestos_cement', 'asbestos cement')], other=oth('g6sm_'))]),
        pr('g6_svp_visible', 'SVP_VISIBLE', 'Visible/Partially Visible:', 'Defect repairs',
           subs={'roof space/other': '{DRAIN_SVP_VISIBLE_IN}'}, when=['cb_dr_svp_visible', 'true'],
           extra=[cb('cb_dr_svp_visible', 'Visible / partially visible')],
           tokens=[checks('{DRAIN_SVP_VISIBLE_IN}', 'Sections visible in the', [('g6sv_roof_space', 'roof space')],
                          other=oth('g6sv_'))]),
    ]},
    {'screen': REPAIR, 'set_title': 'Drainage Repairs', 'replace_all': True, 'keep': [], 'rules': [
        pr('g6_cover', 'CHAMBER_COVER', 'Inspection Chamber Cover:', 'Inspection Chamber Walls:', subs={CV: '{DRAIN_COVER_DEFECT}'},
           when=['cb_g6_cover', 'true'], extra=[cb('cb_g6_cover', 'Inspection chamber cover')],
           tokens=[ck('{DRAIN_COVER_DEFECT}', 'Cover defect', CV, 'g6cv_', other=oth('g6cv_'))]),
        pr('g6_walls', 'CHAMBER_WALLS', 'Inspection Chamber Walls:', 'Drain Channels:', subs={CW: '{DRAIN_WALL_DEFECT}'},
           when=['cb_g6_walls', 'true'], extra=[cb('cb_g6_walls', 'Inspection chamber walls')],
           tokens=[ck('{DRAIN_WALL_DEFECT}', 'Wall defect', CW, 'g6cw_', other=oth('g6cw_'))]),
        pr('g6_channels', 'DRAIN_CHANNELS', 'Drain Channels:', 'Soil and Vent Pipe Defects:', subs={DC: '{DRAIN_CHANNEL_DEFECT}'},
           when=['cb_g6_channels', 'true'], extra=[cb('cb_g6_channels', 'Drain channels')],
           tokens=[ck('{DRAIN_CHANNEL_DEFECT}', 'Channel defect', DC, 'g6dc_', other=oth('g6dc_'))]),
        pr('g6_svp_defects', 'SVP_DEFECTS', 'Soil and Vent Pipe Defects:', 'Tree Root Ingress:', subs={SD: '{DRAIN_SVP_DEFECT}'},
           when=['cb_g6_svp_defects', 'true'], extra=[cb('cb_g6_svp_defects', 'Soil and vent pipe defects')],
           tokens=[ck('{DRAIN_SVP_DEFECT}', 'Pipe defect', SD, 'g6sd_', other=oth('g6sd_'))]),
        pr('g6_roots', 'TREE_ROOT_INGRESS', 'Tree Root Ingress:', 'Gullies:', when=['cb_roots_in_chamber', 'true'],
           extra=[cb('cb_roots_in_chamber', 'Tree root ingress')]),
        pr('g6_gullies', 'GULLIES', 'Gullies:', 'Asbestos Cement Soil Stack:', subs={GU: '{DRAIN_GULLY_DEFECT}'},
           when=['cb_g6_gullies', 'true'], extra=[cb('cb_g6_gullies', 'Gullies')],
           tokens=[ck('{DRAIN_GULLY_DEFECT}', 'Gully defect', GU, 'g6gu_', other=oth('g6gu_'))]),
        pr('g6_asbestos', 'ASBESTOS_SOIL_STACK', 'Asbestos Cement Soil Stack:', 'Condition rating',
           when=['cb_g6_asbestos', 'true'], extra=[cb('cb_g6_asbestos', 'Asbestos cement soil stack')]),
    ]},
    {'remove_screens': ['activity_services_drainage_repair_chamber_walls', 'activity_services_drainage_repair_chamber_pipes',
                        'activity_services_drainage_repair_soil_and_vent', 'activity_services_drainage_repair_roots_in_chamber',
                        'activity_services_drainage_repair_gullies', 'activity_services_drainage_repair_defect_dampness',
                        'activity_services_drainage_not_inspected', 'activity_services_drainage_chamber_lids',
                        'activity_services_drainage_public_system']},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
