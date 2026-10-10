# -*- coding: utf-8 -*-
"""Generate slices/e2_e.json (E2 Roof covering) for slice.py.

    python tool/phrase_audit/verbatim/slices/gen_e2.py
    python tool/phrase_audit/verbatim/slice.py tool/phrase_audit/verbatim/slices/e2_e.json
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e2_e.json')
RC = '{E_ROOF_COVERING}'
RCR = '{E_ROOF_COVERING_REPAIR}'

NOREP = ('No repair required: No significant defects requiring immediate attention were '
         'identified unless otherwise stated below.')


slices = []

# ───────────── Description + condition (pitched / mansard / other) ─────────────
PDF_DESC = ('Description: The pitched, mansard, flat roof covering to the main building, extension, '
            'porch, or bay window, other is formed in original or replacement clay tiles, concrete '
            'tiles, natural slate, artificial slate, fibre cement slates, aluminium sheets, composite '
            'slate, asbestos sheet, other material.')
PDF_COND = 'Condition: Where visible, the covering appears in good, reasonable, fair, poor, very poor condition.'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
LOC = [('cb_main_building', 'main building'), ('cb_extension', 'extension'),
       ('rc_loc_porch', 'porch'), ('cb_bay_window', 'bay window')]
MAT = [('rc_mat_original_clay', 'original clay tiles'), ('rc_mat_replacement_clay', 'replacement clay tiles'),
       ('cb_concrete', 'concrete tiles'), ('cb_natural', 'natural slate'),
       ('rc_mat_artificial_slate', 'artificial slate'), ('rc_mat_fibre_cement', 'fibre cement slates'),
       ('rc_mat_aluminium', 'aluminium sheets'), ('cb_composite', 'composite slate'),
       ('rc_mat_asbestos_sheet', 'asbestos sheet')]
OLD_FIELD = {'id': 'cb_old_roof_covering', 'label': 'Old roof covering', 'type': 'checkbox'}

DESC_TEXT = 'Description: The {RC_TYPE} roof covering to the {RC_LOCATION} is formed in {RC_MATERIAL}.'
COND_TEXT = ('Condition: Where visible, the covering appears in {RC_TYPE_CONDITION} condition. '
             + NOREP + ' The roof covering appears to be adequately performing its function. '
             'Routine maintenance appropriate to the age of the roof covering should be expected.')
OLD_TEXT = ('Old roof covering: The roof covering over the building is old and may have reached, or be '
            'nearing, the end of its useful life and will need to be stripped and renewed soon. If '
            're-covered in heavier materials the timbers may need to be strengthened to comply with '
            'current Building Regulations. Further, although functioning satisfactorily, older roof '
            'coverings should be expected to require increased maintenance and eventual replacement as '
            'part of their normal service life.')
ASB_TEXT = ('Asbestos: Parts of the roof covering and verge may contain asbestos. This type of asbestos base '
            'product is not normally a cause for concern according to the Health and Safety Executive. '
            'However, it should not be disturbed, sanded, or drilled without taking suitable safety '
            'precautions. When the slates are eventually replaced, a licensed removal contractor will need '
            'to be instructed, and this could be costly. Therefore, quotations for this work should be '
            'obtained before purchase commitment. Because of the possible asbestos content, you should get '
            'advice from a contractor experienced in this type of work or an asbestos specialist before any '
            'work is carried out.')

for sid, rtype, tag in [('outside_property_about_roof_layout', 'pitched', 'pitched'),
                        ('outside_property_about_roof_layout__mansard', 'mansard', 'mansard'),
                        ('outside_property_about_roof_layout__other', None, 'other')]:
    if rtype:
        t_type = {'kind': 'constant', 'token': '{RC_TYPE}', 'value': rtype}
    else:
        t_type = {'kind': 'text', 'token': '{RC_TYPE}', 'dropdown': 'other', 'field_label': 'Other roof type'}
    slices.append({
        'screen': sid, 'replace_all': True, 'keep': [],
        'rules': [
            rule(f'e2_desc_{tag}', [RC], '{RC_ABOUT_TYPE}', DESC_TEXT, pdf=PDF_DESC,
                 tokens=[t_type,
                         checks('{RC_LOCATION}', 'Location', LOC, other=('cb_other_22', 'etRoofLocationOther')),
                         checks('{RC_MATERIAL}', 'Material', MAT, other=('cb_other_78', 'etRoofMaterialOther'))]),
            rule(f'e2_cond_{tag}', [RC], '{RC_ABOUT_TYPE_CONDITION}', COND_TEXT, pdf=PDF_COND,
                 tokens=[dd('{RC_TYPE_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
            rule(f'e2_old_{tag}', [RC], '{OLD_ROOF_COVERING}', OLD_TEXT, when=['cb_old_roof_covering', 'true'],
                 extra=[OLD_FIELD]),
            rule(f'e2_asbestos_{tag}', ['{E_ROOF_COVERING_MATERIAL}'], '{MATERIAL_COMPOSITE}', ASB_TEXT,
                 when=['cb_composite', 'true'], when_any=[['rc_mat_asbestos_sheet', 'true']]),
        ]})

# ───────────── Flat roof coverings ─────────────
FLAT_MAT = [('cb_mineral_felt', 'mineral felt'), ('rc_flat_hp_felt', 'high-performance felt'),
            ('cb_rubber', 'rubber membrane'), ('cb_single_ply_membrane', 'single-ply membrane'),
            ('rc_flat_grp', 'GRP fibreglass'), ('rc_flat_asphalt', 'asphalt'),
            ('cb_fiberglass', 'fibreglass'), ('rc_flat_lead', 'lead')]
PDF_FLAT = ('Flat roof coverings: The flat roof covering over the building is formed in mineral felt, '
            'high-performance felt, rubber membrane, single-ply membrane, GRP fibreglass, asphalt, '
            'fibreglass, lead, other material.')
FELT_TEXT = ('Flat felt roof coverings have a comparatively short life and will require regular maintenance '
             'checks. Even though the general condition of the felt may appear satisfactory for its type and '
             'age, repairs or replacement must be expected in the future. It is difficult to predict when '
             'this will be required as felt roofs can break down with little warning, even when visually '
             'appearing sound.')
FLAT_OLD = ('Old roof covering: The flat roof covering over the building is old and may have reached, or be '
            'nearing, the end of its useful life and will need to be stripped and renewed soon. If '
            're-covered in heavier materials, the timbers may need to be strengthened to comply with '
            'current Building Regulations. Further, although functioning satisfactorily, older roof '
            'coverings should be expected to require increased maintenance and eventual replacement as '
            'part of their normal service life.')
slices.append({
    'screen': 'outside_property_about_roof_layout__flat', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_flat_desc', [RC], '{RC_FLAT_ABOUT}',
             'Flat roof coverings: The flat roof covering over the building is formed in {RC_MATERIAL}.',
             pdf=PDF_FLAT,
             tokens=[checks('{RC_MATERIAL}', 'Material', FLAT_MAT, other=('cb_other_78', 'etRoofMaterialOther'))]),
        rule('e2_flat_cond', [RC], '{RC_FLAT_CONDITION}',
             'Condition: Where visible, the covering appears in {RC_TYPE_CONDITION} condition.',
             pdf=PDF_COND, tokens=[dd('{RC_TYPE_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
        rule('e2_flat_felt', ['{E_ROOF_COVERING_MATERIAL}'], '{FLAT_MATERIAL_MINERAL_FELT}', FELT_TEXT,
             when=['cb_mineral_felt', 'true'], when_any=[['rc_flat_hp_felt', 'true']]),
        rule('e2_flat_norepair', [RC], '{RC_FLAT_NO_REPAIR}',
             NOREP + ' The flat roof covering appears to be adequately performing its function. Routine '
             'maintenance appropriate to the age of the roof covering should be expected.',
             when=['actv_condition', 'Good'],
             when_any=[['actv_condition', v] for v in COND5[1:]]),
        rule('e2_flat_old', [RC], '{OLD_ROOF_COVERING_FLAT}', FLAT_OLD, when=['cb_old_roof_covering', 'true'],
             extra=[OLD_FIELD]),
    ]})

# the old "weathered" condition screen shares the pitched condition sentence
slices.append({
    'screen': 'outside_property_roof_covering_weathered_layout',
    'rules': [
        rule('e2_cond_weathered', [RC], '{RC_ABOUT_TYPE_CONDITION}', COND_TEXT, pdf=PDF_COND,
             when=['cb_weathered', 'true'],
             tokens=[dd('{RC_TYPE_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
    ]})

# ───────────── Flashings ─────────────
COND4 = ['Good', 'Reasonable', 'Poor', 'Defective']
FL_MAT = [('cb_lead', 'lead'), ('cb_mortar', 'mortar'), ('cb_tiles', 'clay tiles'),
          ('rc_fl_mineral_felt', 'mineral felt'), ('rc_fl_bitumen_tape', 'bitumen tape'),
          ('rc_fl_lead_substitute', 'lead substitute')]
slices.append({
    'screen': 'outside_property_roof_covering_flashing_layout', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_flashing', [RC], '{E_RC_FLASHING}',
             'Flashings: The waterproofing at the junction of the roof covering and wall (called the flashing) '
             'appears to be formed in {RC_FLASHING}.',
             pdf='Flashings: The waterproofing at the junction of the roof covering and wall (called the '
                 'flashing) appears to be formed in lead, mortar, clay tiles, mineral felt, bitumen tape, '
                 'lead substitute, other.',
             tokens=[checks('{RC_FLASHING}', 'Formed in', FL_MAT, other=('cb_other_33', 'et_other_87'))]),
        rule('e2_flashing_cond', [RC], '{E_RC_FLASHING_CONDITION}',
             'Condition: Where visible, the flashings appear in {RC_FLASHING_CONDITION} condition. Defective '
             'flashings should be repaired to reduce the risk of water penetration. ' + NOREP +
             ' Routine maintenance appropriate to the age of the roof covering should be expected.',
             pdf='Condition: Where visible, the flashings appear in good, reasonable, poor, defective condition.',
             tokens=[dd('{RC_FLASHING_CONDITION}', 'actv_condition', 'Condition', COND4, lower=True)]),
    ]})

# ───────────── Ridge / hip tiles ─────────────
slices.append({
    'screen': 'outside_property_roof_covering_ridge_tiles_layout', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_ridge', [RC], '{E_RC_RIDGE_TILES}',
             'Ridge tiles: The covering along the top of the roof structure, called the ridge tiles, is '
             'assumed to be formed in {RC_RIDGE_TILES}.',
             pdf='Ridge tiles: The covering along the top of the roof structure, called the ridge tiles, is '
                 'assumed to be formed in clay, concrete, other material.',
             tokens=[checks('{RC_RIDGE_TILES}', 'Formed in',
                            [('rc_ridge_clay', 'clay'), ('cb_concrete', 'concrete')],
                            other=('cb_other_62', 'et_other_101'))]),
        rule('e2_ridge_cond', [RC], '{E_RC_RIDGE_TILES_CONDITION}',
             'Condition: Where visible, they appear in {RC_RIDGE_TILES_CONDITION} condition. Loose or '
             'defective ridge tiles should be rebedded or mechanically fixed as appropriate. ' + NOREP +
             ' Routine maintenance appropriate to the age of the ridge tiles should be expected.',
             pdf='Condition: Where visible, they appear in good, reasonable, poor, defective condition.',
             tokens=[dd('{RC_RIDGE_TILES_CONDITION}', 'actv_formed_in', 'Condition', COND4, lower=True)]),
    ]})
slices.append({
    'screen': 'outside_property_roof_covering_hip_tiles_layout', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_hip', [RC], '{E_RC_HIP_TILES}',
             'Hip tiles: The covering along the junction of the roof slopes, called the hip tiles, is '
             'assumed to be formed in {RC_HIP_TILES}.',
             pdf='Hip tiles: The covering along the junction of the roof slopes, called the hip tiles, is '
                 'assumed to be formed in clay, concrete, other material.',
             tokens=[checks('{RC_HIP_TILES}', 'Formed in',
                            [('rc_hip_clay', 'clay'), ('cb_concrete', 'concrete')],
                            other=('cb_other_62', 'et_other_101'))]),
        rule('e2_hip_cond', [RC], '{E_RC_HIP_TILES_CONDITION}',
             'Condition: Where visible, they appear in {RC_HIP_TILES_CONDITION} condition. Repairs should be '
             'undertaken where movement or deterioration is evident. ' + NOREP +
             ' Routine maintenance appropriate to the age of the hip tiles should be expected.',
             pdf='Condition: Where visible, they appear in good, reasonable, poor, defective condition.',
             tokens=[dd('{RC_HIP_TILES_CONDITION}', 'actv_formed_in', 'Condition', COND4, lower=True)]),
    ]})

# ───────────── Valley gutters (description) ─────────────
slices.append({
    'screen': 'outside_property_roof_covering_valley_gutters_layout',
    'new_screen': {'id': 'outside_property_roof_covering_valley_gutters_layout', 'title': 'Valley Gutters',
                   'parent': 'group_roof_covering_10', 'order': 13,
                   'after': 'outside_property_roof_covering_hip_tiles_layout'},
    'rules': [
        rule('e2_valley', [RC], '{E_RC_VALLEY_GUTTERS}',
             'Valley Gutters: The valley gutters are formed in {RC_VALLEY_GUTTERS}.',
             pdf='Valley Gutters: The valley gutters are formed in lead, mortar, other material.',
             tokens=[checks('{RC_VALLEY_GUTTERS}', 'Formed in',
                            [('rc_vg_lead', 'lead'), ('rc_vg_mortar', 'mortar')],
                            other=('rc_vg_other', 'rc_vg_other_text'))]),
        rule('e2_valley_cond', [RC], '{E_RC_VALLEY_GUTTERS_CONDITION}',
             'Condition: Where visible, they appear in {RC_VALLEY_GUTTERS_CONDITION} condition. Blocked or '
             'defective valley gutters should be cleared, repaired, or replaced as necessary to ensure '
             'effective drainage and prevent water penetration into the building. ' + NOREP +
             ' Routine maintenance appropriate to the age of the guttering should be expected.',
             pdf='Condition: Where visible, they appear in good, reasonable, poor, blocked condition.',
             tokens=[dd('{RC_VALLEY_GUTTERS_CONDITION}', 'actv_condition', 'Condition',
                        ['Good', 'Reasonable', 'Poor', 'Blocked'], lower=True)]),
    ]})

# ───────────── Parapet walls ─────────────
slices.append({
    'screen': 'outside_property_roof_covering_parapet_wall_layout', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_parapet', [RC], '{E_RC_PARAPET_WALL}',
             'Parapet walls: The parapet wall(s) are constructed of {RC_PARAPET_WALL_BUILT_WITH}.',
             pdf='Parapet walls: The parapet wall(s) are constructed of brick, stone, rendered masonry, '
                 'concrete, other.',
             master_ref_after='{E_RC_PARAPET_WALL_CONDITION}' if False else None,
             tokens=[checks('{RC_PARAPET_WALL_BUILT_WITH}', 'Constructed of',
                            [('cb_bricks', 'brick'), ('rc_pw_stone', 'stone'),
                             ('rc_pw_rendered_masonry', 'rendered masonry'), ('cb_concrete', 'concrete')],
                            other=('cb_other_44', 'et_other_101'))]),
        rule('e2_parapet_coping', [RC], '{E_RC_PARAPET_COPING}',
             'Coping: The parapet coping is formed in {RC_PARAPET_COPING}.',
             pdf='Coping: The parapet coping is formed in stone, tiles, concrete, engineering brick, metal, '
                 'other material.',
             tokens=[checks('{RC_PARAPET_COPING}', 'Coping formed in',
                            [('rc_pc_stone', 'stone'), ('rc_pc_tiles', 'tiles'), ('rc_pc_concrete', 'concrete'),
                             ('rc_pc_engineering_brick', 'engineering brick'), ('rc_pc_metal', 'metal')],
                            other=('rc_pc_other', 'rc_pc_other_text'))]),
        rule('e2_parapet_cond', [RC], '{E_RC_PARAPET_WALL_CONDITION}',
             'Condition: Where visible, these elements appear in {RC_PARAPET_WALL_CONDITION} condition. '
             'Defective copings or pointing should be repaired to prevent water penetration. ' + NOREP +
             ' Routine maintenance appropriate to the age of the wall should be expected.',
             pdf='Condition: Where visible, these elements appear in good, reasonable, poor, defective condition.',
             tokens=[dd('{RC_PARAPET_WALL_CONDITION}', 'android_material_design_spinner3', 'Condition',
                        COND4, lower=True)]),
    ]})

# ───────────── Roof line deflection / structure ─────────────
slices.append({
    'screen': 'outside_property_roof_covering_deflection_layout', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_deflection', ['{E_RC_DEFLECTION_STATUS}'], '{DEFLECTION_MINOR}',
             'Roof line deflection: Minor undulation or deflection to {RC_DEFLECTION_STATUS_LOCATION} roof '
             'slopes were observed. Such distortion is not uncommon in properties of this age and, unless '
             'accompanied by evidence of progressive movement, is not necessarily of structural significance.',
             pdf='Roof line deflection: Minor undulation or deflection to all, front, rear, side roof '
                 'slopes were observed.',
             tokens=[checks('{RC_DEFLECTION_STATUS_LOCATION}', 'Location',
                            [('rc_df_all', 'all'), ('cb_front_45', 'front'), ('cb_rear_47', 'rear'),
                             ('cb_side_41', 'side')])]),
    ]})
STRUCT_DD = {'id': 'actv_status', 'label': 'Status', 'type': 'dropdown',
             'options': ['No repair required', 'Repair defect']}
slices.append({
    'screen': 'outside_property_roof_covering_roof_structure_layout', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_struct_ok', ['{E_ROOF_COVERING_ROOF_CONDITION}'], '{RC_ROOF_CONDITION_OK}',
             'No repair required: No repair is currently needed, and this is not considered to be '
             'structurally significant. The timber used in older roofs can gradually change shape or distort '
             'during normal use. Also, heavier replacement tiles can cause minor deflection to the roof line '
             'in some instances. This does not currently appear to be a problem and is considered normal for '
             'this type of roof. Should further deflection or distortion occur, you should arrange for '
             'inspection by a qualified person.',
             when=['actv_status', 'No repair required'], extra=[STRUCT_DD]),
        rule('e2_struct_defect', ['{E_ROOF_COVERING_ROOF_CONDITION}'], '{RC_ROOF_CONDITION_INVESTIGATE}',
             'Repair defect: The surface of the {RC_ROOF_INVESTIGATE_LOCATION} roof slope(s) of the building '
             'is significantly distorted, uneven or undulating. You should contact a qualified roofing '
             'contractor to replace damaged timber or strengthen any weakened or undersized timber so that '
             'the roof structure can adequately bear the weight of the roof covering (see section J1 - Risk '
             'to Building).',
             pdf='Repair defect: The surface of the front, rear, side roof slope(s) of the building is '
                 'significantly distorted, uneven or undulating.',
             when=['actv_status', 'Repair defect'],
             tokens=[checks('{RC_ROOF_INVESTIGATE_LOCATION}', 'Location',
                            [('cb_front_39', 'front'), ('cb_rear_20', 'rear'), ('cb_side_78', 'side')],
                            cond='actv_status=Repair defect')]),
    ]})

# ───────────── Repairs: tiles (soon / now / leaking) ─────────────
TILE_ISSUES = [('rc_rt_loose', 'loose'), ('rc_rt_missing', 'missing'), ('rc_rt_lifted', 'lifted'),
               ('rc_rt_slipped', 'slipped'), ('rc_rt_cracked', 'cracked'), ('rc_rt_broken', 'broken'),
               ('rc_rt_distorted', 'distorted')]
TC = 'actv_condition=Repair soon|Repair now'
COND_DD = {'id': 'actv_condition', 'label': 'Condition', 'type': 'dropdown',
           'options': ['Repair soon', 'Repair now', 'Leaking']}


def tile_issues():
    return checks('{RC_ROOF_REPAIR_TILES_ISSUE}', 'Defects', TILE_ISSUES,
                  other=('rc_rt_other', 'rc_rt_other_text'), cond=TC)


slices.append({
    'screen': 'activity_outside_property_roof_repair_tiles', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_tiles_soon', ['{E_RC_TILES}'], '{REPAIR_SOON}',
             'Repair soon: One or more tiles, slates, are {RC_ROOF_REPAIR_TILES_ISSUE}. This should be '
             'repaired soon. You should contact a qualified roofing contractor to carry out further '
             'investigation and replace or repair damaged covering.',
             pdf='Repair soon: One or more tiles, slates, are loose, missing, lifted, slipped, cracked, '
                 'broken, distorted, other.',
             when=['actv_condition', 'Repair soon'], extra=[COND_DD], tokens=[tile_issues()]),
        rule('e2_tiles_now', ['{E_RC_TILES}'], '{REPAIR_NOW}',
             'Repair now: One or more tiles, slates, roof covering sections are severely or significantly '
             '{RC_ROOF_REPAIR_TILES_ISSUE}. Given the extent of the defect, this should be repaired now. The '
             'fixings on older roofs can weaken and result in more future maintenance. In some cases, it may '
             'be economical to replace the whole roof covering rather than continuing to repair. You should '
             'contact a qualified roofing contractor to carry out further investigation and recommend '
             'remedial work.',
             pdf='Repair now: One or more tiles, slates, roof covering sections are severely or '
                 'significantly loose, missing, lifted, slipped, cracked, broken, distorted, other.',
             when=['actv_condition', 'Repair now'], tokens=[tile_issues()]),
        rule('e2_tiles_leaking', ['{E_RC_TILES}'], '{LEAKING}',
             'Leaking: The roof covering has extensive defects that are likely to allow water penetration '
             'into the building and may present a safety risk. Urgent repair is required. You should '
             'instruct a suitably qualified roofing contractor to carry out a detailed inspection, identify '
             'the full extent of the defects, and undertake the necessary remedial works without delay.',
             when=['actv_condition', 'Leaking']),
    ]})

# ───────────── Repairs: roof spreading ─────────────
slices.append({
    'screen': 'activity_outside_property_roof_spreading_repair', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_spreading', [RCR], '{RC_ROOF_SPREADING}',
             'Roof Spreading: The roof slopes to {RC_ROOF_SPREADING_LOCATION} of the building appear uneven or '
             'undulating, and the adjoining wall appears distorted, cracked, bowing or leaning outwards. '
             'These are visual indicators that may be consistent with roof spread and suggest that the roof '
             'timber structure may require strengthening. I recommend that you instruct a suitably qualified '
             'structural engineer or roofing specialist to carry out further investigation and advise on any '
             'necessary remedial work without undue delay (see section J1 - Risk to Building).',
             pdf='Roof Spreading: The roof slopes to all, front, side, and rear of the building appear '
                 'uneven or undulating, and the adjoining wall appears distorted, cracked, bowing or '
                 'leaning outwards.',
             tokens=[checks('{RC_ROOF_SPREADING_LOCATION}', 'Location',
                            [('rc_rs_all', 'all'), ('rc_rs_front', 'front'), ('rc_rs_side', 'side'),
                             ('rc_rs_rear', 'rear')])]),
    ]})

# ───────────── Repairs: flat roof ─────────────
FLAT_ISSUES = [('rc_fr_weathered', 'weathered'), ('rc_fr_blistered', 'blistered'), ('rc_fr_split', 'split'),
               ('rc_fr_torn', 'torn'), ('rc_fr_worn', 'worn'), ('rc_fr_ponding', 'ponding'),
               ('rc_fr_damaged', 'damaged')]
SN = ['Repair soon', 'Repair now']
SN_DD = {'id': 'actv_condition', 'label': 'Condition', 'type': 'dropdown', 'options': SN}


def flat_issues():
    return checks('{RC_FLAT_ROOF_REPAIR_COVERED}', 'Defects', FLAT_ISSUES,
                  other=('rc_fr_other', 'rc_fr_other_text'))


PDF_FLAT_REPAIR = ('Repair Flat roof: The flat roof covering is weathered, blistered, split, torn, worn, '
                   'ponding, damaged, other.')
slices.append({
    'screen': 'activity_outside_property_roof_repair_flat_roof', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_flatrepair_soon', ['{E_RC_FLAT_ROOF_REPAIR}'], '{REPAIR_SOON}',
             'Repair Flat roof: The flat roof covering is {RC_FLAT_ROOF_REPAIR_COVERED}. Repairs or '
             'replacement should be undertaken before further deterioration results in water penetration. '
             'To replace the covering, the work will have to meet the requirements of the building '
             'regulations. This may increase the amount of repair work.',
             pdf=PDF_FLAT_REPAIR, when=['actv_condition', 'Repair soon'], extra=[SN_DD], tokens=[flat_issues()]),
        rule('e2_flatrepair_now', ['{E_RC_FLAT_ROOF_REPAIR}'], '{REPAIR_NOW}',
             'Repair Flat roof: The flat roof covering is {RC_FLAT_ROOF_REPAIR_COVERED}. Causing damp - The '
             'observed defect is causing damp penetration to the building below. The flat roof covering '
             'needs repair or replacement now. To do this, the work will have to meet the requirements of '
             'the Building Regulations. This may increase the amount of repair work (see section J1 - Risk '
             'to Building).',
             when=['actv_condition', 'Repair now'], tokens=[flat_issues()]),
    ]})

# ───────────── Repairs: parapet wall ─────────────
PW_SUBJ = [('rc_pr_rendering', 'rendering'), ('rc_pr_copping', 'copping'), ('rc_pr_flashing', 'flashing')]
PW_ISS = [('rc_pr_damaged', 'damaged'), ('rc_pr_loose', 'loose'), ('rc_pr_partly_missing', 'partly missing'),
          ('rc_pr_cracked', 'cracked'), ('rc_pr_poorly_secured', 'poorly secured')]
PR_TAIL = (' Adjacent parts of the roof covering may have to be disturbed to repair the verge tiles, and '
           'this can increase the amount of repair work.')
PDF_PR = ('Repair parapet: The rendering, copping, flashing, other of the parapet(s) of the roof are '
          'damaged, loose, partly missing, cracked, poorly secured, other.')


def pr_tokens():
    return [checks('{RC_PARAPET_WALL_REPAIR_SUBJECT}', 'Parapet parts', PW_SUBJ,
                   other=('rc_pr_subj_other', 'rc_pr_subj_other_text')),
            checks('{RC_PARAPET_WALL_REPAIR_ISSUE}', 'Defects', PW_ISS,
                   other=('rc_pr_iss_other', 'rc_pr_iss_other_text'))]


slices.append({
    'screen': 'activity_outside_property_roof_repair_parapet_wall', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_parapetrepair_soon', ['{E_RC_PARAPET_WALL_REPAIR}'], '{REPAIR_SOON}',
             'Repair parapet: The {RC_PARAPET_WALL_REPAIR_SUBJECT} of the parapet(s) of the roof are '
             '{RC_PARAPET_WALL_REPAIR_ISSUE}. This should be repaired soon.' + PR_TAIL,
             pdf=[PDF_PR, 'This should be repaired soon, repaired now.'],
             when=['actv_condition', 'Repair soon'], extra=[SN_DD], tokens=pr_tokens()),
        rule('e2_parapetrepair_now', ['{E_RC_PARAPET_WALL_REPAIR}'], '{REPAIR_NOW}',
             'Repair parapet: The {RC_PARAPET_WALL_REPAIR_SUBJECT} of the parapet(s) of the roof are '
             '{RC_PARAPET_WALL_REPAIR_ISSUE}. This should be repaired now.' + PR_TAIL,
             when=['actv_condition', 'Repair now'], tokens=pr_tokens()),
        rule('e2_parapetrepair_hazard', ['{E_RC_PARAPET_WALL_REPAIR}'], '{REPAIR_NOW_SAFETY_HAZARD}',
             'Safety hazard: This is a safety hazard, and parts of the parapet wall may fall to the ground '
             'and cause injury to people or property damage (see section J3 - Risk to People).',
             when=['cb_safety_hazard', 'true'],
             extra=[{'id': 'cb_safety_hazard', 'label': 'Safety hazard', 'type': 'checkbox'}]),
    ]})

# ───────────── Repairs: verge ─────────────
VG_ITEMS = [('rc_vr_mortar', 'mortar'), ('rc_vr_tiles', 'tiles'), ('rc_vr_slates', 'slates'),
            ('rc_vr_clips', 'clips'), ('rc_vr_caps', 'caps')]
VG_ISS = [('rc_vr_damaged', 'damaged'), ('rc_vr_cracked', 'cracked'), ('rc_vr_loose', 'loose')]
slices.append({
    'screen': 'activity_outside_property_roof_repair_verge', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_verge', ['{E_RC_VERGE_REPAIR}'], '{REPAIR_SOON}',
             'Repair verge: The {RC_VERGE_REPAIR_ITEM} items along the edge of the roof, called the verge, '
             'are {RC_VERGE_REPAIR_ISSUE}. This should be repaired soon and, if significant, repaired '
             'promptly. Adjacent parts of the roof covering may have to be disturbed to repair the verge, '
             'and this can increase the amount of repair work. This should be repaired soon.',
             pdf='Repair verge: The mortar, tiles, slates, clips, caps, other items along the edge of the '
                 'roof, called the verge, are damaged, cracked, loose, other.',
             tokens=[checks('{RC_VERGE_REPAIR_ITEM}', 'Verge parts', VG_ITEMS,
                            other=('rc_vr_item_other', 'rc_vr_item_other_text')),
                     checks('{RC_VERGE_REPAIR_ISSUE}', 'Defects', VG_ISS,
                            other=('rc_vr_iss_other', 'rc_vr_iss_other_text'))]),
    ]})

# ───────────── Repairs: valley gutters ─────────────
VGU_LOC = [('rc_vg_all', 'all'), ('rc_vg_front', 'front'), ('rc_vg_side', 'side'), ('rc_vg_rear', 'rear')]
VGU_ISS = [('rc_vgi_blocked', 'blocked'), ('rc_vgi_loose_mortar', 'has loose mortar'),
           ('rc_vgi_misaligned', 'poorly aligned')]
PDF_VGU = ('Repair valley gutters: The valley gutter at the junction of the roofs to all, front, side, rear, '
           'of the building is blocked, has loose mortar, poorly aligned.')
VGU_TAIL = (' Adjacent parts of the roof covering may have to be disturbed to repair the gutter, and this '
            'can increase the amount of repair work. This should be repaired soon.')


def vgu_tokens():
    return [checks('{RC_VALLEY_GUTTERS_REPAIR_LOCATION}', 'Location', VGU_LOC),
            checks('{RC_VALLEY_GUTTERS_REPAIR_ISSUE}', 'Defects', VGU_ISS)]


slices.append({
    'screen': 'activity_outside_property_roof_repair_valley_gutters', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e2_vgrepair_soon', [RCR], '{E_RC_VALLEY_GUTTERS_REPAIR}',
             'Repair valley gutters: The valley gutter at the junction of the roofs to '
             '{RC_VALLEY_GUTTERS_REPAIR_LOCATION} of the building is {RC_VALLEY_GUTTERS_REPAIR_ISSUE}. '
             'This should be repaired soon.' + VGU_TAIL,
             pdf=[PDF_VGU, 'This should be repaired soon, now.'],
             when=['actv_condition', 'Repair soon'], extra=[SN_DD], tokens=vgu_tokens()),
        rule('e2_vgrepair_now', [RCR], '{E_RC_VALLEY_GUTTERS_REPAIR_NOW}',
             'Repair valley gutters: The valley gutter at the junction of the roofs to '
             '{RC_VALLEY_GUTTERS_REPAIR_LOCATION} of the building is {RC_VALLEY_GUTTERS_REPAIR_ISSUE}. '
             'This should be repaired now.' + VGU_TAIL,
             when=['actv_condition', 'Repair now'], tokens=vgu_tokens()),
    ]})

# ───────────── Repairs: flashing / ridge / hip (new screens) ─────────────
FL_TAIL = (' The roof covering may have to be disturbed to repair the flashing, and this can increase the '
           'amount of the work. The owner of the neighbouring property may have some legal rights over the '
           'shared chimney. You should check with your legal adviser before any work is done.')


def repair_screen(sid, title, order, master, lead, rid, pdf_lead):
    return {
        'screen': sid,
        'new_screen': {'id': sid, 'title': title, 'parent': 'group_repairs_12', 'order': order,
                       'after': 'activity_outside_property_roof_repair_valley_gutters'},
        'rules': [
            rule(f'{rid}_soon', [master], '{REPAIR_SOON}', lead + ' This should be repaired soon.' + FL_TAIL,
                 pdf=[pdf_lead, 'This should be repaired soon, repaired now.'],
                 when=['actv_condition', 'Repair soon'], extra=[SN_DD]),
            rule(f'{rid}_now', [master], '{REPAIR_NOW}', lead + ' This should be repaired now.' + FL_TAIL,
                 when=['actv_condition', 'Repair now']),
        ]}


slices.append(repair_screen(
    'activity_outside_property_roof_repair_flashing', 'Flashing Repair', 8, '{E_RC_FLASHING_REPAIR}',
    'Repair flashing: The waterproofing at the junction of the roof covering and wall is damaged or defective.',
    'e2_flrepair',
    'Repair flashing: The waterproofing at the junction of the roof covering and wall is damaged or defective.'))
slices[-1]['rules'].append(rule(
    'e2_flrepair_damp', ['{E_RC_FLASHING_REPAIR}'], '{CAUSING_DAMP}',
    'Causing damp: This is causing damp penetration to the adjoining building elements, and you must '
    'arrange to repair this urgently. Further defects and damage may be revealed from an intrusive or '
    'closer inspection by a qualified person.',
    when=['cb_causing_damp', 'true'],
    extra=[{'id': 'cb_causing_damp', 'label': 'Causing damp', 'type': 'checkbox'}]))
slices.append(repair_screen(
    'activity_outside_property_roof_repair_ridge_tiles', 'Ridge Tiles Repair', 9, '{E_RC_RIDGE_TILES_REPAIR}',
    'Repair ridge tiles: The covering along the top of the roof structure called, the ridge tiles, is damaged '
    'or defective.',
    'e2_ridgerepair',
    'Repair ridge tiles: The covering along the top of the roof structure called, the ridge tiles, is damaged '
    'or defective.'))
slices.append(repair_screen(
    'activity_outside_property_roof_repair_hip_tiles', 'Hip Tiles Repair', 10, '{E_RC_HIP_TILES_REPAIR}',
    'Repair hip tile: The covering along the slope of the roof structure (called the hip tiles) is damaged or '
    'defective.',
    'e2_hiprepair',
    'Repair hip tile: The covering along the slope of the roof structure (called the hip tiles) is damaged or '
    'defective.'))
# each new screen is placed right after the previous one
slices[-2]['new_screen']['after'] = 'activity_outside_property_roof_repair_flashing'
slices[-1]['new_screen']['after'] = 'activity_outside_property_roof_repair_ridge_tiles'

# ───────────── General maintenance (summary screen) ─────────────
slices.append({
    'screen': 'activity_outside_property_roof_covering_summary',
    'rules': [
        rule('e2_general_maintenance', [RC], '{GENERAL_MAINTENANCE}',
             'General maintenance: Roof coverings should be inspected periodically, particularly following '
             'severe weather. Routine maintenance, including replacement of isolated defective coverings, '
             'clearance of debris and localised repairs, should be expected throughout the life of the roof.',
             when=['cb_general_maintenance', 'true'],
             extra=[{'id': 'cb_general_maintenance', 'label': 'General maintenance', 'type': 'checkbox'}]),
    ]})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s['rules']) for s in slices), 'rules')
