# -*- coding: utf-8 -*-
"""Generate slices/g7_e.json (G7 Common services). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (checks, lst, opts, para_rule)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'g7_e.json')
S = 'G7'
MW = '{G_COMMON_SERVICES}'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{G7_{sub}}}', start, end, **kw)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


CS = ('shared drainage, grounds maintenance, cleaning, lifts, communal heating, hot water systems, door entry systems, '
      'vehicular access, parking areas, other')

slices = [
    {'screen': 'activity_services_shared_services', 'replace_all': True, 'keep': [], 'rules': [
        pr('g7_na', 'NOT_APPLICABLE', 'Not applicable:', 'Description:', when=['cb_not_applicable', 'true'],
           extra=[cb('cb_not_applicable', 'Not applicable')]),
        pr('g7_desc', 'DESCRIPTION', 'Description:', 'Condition rating', subs={CS: '{CS_SERVICES}'},
           when=['cb_cs_communal', 'true'], extra=[cb('cb_cs_communal', 'Communal services')],
           tokens=[checks('{CS_SERVICES}', 'Communal services and installations', opts('g7s_', lst(CS)),
                          other=('g7s_other', 'g7s_other_text'))]),
    ]},
    {'remove_screens': ['activity_services_shared_services_not_inspected']},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
