# -*- coding: utf-8 -*-
"""Generate slices/j3_e.json (J3 Risk to people: native screen, one tick-box per PDF paragraph)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import block, checks, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'j3_e.json')
S, MW = 'J3', '{RISK_TO_PEOPLE}'
SCREEN = 'activity_risks_risk_to_people_'
TRIP = 'uneven paving, damaged steps, raised thresholds, uneven floor surfaces, loose floor coverings, damaged decking, other'


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def pr(rid, sub, start, end, label, **kw):
    fid = 'cb_' + rid
    return para_rule(S, rid, [MW], '{J3_%s}' % sub, start, end, when=[fid, 'true'], extra=[cb(fid, label)], **kw)


# The PDF prints the Control of Asbestos Regulations in bold (**...**); the markers are not report text (CLIENT_QUERIES #11).
assert '**' in block(S)
rules = [
    pr('j3_trip', 'TRIP_HAZARDS', 'Trip Hazards:', 'Damaged Stairs:', 'Trip hazards', subs={TRIP: '{J3_TRIP_LIST}'},
       tokens=[checks('{J3_TRIP_LIST}', 'Including', opts('j3t_', lst(TRIP)), other=('j3t_other', 'j3t_other_text'))]),
    pr('j3_stairs', 'DAMAGED_STAIRS', 'Damaged Stairs:', 'Electrical Safety:', 'Damaged stairs'),
    pr('j3_electrical', 'ELECTRICAL_SAFETY', 'Electrical Safety:', 'Gas Safety:', 'Electrical safety'),
    pr('j3_gas', 'GAS_SAFETY', 'Gas Safety:', 'Asbestos:', 'Gas safety'),
    pr('j3_asbestos', 'ASBESTOS', 'Asbestos:', 'Mould Growth:', 'Asbestos'),
    pr('j3_mould', 'MOULD_GROWTH', 'Mould Growth:', 'General Advice:', 'Mould growth'),
    pr('j3_general', 'GENERAL_ADVICE', 'General Advice:', None, 'General advice'),
]
slices = [{'screen': SCREEN, 'new_screen': {'id': SCREEN, 'title': 'J3 Risk To People', 'parent': None, 'order': 3,
                                            'after': 'activity_risks_risk_to_building_'},
           'replace_all': True, 'keep': [], 'rules': rules}]
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(rules), 'rules')
