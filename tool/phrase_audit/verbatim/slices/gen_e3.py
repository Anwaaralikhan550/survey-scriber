# -*- coding: utf-8 -*-
"""Generate slices/e3_e.json (E3 Rainwater goods) for slice.py."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import checks, dd, rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e3_e.json')
RW = '{E_RAINWATER_GOODS_ABOUT}'
G = 'group_e3_rain_water_goods_13'
COND5 = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']
SN = ['Repair soon', 'Repair now']
SN_DD = {'id': 'actv_condition', 'label': 'Condition', 'type': 'dropdown', 'options': SN}
NOREP = ('No repair required: No significant defects requiring immediate attention were identified '
         'unless otherwise stated below.')

slices = []

TYPES = [('rwg_pvc', 'PVC'), ('cb_cast_iron', 'cast iron'), ('rwg_aluminium', 'aluminium'),
         ('rwg_steel', 'steel'), ('cb_concrete', 'concrete'), ('cb_asbestos_cement', 'asbestos cement')]
slices.append({
    'screen': 'activity_outside_property_rwg_about', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e3_desc', [RW], '{RWG_ABOUT_TYPE}',
             'Description: The rainwater goods comprise {RWG_TYPE} gutters, downpipes, hoppers, and '
             'associated fittings.',
             pdf='Description: The rainwater goods comprise PVC, cast iron, aluminium, steel, concrete, '
                 'asbestos cement, other, gutters, downpipes, hoppers, and associated fittings.',
             tokens=[checks('{RWG_TYPE}', 'Type', TYPES, other=('cb_other_697', 'et_other_427'))]),
        rule('e3_cond', [RW], '{RWG_ABOUT_CONDITION}',
             'Condition: Where visible, the rainwater goods appear in {RWG_CONDITION} condition, consistent '
             'with their age and type. No parts of the rainwater installation were dismantled or tested. The '
             'adequacy of underground drainage has not been assessed as part of this inspection. ' + NOREP +
             ' The rainwater goods appear to be adequately performing their function. Routine maintenance '
             'appropriate to the age and type of the rainwater goods should be expected.',
             pdf='Condition: Where visible, the rainwater goods appear in good, reasonable, fair, poor, very '
                 'poor condition, consistent with their age and type.',
             tokens=[dd('{RWG_CONDITION}', 'actv_condition', 'Condition', COND5, lower=True)]),
        rule('e3_asbestos', [RW], '{RWG_IF_TYPE_ASBESTOS_CEMENT}',
             'The rainwater goods contain asbestos cement. Because of the possible asbestos content, you '
             'should get advice from a contractor experienced in this type of work or an asbestos specialist '
             'before the pipes or gutters are disturbed in any way. This includes activities such as '
             'cleaning out gutters, etc.',
             when=['cb_asbestos_cement', 'true']),
        rule('e3_shared', [RW], '{RAINWATER_GOODS_SHARED}',
             'Shared Rainwater Goods: The rainwater goods are believed to be shared with the adjoining '
             'property. Your legal adviser should confirm ownership, maintenance responsibilities and any '
             'rights or obligations affecting the shared installation (See Section I3).',
             when=['cb_Shared', 'true'],
             extra=[{'id': 'cb_Shared', 'label': 'Shared', 'type': 'checkbox'}]),
        rule('e3_general', [RW], '{RWG_STANDARD_TEXT}',
             'General Maintenance: Rainwater goods should be inspected and cleared at regular intervals, '
             'particularly during the autumn and following severe weather. Routine maintenance will assist '
             'in preventing blockages, overflow, water penetration, and premature deterioration.',
             when=['actv_condition', 'Good'],
             when_any=[['actv_condition', v] for v in COND5[1:]]),
    ]})

# ── Damaged sections (existing repairs screen) ──
DAM = [('rwg_dm_cracked', 'cracked'), ('rwg_dm_distorted', 'distorted'), ('rwg_dm_broken', 'broken'),
       ('rwg_dm_split', 'split'), ('rwg_dm_missing', 'missing')]


def dam_tokens():
    return [checks('{RWG_REPAIR_DEFECT}', 'Defects', DAM, other=('rwg_dm_other', 'rwg_dm_other_text'))]


slices.append({
    'screen': 'activity_outside_property_rwg__repair_pipes_gutters', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e3_damaged_soon', [RW], '{RWG_REPAIR_SOON}',
             'Damaged Sections: Sections of the gutters or downpipes are {RWG_REPAIR_DEFECT}. This should be '
             'repaired soon. Repairs or replacement should be undertaken to maintain the weather resistance '
             'of the building.',
             pdf=['Damaged Sections: Sections of the gutters or downpipes are cracked, distorted, broken, '
                  'split, missing, other.', 'This should be repaired soon, repaired now.'],
             when=['actv_condition', 'Repair soon'], extra=[SN_DD], tokens=dam_tokens()),
        rule('e3_damaged_now', [RW], '{RWG_REPAIR_NOW}',
             'Damaged Sections: Sections of the gutters or downpipes are {RWG_REPAIR_DEFECT}. This should be '
             'repaired now. Repairs or replacement should be undertaken to maintain the weather resistance '
             'of the building.',
             when=['actv_condition', 'Repair now'], tokens=dam_tokens()),
    ]})

# ── New repair screens ──
def new_screen(sid, title, order, after):
    return {'id': sid, 'title': title, 'parent': G, 'order': order, 'after': after}


S_SLOPE = 'activity_outside_property_rwg_insufficient_slope'
slices.append({
    'screen': S_SLOPE,
    'new_screen': new_screen(S_SLOPE, 'Insufficient slope', 5, 'activity_outside_property_rwg__repair_pipes_gutters'),
    'rules': [
        rule('e3_slope', [RW], '{RWG_IF_TYPE_IF_INSUFFICIENT_SLOPE}',
             'Insufficient slope: The slope on the guttering is too shallow. This prevents the rainwater from '
             'draining properly and may result in future leaks. The gutters should be refitted with an '
             'adequate slope soon. You may have to replace parts of the system, and this can increase the '
             'amount of repair work.',
             when=['cb_insufficient_slope', 'true'],
             extra=[{'id': 'cb_insufficient_slope', 'label': 'Insufficient slope', 'type': 'checkbox'}]),
    ]})
S_LEAK = 'activity_outside_property_rwg_leakage'
slices.append({
    'screen': S_LEAK,
    'new_screen': new_screen(S_LEAK, 'Leakage', 6, S_SLOPE),
    'rules': [
        rule('e3_leakage', [RW], '{RWG_LEAKAGE}',
             'Leakage: Staining to fittings and adjoining elements and localised dampness indicate previous '
             'or current leakage from the rainwater goods. The affected sections should be checked for '
             'watertightness and repaired soon or repaired now, depending on the severity of the defect. '
             'Repairs should be undertaken to prevent further deterioration of adjacent building elements.',
             when=['cb_leakage', 'true'],
             extra=[{'id': 'cb_leakage', 'label': 'Leakage', 'type': 'checkbox'}]),
    ]})
S_CONN = 'activity_outside_property_rwg_defective_connections'
CON = [('rwg_cn_loose', 'loose'), ('rwg_cn_missing', 'missing'), ('rwg_cn_leaking', 'leaking'),
       ('rwg_cn_displaced', 'displaced'), ('rwg_cn_defective', 'defective')]


def con_tokens():
    return [checks('{RWG_CONNECTION_DEFECT}', 'Defects', CON, other=('rwg_cn_other', 'rwg_cn_other_text'))]


slices.append({
    'screen': S_CONN,
    'new_screen': new_screen(S_CONN, 'Defective connections', 8, S_LEAK),
    'rules': [
        rule('e3_conn_soon', [RW], '{RWG_CONNECTIONS_SOON}',
             'Defective Connections: One or more gutter or downpipe joints and connections are '
             '{RWG_CONNECTION_DEFECT}. This should be repaired soon. Repairs should be undertaken to maintain '
             'the effectiveness of the rainwater system.',
             pdf=['Defective Connections: One or more gutter or downpipe joints and connections are loose, '
                  'missing, leaking, displaced, defective, other.', 'This should be repaired soon, now.'],
             when=['actv_condition', 'Repair soon'], extra=[SN_DD], tokens=con_tokens()),
        rule('e3_conn_now', [RW], '{RWG_CONNECTIONS_NOW}',
             'Defective Connections: One or more gutter or downpipe joints and connections are '
             '{RWG_CONNECTION_DEFECT}. This should be repaired now. Repairs should be undertaken to maintain '
             'the effectiveness of the rainwater system.',
             when=['actv_condition', 'Repair now'], tokens=con_tokens()),
    ]})
S_CORR = 'activity_outside_property_rwg_corrosion'
slices.append({
    'screen': S_CORR,
    'new_screen': new_screen(S_CORR, 'Corrosion', 10, S_CONN),
    'rules': [
        rule('e3_corrosion', [RW], '{RWG_CORROSION}',
             'Corrosion: Sections of the rainwater goods exhibit {RWG_CORROSION_LEVEL} corrosion. Corroded '
             'sections should be repaired or replaced where necessary to maintain satisfactory performance. '
             'This should be repaired promptly if the damage is significant.',
             pdf='Corrosion: Sections of the rainwater goods exhibit light, moderate, significant corrosion.',
             tokens=[dd('{RWG_CORROSION_LEVEL}', 'actv_corrosion', 'Corrosion',
                        ['Light', 'Moderate', 'Significant'], lower=True)]),
    ]})

# ── Blocked gullies: partially / fully ──
slices.append({
    'screen': 'activity_outside_property_rwg_blocked_gullies', 'replace_all': True, 'keep': [],
    'rules': [
        rule('e3_gullies', [RW], '{RWG_BLOCKED_GULLIES}',
             'Blocked Gullies: One or more drainage gullies serving the rainwater system appear '
             '{RWG_GULLY_STATE}. Blocked gullies may result in localised flooding and water penetration to '
             'adjacent building elements. The gullies should be cleared and maintained regularly.',
             pdf='Blocked Gullies: One or more drainage gullies serving the rainwater system appear '
                 'partially blocked, fully blocked.',
             tokens=[dd('{RWG_GULLY_STATE}', 'actv_gully_state', 'Blocked gullies',
                        ['Partially blocked', 'Fully blocked'], lower=True)]),
    ]})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s['rules']) for s in slices), 'rules')
