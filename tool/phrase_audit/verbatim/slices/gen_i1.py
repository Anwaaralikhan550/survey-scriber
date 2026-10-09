# -*- coding: utf-8 -*-
"""Generate slices/i1_e.json (I1 Issues for legal adviser: Regulations). Text is cut from the PDF block.

The PDF shows one checklist with no "if selected" directives, so every item gets its own tick-box
(nothing is guessed about which items always print; see CLIENT_QUERIES)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'i1_e.json')
S = 'I1'
MW = '{ISSUE_REGULATIONS}'
SCREEN = 'activity_issues_regulation'


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


# (rule id, bank sub, PDF start anchor, field id, checkbox label) in PDF order; each ends where the next starts.
ITEMS = [
    ('i1_intro', 'INTRO', 'The comments below are based solely', 'cb_i1_intro', 'Standard introduction'),
    ('i1_alterations', 'PROPERTY_ALTERATIONS', 'Property Alterations –', 'cb_i1_alterations', 'Property alterations'),
    ('i1_new_build', 'NEW_BUILD', 'New Build Property:', 'cb_new_build', 'New build property'),
    ('i1_roof', 'ROOF_ALTERATIONS', 'Roof Alterations and Loft Conversions –', 'cb_i1_roof', 'Roof alterations and loft conversions'),
    ('i1_converted', 'CONVERTED_BUILDING', 'Converted Building:', 'cb_converted_building', 'Converted building'),
    ('i1_chimney', 'CHIMNEY_BREAST', 'Chimney Breast Alterations –', 'cb_i1_chimney', 'Chimney breast alterations'),
    ('i1_windows', 'REPLACEMENT_WINDOWS', 'Replacement Windows and Doors –', 'cb_i1_windows', 'Replacement windows and doors'),
    ('i1_electrical', 'ELECTRICAL', 'Electrical Installation –', 'cb_i1_electrical', 'Electrical installation'),
    ('i1_gas', 'GAS', 'Gas Installation –', 'cb_i1_gas', 'Gas installation'),
    ('i1_asbestos', 'ASBESTOS', 'Asbestos –', 'cb_i1_asbestos', 'Asbestos'),
    ('i1_flood', 'FLOOD_RISK', 'Flood Risk –', 'cb_i1_flood', 'Flood risk'),
    ('i1_mining', 'MINING', 'Mining and Ground Stability –', 'cb_i1_mining', 'Mining and ground stability'),
    ('i1_trees', 'TREES', 'Trees –', 'cb_i1_trees', 'Trees'),
    ('i1_row', 'RIGHTS_OF_WAY', 'Rights of Way and Easements –', 'cb_i1_row', 'Rights of way and easements'),
    ('i1_boundaries', 'BOUNDARIES', 'Boundaries –', 'cb_i1_boundaries', 'Boundaries'),
    ('i1_shared', 'SHARED_FACILITIES', 'Shared Facilities –', 'cb_i1_shared', 'Shared facilities'),
    ('i1_roads', 'PRIVATE_ROADS', 'Private Roads and Shared Access –', 'cb_i1_roads', 'Private roads and shared access'),
    ('i1_drainage', 'DRAINAGE', 'Drainage –', 'cb_i1_drainage', 'Drainage'),
    ('i1_leasehold', 'LEASEHOLD', 'Leasehold Property –', 'cb_i1_leasehold', 'Leasehold property'),
    ('i1_freehold', 'FREEHOLD', 'Freehold Property –', 'cb_i1_freehold', 'Freehold property'),
    ('i1_listed', 'LISTED_BUILDING', 'Listed Building:', 'cb_listed_building', 'Listed building'),
]

rules = []
for n, (rid, sub, start, fid, label) in enumerate(ITEMS):
    end = ITEMS[n + 1][2] if n + 1 < len(ITEMS) else None
    rules.append(para_rule(S, rid, [MW], '{I1_%s}' % sub, start, end, when=[fid, 'true'], extra=[cb(fid, label)]))

slices = [{'screen': SCREEN, 'replace_all': True, 'keep': [], 'rules': rules}]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', len(rules), 'rules')
