# -*- coding: utf-8 -*-
"""Generate slices/i2_e.json (I2 Guarantees). Text is cut from the PDF block; each item has its own tick-box."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'i2_e.json')
S = 'I2'
MW = '{ISSUE_GUARANTEES}'
SCREEN = 'activity_issues_glazed_sections'


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


ITEMS = [
    ('i2_intro', 'INTRO', 'Where applicable, your legal adviser should obtain copies', 'cb_i2_intro', 'Standard introduction'),
    ('i2_windows', 'WINDOWS_DOORS', 'Window/doors:', 'cb_i2_windows', 'Window / doors'),
    ('i2_boiler', 'BOILER', 'Boiler:', 'cb_i2_boiler', 'Boiler'),
    ('i2_structural', 'STRUCTURAL_ALTERATIONS', 'Structural alterations:', 'cb_i2_structural', 'Structural alterations'),
    ('i2_dpc', 'DPC_TREATMENT', 'DPC treatment:', 'cb_i2_dpc', 'DPC treatment'),
    ('i2_timber', 'TIMBER_TREATMENT', 'Timber treatment:', 'cb_i2_timber', 'Timber treatment'),
    ('i2_cavity', 'CAVITY_INSULATION', 'Cavity insulation:', 'cb_i2_cavity', 'Cavity insulation'),
    ('i2_spray', 'SPRAY_FOAM', 'Spray foam:', 'cb_i2_spray', 'Spray foam'),
    ('i2_renewable', 'RENEWABLE_ENERGY', 'Renewable energy:', 'cb_i2_renewable', 'Renewable energy'),
    ('i2_others', 'OTHERS', 'Others:', 'cb_i2_others', 'Others'),
]

rules = []
for n, (rid, sub, start, fid, label) in enumerate(ITEMS):
    end = ITEMS[n + 1][2] if n + 1 < len(ITEMS) else None
    rules.append(para_rule(S, rid, [MW], '{I2_%s}' % sub, start, end, when=[fid, 'true'], extra=[cb(fid, label)]))

slices = [{'screen': SCREEN, 'replace_all': True, 'keep': [], 'rules': rules}]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', len(rules), 'rules')
