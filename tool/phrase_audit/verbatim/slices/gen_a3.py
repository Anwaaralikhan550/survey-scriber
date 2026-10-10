# -*- coding: utf-8 -*-
"""Generate slices/a3_e.json (D Construction block: type, roof, walls, floors, windows, the two advisories,
listed building, other services). Energy performance is a separate step. Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'a3_e.json')
S = 'Construction'
MW = '{D_CONSTRUCTION}'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], '{A3_%s}' % sub, start, end, **kw)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def oth(p):
    return (p + 'other', p + 'other_text')


def R(rid, sub, start, end, label, lists=(), trig=None):
    subs, tokens = {}, []
    for n, L in enumerate(lists):
        pdf, tok, lab = L[0], L[1], L[2]
        has_other = any(x.strip().startswith('other') for x in pdf.split(', '))
        pre = f'{rid}_{n}_'
        subs[pdf] = tok
        tokens.append(checks(tok, lab, opts(pre, lst(pdf)), other=oth(pre) if has_other else None))
    t = trig or ('cb_' + rid)
    return pr(rid, sub, start, end, subs=subs or None, tokens=tokens, when=[t, 'true'], extra=[cb(t, label)])


TYPE = ('traditional masonry, solid wall, cavity wall, timber frame, steel frame, concrete wall, precast concrete panels, '
        'system-built, other')
RFORM = 'pitched, flat, mansard'
RSTRUCT = 'traditional cut timber, prefabricated trussed rafters, other'
RCOVER = ('clay tiles, concrete tiles, natural slate, artificial slate, fibre cement slates, metal sheeting, mineral felt, '
          'rubber membrane, single-ply membrane, other')
EWALL = 'solid brick, cavity brick, stone, timber frame, steel frame, rendered masonry, other'
IWALL = 'solid masonry, timber stud partitions, lath and plaster, other'
FLOORS = 'solid concrete, suspended timber, beam and block, other'
WFRAME = 'timber, PVCu, aluminium, steel, other'
WGLAZ = 'single, double, triple glazing, secondary glazing'
TYPE_PRE = 'a3_type_0_'
SERVICES = ('photovoltaic (solar PV) panels, solar water heating panels, an inverter, battery storage, '
            'other renewable energy installations')
# ch1 / ch2 keep their ids: report_builder reads them for the I2 renewable-energy guarantee line.
SERVICE_OPTS = [('ch1', 'photovoltaic (solar PV) panels'), ('ch2', 'solar water heating panels'),
                ('a3_os_inverter', 'an inverter'), ('a3_os_battery', 'battery storage')]

slices = [
    {'screen': 'activity_property_construction', 'replace_all': True, 'keep': [], 'rules': [
        R('a3_type', 'TYPE', 'Type:', 'Roof type:', 'Construction type', [(TYPE, '{A3_CONSTRUCTION_TYPE}', 'Constructed using')]),
        pr('a3_visible', 'VISIBLE_ONLY', 'Construction has been identified', 'If timber or steel frame is selected',
           when=['cb_a3_visible', 'true'], extra=[cb('cb_a3_visible', 'Construction identified from visible inspection only')]),
        pr('a3_modern', 'MODERN_BUILDING_DESIGN', 'Modern Building Design:', 'If concrete wall or precast concrete panels',
           when=[TYPE_PRE + 'timber_frame', 'true'], when_any=[[TYPE_PRE + 'steel_frame', 'true']]),
        pr('a3_concrete', 'CONCRETE_ADVISORY', 'Where the property is of concrete or precast', 'Listed building:',
           when=[TYPE_PRE + 'concrete_wall', 'true'], when_any=[[TYPE_PRE + 'precast_concrete_panels', 'true']]),
    ]},
    {'screen': 'activity_property_roof', 'replace_all': True, 'keep': [], 'rules': [
        R('a3_roof_type', 'ROOF_TYPE', 'Roof type:', 'Roof cover:', 'Roof type',
          [(RFORM, '{A3_ROOF_FORM}', 'Main roof is of'), (RSTRUCT, '{A3_ROOF_STRUCTURE}', 'Formed with')]),
        R('a3_roof_cover', 'ROOF_COVER', 'Roof cover:', 'External walls:', 'Roof cover',
          [(RCOVER, '{A3_ROOF_COVER}', 'Roof covering formed in')]),
    ]},
    {'screen': 'activity_extended_wall', 'replace_all': True, 'keep': [], 'rules': [
        R('a3_ext_walls', 'EXTERNAL_WALLS', 'External walls:', 'Internal walls:', 'External walls',
          [(EWALL, '{A3_EXTERNAL_WALLS}', 'Constructed of')]),
    ]},
    {'screen': 'activity_internal_wall', 'replace_all': True, 'keep': [], 'rules': [
        R('a3_int_walls', 'INTERNAL_WALLS', 'Internal walls:', 'Floors:', 'Internal walls',
          [(IWALL, '{A3_INTERNAL_WALLS}', 'Formed in')]),
    ]},
    {'screen': 'activity_construction_floor', 'replace_all': True, 'keep': [], 'rules': [
        R('a3_floors', 'FLOORS', 'Floors:', 'Windows:', 'Floors', [(FLOORS, '{A3_FLOORS}', 'Floors are of')]),
    ]},
    {'screen': 'activity_construction_window', 'replace_all': True, 'keep': [], 'rules': [
        R('a3_windows', 'WINDOWS', 'Windows:', 'Construction has been identified', 'Windows',
          [(WFRAME, '{A3_WINDOW_FRAMES}', 'Fitted with'), (WGLAZ, '{A3_GLAZING}', 'Incorporating')]),
    ]},
    {'screen': 'activity_listed_building__listed_building', 'replace_all': True, 'keep': [], 'rules': [
        pr('a3_listed', 'LISTED_BUILDING', 'Listed building:', 'Energy performance:', when=['android_material_design_spinner', 'Yes'],
           extra=[{'id': 'android_material_design_spinner', 'label': 'Listed building', 'type': 'dropdown',
                   'options': ['Yes', 'No']}]),
    ]},
    {'screen': 'activity_listed_building', 'replace_all': True, 'keep': [], 'rules': [
        pr('a3_listed_alias', 'LISTED_BUILDING', 'Listed building:', 'Energy performance:', when=['android_material_design_spinner', 'Yes'],
           extra=[{'id': 'android_material_design_spinner', 'label': 'Listed building', 'type': 'dropdown',
                   'options': ['Yes', 'No']}]),
    ]},
    {'screen': 'activity_energy_effiency', 'replace_all': True, 'keep': [], 'rules': [
        pr('a3_energy', 'ENERGY_PERFORMANCE', 'Energy performance:', 'Other services:',
           subs={'Energy Efficiency Rating: A, B, C, D, E, F, or G': 'Energy Efficiency Rating: {A3_EE_RATING}',
                 'Potential Rating: A, B, C, D, E, F, or G': 'Potential Rating: {A3_EE_POTENTIAL}'},
           when=['android_material_design_spinner', 'A'], when_any=[['android_material_design_spinner', x] for x in 'BCDEFG'],
           tokens=[dd('{A3_EE_RATING}', 'android_material_design_spinner', 'Energy Efficiency Rating', list('ABCDEFG')),
                   dd('{A3_EE_POTENTIAL}', 'android_material_design_spinner2', 'Potential Rating', list('ABCDEFG'))]),
    ]},
    {'screen': 'activity_other_service', 'replace_all': True, 'keep': [], 'rules': [
        pr('a3_services', 'OTHER_SERVICES', 'Other services:', None, subs={SERVICES: '{A3_SERVICES}'},
           when=['cb_a3_services', 'true'], extra=[cb('cb_a3_services', 'Other services present')],
           tokens=[checks('{A3_SERVICES}', 'Renewable energy installations', SERVICE_OPTS, other=oth('a3_os_'))]),
    ]},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
