# -*- coding: utf-8 -*-
"""Generate slices/h3_e.json (H3 Other area). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (checks, dd, lst, opts, para_rule)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'h3_e.json')
S = 'H3'
MW = '{H_OTHER_AREA}'


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def oth(p):
    return (p + 'other', p + 'other_text')


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{H3_{sub}}}', start, end, **kw)


ROW = 'private road, driveway, footpath, entrance lobby, or other shared access'
FLOOD = 'river, canal, the coast, low-lying land, reservoir, other watercourse'
EMF = 'electricity substation, high-voltage overhead power lines, pylons, other'
STATUS = 'actv_status'
STATUS_DD = {'id': STATUS, 'label': 'Japanese knotweed', 'type': 'dropdown', 'options': ['Not inspected', 'Not found', 'Found']}
MGMT = 'actv_h3_management'
MGMT_DD = {'id': MGMT, 'label': 'Knotweed management', 'type': 'dropdown',
           'options': ['Management A', 'Management B', 'Management C', 'Management D']}

slices = [
    {'screen': 'activity_grounds_other_area_right_of_way', 'replace_all': True, 'keep': [], 'rules': [
        pr('h3_row', 'RIGHT_OF_WAY', 'Right of Way:', 'Lifts:', subs={ROW: '{H3_RIGHT_OF_WAY_OVER}'},
           when=['cb_h3_row', 'true'], extra=[cb('cb_h3_row', 'Right of way')],
           tokens=[checks('{H3_RIGHT_OF_WAY_OVER}', 'Shared rights of way over',
                          [('h3r_private_road', 'private road'), ('h3r_driveway', 'driveway'), ('h3r_footpath', 'footpath'),
                           ('h3r_entrance_lobby', 'entrance lobby')], other=oth('h3r_'))]),
    ]},
    {'screen': 'activity_grounds_other_area_lifts', 'replace_all': True, 'keep': [], 'rules': [
        pr('h3_lifts', 'LIFTS', 'Lifts:', 'Flooding:', when=['cb_lifts', 'true'], extra=[cb('cb_lifts', 'Lifts')]),
    ]},
    {'screen': 'activity_grounds_other_area_flooding', 'replace_all': True, 'keep': [], 'rules': [
        pr('h3_flooding', 'FLOODING', 'Flooding:', 'Electromagnetic Fields (EMF):', subs={FLOOD: '{H3_FLOOD_PROXIMITY}'},
           when=['cb_h3_flooding', 'true'], extra=[cb('cb_h3_flooding', 'Flooding risk')],
           tokens=[checks('{H3_FLOOD_PROXIMITY}', 'Close to', opts('h3f_', lst(FLOOD)), other=None)]),
    ]},
    {'screen': 'activity_grounds_other_area_emf', 'replace_all': True, 'keep': [], 'rules': [
        pr('h3_emf', 'EMF', 'Electromagnetic Fields (EMF):', 'Japanese Knotweed Not Inspected:', subs={EMF: '{H3_EMF_SOURCE}'},
           when=['cb_h3_emf', 'true'], extra=[cb('cb_h3_emf', 'Electromagnetic fields')],
           tokens=[checks('{H3_EMF_SOURCE}', 'Located close to', opts('h3e_', lst(EMF)), other=oth('h3e_'))]),
    ]},
    {'screen': 'activity_grounds_other_area_knotweed', 'replace_all': True, 'keep': [], 'rules': [
        pr('h3_kw_not_inspected', 'KNOTWEED_NOT_INSPECTED', 'Japanese Knotweed Not Inspected:', 'Not Found:',
           when=[STATUS, 'Not inspected'], extra=[STATUS_DD]),
        pr('h3_kw_not_found', 'KNOTWEED_NOT_FOUND', 'Not Found:', 'Found:', when=[STATUS, 'Not found']),
        pr('h3_kw_found', 'KNOTWEED_FOUND', 'Found: Japanese knotweed was identified', 'Management A:',
           when=[STATUS, 'Found'], extra=[MGMT_DD]),
        pr('h3_kw_a', 'MANAGEMENT_A', 'Management A:', 'Management B:', when=[MGMT, 'Management A']),
        pr('h3_kw_b', 'MANAGEMENT_B', 'Management B:', 'Management C:', when=[MGMT, 'Management B']),
        pr('h3_kw_c', 'MANAGEMENT_C', 'Management C:', 'Management D:', when=[MGMT, 'Management C']),
        pr('h3_kw_d', 'MANAGEMENT_D', 'Management D:', None, when=[MGMT, 'Management D']),
    ]},
    {'remove_screens': ['activity_grounds_other_area_common_garden', 'activity_grounds_other_area_not_inspected']},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
