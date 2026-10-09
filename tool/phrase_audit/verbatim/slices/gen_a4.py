# -*- coding: utf-8 -*-
"""Generate slices/a4_e.json (D: Grounds block = topography, gardens, fencing; Parking block = parking, gated,
location, density, road, noise, conservation, facilities, remote, local environment). Text is cut from the PDF."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'a4_e.json')


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def oth(p):
    return (p + 'other', p + 'other_text')


def R(sec, rid, master, sub, start, end, label, lists=(), trig=None, manual=None, **kw):
    """Tick-box (or `trig`) gated paragraph; lists = [(pdf list string, token, label)]."""
    subs, tokens = {}, []
    for n, L in enumerate(lists):
        pdf, tok, lab = L[0], L[1], L[2]
        has_other = any(x.strip().lower().startswith('other') for x in pdf.split(', '))
        pre = f'{rid}_{n}_'
        subs[pdf] = tok
        tokens.append(checks(tok, lab, opts(pre, lst(pdf)), other=oth(pre) if has_other else None))
    t = trig or ('cb_' + rid)
    extra = [] if trig else [cb(t, label)]
    return para_rule(sec, rid, [master], sub, start, end, subs=subs or None, tokens=tokens,
                     when=[t, 'true'], extra=extra, **kw)


G, PK = 'Grounds', 'Parking'
DG, DL = '{D_GROUND}', '{D_LOCATION}'
FIN = 'lawn, artificial lawn, paving, timber decking, gravel, stones, hardstanding, other finishes'
FENCE = 'timber fencing, brick wall, block wall, hedging, wire mesh, concrete sections, metal railings, other'
TOPO = ['Level', 'Gently sloping', 'Moderately sloping', 'Steeply sloping']
PTYPE = 'residential, private, allocated, communal, off-street, underground facility, other'
LOC = ('well-established residential area, modern residential development, mixed residential and commercial area, '
       'rural location, conservation, village setting, suburban location')
ROAD = 'adopted public road, private road, cul-de-sac, unmade road, other'
NOISE = ('train lines or a station, major roads, commercial premises, industrial premises, public open space, '
         'schools, other')
FAC = 'schools, shops, medical facilities, bus services, train stations, parks, other facilities'
BULLETS = ('Susceptible to flooding', 'Railway line', 'Busy road', 'Commercial premises', 'Industrial premises',
           'Public house', 'School', 'Electricity substation', 'Overhead power lines', 'Pylons', 'Airport flight path')
BULLET_PDF = '• ' + ' • '.join(BULLETS) + ' • Other'


def garden(screen, name, key, nxt, prefix=''):
    p = prefix + key.lower()
    return {'screen': screen, 'replace_all': True, 'keep': [], 'rules': [
        R(G, p + '_type', DG, '{A4_%s_%s_GARDEN}' % (prefix.upper(), key) if prefix else '{A4_%s_GARDEN}' % key,
          f'{name}:', nxt, f'{name} finishes', [(FIN, '{A4_%s_FINISHES}' % (prefix.upper() + key), 'Laid to')]),
        R(G, p + '_fence', DG, '{A4_%s_FENCING}' % (prefix.upper() + key), 'Fencing:', None,
          f'{name} boundaries', [(FENCE, '{A4_%s_BOUNDARIES}' % (prefix.upper() + key), 'Boundaries formed by')]),
    ]}


def garden_combined():
    rules = []
    for name, key, nxt in (('Front garden', 'FRONT', 'Rear garden:'), ('Rear garden', 'REAR', 'Communal garden:'),
                           ('Communal garden', 'COMMUNAL', 'Fencing:')):
        rules.append(R(G, 'gg_' + key.lower() + '_type', DG, '{A4_GG_%s_GARDEN}' % key, f'{name}:', nxt,
                       f'{name} finishes', [(FIN, '{A4_GG_%s_FINISHES}' % key, f'{name} laid to')]))
        rules.append(R(G, 'gg_' + key.lower() + '_fence', DG, '{A4_GG_%s_FENCING}' % key, 'Fencing:', None,
                       f'{name} boundaries', [(FENCE, '{A4_GG_%s_BOUNDARIES}' % key, f'{name} boundaries formed by')]))
    return {'screen': 'activity_garden', 'replace_all': True, 'keep': [], 'rules': rules}


def parking(screen, pre):
    return {'screen': screen, 'replace_all': True, 'keep': [], 'rules': [
        para_rule(PK, pre + 'none', [DG], '{A4_NO_PARKING}', 'No Parking:', 'Type:',
                  when=['android_material_design_spinner', 'No Parking'],
                  extra=[{'id': 'android_material_design_spinner', 'label': 'Status', 'type': 'dropdown',
                          'options': ['Available', 'No Parking']}]),
        para_rule(PK, pre + 'type', [DG], '{A4_PARKING_TYPE}', 'Type:', 'Paid parking:', subs={PTYPE: '{A4_PARKING_KINDS}'},
                  when=['android_material_design_spinner', 'Available'],
                  tokens=[checks('{A4_PARKING_KINDS}', 'Comes with', opts(pre + 'k_', lst(PTYPE)), other=oth(pre + 'k_'))]),
        R(PK, pre + 'paid', DG, '{A4_PAID_PARKING}', 'Paid parking:', 'Gated:', 'Paid parking in the area'),
    ]}


slices = [
    {'remove_screens': ['activity_estate_location']},
    {'screen': 'activity_topography', 'replace_all': True, 'keep': [], 'rules': [
        para_rule(G, 'a4_topo', [DG], '{A4_TOPOGRAPHY}', 'Topology:', 'Front garden:',
                  subs={'level, gently sloping, moderately sloping, steeply sloping': '{A4_SLOPE}'},
                  when=['android_material_design_spinner', TOPO[0]],
                  when_any=[['android_material_design_spinner', x] for x in TOPO[1:]],
                  tokens=[dd('{A4_SLOPE}', 'android_material_design_spinner', 'Ground', TOPO, lower=True)]),
    ]},
    garden('activity_front_garden', 'Front garden', 'FRONT', 'Rear garden:'),
    garden('activity_rear_garden', 'Rear garden', 'REAR', 'Communal garden:'),
    garden('activity_communal_garden', 'Communal garden', 'COMMUNAL', 'Fencing:'),
    garden_combined(),
    parking('activity_parking', 'a4_pk_'),
    parking('activity_parking__parking', 'a4_pp_'),
    {'screen': 'activity_gated_community', 'replace_all': True, 'keep': [], 'rules': [
        para_rule(PK, 'a4_gated', [DG], '{A4_GATED}', 'Gated:', 'Location:', when=['android_material_design_spinner3', 'Yes'],
                  extra=[{'id': 'android_material_design_spinner3', 'label': 'Gated development', 'type': 'dropdown',
                          'options': ['Yes', 'No']}]),
    ]},
    {'screen': 'activity_property_location', 'replace_all': True, 'keep': [], 'rules': [
        R(PK, 'a4_location', DL, '{A4_LOCATION}', 'Location:', 'Density:', 'Location', [(LOC, '{A4_AREA}', 'Situated within a')]),
        para_rule(PK, 'a4_density', [DL], '{A4_DENSITY}', 'Density:', 'Road:',
                  subs={'low, medium, high density': '{A4_DENSITY_LEVEL}'},
                  when=['android_material_design_spinner2', 'Low'],
                  when_any=[['android_material_design_spinner2', x] for x in ('Medium', 'High')],
                  tokens=[dd('{A4_DENSITY_LEVEL}', 'android_material_design_spinner2', 'Surrounding development',
                             ['Low', 'Medium', 'High'], lower=True)]),
    ]},
    {'screen': 'activity_property_private_road', 'replace_all': True, 'keep': [], 'rules': [
        R(PK, 'a4_road', DL, '{A4_ROAD}', 'Road:', 'Noise:', 'Road', [(ROAD, '{A4_ROAD_KIND}', 'Located on a')]),
    ]},
    {'screen': 'activity_property_is_noisy_area', 'replace_all': True, 'keep': [], 'rules': [
        R(PK, 'a4_noise', DL, '{A4_NOISE}', 'Noise:', 'Conservation area:', 'Noise',
          [(NOISE, '{A4_NOISE_SOURCES}', 'Close to')]),
    ]},
    {'screen': 'activity_property_ground_area', 'rules': [
        para_rule(PK, 'a4_conservation', [DL], '{A4_CONSERVATION}', 'Conservation area:', 'Facilities:',
                  when=['ch4', 'true']),
    ]},
    {'screen': 'activity_property_facelities', 'replace_all': True, 'keep': [], 'rules': [
        R(PK, 'a4_facilities', DL, '{A4_FACILITIES}', 'Facilities:', 'Remote area', 'Facilities',
          [(FAC, '{A4_AMENITIES}', 'Observed')]),
        para_rule(PK, 'a4_remote', [DL], '{A4_REMOTE}', 'Remote area', 'Local environment:', when=['cb_a4_remote', 'true'],
                  extra=[cb('cb_a4_remote', 'Remote area')]),
    ]},
    {'screen': 'activity_property_local_environment', 'replace_all': True, 'keep': [], 'rules': [
        para_rule(PK, 'a4_lenv', [DL], '{A4_LOCAL_ENVIRONMENT}', 'Local environment:',
                  'If an electricity substation or overhead power lines',
                  subs={BULLET_PDF: '{A4_FEATURES}.'}, when=['cb_a4_lenv', 'true'], extra=[cb('cb_a4_lenv', 'Local environment')],
                  tokens=[checks('{A4_FEATURES}', 'Environmental features', opts('a4_lenv_0_', list(BULLETS)),
                                 other=oth('a4_lenv_0_'))]),
        para_rule(PK, 'a4_emf', [DL], '{A4_EMF}', 'The property is in a location that could be affected',
                  'If susceptible to flooding is selected',
                  when=['a4_lenv_0_electricity_substation', 'true'], when_any=[['a4_lenv_0_overhead_power_lines', 'true']]),
        para_rule(PK, 'a4_flood', [DL], '{A4_FLOODING}', 'The property is situated close to the sea', 'E ',
                  when=['a4_lenv_0_susceptible_to_flooding', 'true']),
    ]},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
