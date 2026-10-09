# -*- coding: utf-8 -*-
"""Generate slices/j1_e.json (J1 Risk to building). Text is cut from the PDF block; each paragraph has its own tick-box."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (checks, lst, opts, para_rule)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'j1_e.json')
S = 'J1'
MW = '{RISK_TO_BUILDING}'
SCREEN = 'activity_risks_risk_to_building_'


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def R(rid, sub, start, end, label, lists=()):
    subs, tokens = {}, []
    for n, (pdf, tok, lab, explicit) in enumerate(lists):
        pre = f'{rid}_{n}_'
        subs[pdf] = tok
        tokens.append(checks(tok, lab, explicit if explicit is not None else opts(pre, lst(pdf)), other=None))
    fid = 'cb_j1_' + rid[3:]
    return para_rule(S, rid, [MW], '{J1_%s}' % sub, start, end, subs=subs or None, tokens=tokens,
                     when=[fid, 'true'], extra=[cb(fid, label)])


SM = 'historic, localised, recurring, progressive'
WP = 'roof leakage, penetrating damp, plumbing leakage, condensation, and localised dampness'
TD = 'wet rot, dry rot, localised timber decay'
CO = 'condensation, surface mould growth, limited ventilation'
DR = 'blocked gullies, standing water, poor surface drainage, localised ponding'

slices = [
    {'screen': SCREEN, 'replace_all': True, 'keep': [], 'rules': [
        R('j1_structural', 'STRUCTURAL_MOVEMENT', 'Structural Movement:', 'Water Penetration:', 'Structural movement',
          [(SM, '{J1_MOVEMENT_KIND}', 'Evidence of', None)]),
        R('j1_water', 'WATER_PENETRATION', 'Water Penetration:', 'Timber Decay:', 'Water penetration',
          [(WP, '{J1_WATER_SOURCE}', 'Evidence of',
            [('j1w_roof_leakage', 'roof leakage'), ('j1w_penetrating_damp', 'penetrating damp'),
             ('j1w_plumbing_leakage', 'plumbing leakage'), ('j1w_condensation', 'condensation'),
             ('j1w_localised_dampness', 'localised dampness')])]),
        R('j1_timber', 'TIMBER_DECAY', 'Timber Decay:', 'Wood-Boring Insects:', 'Timber decay',
          [(TD, '{J1_TIMBER_DECAY_KIND}', 'Evidence of', None)]),
        R('j1_woodboring', 'WOOD_BORING_INSECTS', 'Wood-Boring Insects:', 'Condensation:', 'Wood-boring insects'),
        R('j1_condensation', 'CONDENSATION', 'Condensation:', 'Drainage:', 'Condensation',
          [(CO, '{J1_CONDENSATION_KIND}', 'Evidence of', None)]),
        R('j1_drainage', 'DRAINAGE', 'Drainage:', 'Significant subsidence:', 'Drainage',
          [(DR, '{J1_DRAINAGE_KIND}', 'Evidence of', None)]),
        R('j1_subsidence', 'SIGNIFICANT_SUBSIDENCE', 'Significant subsidence:', 'Tree defects:', 'Significant subsidence'),
        R('j1_trees', 'TREE_DEFECTS', 'Tree defects:', None, 'Tree defects'),
    ]},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
