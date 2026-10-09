# -*- coding: utf-8 -*-
"""Generate slices/e4_e.json (E4 Main walls) for slice.py. Bank text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import P, checks, dd, lst, opts, para_rule, rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e4_e.json')
S = 'E4'
MW = '{E_MAIN_WALLS}'
G16 = 'group_main_walls_16'
G17 = 'group_about_the_wall_17'
CD = 'Causing damp: This is allowing damp to get into the building. These should be repaired now.'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
SN = ['Repair soon', 'Repair now']


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], sub, start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None, cap=False):
    labels = lst(pdf_list)
    return checks(token, label, opts(prefix, labels), other=other, cond=cond, cap=cap)


def new_screen(sid, title, parent, order, after):
    return {'id': sid, 'title': title, 'parent': parent, 'order': order, 'after': after}


slices = []

# ───────────── About the wall (description, condition, painted) — one screen per wall type ─────────────
LOC_LIST = 'main building, extension(s), other'
TYPE_LIST = ('solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, '
             'other construction type(s)')
COND_LIST = 'good, reasonable, fair, poor, very poor'
ABOUT = [
    ('activity_outside_property_main_walls_about_wall', 'solid', 'solid brick', None),
    ('activity_outside_property_main_walls_about_wall__cavity_brick_wall', 'cbrick', 'cavity brick', None),
    ('activity_outside_property_main_walls_about_wall__cavity_block_wall', 'cblock', 'cavity blockwork', None),
    ('activity_outside_property_main_walls_about_wall__cavity_stud_wall', 'stud', 'timber frame', None),
    ('activity_outside_property_main_walls_about_wall__other', 'other', None, None),
    ('activity_outside_property_main_walls_about_wall__rendered_masonry', 'rendered', 'rendered masonry',
     ('Rendered masonry', 12, 'activity_outside_property_main_walls_about_wall__other')),
    ('activity_outside_property_main_walls_about_wall__pebble_dash_masonry', 'pebble', 'pebble dash masonry',
     ('Pebble dash masonry', 14, 'activity_outside_property_main_walls_about_wall__rendered_masonry')),
]
for sid, tag, wtype, newscr in ABOUT:
    if wtype:
        t_type = {'kind': 'constant', 'token': '{WALL_TYPE}', 'value': wtype}
    else:
        t_type = {'kind': 'text', 'token': '{WALL_TYPE}', 'dropdown': 'other', 'field_label': 'Other construction type'}
    desc = pr(f'e4_desc_{tag}', '{E4_DESCRIPTION}', 'Description: The external walls of the main building',
              'Cladding: The external wall finish',
              subs={LOC_LIST + ',': '{WALL_LOCATION}', '(type 000)': '{WALL_THICKNESS}', TYPE_LIST: '{WALL_TYPE}'},
              tokens=[ck('{WALL_LOCATION}', 'Wall', LOC_LIST, 'e4w_loc_', other=('cb_other_832', 'et_other_133')),
                      {'kind': 'text', 'token': '{WALL_THICKNESS}', 'dropdown': 'et_thickness',
                       'field_label': 'Thickness (mm)'},
                      t_type])
    cond = pr(f'e4_cond_{tag}', '{E4_CONDITION}', 'Condition: Where visible, the walls', 'Painted Walls:',
              subs={COND_LIST: '{WALL_CONDITION_VALUE}'},
              tokens=[dd('{WALL_CONDITION_VALUE}', 'actv_condition', 'Condition', COND5, lower=True)])
    painted = pr(f'e4_painted_{tag}', '{E4_PAINTED}', 'Painted Walls:', 'EWS1 Cladding:',
                 when=['cb_painted', 'true'],
                 extra=[{'id': 'cb_painted', 'label': 'Painted walls', 'type': 'checkbox'}])
    sl = {'screen': sid, 'replace_all': True, 'keep': [], 'rules': [desc, cond, painted]}
    if newscr:
        sl['new_screen'] = new_screen(sid, newscr[0], G17, newscr[1], newscr[2])
    slices.append(sl)

# ───────────── Cladding ─────────────
CLAD = ('facing brickwork, natural or reconstituted stone, timber cladding, plastic panelling boards. '
        'weatherboarding, fibre cement boards, uPVC cladding, fibre cement panels, composite cladding panels, '
        'glass curtain walling, hanging tiles (including shingle or plain tiles), aluminium cladding panels, '
        'terracotta cladding tiles, other finishes')
clad_labels = [x.strip() for x in CLAD.replace('. ', ', ').split(', ') if not x.strip().startswith('other')]
slices.append({
    'screen': 'activity_outside_property_main_walls_cladding', 'replace_all': True, 'keep': [],
    'rules': [pr('e4_cladding', '{E4_CLADDING}', 'Cladding: The external wall finish',
                 'Condition: Where visible, the walls', subs={CLAD: '{WALL_CLADDING}'},
                 tokens=[checks('{WALL_CLADDING}', 'Cladding', opts('e4c_', clad_labels),
                                other=('e4c_other', 'e4c_other_text'))])]})

# ───────────── EWS1 (new screen) ─────────────
EWS_LIST = ('brick-slip, brick-effect outer face, rainscreen boards, terracotta tiles, compressed composite '
            'boards, aluminium panels, glass reinforced concrete (GRC) panels, glass curtain walling, hanging '
            'tiles (including shingle or plain tiles), aluminium cladding panels')
S_EWS = 'activity_outside_property_main_walls_ews1'
EWS_DD = {'id': 'actv_ews1', 'label': 'EWS1', 'type': 'dropdown',
          'options': ['EWS1 form not required', 'EWS1 form required']}
slices.append({
    'screen': S_EWS,
    'new_screen': new_screen(S_EWS, 'EWS1 Cladding', G16, 4, 'activity_outside_property_main_walls_cladding'),
    'rules': [
        pr('e4_ews1', '{E4_EWS1_CLADDING}', 'EWS1 Cladding:', 'EWS1 form not required:',
           subs={'partially or predominantly': '{EWS1_EXTENT}', EWS_LIST: '{EWS1_TYPES}'},
           tokens=[dd('{EWS1_EXTENT}', 'actv_ews1_extent', 'Extent', ['Partially', 'Predominantly'], lower=True),
                   checks('{EWS1_TYPES}', 'Cladded with', opts('e4e_', lst(EWS_LIST)))]),
        pr('e4_ews1_not', '{E4_EWS1_NOT_REQUIRED}', 'EWS1 form not required:', 'EWS1 form required:',
           when=['actv_ews1', 'EWS1 form not required'], extra=[EWS_DD]),
        pr('e4_ews1_req', '{E4_EWS1_REQUIRED}', 'EWS1 form required:', 'Minor subsidence:',
           when=['actv_ews1', 'EWS1 form required']),
    ]})

# ───────────── Damp, moisture and DPC ─────────────
DAMP_DD = {'id': 'actv_status', 'label': 'Status', 'type': 'dropdown', 'options': ['No damp found', 'Damp found']}
DF = 'actv_status=Damp found'
CAUSES = 'overflowing gutter, roof leak, leaking downpipe, bridged DPC, blocked gully, other'
REPAIRS = 'gutters, roof covering, downpipes, damp-proof course, blocked gullies, damaged drainage, other'
BOTH = [['actv_status', 'Damp found']]
slices.append({
    'screen': 'activity_outside_property_main_walls_damp', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_moisture', '{E4_MOISTURE_READINGS}', 'Moisture metre readings:', 'No damp found:',
           when=['actv_status', 'No damp found'], when_any=BOTH, extra=[DAMP_DD]),
        pr('e4_nodamp', '{E4_NO_DAMP}', 'No damp found:', 'Damp found:', when=['actv_status', 'No damp found']),
        pr('e4_damp', '{E4_DAMP_FOUND}', 'Damp found:', 'Penetrating damp cause:',
           subs={'(enter locations)': '{DAMP_LOCATIONS}'}, when=['actv_status', 'Damp found'],
           tokens=[{'kind': 'text', 'token': '{DAMP_LOCATIONS}', 'dropdown': 'et_location_677',
                    'field_label': 'Location of elevated readings (e.g. lower walls in the lounge)',
                    'cond': DF}]),
        pr('e4_pen', '{E4_PENETRATING}', 'Penetrating damp cause:', 'Repair options:',
           subs={CAUSES: '{DAMP_CAUSES}'}, when=['actv_status', 'Damp found'],
           tokens=[ck('{DAMP_CAUSES}', 'Penetrating damp probably caused by', CAUSES, 'e4d_cause_',
                      other=('e4d_cause_other', 'e4d_cause_other_text'), cond=DF)]),
        pr('e4_repair_opts', '{E4_REPAIR_OPTIONS}', 'Repair options:', 'Investigate cause:',
           subs={REPAIRS: '{DAMP_REPAIRS}'}, when=['actv_status', 'Damp found'],
           tokens=[ck('{DAMP_REPAIRS}', 'Repairs may involve', REPAIRS, 'e4d_rep_',
                      other=('e4d_rep_other', 'e4d_rep_other_text'), cond=DF)]),
        pr('e4_investigate', '{E4_INVESTIGATE_CAUSE}', 'Investigate cause:', 'Rising damp:',
           when=['cb_unknown_cause', 'true'],
           extra=[{'id': 'cb_unknown_cause', 'label': 'Investigate cause', 'type': 'checkbox',
                   'conditionalOn': DF, 'conditionalMode': 'show'}]),
        pr('e4_rising', '{E4_RISING_DAMP}', 'Rising damp:', 'Add text to:', when=['cb_rising_damp', 'true'],
           extra=[{'id': 'cb_rising_damp', 'label': 'Rising damp', 'type': 'checkbox',
                   'conditionalOn': DF, 'conditionalMode': 'show'}]),
        pr('e4_drain', '{E4_INSTALL_DRAIN_GUTTERING}', 'Install drain guttering:', 'Removed wall:',
           when=['cb_install_french_gutters', 'true'],
           extra=[{'id': 'cb_install_french_gutters', 'label': 'Install drain guttering', 'type': 'checkbox',
                   'conditionalOn': DF, 'conditionalMode': 'show'}]),
    ]})

DPC_LIST = 'plastic, felt, slates, engineering bricks, other'
DPC_DD = {'id': 'actv_status', 'label': 'Status', 'type': 'dropdown',
          'options': ['Visible', 'Partially visible', 'Not visible']}
slices.append({
    'screen': 'activity_outside_property_main_walls_dpc', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_dpc', '{E4_DPC}', 'Damp-proof course:', 'The DPC is assumed to consist of',
           subs={'visible, partially visible, not visible': '{DPC_STATE}'},
           tokens=[dd('{DPC_STATE}', 'actv_status', 'DPC', ['Visible', 'Partially visible', 'Not visible'],
                      lower=True)]),
        pr('e4_dpc_material', '{E4_DPC_MATERIAL}', 'The DPC is assumed to consist of', 'The adequacy of concealed',
           subs={DPC_LIST: '{DPC_MATERIAL}'},
           tokens=[ck('{DPC_MATERIAL}', 'DPC assumed to consist of', DPC_LIST, 'e4p_',
                      other=('e4p_other', 'e4p_other_text'))]),
        pr('e4_dpc_adequacy', '{E4_DPC_ADEQUACY}', 'The adequacy of concealed', 'DPC Treatment noted:',
           when=['actv_status', 'Visible'], when_any=[['actv_status', 'Partially visible'], ['actv_status', 'Not visible']]),
    ]})

TREAT = 'damp proof course treatment, wall ventilation apparatus, ventilation holes, other'
S_TREAT = 'activity_outside_property_main_walls_dpc_treatment'
slices.append({
    'screen': S_TREAT,
    'new_screen': new_screen(S_TREAT, 'DPC Treatment', G16, 8, 'activity_outside_property_main_walls_dpc'),
    'rules': [pr('e4_treatment', '{E4_DPC_TREATMENT}', 'DPC Treatment noted:', 'Moisture metre readings:',
                 subs={TREAT: '{DPC_TREATMENT}'},
                 tokens=[ck('{DPC_TREATMENT}', 'Evidence noted of', TREAT, 'e4t_',
                            other=('e4t_other', 'e4t_other_text'))])]})

# ───────────── Removed wall, extensions, cavity insulation, thin wall, trees ─────────────
REM = 'lounge, kitchen, bedroom, other'
RDEF = 'cracking, distortions, other'
slices.append({
    'screen': 'activity_outside_property_main_walls_removed_wall', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_removed', '{E4_REMOVED_WALL}', 'Removed wall:', 'Defect noted:', subs={REM: '{REMOVED_LOCATION}'},
           tokens=[ck('{REMOVED_LOCATION}', 'Wall removed to', REM, 'e4r_', other=('cb_other_1020', 'et_other_522'))]),
        pr('e4_removed_defect', '{E4_REMOVED_DEFECT}', 'Defect noted:', 'Extensions and alterations:',
           subs={RDEF: '{REMOVED_DEFECTS}'},
           tokens=[ck('{REMOVED_DEFECTS}', 'Defects noted', RDEF, 'e4rd_', other=('e4rd_other', 'e4rd_other_text'))]),
    ]})
EXT = 'wall removal, new openings, replacement lintels, structural alterations, building extension works, other alterations'
S_EXT = 'activity_outside_property_main_walls_extensions'
slices.append({
    'screen': S_EXT,
    'new_screen': new_screen(S_EXT, 'Extensions and alterations', G16, 10,
                             'activity_outside_property_main_walls_removed_wall'),
    'rules': [pr('e4_extensions', '{E4_EXTENSIONS}', 'Extensions and alterations:', 'No Structural Movement:',
                 subs={EXT: '{EXT_ALTERATIONS}'},
                 tokens=[ck('{EXT_ALTERATIONS}', 'Alterations', EXT, 'e4x_', other=('e4x_other', 'e4x_other_text'))])]})
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_cavity_wall_insulation', 'replace_all': True, 'keep': [],
    'rules': [pr('e4_cwi', '{E4_CAVITY_WALL_INSULATION}', 'Cavity Wall Insulation:', 'Thin wall:',
                 when=['cb_not_inspected', 'true'],
                 extra=[{'id': 'cb_not_inspected', 'label': 'Cavity Wall Insulation', 'type': 'checkbox'}])]})
THIN_W = 'front, rear, side'
THIN_L = 'main building, extension, other'
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_thin_slim_wall', 'replace_all': True, 'keep': [],
    'rules': [pr('e4_thin', '{E4_THIN_WALL}', 'Thin wall:', 'Damp-proof course:',
                 subs={THIN_W: '{THIN_WALLS}', THIN_L: '{THIN_LOCATIONS}'},
                 tokens=[ck('{THIN_WALLS}', 'Walls', THIN_W, 'e4tw_'),
                         ck('{THIN_LOCATIONS}', 'Location', THIN_L, 'e4tl_', other=('cb_other_423', 'et_other_883'))])]})
TREE_DEF = 'cracking, distortion, heave, other observed defects'
TREE_DD = {'id': 'actv_trees', 'label': 'Trees', 'type': 'dropdown', 'options': ['Trees', 'Tree defects noted']}
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_near_by_tress', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_trees', '{E4_TREES}', 'Trees:', 'Tree defects noted:', when=['actv_trees', 'Trees'], extra=[TREE_DD]),
        pr('e4_tree_defects', '{E4_TREE_DEFECTS}', 'Tree defects noted:', 'Spalled Brickwork:',
           subs={TREE_DEF: '{TREE_DEFECTS}'}, when=['actv_trees', 'Tree defects noted'],
           tokens=[ck('{TREE_DEFECTS}', 'Defects', TREE_DEF, 'e4td_', other=('e4td_other', 'e4td_other_text'),
                      cond='actv_trees=Tree defects noted')]),
    ]})

# ───────────── Movements ─────────────
MOVE_OPTS = ['Minor subsidence', 'Significant subsidence', 'No structural movement', 'Normal defects',
             'Recent defects', 'Recurring defects', 'Differential thermal movement', 'Restraint steel rods']
MV_DD = {'id': 'actv_movement_status', 'label': 'Movement status', 'type': 'dropdown', 'options': MOVE_OPTS}
W3 = 'front, side, rear'
LOC6 = 'main building, back addition, extension, bay window, porch, other'
CAUSE6 = 'settlement, subsidence, nearby vegetation, point loading, wall tie damage, other causes'
mv = []
for i, (name, nxt, marker) in enumerate([
        ('Minor subsidence', 'Significant subsidence:', 'Minor subsidence:'),
        ('Significant subsidence', 'Cavity Wall Insulation:', 'Significant subsidence:'),
        ('No structural movement', 'Normal defects:', 'No Structural Movement:'),
        ('Normal defects', 'Recent defects:', 'Normal defects:')]):
    mv.append(pr(f'e4_mv_{i}', '{E4_MOVE_' + str(i) + '}', marker, nxt, when=['actv_movement_status', name],
                 extra=[MV_DD] if i == 0 else None))
mv.append(pr('e4_mv_recent', '{E4_MOVE_RECENT}', 'Recent defects:', 'Recurring defects:',
             subs={W3: '{MOVE_WALLS}', LOC6: '{MOVE_LOCATIONS}', CAUSE6: '{MOVE_CAUSES}'},
             when=['actv_movement_status', 'Recent defects'],
             tokens=[ck('{MOVE_WALLS}', 'Walls', W3, 'e4m_w_', cond='actv_movement_status=Recent defects'),
                     ck('{MOVE_LOCATIONS}', 'Location', LOC6, 'e4m_l_', other=('e4m_l_other', 'e4m_l_other_text'),
                        cond='actv_movement_status=Recent defects'),
                     ck('{MOVE_CAUSES}', 'Cracks potentially arising from', CAUSE6, 'e4m_c_',
                        other=('e4m_c_other', 'e4m_c_other_text'), cond='actv_movement_status=Recent defects')]))
mv.append(pr('e4_mv_recurring', '{E4_MOVE_RECURRING}', 'Recurring defects:', 'Differential Thermal Movement:',
             subs={LOC6: '{MOVE_LOCATIONS_RECURRING}'}, when=['actv_movement_status', 'Recurring defects'],
             tokens=[ck('{MOVE_LOCATIONS_RECURRING}', 'Walls repaired', LOC6, 'e4m_r_',
                        other=('e4m_r_other', 'e4m_r_other_text'), cond='actv_movement_status=Recurring defects')]))
mv.append(pr('e4_mv_thermal', '{E4_MOVE_THERMAL}', 'Differential Thermal Movement:', 'Restraint steel rods:',
             when=['actv_movement_status', 'Differential thermal movement']))
mv.append(pr('e4_mv_rods', '{E4_MOVE_RODS}', 'Restraint steel rods:', 'Trees:',
             when=['actv_movement_status', 'Restraint steel rods']))
slices.append({'screen': 'activity_outside_property_main_walls_movements', 'replace_all': True, 'keep': [],
               'rules': mv})

# ───────────── Repairs ─────────────
DEFECT_FIELD = None


def sev(dd_id, opts_list):
    return {'id': dd_id, 'label': 'Severity', 'type': 'dropdown', 'options': opts_list}


SP_DD = sev('actv_severity', ['Minor', 'Moderate', 'Significant'])
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_spalling', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_spall', '{E4_SPALLING}', 'Spalled Brickwork:', CD,
           subs={'minor, moderate, significant': '{SPALL_SEVERITY}'},
           tokens=[dd('{SPALL_SEVERITY}', 'actv_severity', 'Deterioration', ['Minor', 'Moderate', 'Significant'],
                      lower=True)]),
        pr('e4_spall_damp', '{E4_SPALLING_DAMP}', CD, 'Repair pointing:', when=['cb_causing_damp', 'true'],
           extra=[{'id': 'cb_causing_damp', 'label': 'Causing damp', 'type': 'checkbox'}]),
    ]})
PT = 'eroded, cracked, loose, missing, damaged, other'
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_pointing', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_pointing', '{E4_POINTING}', 'Repair pointing:', CD, subs={PT: '{POINTING_DEFECTS}'},
           tokens=[ck('{POINTING_DEFECTS}', 'Pointing is', PT, 'e4pt_', other=('e4pt_other', 'e4pt_other_text'))]),
        pr('e4_pointing_damp', '{E4_POINTING_DAMP}', CD, 'Repair render:', when=['cb_causing_damp', 'true'],
           extra=[{'id': 'cb_causing_damp', 'label': 'Causing damp', 'type': 'checkbox'}]),
    ]})
RN = 'cracked, eroded, loose, missing, damaged'
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_render', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_render', '{E4_RENDER}', 'Repair render:', 'Hazard:', subs={RN: '{RENDER_DEFECTS}'},
           tokens=[ck('{RENDER_DEFECTS}', 'Render is', RN, 'e4rn_')]),
        pr('e4_render_hazard', '{E4_RENDER_HAZARD}', 'Hazard:', CD, when=['cb_hazard', 'true'],
           extra=[{'id': 'cb_hazard', 'label': 'Hazard', 'type': 'checkbox'}]),
        pr('e4_render_damp', '{E4_RENDER_DAMP}', CD, 'Wall Ties defects:', when=['cb_causing_damp', 'true'],
           extra=[{'id': 'cb_causing_damp', 'label': 'Causing damp', 'type': 'checkbox'}]),
    ]})
WT_DD = {'id': 'actv_status', 'label': 'Wall ties', 'type': 'dropdown', 'options': ['Wall Ties defects', 'Repair defect']}
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_wall_the_repair', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_walltie_prev', '{E4_WALL_TIES_PREVIOUS}', 'Wall Ties defects:', 'Repair defect: Some signs',
           when=['actv_status', 'Wall Ties defects'], extra=[WT_DD]),
        pr('e4_walltie_defect', '{E4_WALL_TIES_DEFECT}', 'Repair defect: Some signs', 'Lintel defect:',
           when=['actv_status', 'Repair defect']),
    ]})

WALLS4 = 'front, side, rear, other'
LOCS5 = 'main building, back addition, extension, bay window, other'
LINTEL_DEF = 'damaged, cracked, or distorted'
SILL_DEF = 'damaged, rotten, cracked, distorted, other'
for sid, tag in [('activity_outside_property_main_wall_repairs_lintel', 'win'),
                 ('activity_outside_property_main_wall_repairs_lintel__door', 'door')]:
    LDD = {'id': 'actv_condition', 'label': 'Severity', 'type': 'dropdown',
           'options': ['Minor defects', 'Significant defect']}
    slices.append({
        'screen': sid, 'replace_all': True, 'keep': [],
        'rules': [
            pr(f'e4_lintel_{tag}', '{E4_LINTEL}', 'Lintel defect:', 'Minor defects:',
               subs={WALLS4: '{LINTEL_WALLS}', LOCS5: '{LINTEL_LOCATIONS}'},
               tokens=[ck('{LINTEL_WALLS}', 'Wall', WALLS4, 'e4l_w_', other=('e4l_w_other', 'e4l_w_other_text')),
                       ck('{LINTEL_LOCATIONS}', 'Location', LOCS5, 'e4l_l_', other=('e4l_l_other', 'e4l_l_other_text'))]),
            pr(f'e4_lintel_minor_{tag}', '{E4_LINTEL_MINOR}', 'Minor defects:', 'Significant defect:',
               when=['actv_condition', 'Minor defects'], extra=[LDD]),
            pr(f'e4_lintel_major_{tag}', '{E4_LINTEL_SIGNIFICANT}', 'Significant defect:', 'Add text to:',
               when=['actv_condition', 'Significant defect']),
        ]})
SDD = {'id': 'actv_condition', 'label': 'Severity', 'type': 'dropdown',
       'options': ['Minor Defect', 'Significant Defect']}
slices.append({
    'screen': 'activity_outside_property_main_wall_repairs_window_sills', 'replace_all': True, 'keep': [],
    'rules': [
        pr('e4_sill', '{E4_WINDOWSILL}', 'Windowsill defect:', 'Minor Defect:',
           subs={WALLS4.replace('other', 'other wall'): '{SILL_WALLS}'} if False else
           {'front, side, rear, other wall': '{SILL_WALLS} wall', LOCS5: '{SILL_LOCATIONS}', SILL_DEF: '{SILL_DEFECTS}'},
           tokens=[ck('{SILL_WALLS}', 'Wall', WALLS4, 'e4s_w_', other=('e4s_w_other', 'e4s_w_other_text')),
                   ck('{SILL_LOCATIONS}', 'Location', LOCS5, 'e4s_l_', other=('e4s_l_other', 'e4s_l_other_text')),
                   ck('{SILL_DEFECTS}', 'Defects', SILL_DEF, 'e4s_d_', other=('e4s_d_other', 'e4s_d_other_text'))]),
        pr('e4_sill_minor', '{E4_SILL_MINOR}', 'Minor Defect:', 'Significant Defect:',
           when=['actv_condition', 'Minor Defect'], extra=[SDD]),
        pr('e4_sill_major', '{E4_SILL_SIGNIFICANT}', 'Significant Defect:', 'General Maintenance:',
           when=['actv_condition', 'Significant Defect']),
    ]})

# ───────────── General maintenance ─────────────
slices.append({
    'screen': 'activity_outside_property_main_walls_main_screen',
    'rules': [pr('e4_general', '{E4_GENERAL_MAINTENANCE}', 'General Maintenance:', 'If the Property is a Flat',
                 when=['cb_general_maintenance', 'true'],
                 extra=[{'id': 'cb_general_maintenance', 'label': 'General maintenance', 'type': 'checkbox'}])]})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s['rules']) for s in slices), 'rules')
