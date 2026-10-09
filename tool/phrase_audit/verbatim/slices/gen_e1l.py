# -*- coding: utf-8 -*-
"""Generate slices/e1l_e.json (E1 Chimney stacks leftovers: number, location, condition, shared, leaning, removed,
not inspected / not applicable / dummy, and every repair screen). Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import checks, dd, lst, opts, para_rule, slug  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e1l_e.json')
S, MW = 'E1', '{E_CHIMNEY}'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], '{E1L_%s}' % sub, start, end, **kw)


def cb(fid, label, cond=None):
    return field(fid, label, 'checkbox', cond=cond)


def oth(p):
    return (p + 'other', p + 'other_text')


def anyof(prefix, pdf_list):
    """when / when_any over every option id of a PDF list (items starting with 'other' use prefix+'other')."""
    ids = [prefix + slug(x) for x in lst(pdf_list)]
    if any(x.strip().startswith('other') for x in pdf_list.split(', ')):
        ids.append(prefix + 'other')
    return dict(when=[ids[0], 'true'], when_any=[[i, 'true'] for i in ids[1:]])


def clist(token, label, pdf_list, prefix):
    has_other = any(x.strip().startswith('other') for x in pdf_list.split(', '))
    return checks(token, label, opts(prefix, lst(pdf_list)), other=oth(prefix) if has_other else None)


def urgency_dd(token, fid):
    return dd(token, fid, 'Condition', ['Repaired soon', 'Repaired now'], lower=True)


URG = 'repaired soon, repaired now'
LOC = 'front, rear, side, centre, other locations'
LOC4 = 'front, rear, side, centre'
DEF_AERIAL = 'loose, rusted, damaged, dangling, other'
COND = 'good, reasonable, fair, poor, very poor'
NOW = 'Repaired now'
slices = [{'remove_screens': ['activity_outside_property_rendering', 'activity_outside_property_chimney_removed_chimney_stack']}]

slices.append({'screen': 'activity_outside_property_stacks',
               'remove_fields': ['android_material_design_spinner3', 'EtMultipleNumber', 'android_material_design_spinner4',
                                 'android_material_design_spinner5'],
               'rules': [pr('e1l_number', 'NUMBER', 'Number:', 'Location:', subs={'one, two, three, multiple': '{CS_NUMBER}'},
                            when=['actv_stack_number', 'One'],
                            when_any=[['actv_stack_number', x] for x in ('Two', 'Three', 'Multiple')],
                            tokens=[dd('{CS_NUMBER}', 'actv_stack_number', 'Number of stacks',
                                       ['One', 'Two', 'Three', 'Multiple'], lower=True)])]})

slices.append({'screen': 'activity_outside_property_location', 'replace_all': True, 'keep': [], 'rules': [
    pr('e1l_location', 'LOCATION', 'Location: The chimney stack(s) are located', 'Pots:', subs={LOC: '{CS_LOCATIONS}'},
       tokens=[clist('{CS_LOCATIONS}', 'Located to the', LOC, 'e1l_loc_')], when=['cb_e1l_location', 'true'],
       extra=[cb('cb_e1l_location', 'Location')])]})

slices.append({'screen': 'activity_outside_property_condition', 'replace_all': True, 'keep': [], 'rules': [
    pr('e1l_condition', 'STACK_CONDITION', 'Condition: Where visible, the chimney stack(s)', 'No repair:',
       subs={COND: '{CS_STACK_CONDITION}'}, when=['android_material_design_spinner3', 'Good'],
       when_any=[['android_material_design_spinner3', x] for x in ('Reasonable', 'Fair', 'Poor', 'Very poor')],
       tokens=[dd('{CS_STACK_CONDITION}', 'android_material_design_spinner3', 'Condition',
                  ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'], lower=True)]),
    pr('e1l_norepair', 'NO_REPAIR', 'No repair:', 'Flashings:', when=['cb_e1l_norepair', 'true'],
       extra=[cb('cb_e1l_norepair', 'No repair needed')])]})

slices.append({'screen': 'activity_outside_property_shared_chimney', 'replace_all': True, 'keep': [], 'rules': [
    pr('e1l_shared', 'SHARED', 'Shared chimney:', 'Not fully inspected:', when=['cb_e1l_shared', 'true'],
       extra=[cb('cb_e1l_shared', 'Shared chimney')])]})

slices.append({'screen': 'activity_outside_property_leaning_chimney',
               'remove_fields': ['label_location_2', 'ch1', 'ch2', 'ch3', 'ch4', 'cb_other_608', 'et_other_752',
                                 'label_condition_4'],
               'rules': [
                   pr('e1l_lean_ok', 'LEAN_NO_REPAIR', 'No repair required:', 'Repair required:', after='Leaning chimney:',
                      when=['android_material_design_spinner4', 'No repair required'],
                      extra=[{'id': 'android_material_design_spinner4', 'label': 'Condition', 'type': 'dropdown',
                              'options': ['No repair required', 'Repair required']}]),
                   pr('e1l_lean_repair', 'LEAN_REPAIR', 'Repair required:', 'Add text to:', after='Leaning chimney:',
                      when=['android_material_design_spinner4', 'Repair required'])]})

slices.append({'screen': 'activity_outside_property_chimney_removed_pots', 'replace_all': True, 'keep': [], 'rules': [
    pr('e1l_removed', 'REMOVED', 'Removed chimney or pots:', 'Poor chimney condition:',
       subs={LOC4: '{CS_REMOVED_LOCATIONS}', 'removed, altered, covered over with roofing': '{CS_REMOVED_WHAT}'},
       when=['cb_Removed_pots', 'true'], extra=[cb('cb_Removed_pots', 'Removed chimney or pots')],
       tokens=[clist('{CS_REMOVED_LOCATIONS}', 'Location', LOC4, 'e1l_rm_'),
               clist('{CS_REMOVED_WHAT}', 'Work carried out', 'removed, altered, covered over with roofing', 'e1l_rw_')])]})

slices.append({'screen': 'activity_outside_property_chimney_not_inspected', 'replace_all': True, 'keep': [], 'rules': [
    pr('e1l_na', 'NOT_APPLICABLE', 'Not Applicable:', 'Not Inspected:', when=['cb_Not_applicable', 'true'],
       extra=[cb('cb_Not_applicable', 'Not applicable')]),
    pr('e1l_ni', 'NOT_INSPECTED', 'Not Inspected:', 'Shared chimney:', when=['cb_not_inspected_access', 'true'],
       extra=[cb('cb_not_inspected_access', 'Not inspected (access restricted)')]),
    pr('e1l_dummy', 'DUMMY_BREAST', 'Dummy chimney breast:', 'Description:', when=['cb_dummy_chimney_breast', 'true'],
       extra=[cb('cb_dummy_chimney_breast', 'Dummy chimney breast')])]})


def repair(screen, fid, rid, sub, start, end, damp=None, damp_id='cb_is_causing_dump'):
    fields = [{'id': fid, 'label': 'Condition', 'type': 'dropdown', 'options': ['Repaired soon', 'Repaired now']}]
    rules = [pr(rid, sub, start, end, subs={URG: '{CS_URGENCY_%s}' % rid.upper()},
                when=[fid, 'Repaired soon'], when_any=[[fid, NOW]],
                tokens=[urgency_dd('{CS_URGENCY_%s}' % rid.upper(), fid)])]
    if damp:
        rules.append(pr(rid + '_damp', sub + '_DAMP', 'Causing damp:', damp, after=start,
                        when=[damp_id, 'true'], extra=[cb(damp_id, 'Is causing damp', cond=(fid, NOW))]))
    return {'screen': screen, 'replace_all': True, 'keep': [], 'rules': rules}


slices.append(repair('activity_outside_property_repair_flashing', 'android_material_design_spinner4', 'e1l_rflash',
                     'REPAIR_FLASHING', 'Repair flashing:', 'Causing damp:', damp='Flaunching:'))
slices.append(repair('activity_outside_property_chimney_repair_flaunching', 'actv_condition', 'e1l_rflaunch',
                     'REPAIR_FLAUNCHING', 'Repair flaunching:', 'Causing damp:', damp='Pointing Condition:'))
slices.append(repair('activity_outside_property_repair_chimney_repointing', 'actv_condition', 'e1l_rpoint',
                     'REPOINTING', 'Repointing:', 'Damaged chimney pots:'))
# repointing keeps the damp tick-box for the J1 cross-injection (report_builder), no E1 sentence of its own
slices[-1]['rules'][0]['extra_fields'] = [cb('cb_is_causing_dump', 'Is causing damp', cond=('actv_condition', NOW))]

slices.append({'screen': 'activity_outside_property_repair_chimney_pots', 'replace_all': True, 'keep': [], 'rules': [
    pr('e1l_rpot', 'REPAIR_POT', 'Repair pot:', 'Leaning chimney:', after='Damaged chimney pots:',
       when=['actv_condition', 'Repair soon'], when_any=[['actv_condition', 'Repair now']],
       extra=[{'id': 'actv_condition', 'label': 'Condition', 'type': 'dropdown', 'options': ['Repair soon', 'Repair now']},
              field('cb_is_safety_hazard', 'Is safety hazard', 'checkbox', cond=('actv_condition', 'Repair now'))])]})

slices.append({'screen': 'activity_outside_property_repair_chimney_disrepair', 'replace_all': True, 'keep': [], 'rules': [
    pr('e1l_poor', 'POOR_CHIMNEY', 'Poor chimney condition:', 'Add text to:', subs={LOC4: '{CS_POOR_LOCATIONS}'},
       when=['cb_repair_soon_70', 'true'], extra=[cb('cb_repair_soon_70', 'Poor chimney condition')],
       tokens=[clist('{CS_POOR_LOCATIONS}', 'Chimney stack(s) on the', LOC4, 'e1l_pc_')])]})


def aerial(screen, pre):
    d = pre + 'd_'
    return {'screen': screen, 'replace_all': True, 'keep': [], 'rules': [
        pr(pre + 'def', 'REPAIR_AERIAL_' + pre.upper().strip('_'), 'Repair aerials and satellite dishes:', 'Repair soon:',
           subs={DEF_AERIAL: '{CS_AERIAL_DEFECTS}'}, tokens=[clist('{CS_AERIAL_DEFECTS}', 'Defect', DEF_AERIAL, d)],
           when=['cb_' + pre + 'def', 'true'],
           extra=[cb('cb_' + pre + 'def', 'Aerial / satellite dish defect'),
                  {'id': 'actv_condition', 'label': 'Condition', 'type': 'dropdown',
                   'options': ['Repair soon', 'Repair now']}]),
        pr(pre + 'soon', 'AERIAL_SOON', 'Repair soon:', 'Repair now:', after='Repair aerials and satellite dishes:',
           when=['actv_condition', 'Repair soon']),
        pr(pre + 'now', 'AERIAL_NOW', 'Repair now:', 'General notes:', after='Repair aerials and satellite dishes:',
           when=['actv_condition', 'Repair now'],
           extra=[field('cb_is_safety_hazard', 'Is safety hazard', 'checkbox', cond=('actv_condition', 'Repair now'))]),
    ]}


slices.append(aerial('activity_outside_property_repair_chimney_dish_aerial', 'e1l_ae_'))
slices.append(aerial('activity_outside_property_repair_chimney_dish_aerial__satellite', 'e1l_sa_'))

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
