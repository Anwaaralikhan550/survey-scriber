# -*- coding: utf-8 -*-
"""Generate slices/a2_e.json (A: Overall opinion block, property description part: type, year built, extended,
converted, flat information). The opinion / price paragraph is left as is (CLIENT_QUERIES #12)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import P, checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'a2_e.json')
S = 'Overall opinion'


def pr(rid, master, sub, start, end, **kw):
    return para_rule(S, rid, [master], sub, start, end, **kw)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def oth(p):
    return (p + 'other', p + 'other_text')


def text_tok(token, field, label):
    return {'kind': 'text', 'token': token, 'dropdown': field, 'field_label': label}


TYPE = 'detached, semi-detached, end-of-terrace, mid-terrace, purpose-built flat, converted flat, maisonette, bungalow, cottage, other'
BEDS = 'one, two, three, four, five, six or more'
EXT = 'side, rear, front, single-storey, two-storey, roof, loft'
PRIOR = 'detached house, semi-detached house, mid-terrace house, end-terrace house, other'
FLOOR = 'lower ground floor, ground floor, first floor, second floor, third floor, fourth floor, other floor'
STOREY = 'one, two, three, four, other'
ACCESS = 'private door, communal door, communal door with entry system, other'
ELEV = 'front, side, rear,'
BANDS = ['pre-1900', '1900– 1929', '1930–1949', '1950–1969', '1970–1989', '1990–2009', '2010 onwards',
         'the exact construction date is unknown']

yb, _ = P(S, 'Year built:', 'Not Extended:')
YB_FULL = yb[yb.index('built in ') + 9:yb.index('. This assessment')]
band_ids = [('a2yb_' + str(n), b) for n, b in enumerate(BANDS)]

EXT_DD = {'id': 'android_material_design_spinner', 'label': 'Extension', 'type': 'dropdown',
          'options': ['Not extended', 'Extended']}
CON_DD = {'id': 'android_material_design_spinner', 'label': 'Conversion', 'type': 'dropdown',
          'options': ['Not converted', 'Converted']}
DATE_DD = {'id': 'actv_a2_conversion_date', 'label': 'Date of conversion', 'type': 'dropdown',
           'options': ['Known date', 'Unknown date']}

slices = [
    {'screen': 'activity_property_type', 'replace_all': True, 'keep': [], 'rules': [
        pr('a2_type', '{D_PROPERTY_TYPE}', '{A2_PROPERTY_TYPE}', 'Property type:', 'Year built:',
           subs={TYPE: '{A2_TYPE}', BEDS: '{A2_BEDROOMS}'}, when=['cb_a2_type', 'true'],
           extra=[cb('cb_a2_type', 'Property type')],
           tokens=[checks('{A2_TYPE}', 'The property is a', opts('a2t_', lst(TYPE)), other=oth('a2t_')),
                   dd('{A2_BEDROOMS}', 'actv_a2_bedrooms', 'Providing bedrooms',
                      ['One', 'Two', 'Three', 'Four', 'Five', 'Six or more'], lower=True)]),
    ]},
    {'screen': 'activity_property_built_year', 'replace_all': True, 'keep': [], 'rules': [
        pr('a2_year_exact', '{D_YEAR_BUILT}', '{A2_YEAR_EXACT}', 'Year built:', 'Not Extended:', subs={YB_FULL: '{A2_YEAR}'},
           when=['cb_a2_year_exact', 'true'], extra=[cb('cb_a2_year_exact', 'Exact year known')],
           tokens=[text_tok('{A2_YEAR}', 'android_material_design_spinner', 'Year built (enter year)')]),
        pr('a2_year_band', '{D_YEAR_BUILT}', '{A2_YEAR_BAND}', 'Year built:', 'Not Extended:', subs={YB_FULL: '{A2_BAND}'},
           when=['actv_a2_year_band', BANDS[0]], when_any=[['actv_a2_year_band', b] for b in BANDS[1:]],
           tokens=[dd('{A2_BAND}', 'actv_a2_year_band', 'Year built band', BANDS)]),
    ]},
    {'screen': 'activity_property_extended', 'replace_all': True, 'keep': [], 'rules': [
        pr('a2_not_extended', '{D_EXTENDED}', '{A2_NOT_EXTENDED}', 'Not Extended:', 'Extended: The property has been extended',
           when=['android_material_design_spinner', 'Not extended'], extra=[EXT_DD]),
        pr('a2_extended', '{D_EXTENDED}', '{A2_EXTENDED}', 'Extended: The property has been extended', 'Not converted:', subs={EXT: '{A2_EXTENSION}'},
           when=['android_material_design_spinner', 'Extended'],
           tokens=[checks('{A2_EXTENSION}', 'Extended to provide', opts('a2e_', lst(EXT)), other=None)]),
    ]},
    {'screen': 'activity_property_converted', 'replace_all': True, 'keep': [], 'rules': [
        pr('a2_not_converted', '{D_CONVERTED}', '{A2_NOT_CONVERTED}', 'Not converted:', 'Converted: The property has been converted',
           when=['android_material_design_spinner', 'Not converted'], extra=[CON_DD]),
        pr('a2_converted', '{D_CONVERTED}', '{A2_CONVERTED}', 'Converted: The property has been converted', 'Known date:', subs={PRIOR: '{A2_PRIOR_TYPE}'},
           when=['android_material_design_spinner', 'Converted'],
           tokens=[checks('{A2_PRIOR_TYPE}', 'The property was a', opts('a2c_', lst(PRIOR)), other=oth('a2c_'))]),
        pr('a2_known_date', '{D_CONVERTED}', '{A2_KNOWN_DATE}', 'Known date:', 'Unknown date:', subs={'(YYYY)': '{A2_YEAR_CONVERTED}'},
           when=['actv_a2_conversion_date', 'Known date'], extra=[DATE_DD],
           tokens=[text_tok('{A2_YEAR_CONVERTED}', 'textView3', 'Year of conversion')]),
        pr('a2_unknown_date', '{D_CONVERTED}', '{A2_UNKNOWN_DATE}', 'Unknown date:', 'Flat information:',
           when=['actv_a2_conversion_date', 'Unknown date']),
    ]},
    {'screen': 'activity_property_flate', 'replace_all': True, 'keep': [], 'rules': [
        pr('a2_flat', '{D_FLAT_INFO}', '{A2_FLAT_INFORMATION}', 'Flat information:', 'Accommodation summary:',
           subs={FLOOR: '{A2_FLOOR}', STOREY: '{A2_STOREYS}', ACCESS: '{A2_ACCESS}', ELEV: '{A2_ELEVATION}'},
           when=['cb_a2_flat', 'true'], extra=[cb('cb_a2_flat', 'Flat information')],
           tokens=[dd('{A2_FLOOR}', 'actv_a2_floor', 'Located on the',
                      ['Lower ground floor', 'Ground floor', 'First floor', 'Second floor', 'Third floor', 'Fourth floor'],
                      lower=True),
                   dd('{A2_STOREYS}', 'actv_a2_storeys', 'Storeys in the building', ['One', 'Two', 'Three', 'Four'], lower=True),
                   dd('{A2_ACCESS}', 'actv_a2_access', 'Accessed via a',
                      ['Private door', 'Communal door', 'Communal door with entry system'], lower=True),
                   dd('{A2_ELEVATION}', 'actv_a2_elevation', 'Elevation', ['Front', 'Side', 'Rear'], lower=True)]),
    ]},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
