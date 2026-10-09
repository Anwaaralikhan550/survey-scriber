# -*- coding: utf-8 -*-
"""Generate slices/e0_e.json (E leftovers: E limitations + weather condition text [PDF block 'Parking' tail], E2/E3
not-inspected, E3 blocked gutters / rainwater runoffs). Text is cut from the PDF."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e0_e.json')


def cb(fid, label):
    return field(fid, label, 'checkbox')


def lim(rid, sub, start, end, **kw):
    return para_rule('Parking', rid, ['{E_LIMITATIONS}'], '{E0_%s}' % sub, start, end, **kw)


LIM_LIST = ('height, restricted access, nearby buildings, vegetation, weather conditions, roof configuration, '
            'health and safety considerations')
WX = ['Wet weather', 'Dry weather', 'Snowfall']
WX_STARTS = [('Wet weather:', 'Dry weather:'), ('Dry weather:', 'Snowfall:'), ('Snowfall:', None)]


def weather(screen):
    pre = 'e0w_' + ('roof_' if 'roof' in screen else 'rwg_')
    rules = []
    for (name, (st, en)) in zip(WX, WX_STARTS):
        rules.append(lim(pre + name.split()[0].lower(), 'WEATHER_' + name.split()[0].upper(), st, en,
                         when=['actv_status', name],
                         extra=[{'id': 'actv_status', 'label': 'Weather condition', 'type': 'dropdown', 'options': WX}]))
    return {'screen': screen, 'replace_all': True, 'keep': [], 'rules': rules}


def not_inspected(screen, sec, master, rid, fid):
    return {'screen': screen, 'replace_all': True, 'keep': [], 'rules': [
        para_rule(sec, rid, [master], '{E0_NOT_INSPECTED_%s}' % sec, 'Not Inspected:', 'Description:',
                  when=[fid, 'true'], extra=[cb(fid, 'Not inspected')])]}


slices = [
    {'remove_screens': ['activity_outside_property_roof_repair_poor_roof', 'activity_outside_property_windows_not_inspected',
                        'outside_property_roof_covering_roof_spreading_layout']},
    {'screen': 'activity_outside_property_limitation', 'replace_all': True, 'keep': [], 'rules': [
        lim('e0_ground', 'GROUND_LEVEL', 'My inspection of the exterior was carried out', 'My inspection was restricted',
            when=['cb_e0_ground', 'true'], extra=[cb('cb_e0_ground', 'Inspected from ground level')]),
        lim('e0_vantage', 'VANTAGE_POINTS', 'My inspection was restricted by the surrounding', 'Limitations: The inspection was limited',
            when=['cb_e0_vantage', 'true'], extra=[cb('cb_e0_vantage', 'Restricted by surrounding elements')]),
        lim('e0_limited', 'LIMITED_BY', 'Limitations: The inspection was limited', 'Restricted Access:',
            subs={LIM_LIST: '{E0_LIMITS}'}, when=['cb_e0_limited', 'true'], extra=[cb('cb_e0_limited', 'Inspection limited by')],
            tokens=[checks('{E0_LIMITS}', 'Limited by', opts('e0l_', lst(LIM_LIST)), other=None)]),
        lim('e0_restricted', 'RESTRICTED_ACCESS', 'Restricted Access:', 'Roof coverings, chimney stacks',
            when=['cb_e0_restricted', 'true'], extra=[cb('cb_e0_restricted', 'No direct access to the rear')]),
        lim('e0_binoculars', 'BINOCULARS', 'Roof coverings, chimney stacks', 'Weather condition',
            when=['cb_e0_binoculars', 'true'], extra=[cb('cb_e0_binoculars', 'Binoculars / nothing opened up')]),
    ]},
    weather('outside_property_roof_covering_weather_layout'),
    weather('activity_rwg_weather_condition'),
    not_inspected('activity_outside_property_roof_not_inspected', 'E2', '{E_ROOF_COVERING}', 'e0_roof_ni', 'cb_e0_roof_ni'),
    not_inspected('activity_outside_property_rain_water_goods_not_inspected', 'E3', '{E_RAINWATER_GOODS_ABOUT}',
                  'e0_rwg_ni', 'cb_not_inspected'),
    {'screen': 'activity_outside_property_rwg_blocked_rwg', 'replace_all': True, 'keep': [], 'rules': [
        para_rule('E3', 'e0_rwg_blocked', ['{E_RAINWATER_GOODS_ABOUT}'], '{E0_BLOCKED_GUTTERS}', 'Blocked Gutters:',
                  'Blocked Gullies:', when=['cb_blocked_rwg', 'true'], extra=[cb('cb_blocked_rwg', 'Blocked gutters')])]},
    {'screen': 'activity_outside_property_rwg_open_runoffs', 'replace_all': True, 'keep': [], 'rules': [
        para_rule('E3', 'e0_rwg_runoffs', ['{E_RAINWATER_GOODS_ABOUT}'], '{E0_RUNOFFS}', 'Rainwater runoffs:',
                  'Shared Rainwater Goods:', when=['cb_open_runoffs', 'true'],
                  extra=[cb('cb_open_runoffs', 'Open rainwater runoffs')])]},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
