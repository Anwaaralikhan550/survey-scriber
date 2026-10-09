# -*- coding: utf-8 -*-
"""The seven "If the Property is a Flat, add this" paragraphs (E1, E2, E3, E4, E8, E9, F1).

Each is a tick-box ("Property is a flat") on its section's main screen, so nothing is inferred about
property type (see CLIENT_QUERIES). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'flat_e.json')
CHIMNEY = ['{E_CHIMNEY_SINGLE_STACK}', '{E_CHIMNEY_MULTI_STACK}']

# (rule id, PDF section, masters, bank sub, start sentence, end anchor, main screen id)
FLATS = [
    ('flat_e1', 'E1', CHIMNEY, '{FLAT_MANAGEMENT}',
     'You should ask the management company whether any repairs to the chimney stack(s)', 'Condition rating',
     'activity_outside_property_chimney_main_screen'),
    ('flat_e2', 'E2', ['{E_ROOF_COVERING}'], '{FLAT_MANAGEMENT}',
     'You should ask the management company whether any repairs to the roof covering', 'Condition rating',
     'activity_outside_property_roof_covering_main'),
    ('flat_e3', 'E3', ['{E_RAINWATER_GOODS_ABOUT}'], '{FLAT_MANAGEMENT}',
     'You should ask the management company whether any repairs to the rainwater goods', 'Condition rating',
     'activity_outside_property_rainwater_goods_main_screen'),
    ('flat_e4', 'E4', ['{E_MAIN_WALLS}'], '{FLAT_MANAGEMENT}',
     'You should ask the management company whether any repairs to the external walls', 'Condition rating',
     'activity_outside_property_main_walls_main_screen'),
    ('flat_e8', 'E8', ['{E_OTHER_JOINERY_AND_FINISHES}'], '{FLAT_MANAGEMENT}',
     'As this is a leasehold property', 'General Maintenance:',
     'activity_outside_property_other_joinery_and_finishes_main_screen'),
    ('flat_e9', 'E9', ['{E_OTHER_AREA}'], '{FLAT_MANAGEMENT}',
     'It is assumed that the common parts', 'Condition rating',
     'activity_outside_property_other_main_screen'),
    ('flat_f1', 'F1', ['{F_ABOUT_ROOF_STRUCTURE}'], '{FLAT_MANAGEMENT}',
     'You should ask the management company whether any repairs to the roof structure', 'Condition rating',
     'activity_inside_property_roof_structure_main_screen'),
]

slices = []
for rid, sec, masters, sub, start, end, screen in FLATS:
    kw = {'dart_master': '@chimney'} if masters is CHIMNEY else {}
    rule = para_rule(sec, rid, masters, sub, start, end, when=['cb_property_is_flat', 'true'],
                     extra=[{'id': 'cb_property_is_flat', 'label': 'Property is a flat', 'type': 'checkbox'}], **kw)
    slices.append({'screen': screen, 'rules': [rule]})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices')
