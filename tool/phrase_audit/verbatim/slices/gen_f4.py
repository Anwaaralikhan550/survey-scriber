# -*- coding: utf-8 -*-
"""Generate slices/f4_e.json (F4 Floors). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f4_e.json')
S = 'F4'
MW = '{F_FLOORS}'
I_ = 'activity_in_side_property_floors_'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F4_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


slices = []
FC = 'solid concrete, suspended timber, beam and block, other'
FF = 'floorboards, carpet, tiles, ceramic tiles, laminate flooring, wood flooring, vinyl, stone tiles, other'
slices.append({'screen': I_ + 'about_floor', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_desc', 'DESCRIPTION', 'Description: The floors are formed in', 'Condition: Where visible, the floors appear',
       subs={FC: '{FLOOR_CONSTRUCTION}', FF: '{FLOOR_FINISHES}'},
       tokens=[ck('{FLOOR_CONSTRUCTION}', 'Floors formed in', FC, 'f4c_', other=('cb_other_989', 'et_other_424')),
               ck('{FLOOR_FINISHES}', 'Floor finishes comprise', FF, 'f4f_', other=('cb_other_837', 'et_other_882'))]),
    pr('f4_cond', 'CONDITION', 'Condition: Where visible, the floors appear', 'No Creaking floor:', subs={COND_LIST: '{FLOOR_CONDITION}'},
       tokens=[dd('{FLOOR_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
    pr('f4_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})
CR_DD = {'id': 'actv_status', 'label': 'Creaking', 'type': 'dropdown', 'options': ['No Creaking floor', 'Creaking floor noted']}
slices.append({'screen': I_ + 'creaking', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_nocreak', 'NO_CREAKING', 'No Creaking floor:', 'Creaking floor noted:', when=['actv_status', 'No Creaking floor'],
       extra=[CR_DD]),
    pr('f4_creak', 'CREAKING_NOTED', 'Creaking floor noted:', 'Repair timber floor:', when=['actv_status', 'Creaking floor noted']),
]})
RL = 'lounge, bedroom, kitchen, bathroom, hallway, other'
RD = ('broken, poorly supported, uneven, springy, loose, sloping, incomplete, damp, insect infested, rotten, poorly '
      'ventilated, others')
slices.append({'screen': I_ + 'repair_floor_repair', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_repair', 'REPAIR_TIMBER_FLOOR', 'Repair timber floor:', 'No Cracked Tiles:',
       subs={RL: '{FLOOR_LOCATIONS}', RD: '{FLOOR_DEFECTS}', 'minor, significant': '{FLOOR_SEVERITY}'},
       tokens=[ck('{FLOOR_LOCATIONS}', 'Timber floor to', RL, 'f4rl_', other=('cb_other_221', 'et_other_911')),
               checks('{FLOOR_DEFECTS}', 'Defects', opts('f4rd_', lst(RD)), other=('cb_other_565', 'et_other_232')),
               dd('{FLOOR_SEVERITY}', 'actv_repair_type', 'Defect is considered', ['Minor', 'Significant'], lower=True)])]})
TL = 'kitchen, utility room, bathroom, toilet, conservatory, porch, other'
TLC = 'cracked, loose, damaged'
TL_DD = {'id': 'actv_tiles', 'label': 'Floor tiles', 'type': 'dropdown', 'options': ['No cracked tiles', 'Cracked tiles']}
slices.append({'screen': I_ + 'tiles', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_tiles_ok', 'NO_CRACKED_TILES', 'No Cracked Tiles:', 'Cracked Tiles:', when=['actv_tiles', 'No cracked tiles'],
       subs={COND_LIST: '{TILE_CONDITION}', TL: '{TILE_LOCATIONS}'}, extra=[TL_DD],
       tokens=[dd('{TILE_CONDITION}', 'actv_tile_condition', 'Tile condition', COND5, lower=True,
                  cond='actv_tiles=No cracked tiles'),
               ck('{TILE_LOCATIONS}', 'Floor tiles in', TL, 'f4t_', other=('cb_other_240', 'et_other_392'),
                  cond='actv_tiles=No cracked tiles|Cracked tiles')]),
    pr('f4_tiles_bad', 'CRACKED_TILES', 'Cracked Tiles:', 'Loose Floorboards:', when=['actv_tiles', 'Cracked tiles'],
       subs={TLC: '{TILE_DEFECTS}', TL: '{TILE_LOCATIONS}'},
       tokens=[ck('{TILE_DEFECTS}', 'Tiles are', TLC, 'f4td_', cond='actv_tiles=Cracked tiles'),
               ck('{TILE_LOCATIONS}', 'Floor tiles in', TL, 'f4t_', other=('cb_other_240', 'et_other_392'),
                  cond='actv_tiles=No cracked tiles|Cracked tiles')]),
]})
slices.append({'screen': I_ + 'loose_floorboards', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_loose', 'LOOSE_FLOORBOARDS', 'Loose Floorboards:', 'Wood Boring Noted:', when=['cb_loose_floorboards', 'true'],
       extra=[cb('cb_loose_floorboards', 'Loose floorboards')])]})
WBA = 'active, historic'
WBL = 'property, lounge, bedrooms, bathrooms, kitchens, other'
slices.append({'screen': I_ + 'timber_infection', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_wb', 'WOOD_BORING_NOTED', 'Wood Boring Noted:', 'Timber decay noted:', subs={WBA: '{WB_ACTIVITY}', WBL: '{WB_LOCATIONS}'},
       tokens=[ck('{WB_ACTIVITY}', 'Activity observed', WBA, 'f4wa_'),
               ck('{WB_LOCATIONS}', 'Observed in', WBL, 'f4wl_', other=('cb_other_965', 'et_other_529'))])]})
TD = 'floor timbers, staircase timbers, bathroom floor, kitchen floor, basement floor joists, other'
slices.append({'screen': I_ + 'timber_decay', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_decay', 'TIMBER_DECAY_NOTED', 'Timber decay noted:', 'Dampness noted:', subs={TD: '{DECAY_LOCATIONS}'},
       tokens=[ck('{DECAY_LOCATIONS}', 'Decay noted to', TD, 'f4dc_', other=('cb_other_802', 'et_other_592'))])]})
DL = 'lounge, bedroom, kitchen, bathroom, utility room, other'
DC = 'faulty plumbing, bathtub spillage, leaking sealants, other'
DMP_DD = {'id': 'actv_status', 'label': 'Dampness', 'type': 'dropdown', 'options': ['Dampness noted', 'Unknown damp cause']}
slices.append({'screen': I_ + 'dampness', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_damp', 'DAMPNESS_NOTED', 'Dampness noted:', 'Unknown damp cause:', subs={DL: '{DAMP_LOCATIONS}', DC: '{DAMP_CAUSES}'},
       when=['actv_status', 'Dampness noted'], extra=[DMP_DD],
       tokens=[ck('{DAMP_LOCATIONS}', 'Dampness in', DL, 'f4dl_', other=('cb_other_240', 'et_other_392'), cond='actv_status=Dampness noted'),
               ck('{DAMP_CAUSES}', 'Suspected cause', DC, 'f4dcs_', other=('cb_other_215', 'et_other_358'), cond='actv_status=Dampness noted')]),
    pr('f4_damp_unknown', 'UNKNOWN_DAMP_CAUSE', 'Unknown damp cause:', 'Underfloor Ventilation:',
       when=['actv_status', 'Unknown damp cause']),
]})
slices.append({'screen': I_ + 'floor_ventilation', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_vent', 'UNDERFLOOR_VENTILATION', 'Underfloor Ventilation:', 'Laminate/Wood floor defects:',
       subs={'adequate, limited, or restricted': '{UNDERFLOOR_VENTILATION}'},
       tokens=[dd('{UNDERFLOOR_VENTILATION}', 'actv_condition', 'Underfloor ventilation', ['Adequate', 'Limited', 'Restricted'],
                  lower=True)])]})
LL = 'lounge, bedroom, kitchen, bathroom, utility room, hallway, other'
LD = 'worn, damaged, poorly fitted, incomplete, cracked, lifted, other'
slices.append({'screen': I_ + 'repair_floor_laminate_wood_floor', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_laminate', 'LAMINATE_WOOD_DEFECTS', 'Laminate/Wood floor defects:', 'Excessive floor vibration:',
       subs={LL: '{LAMINATE_LOCATIONS}', LD: '{LAMINATE_DEFECTS}'},
       tokens=[ck('{LAMINATE_LOCATIONS}', 'Flooring to', LL, 'f4ll_', other=('cb_other_345', 'et_other_711')),
               ck('{LAMINATE_DEFECTS}', 'Defects', LD, 'f4ld_', other=('cb_other_1109', 'et_other_588'))])]})
slices.append({'screen': I_ + 'repair_floor_vibration', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_vibration', 'EXCESSIVE_VIBRATION', 'Excessive floor vibration:', 'Sloping floor:', when=['cb_floor_vibration_excessive', 'true'],
       extra=[cb('cb_floor_vibration_excessive', 'Excessive floor vibration')])]})
SL = 'lounge, bedroom, kitchen, bathroom, utility room, hallway, other'
slices.append({'screen': I_ + 'repair_sloping_floor', 'replace_all': True, 'keep': [], 'rules': [
    pr('f4_sloping', 'SLOPING_FLOOR', 'Sloping floor:', 'General Maintenance:', subs={SL: '{SLOPING_LOCATIONS}', 'slightly, significantly': '{SLOPE_DEGREE}'},
       tokens=[ck('{SLOPING_LOCATIONS}', 'Floor to', SL, 'f4sl_', other=('cb_other_856', 'et_other_113')),
               dd('{SLOPE_DEGREE}', 'actv_status', 'Slope', ['Slightly', 'Significantly'], lower=True)])]})
slices.append({'screen': 'activity_inside_property_floors_main_screen', 'rules': [
    pr('f4_intro', 'INTRO', 'The condition of concealed floor timbers', 'Description: The floors are formed in', first=True,
       when=[RATING[0], RATING[1]], when_any=RATING[2])]})
slices.append({'remove_screens': [I_ + 'repair_uneven_floor', I_ + 'repair_not_inspetcted']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
