# -*- coding: utf-8 -*-
"""Generate slices/a1_e.json (A: Property address block = Weather, Status, Orientation). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import dd, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'a1_e.json')
S = 'Property address'
WN = 'dry, wet, overcast, sunny, cold, windy, rainy, snowing'
WEATHER = ['Dry', 'Wet', 'Overcast', 'Sunny', 'Cold', 'Windy', 'Rainy', 'Snowing']
OCC = ['Occupied', 'Vacant', 'Partly occupied']
FUR = ['Fully furnished', 'Partly furnished', 'Unfurnished']
COV = ['Fully covered', 'Partly covered', 'Uncovered']
ORI = ['North', 'North-east', 'East', 'South-east', 'South', 'South-west', 'West', 'North-west']


def rule(rid, master, sub, start, end, subs, tokens, trigger, trigger_vals):
    return para_rule(S, rid, [master], sub, start, end, subs=subs, tokens=tokens,
                     when=[trigger, trigger_vals[0]], when_any=[[trigger, v] for v in trigger_vals[1:]])


slices = [
    {'screen': 'activity_property_weather', 'replace_all': True, 'keep': [], 'rules': [
        rule('a1_weather', '{D_WEATHER}', '{A1_WEATHER}', 'Weather:', 'Status:',
             {'weather was ' + WN + ', following': 'weather was {A1_WEATHER_NOW}, following',
              'a period of ' + WN + ' weather': 'a period of {A1_WEATHER_BEFORE} weather'},
             [dd('{A1_WEATHER_NOW}', 'android_material_design_spinner', 'Current weather', WEATHER, lower=True),
              dd('{A1_WEATHER_BEFORE}', 'android_material_design_spinner2', 'Previous weather', WEATHER, lower=True)],
             'android_material_design_spinner', WEATHER),
    ]},
    {'screen': 'activity_property_status', 'replace_all': True, 'keep': [], 'rules': [
        rule('a1_status', '{D_PROPERTY_STATUS}', '{A1_STATUS}', 'Status:', 'Orientation:',
             {'occupied, vacant, or partly occupied': '{A1_OCCUPANCY}',
              'fully furnished, partly furnished, unfurnished': '{A1_FURNISHING}',
              'fully covered, partly covered, uncovered': '{A1_FLOOR_COVERING}'},
             [dd('{A1_OCCUPANCY}', 'android_material_design_spinner', 'Occupancy', OCC, lower=True),
              dd('{A1_FURNISHING}', 'android_material_design_spinner2', 'Furnishing', FUR, lower=True),
              dd('{A1_FLOOR_COVERING}', 'android_material_design_spinner3', 'Floor covering', COV, lower=True)],
             'android_material_design_spinner', OCC),
    ]},
    {'screen': 'activity_property_facing', 'replace_all': True, 'keep': [], 'rules': [
        rule('a1_orientation', '{D_PROPERTY_FACING}', '{A1_ORIENTATION}', 'Orientation:', None,
             {'north, north-east, east, south-east, south, south-west, west, north-west': '{A1_FACING}'},
             [dd('{A1_FACING}', 'android_material_design_spinner', 'Orientation', ORI, lower=True)],
             'android_material_design_spinner', ORI),
    ]},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
