# -*- coding: utf-8 -*-
"""Generate slices/g1_e.json (G1 Electricity) + the G Services intro and G1 static text. Text is cut from the PDF."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import (P, add_or_set, block, checks, dd, lst, opts, para_rule, set_keys)  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'g1_e.json')
S = 'G1'
MW = '{G_ELECTRICITY}'
I_ = 'activity_service_about_electricity'
GROUP = 'group_electricity_86'


def pr(rid, sub, start, end, **kw):
    return para_rule(S, rid, [MW], f'{{G1_{sub}}}', start, end, **kw)


def ck(token, label, pdf_list, prefix, other=None, cond=None):
    return checks(token, label, opts(prefix, lst(pdf_list)), other=other, cond=cond)


def cb(fid, label):
    return {'id': fid, 'label': label, 'type': 'checkbox'}


# ── static texts ──
b9 = block('F9')
g_intro = b9[b9.index('Services are concealed within the structure'):].strip()
eicr, _ = P(S, 'Electrical installations should be inspected and assessed', 'General Maintenance:')
set_keys([add_or_set('{G_LIMITATIONS_STANDARD_TEXT}', g_intro),
          add_or_set('{G_ELECTRICITY}::{STANDARD_TEXT_2}', eicr)])

slices = []
ML = 'under the stairs, in an outside box, in the entrance hall, in the kitchen, in the garage, in a communal cupboard, other'
CL = 'under the stairs, in the entrance hall, in the kitchen, in the garage, in a communal cupboard, other'
RCD_LABELS = ['RCD protection', 'RCBO protection', 'surge protection', 'no visible RCD protection']
slices.append({'screen': I_, 'replace_all': True, 'keep': [], 'rules': [
    pr('g1_meter', 'METER', 'Metre: There is a mains electricity supply', 'Metre not found:', subs={ML: '{ELE_METER_LOCATION}'},
       tokens=[ck('{ELE_METER_LOCATION}', 'Meter located', ML, 'g1m_', other=('cb_other_387', 'et_other_564'))]),
    pr('g1_meter_nf', 'METER_NOT_FOUND', 'Metre not found:', 'Consumer unit:', when=['cb_electricity_not_inspected', 'true'],
       extra=[cb('cb_electricity_not_inspected', 'Meter not found')]),
    pr('g1_cu', 'CONSUMER_UNIT', 'Consumer unit: There is a consumer unit(s)', 'Not found:', subs={CL: '{ELE_CU_LOCATION}'},
       tokens=[ck('{ELE_CU_LOCATION}', 'Consumer unit installed', CL, 'g1c_', other=('cb_other_717', 'et_other_618'))]),
    pr('g1_cu_nf', 'CONSUMER_UNIT_NOT_FOUND', 'Not found: I did not find the consumer', 'RCD Protection:',
       when=['cb_fuse_not_inspected', 'true'], extra=[cb('cb_fuse_not_inspected', 'Consumer unit not found')]),
    pr('g1_rcd', 'RCD_PROTECTION', 'RCD Protection:', 'Dated or Old:',
       subs={'RCD protection, RCBO protection, surge protection; no visible RCD protection': '{ELE_RCD}'},
       tokens=[checks('{ELE_RCD}', 'The consumer unit incorporates', opts('g1r_', RCD_LABELS))]),
    pr('g1_dated', 'DATED_OR_OLD', 'Dated or Old:', 'Poor Standards:', when=['cb_dated_electrical_system', 'true'],
       extra=[cb('cb_dated_electrical_system', 'Dated or old installation')]),
    pr('g1_general', 'GENERAL_MAINTENANCE', 'General Maintenance:', 'Condition rating', when=['cb_general_maintenance', 'true'],
       extra=[cb('cb_general_maintenance', 'General maintenance')]),
]})
PS = 'exposed wires, damaged fittings, cracked fixtures, DIY work, other'
slices.append({'screen': 'activity_services_electricity_repair_electrical_hazard', 'replace_all': True, 'keep': [], 'rules': [
    pr('g1_poor', 'POOR_STANDARDS', 'Poor Standards:', 'Risk to people:', subs={PS: '{ELE_POOR_STANDARDS}'},
       tokens=[ck('{ELE_POOR_STANDARDS}', 'Electrical system is below current standards because', PS, 'g1p_',
                  other=('cb_other_685', 'et_other_733'))])]})
BT = 'loft, under the stairs, other'
slices.append({'screen': 'activity_services_solar_power', 'replace_all': True, 'keep': [], 'rules': [
    pr('g1_pv', 'SOLAR_PV', 'Solar photovoltaic (PV) system:', 'Battery storage/Inverter:', when=['cb_solar_pv', 'true'],
       extra=[cb('cb_solar_pv', 'Solar photovoltaic (PV) system')]),
    pr('g1_battery', 'SOLAR_BATTERY', 'Battery storage/Inverter:', 'Solar thermal (hot water):', subs={BT: '{ELE_BATTERY_LOCATION}'},
       tokens=[ck('{ELE_BATTERY_LOCATION}', 'Battery/inverter in', BT, 'g1b_', other=('cb_other_870', 'et_other_723'))]),
]})
slices.append({'screen': 'activity_services_water_heating_solar_power', 'replace_all': True, 'keep': [], 'rules': [
    pr('g1_thermal', 'SOLAR_THERMAL', 'Solar thermal (hot water):', 'Electrical installations should be inspected',
       when=['cb_solar_power', 'true'], extra=[cb('cb_solar_power', 'Solar thermal (hot water)')])]})
slices.append({'remove_screens': ['activity_services_electricity_repair_loose_panels', 'activity_services_electricity_not_inspected']})

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(slices), 'slices,', sum(len(s.get('rules', [])) for s in slices), 'rules')
