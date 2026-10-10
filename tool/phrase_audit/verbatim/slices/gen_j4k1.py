# -*- coding: utf-8 -*-
"""Generate slices/j4k1_e.json (J4 Other risks proximity + further investigations; K1 Valuation assumptions)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import para_rule  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'j4k1_e.json')


def pr(sub, rid, master, start, end, fid, label):
    return para_rule('J4', rid, [master], '{%s}' % sub, start, end, when=[fid, 'true'],
                     extra=[field(fid, label, 'checkbox')])


J = '{RISK_TO_OTHER}'
K = '{K1_VALUATION}'
slices = [
    {'screen': 'activity_risks_other_', 'replace_all': True, 'keep': [], 'rules': [
        pr('J4_AIRPORT', 'j4_airport', J, 'Airport:', 'Train Station:', 'cb_airport', 'Airport'),
        pr('J4_TRAIN_STATION', 'j4_station', J, 'Train Station:', 'Railway Line:', 'cb_train_station', 'Train Station'),
        pr('J4_RAILWAY_LINE', 'j4_line', J, 'Railway Line:', 'Motorway:', 'cb_train_line', 'Railway Line'),
        pr('J4_MOTORWAY', 'j4_motorway', J, 'Motorway:', 'Further Investigations and Repairs:', 'cb_motorway', 'Motorway'),
    ]},
    {'screen': 'activity_risks_repair_or_improve', 'replace_all': True, 'keep': [], 'rules': [
        pr('J4_FURTHER_INVESTIGATIONS', 'j4_further', J, 'Further Investigations and Repairs:', 'K1 Valuations assumptions',
           'cb_repair_or_improve', 'Further investigations and repairs')]},
    {'screen': 'activity_k1_valuation_assumptions',
     'new_screen': {'id': 'activity_k1_valuation_assumptions', 'title': 'K1 Valuation assumptions', 'parent': None,
                    'order': 2, 'after': 'activity_capture_floor_site_plan_sketches'},
     'replace_all': True, 'keep': [], 'rules': [
        pr('K1_MARKET_VALUE', 'k1_market', K, 'Market Value:', 'Flats:', 'cb_k1_market', 'Market value'),
        pr('K1_FLATS', 'k1_flats', K, 'Flats:', 'Lease Length:', 'cb_k1_flats', 'Flats (leasehold assumption)'),
        pr('K1_LEASE_LENGTH', 'k1_lease', K, 'Lease Length:', None, 'cb_k1_lease', 'Lease length')]},
]
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, sum(len(s['rules']) for s in slices), 'rules')
