# -*- coding: utf-8 -*-
"""Generate slices/f1_e.json (F1 Roof structure). Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, lst, opts, para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f1_e.json')
S = 'F1'
MW = '{F_ABOUT_ROOF_STRUCTURE}'
G = 'group_roof_structure_58'
I_ = 'activity_inside_property_'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
COND_LIST = 'good, reasonable, fair, poor, very poor'
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{F1_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None, cap=False):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond, cap=cap)


def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': G, 'order': order, 'after': after}


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


slices = []

# ───────────── Loft converted ─────────────
slices.append({'screen': I_ + 'loft_converted', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_loft', 'LOFT_CONVERTED', 'Loft converted:', 'The roof structure was inspected from',
       when=['cb_loft_converted', 'true'], extra=[cb('cb_loft_converted', 'Loft converted')])]})

# ───────────── About: description, condition, spray foam, water penetration, soil pipe, general ─────────────
DESC = 'traditional cut timber, prefabricated trussed rafters, steel, other'
slices.append({'screen': I_ + 'about_roof_structure', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_desc', 'DESCRIPTION', 'Description: The roof structure is formed in', 'Condition: Where visible, the roof structure appears',
       subs={DESC: '{RS_CONSTRUCTION}'},
       tokens=[ck('{RS_CONSTRUCTION}', 'Roof structure formed in', DESC, 'f1d_', other=('f1d_other', 'f1d_other_text'))]),
    pr('f1_cond', 'CONDITION', 'Condition: Where visible, the roof structure appears', 'Roof Underlay', subs={COND_LIST: '{RS_CONDITION}'},
       tokens=[dd('{RS_CONDITION}', 'actv_roof_structure_condition', 'Condition', COND5, lower=True)]),
    pr('f1_spray', 'SPRAY_FOAM', 'Spray foam insulation:', 'No Wood-boring:', when=['cb_spray_foam', 'true'],
       extra=[cb('cb_spray_foam', 'Spray foam insulation')]),
    pr('f1_water', 'WATER_PENETRATION', 'Evidence of Water Penetration:', 'Capped Soil Vent Pipe:',
       when=['cb_water_penetration', 'true'], extra=[cb('cb_water_penetration', 'Evidence of water penetration')]),
    pr('f1_soilpipe', 'CAPPED_SOIL_PIPE', 'Capped Soil Vent Pipe:', 'General Maintenance:',
       when=['cb_capped_soil_vent_pipe', 'true'], extra=[cb('cb_capped_soil_vent_pipe', 'Capped soil and vent pipe')]),
    pr('f1_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'If the Property is a Flat',
       when=['cb_general_maintenance', 'true'], extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})

# ───────────── Underlay (new) ─────────────
UL = 'traditional bituminous felt, breathable membrane, timber boards, other'
UD = 'worn, torn, missing, damaged'
S_UL = I_ + 'roof_underlay'
UL_DD = {'id': 'actv_underlay', 'label': 'Roof underlay', 'type': 'dropdown', 'options': ['No underlay', 'Underlay present']}
slices.append({'screen': S_UL, 'new_screen': new_screen(S_UL, 'Roof underlay', 24, I_ + 'about_roof_structure'), 'rules': [
    pr('f1_ul_no', 'NO_UNDERLAY', 'No Underlay:', 'Underlay present:', when=['actv_underlay', 'No underlay'], extra=[UL_DD]),
    pr('f1_ul_present', 'UNDERLAY_PRESENT', 'Underlay present:', 'Defects noted: The roof underlay',
       subs={UL: '{UL_MATERIALS}', COND_LIST: '{UL_CONDITION}'}, when=['actv_underlay', 'Underlay present'],
       tokens=[ck('{UL_MATERIALS}', 'Underside incorporates', UL, 'f1u_', other=('f1u_other', 'f1u_other_text'),
                  cond='actv_underlay=Underlay present'),
               dd('{UL_CONDITION}', 'actv_ul_condition', 'Underlay condition', COND5, lower=True,
                  cond='actv_underlay=Underlay present')]),
    pr('f1_ul_defects', 'UNDERLAY_DEFECTS', 'Defects noted: The roof underlay', 'Roof Ventilation', subs={UD: '{UL_DEFECTS}'},
       tokens=[ck('{UL_DEFECTS}', 'Underlay is', UD, 'f1ud_', cond='actv_underlay=Underlay present')]),
]})

# ───────────── Ventilation (new) ─────────────
S_VE = I_ + 'roof_ventilation'
VE_DD = {'id': 'actv_ventilation', 'label': 'Roof ventilation', 'type': 'dropdown',
         'options': ['No ventilation', 'Ventilation noted', 'Condensation noted']}
slices.append({'screen': S_VE, 'new_screen': new_screen(S_VE, 'Roof ventilation', 26, S_UL), 'rules': [
    pr('f1_ve_no', 'NO_VENTILATION', 'No ventilation:', 'Ventilation noted:', when=['actv_ventilation', 'No ventilation'], extra=[VE_DD]),
    pr('f1_ve_noted', 'VENTILATION_NOTED', 'Ventilation noted:', 'Condensation noted:',
       subs={'adequate, limited, restricted': '{VENT_LEVEL}'}, when=['actv_ventilation', 'Ventilation noted'],
       tokens=[dd('{VENT_LEVEL}', 'actv_vent_level', 'Ventilation appears', ['Adequate', 'Limited', 'Restricted'], lower=True,
                  cond='actv_ventilation=Ventilation noted')]),
    pr('f1_ve_cond', 'CONDENSATION_NOTED', 'Condensation noted:', 'Thermal Insulation:',
       when=['actv_ventilation', 'Condensation noted']),
]})

# ───────────── Insulation (new) ─────────────
INS = 'adequate, limited, insufficient, poorly fitted, other'
S_IN = I_ + 'roof_insulation'
IN_DD = {'id': 'actv_insulation_outcome', 'label': 'Insulation outcome', 'type': 'dropdown',
         'options': ['Adequate insulation', 'Inadequate/no insulation']}
slices.append({'screen': S_IN, 'new_screen': new_screen(S_IN, 'Roof insulation', 28, S_VE), 'rules': [
    pr('f1_in', 'THERMAL_INSULATION', 'Thermal Insulation:', 'Adequate insulation:', subs={INS: '{INSULATION_STATE}'},
       tokens=[ck('{INSULATION_STATE}', 'Insulation appears', INS, 'f1i_', other=('f1i_other', 'f1i_other_text'))]),
    pr('f1_in_ok', 'INSULATION_ADEQUATE', 'Adequate insulation:', 'Inadequate/no insulation:',
       when=['actv_insulation_outcome', 'Adequate insulation'], extra=[IN_DD]),
    pr('f1_in_bad', 'INSULATION_INADEQUATE', 'Inadequate/no insulation:', 'Water Storage Tanks:',
       when=['actv_insulation_outcome', 'Inadequate/no insulation']),
]})

# ───────────── Water tanks ─────────────
TK = 'plastic, galvanised steel, asbestos cement, fibreglass, other'
TC = 'plastic, galvanised metal, asbestos, other'
TD = 'Plastic, galvanised steel, asbestos cement, other'
slices.append({'screen': I_ + 'water_tank', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_tank', 'WATER_TANKS', 'Water Storage Tanks:', 'Condition: Where visible, the tank', subs={TK: '{TANK_MATERIALS}'},
       tokens=[ck('{TANK_MATERIALS}', 'Cold water storage tanks', TK, 'f1t_', other=('f1t_other', 'f1t_other_text'))]),
    pr('f1_tank_cond', 'TANK_CONDITION', 'Condition: Where visible, the tank', 'Leaking: The water tank',
       subs={COND_LIST: '{TANK_CONDITION}'}, tokens=[dd('{TANK_CONDITION}', 'actv_tank_condition', 'Tank condition', COND5, lower=True)]),
    pr('f1_tank_leak', 'TANK_LEAKING', 'Leaking: The water tank', 'Water Tank Insulation:', when=['cb_tank_leaking', 'true'],
       extra=[cb('cb_tank_leaking', 'Leaking')]),
    pr('f1_tank_ins', 'TANK_INSULATION', 'Water Tank Insulation:', 'Missing or Inadequate tank cover:',
       subs={'adequately insulated, partially insulated, uninsulated': '{TANK_INSULATION}'},
       tokens=[dd('{TANK_INSULATION}', 'actv_tank_insulation', 'Tank insulation',
                  ['Adequately insulated', 'Partially insulated', 'Uninsulated'], lower=True)]),
    pr('f1_tank_cover', 'TANK_COVER', 'Missing or Inadequate tank cover:', 'Disused Water Tank:', subs={TC: '{TANK_COVER_MATERIALS}'},
       tokens=[ck('{TANK_COVER_MATERIALS}', 'Tank cover missing or inadequate', TC, 'f1c_', other=('f1c_other', 'f1c_other_text'))]),
    pr('f1_tank_disused', 'TANK_DISUSED', 'Disused Water Tank:', 'Timber defects:', subs={TD: '{DISUSED_TANKS}'},
       tokens=[checks('{DISUSED_TANKS}', 'Disused tanks',
                      opts('f1x_', [x.lower() for x in lst(TD)]), cap=True, other=('f1x_other', 'f1x_other_text'))]),
]})

# ───────────── Repairs / defects ─────────────
TDEF = 'distortion, splitting, cracking, notching, alterations, other'
slices.append({'screen': I_ + 'repair_timber_structure', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_tdef', 'TIMBER_DEFECTS', 'Timber defects:', 'Timber Decay:', subs={TDEF: '{TIMBER_DEFECTS}'},
       tokens=[ck('{TIMBER_DEFECTS}', 'Localised', TDEF, 'f1td_', other=('f1td_other', 'f1td_other_text'))])]})
TROT = 'wet rot, dry rot, fungal decay, other'
slices.append({'screen': I_ + 'repair_timber_rot', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_rot', 'TIMBER_DECAY', 'Timber Decay:', 'Thin Timbers:', subs={TROT: '{TIMBER_DECAY}'},
       tokens=[ck('{TIMBER_DECAY}', 'Evidence of', TROT, 'f1r_', other=('f1r_other', 'f1r_other_text'))])]})
slices.append({'screen': I_ + 'repair_under_size_timber', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_thin', 'THIN_TIMBERS', 'Thin Timbers:', 'Heavy tiles sagging:', when=['cb_not_inspected', 'true'],
       extra=[cb('cb_not_inspected', 'Thin timbers')])]})
slices.append({'screen': I_ + 'repair_heavy_roof', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_heavy', 'HEAVY_TILES', 'Heavy tiles sagging:', 'Spray foam insulation:', when=['cb_not_inspected', 'true'],
       extra=[cb('cb_not_inspected', 'Heavy tiles sagging')])]})
WB = 'active, historic'
WB_DD = {'id': 'actv_insect_infestation', 'label': 'Wood-boring insects', 'type': 'dropdown',
         'options': ['No wood-boring', 'Wood boring noted']}
slices.append({'screen': I_ + 'repair_insect_infestation', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_wb_no', 'NO_WOOD_BORING', 'No Wood-boring:', 'Wood Boring Noted:', when=['actv_insect_infestation', 'No wood-boring'],
       extra=[WB_DD]),
    pr('f1_wb_yes', 'WOOD_BORING_NOTED', 'Wood Boring Noted:', 'Roof Movement:', subs={WB: '{WB_ACTIVITY}'},
       when=['actv_insect_infestation', 'Wood boring noted'],
       tokens=[ck('{WB_ACTIVITY}', 'Activity observed', WB, 'f1w_', cond='actv_insect_infestation=Wood boring noted')]),
]})
S_RM = I_ + 'roof_movement'
RMV = 'deflection, sagging, spread, other'
RMS = 'normal, minor, significant, severe, presents a hazard, other'
slices.append({'screen': S_RM, 'new_screen': new_screen(S_RM, 'Roof movement', 30, I_ + 'repair_heavy_roof'), 'rules': [
    pr('f1_move', 'ROOF_MOVEMENT', 'Roof Movement:', 'Structural Alterations:', subs={RMV: '{RM_EVIDENCE}', RMS: '{RM_LEVEL}'},
       tokens=[ck('{RM_EVIDENCE}', 'Evidence of', RMV, 'f1m_', other=('f1m_other', 'f1m_other_text')),
               ck('{RM_LEVEL}', 'Observed movement is', RMS, 'f1ml_', other=('f1ml_other', 'f1ml_other_text'))])]})
S_SA = I_ + 'structural_alterations'
SA = ('loft conversion, altered roof members, removed struts, trimmed rafters, replacement supports, additional timber '
      'supports, other')
slices.append({'screen': S_SA, 'new_screen': new_screen(S_SA, 'Structural alterations', 32, S_RM), 'rules': [
    pr('f1_alter', 'STRUCTURAL_ALTERATIONS', 'Structural Alterations:', 'Chimney Breast Alterations:', subs={SA: '{RS_ALTERATIONS}'},
       tokens=[ck('{RS_ALTERATIONS}', 'Alterations include', SA, 'f1a_', other=('f1a_other', 'f1a_other_text'))])]})

# ───────────── Chimney breast ─────────────
CB = 'removed, partially removed, altered, rendered, other'
CB_DD = {'id': 'actv_status', 'label': 'Support to remaining structure', 'type': 'dropdown',
         'options': ['Not inspected', 'Adequate support', 'Poor support', 'Risk of collapse']}
slices.append({'screen': I_ + 'repair_removed_chimney_breast', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_cb', 'CHIMNEY_BREAST', 'Chimney Breast Alterations:', 'Not inspected: Part of the chimney', subs={CB: '{CB_STATE}'},
       tokens=[ck('{CB_STATE}', 'Chimney breast has been', CB, 'f1cb_', other=('f1cb_other', 'f1cb_other_text'))]),
    pr('f1_cb_ni', 'CHIMNEY_NOT_INSPECTED', 'Not inspected: Part of the chimney', 'Adequate support: Part',
       when=['actv_status', 'Not inspected'], extra=[CB_DD]),
    pr('f1_cb_ok', 'CHIMNEY_ADEQUATE', 'Adequate support: Part', 'Poor support: Part', when=['actv_status', 'Adequate support']),
    pr('f1_cb_poor', 'CHIMNEY_POOR', 'Poor support: Part', 'Add text to:', when=['actv_status', 'Poor support']),
    pr('f1_cb_risk', 'CHIMNEY_COLLAPSE', 'Risk of collapse: Part', 'Add text to:', when=['actv_status', 'Risk of collapse']),
    pr('f1_cb_damp', 'CHIMNEY_DAMP', 'Minor Chimney Damp:', 'Party Wall', when=['cb_damp_chimney', 'true'],
       extra=[cb('cb_damp_chimney', 'Minor chimney damp')]),
]})
PW_DD = {'id': 'actv_party_wall', 'label': 'Party wall', 'type': 'dropdown', 'options': ['Partially missing', 'Largely missing']}
slices.append({'screen': I_ + 'repair_party_walls', 'replace_all': True, 'keep': [], 'rules': [
    pr('f1_pw_part', 'PARTY_WALL_PARTIAL', 'Partially missing: The party wall', 'Largely missing: The party wall',
       when=['actv_party_wall', 'Partially missing'], extra=[PW_DD]),
    pr('f1_pw_large', 'PARTY_WALL_LARGE', 'Largely missing: The party wall', 'Evidence of Water Penetration:',
       when=['actv_party_wall', 'Largely missing']),
]})

# ───────────── Not fully inspected (Inspection limitations paragraph attached to the E9 block by the digitiser) ─────────────
NF = ('limited roof height; the floor was not safe to walk on, floor was boarded, excessive storage, insulation, '
      'underlining, other')
nf_labels = ['limited roof height', 'the floor was not safe to walk on', 'floor was boarded', 'excessive storage',
             'insulation', 'underlining']
slices.append({'screen': I_ + 'roof_structure_not_inspected', 'replace_all': True, 'keep': [], 'rules': [
    para_rule('E9', 'f1_not_full', [MW], '{F1_ROOF_NOT_FULLY_INSPECTED}', 'Roof Not Fully Inspected:', 'Unsafe floor:',
              subs={NF: '{RS_LIMITS}'},
              tokens=[checks('{RS_LIMITS}', 'Could not fully inspect the roof timber because', opts('f1n_', nf_labels),
                             other=('f1n_other', 'f1n_other_text'))]),
    para_rule('E9', 'f1_unsafe', [MW], '{F1_UNSAFE_FLOOR}', 'Unsafe floor:', None, when=['cb_unsafe_floor', 'true'],
              extra=[cb('cb_unsafe_floor', 'Unsafe floor')]),
]})

# ───────────── Main screen: intro ─────────────
slices.append({'screen': I_ + 'roof_structure_main_screen', 'rules': [
    pr('f1_intro', 'INTRO', 'The roof structure was inspected from', 'Description: The roof structure is formed in', first=True,
       when=[RATING[0], RATING[1]], when_any=RATING[2])]})

slices.append({'remove_screens': [I_ + 'weather_condition', I_ + 'repair_tank', I_ + 'repair_roof_spreading']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
