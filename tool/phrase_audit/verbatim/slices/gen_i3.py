# -*- coding: utf-8 -*-
"""Generate slices/i3_e.json (I3 Other matters). Text is cut from the PDF block; each paragraph has its own tick-box."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'i3_e.json')
S = 'I3'
MW = '{ISSUE_OTHER_MATTERS}'
SCREEN = 'activity_issues_other_matters'


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


# (rule id, bank sub, PDF start, field id, label); each paragraph ends where the next starts.
ITEMS = [
    ('i3_freehold', 'FREEHOLD', 'Freehold Property:', 'cb_freehold', 'Freehold property'),
    ('i3_leasehold', 'LEASEHOLD', 'Leasehold Property:', 'cb_leasehold', 'Leasehold property'),
    ('i3_share', 'SHARE_OF_FREEHOLD', 'Share of Freehold Property:', 'cb_i3_share', 'Share of freehold property'),
    ('i3_flying', 'FLYING_FREEHOLD', 'Flying Freehold:', 'cb_i3_flying', 'Flying freehold'),
    ('i3_road', 'PRIVATE_ROAD', 'Private Road:', 'cb_private_road', 'Private road'),
    ('i3_row', 'RIGHTS_OF_WAY', 'Rights of Way:', 'cb_right_of_way', 'Rights of way'),
    ('i3_party', 'PARTY_WALL', 'Party Wall:', 'cb_party_walls', 'Party wall'),
    ('i3_tenanted', 'TENANTED', 'Tenanted Property:', 'cb_tenanted', 'Tenanted property'),
    ('i3_general', 'GENERAL_LEGAL_ENQUIRIES', 'General Legal Enquiries:', 'cb_i3_general', 'General legal enquiries'),
]
# The last paragraph ends before the "J Risks" section intro the digitiser attached to this block.
LAST_END = 'J Risks'

rules = []
for n, (rid, sub, start, fid, label) in enumerate(ITEMS):
    end = ITEMS[n + 1][2] if n + 1 < len(ITEMS) else LAST_END
    rules.append(para_rule(S, rid, [MW], '{I3_%s}' % sub, start, end, when=[fid, 'true'], extra=[cb(fid, label)]))

slices = [{'screen': SCREEN, 'replace_all': True, 'keep': [], 'rules': rules}]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', len(rules), 'rules')
