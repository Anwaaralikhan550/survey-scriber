# -*- coding: utf-8 -*-
"""Generate slices/h2_e.json (H2 Outbuildings & other grounds). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (checks, dd, lst, opts, para_rule)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'h2_e.json')
S = 'H2'
MW = '{H_OTHER}'


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


def oth(p):
    return (p + 'other', p + 'other_text')


def R(rid, sub, start, end, label, lists=(), after=None, trig=None, extra=()):
    """Paragraph rule triggered by a tick-box; each list = (pdf_list, token, field label[, explicit options, other]).
    Text is cut from the PDF block; pdf_list substrings become tokens."""
    subs, tokens = {}, []
    for n, L in enumerate(lists):
        pdf, tok, lab = L[0], L[1], L[2]
        explicit = L[3] if len(L) > 3 else None
        has_other = L[4] if len(L) > 4 else any(x.strip().startswith('other') for x in pdf.split(', '))
        pre = f'{rid}_{n}_'
        subs[pdf] = tok
        tokens.append(checks(tok, lab, explicit if explicit is not None else opts(pre, lst(pdf)),
                             other=oth(pre) if has_other else None))
    t = trig or ('cb_h2_' + rid)
    return para_rule(S, rid, [MW], '{H2_%s}' % sub, start, end, subs=subs or None, tokens=tokens, after=after,
                     when=[t, 'true'], extra=[cb(t, label)] + list(extra))


COND = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
CONDS = 'good, reasonable, fair, poor, very poor'


def C(rid, sub, start, end, field, label, after=None):
    """Condition paragraph driven by a single dropdown (good ... very poor)."""
    return para_rule(S, rid, [MW], '{H2_%s}' % sub, start, end, subs={CONDS: '{H2_%s_COND}' % sub}, after=after,
                     when=[field, COND[0]], when_any=[[field, c] for c in COND[1:]],
                     tokens=[dd('{H2_%s_COND}' % sub, field, label, COND, lower=True)])


def keep_ids(pdf, mapping, prefix):
    """Options for a PDF list; labels listed in `mapping` keep their old field id (J2 reads them)."""
    return [(mapping.get(l, prefix + l.replace(' ', '_')), l) for l in lst(pdf)]


TOPO = 'level, sloping, hilly, undulating'
TOPO_DD = {'id': 'actv_type', 'label': 'The property is set within', 'type': 'dropdown',
           'options': ['Level', 'Sloping', 'Hilly', 'Undulating']}
CG_SURF = 'paved, lawned, decked, artificially lawned, laid with stones, laid with tile chippings, other'
CG_FENCE = 'timber, brick, concrete, wire mesh, hedges, shrubs, other'
OUTSIDE = 'front garden, rear garden, side garden, courtyard garden, terrace, patio, other'
SURF = 'lawn, block paving, concrete, gravel, tarmac, timber decking, composite decking, stone paving, other finishes'
BOUND = 'timber fencing, brick walls, hedging, stone walls, concrete sections, wire, metal railings, other'
FENCE_DEF = 'cracked, broken, unstable, leaning, loose in places, severely damaged, rotten, missing in places, other'
FENCE_IDS = {'broken': 'cb_broken', 'unstable': 'cb_unstable', 'leaning': 'cb_leaning', 'loose in places': 'cb_loose_in_places',
             'severely damaged': 'cb_badly_damaged', 'rotten': 'cb_rotted_in_places', 'missing in places': 'cb_missing_in_places'}
SHED_MAT = 'timber, brick, aluminium, other'
SHED_ROOF = 'pitched, flat, other'
SHED_COV = 'felt, tiles, metal sheets, other'
HARD_A = 'level, reasonably level'
HARD_B = 'no unevenness, minor unevenness'
SHARED = 'shared driveway, shared garden, communal parking, communal gardens, shared pathways, other'
OB_TYPE = 'large shed, workshop, annex, summer house, office, studio, other'
OB_CONS = 'bricks, blocks, timber, steel, prefabricated concrete, aluminium, composite boards, other'
OB_RT = 'pitched, flat, lean-to, other'
OB_COV = 'clay tiles, concrete tiles, slates, felt, rubber membrane, metal sheets, other'
OB_FLOOR = 'concrete, suspended timber, engineered timber, beam and block, other'
OB_DW = 'timber uPVC, aluminium, metal, other'
ROB_TYPE = 'shed, workshop, annex, summer house, office, studio, other'
ROB_DEF = 'damaged, have broken parts, is unstable, is rotted in places, have missing sections, other'
RW = 'cracked, leaning, distorted, unstable, weak, damaged, in poor condition'
RW_IDS = {'cracked': 'cb_cracked', 'distorted': 'cb_distorted', 'unstable': 'cb_unstable', 'damaged': 'cb_damaged'}
TREE_AT = 'property, fencing, finished grounds, outbuilding, other'
TREE_DEF = 'significant cracks, subsidence movement'
TREE_IDS = {'significant cracks': 'cb_significant_cracks', 'subsidence movement': 'cb_subsidence_movement'}
TREE_DD = {'id': 'actv_condition', 'label': 'Nearby trees', 'type': 'dropdown', 'options': ['No defects', 'Defects noted']}

# J2 (Risk to Grounds) still reads these location tick-boxes; they are not report text.
RW_LOC = [cb('cb_front', 'Front'), cb('cb_side', 'Side'), cb('cb_rear', 'Rear')]
FENCE_LOC = [cb('cb_front', 'Front'), cb('cb_rear', 'Rear'), cb('cb_side', 'Side'), cb('cb_communal', 'Communal')]

slices = [
    {'screen': 'activity_grounds_other_grounds', 'replace_all': True, 'keep': [], 'rules': [
        para_rule(S, 'h2_topo', [MW], '{H2_GROUNDS_TOPOGRAPHY}', 'Grounds: The subject property', 'Shared Garden:',
                  subs={TOPO: '{H2_TOPOGRAPHY}'}, when=['actv_type', 'Level'],
                  when_any=[['actv_type', v] for v in ('Sloping', 'Hilly', 'Undulating')],
                  tokens=[dd('{H2_TOPOGRAPHY}', 'actv_type', 'The property is set within',
                             ['Level', 'Sloping', 'Hilly', 'Undulating'], lower=True)]),
    ]},
    {'screen': 'activity_grounds_shared_access', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_shared_garden', 'SHARED_GARDEN', 'Shared Garden:', 'Grounds: The communal', 'Shared garden'),
        R('h2_comm_surface', 'COMMUNAL_GROUNDS', 'Grounds: The communal/shared garden is', 'Fence: The boundary fences',
          'Communal garden surfaces', [(CG_SURF, '{H2_COMM_SURFACE}', 'Communal garden is')]),
        R('h2_comm_fence', 'COMMUNAL_FENCE', 'Fence: The boundary fences', 'No Fencing:', 'Communal garden fences',
          [(CG_FENCE, '{H2_COMM_FENCE}', 'Boundary fences formed in')]),
        R('h2_comm_no_fence', 'NO_FENCING', 'No Fencing:', 'Condition: Where visible, the garage appears', 'No fencing'),
        C('h2_comm_cond', 'COMMUNAL_CONDITION', 'Condition: Where visible, the garage appears', 'Description: The outside areas',
          'actv_h2_comm_cond', 'Communal garden condition', after='No Fencing:'),
        R('h2_shared_areas', 'SHARED_AREAS', 'Shared Areas:', 'Condition: Where visible, the shared areas', 'Shared areas',
          [(SHARED, '{H2_SHARED_AREAS}', 'Property benefits from a')]),
        C('h2_shared_cond', 'SHARED_AREAS_CONDITION', 'Condition: Where visible, the shared areas', 'Private road:',
          'actv_h2_shared_cond', 'Shared areas condition'),
    ]},
    {'screen': 'activity_grounds_other_front_garden', 'set_title': 'Gardens', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_outside', 'OUTSIDE_AREAS', 'Description: The outside areas', 'Grounds: The surfaces', 'Outside areas',
          [(OUTSIDE, '{H2_OUTSIDE_AREAS}', 'Outside areas comprise')]),
        R('h2_surfaces', 'SURFACES', 'Grounds: The surfaces comprise', 'Fence: The boundaries comprise', 'Garden surfaces',
          [(SURF, '{H2_SURFACES}', 'Surfaces comprise')]),
        R('h2_boundaries', 'BOUNDARIES', 'Fence: The boundaries comprise', 'Condition: Where visible, the garage appears',
          'Boundaries', [(BOUND, '{H2_BOUNDARIES}', 'Boundaries comprise')]),
        C('h2_garden_cond', 'GARDEN_CONDITION', 'Condition: Where visible, the garage appears', 'No defects noted:',
          'actv_h2_garden_cond', 'Garden condition', after='Fence: The boundaries comprise'),
        R('h2_garden_no_defects', 'GARDEN_NO_DEFECTS', 'No defects noted:', 'Repair fence:', 'Garden: no defects noted',
          after='Fence: The boundaries comprise'),
        R('h2_hardstanding', 'HARDSTANDING', 'Hardstanding areas:', 'Shared Areas:', 'Hardstanding areas',
          [(HARD_A, '{H2_HARD_LEVEL}', 'Paths and hardstanding appear', None, False),
           (HARD_B, '{H2_HARD_UNEVEN}', 'and exhibit', None, False)]),
    ]},
    {'screen': 'activity_grounds_other_repair_fence', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_repair_fence', 'REPAIR_FENCE', 'Repair fence:', 'Sheds:', 'Repair fence',
          [(FENCE_DEF, '{H2_FENCE_DEFECTS}', 'Boundary fencing is', keep_ids(FENCE_DEF, FENCE_IDS, 'h2fd_'), True)],
          extra=FENCE_LOC),
    ]},
    {'screen': 'activity_grounds_other_repair_shed', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_sheds', 'SHEDS', 'Sheds: There is', 'Condition: Where visible, the shed(s)', 'Sheds',
          [(SHED_MAT, '{H2_SHED_MATERIAL}', 'Shed(s) of'), (SHED_ROOF, '{H2_SHED_ROOF}', 'Roof(s) are'),
           (SHED_COV, '{H2_SHED_COVER}', 'Covered with')]),
        C('h2_shed_cond', 'SHED_CONDITION', 'Condition: Where visible, the shed(s)', 'Hardstanding areas:',
          'actv_h2_shed_cond', 'Shed condition'),
    ]},
    {'screen': 'activity_grounds_other_large_outbuildings', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_ob', 'OUTBUILDING', 'Outbuilding: The property incorporates', 'Construction: The structure', 'Outbuilding',
          [(OB_TYPE, '{H2_OB_TYPE}', 'Property incorporates a')]),
        R('h2_ob_cons', 'OB_CONSTRUCTION', 'Construction: The structure', 'Roof: The roof is of pitched, flat, lean-to',
          'Outbuilding construction', [(OB_CONS, '{H2_OB_CONSTRUCTION}', 'Structure formed of')]),
        R('h2_ob_roof', 'OB_ROOF', 'Roof: The roof is of pitched, flat, lean-to', 'Floor: The floor is constructed',
          'Outbuilding roof', [(OB_RT, '{H2_OB_ROOF}', 'Roof construction'), (OB_COV, '{H2_OB_COVER}', 'Roof covered with')]),
        R('h2_ob_floor', 'OB_FLOOR', 'Floor: The floor is constructed', 'Doors and windows:', 'Outbuilding floor',
          [(OB_FLOOR, '{H2_OB_FLOOR}', 'Floor constructed of')]),
        R('h2_ob_doors', 'OB_DOORS', 'Doors and windows:', 'Condition: Where visible, the building', 'Outbuilding doors and windows',
          [(OB_DW, '{H2_OB_DOORS}', 'Doors / windows formed of')]),
        C('h2_ob_cond', 'OB_CONDITION', 'Condition: Where visible, the building', 'No defects noted:',
          'actv_h2_ob_cond', 'Outbuilding condition'),
        R('h2_ob_no_defects', 'OB_NO_DEFECTS', 'No defects noted:', 'Repair outbuilding:', 'Outbuilding: no defects noted',
          after='Condition: Where visible, the building'),
    ]},
    {'screen': 'activity_other_repair_outbuilding', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_repair_ob', 'REPAIR_OUTBUILDING', 'Repair outbuilding:', 'Retaining Wall:', 'Repair outbuilding',
          [(ROB_TYPE, '{H2_ROB_TYPE}', 'Parts of the'), (ROB_DEF, '{H2_ROB_DEFECTS}', 'Defects')]),
    ]},
    {'screen': 'activity_other_repair_retaining_walls', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_rw', 'RETAINING_WALL', 'Retaining Wall:', 'Nearby Trees:', 'Retaining wall',
          [(RW, '{H2_RW_DEFECTS}', 'Retaining wall is', keep_ids(RW, RW_IDS, 'h2rw_'), False)], extra=RW_LOC),
    ]},
    {'screen': 'activity_other_repair_nearby_trees', 'replace_all': True, 'keep': [], 'rules': [
        para_rule(S, 'h2_trees', [MW], '{H2_NEARBY_TREES}', 'Nearby Trees:', 'No defects: No significant',
                  when=['actv_condition', 'No defects'], when_any=[['actv_condition', 'Defects noted']], extra=[TREE_DD]),
        para_rule(S, 'h2_trees_none', [MW], '{H2_TREES_NO_DEFECTS}', 'No defects: No significant', 'Defects noted: One or more trees',
                  when=['actv_condition', 'No defects']),
        para_rule(S, 'h2_trees_defects', [MW], '{H2_TREES_DEFECTS}', 'Defects noted: One or more trees', 'Subsoil:',
                  subs={TREE_AT: '{H2_TREE_AFFECTED}', TREE_DEF: '{H2_TREE_DEFECT}'}, when=['actv_condition', 'Defects noted'],
                  tokens=[checks('{H2_TREE_AFFECTED}', 'Detrimental effects on the', opts('h2ta_', lst(TREE_AT)),
                                 other=oth('h2ta_')),
                          checks('{H2_TREE_DEFECT}', 'Defects include', keep_ids(TREE_DEF, TREE_IDS, 'h2td_'))]),
    ]},
    {'screen': 'activity_other_repair_shrinkable_clay', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_subsoil', 'SUBSOIL', 'Subsoil:', 'Condition rating', 'Subsoil', trig='cb_shrinkable_clay'),
    ]},
    {'screen': 'activity_grounds_other_private_road', 'replace_all': True, 'keep': [], 'rules': [
        R('h2_private', 'PRIVATE_ROAD', 'Private road:', 'Outbuilding: The property incorporates', 'Private road',
          trig='cb_private_road'),
    ]},
    {'remove_screens': ['activity_grounds_other_front_garden__rear_garden', 'activity_grounds_other_front_garden__side_garden',
                        'activity_grounds_other_front_garden__other_garden', 'activity_grounds_other_front_garden__communal_garden',
                        'activity_other_repair_legal_issues', 'activity_grounds_other_not_inspected',
                        'activity_grounds_other_communal_garden', 'activity_grounds_other_other_garden',
                        'activity_grounds_other_rear_garden', 'activity_grounds_other_side_garden']},
]

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
