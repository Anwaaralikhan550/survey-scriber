# Tree edits for A2 (Oil/LPG), A3 (Electricity Dated), A5 (three roofs), A8 (rainwater), A9 (timber wet rot).
import sys, json
sys.path.insert(0, 'E:/survey-scriber/tmp/client-edits-2026-11-13')
from tree_edit import *
import tree_edit as T

def fields(nid): return T.get_fields(nid)
def drop(nid, ids):
    fs = [f for f in fields(nid) if f['id'] not in ids]
    set_fields(nid, fs)

# A8 rainwater: "and associated fittings" is fixed text, no tick.
drop('val_rainwater_goods', {'cb_rw_fittings'})

# A9 Significant Valuation Consideration, Timber Defects: Dry Rot and Wet Rot as two ticks.
fs = fields('val_sv_timber')
i = next(k for k, f in enumerate(fs) if f['id'] == 'cb_svt_rot')
fs.insert(i + 1, cb('cb_svt_wet', 'Extensive Wet Rot'))
set_fields('val_sv_timber', fs)

# A3 Electricity: one Dated tick beside the meter location.
fs = fields('val_electric_material')
i = next(k for k, f in enumerate(fs) if f['id'] == 'et_em_other_text')
fs.insert(i + 1, cb('cb_em_dated', 'Dated'))
set_fields('val_electric_material', fs)

# A5 three roofs. Pitched loses the three flat-roof materials (old answers still print), Flat gets them,
# Other Roof gets the client's whole roof list.
drop('val_pitched_roof', {'cb_r_felt', 'cb_r_rubber', 'cb_r_single'})
fs = fields('val_flat_roof')
head = [f for f in fs if f['id'] == 'label_flat_roof']
tail = [f for f in fs if f['id'] in ('actv_condition_flat_roof', 'et_notes_flat_roof', 'et_general_remarks_flat_roof')]
set_fields('val_flat_roof', head + [
    cb('cb_fr_felt', 'mineral felt'), cb('cb_fr_rubber', 'rubber membrane'), cb('cb_fr_single', 'single-ply membrane'),
    *other_pair('cb_fr_other', 'et_fr_other_text'),
] + tail)
fs = fields('val_other_roof')
keep = [f for f in fs if f['id'] in ('label_other_roof', 'et_other_roof_name')]
tail = [f for f in fs if f['id'] in ('actv_condition_other_roof', 'et_notes_other_roof', 'cb_partial_view_or',
                                     'actv_visibility_condition_or', 'et_visibility_notes_or',
                                     'actv_roof_ventilation_or', 'et_general_remarks_other_roof')]
set_fields('val_other_roof', keep + [
    cb('cb_or_clay', 'clay tiles'), cb('cb_or_concrete', 'concrete tiles'), cb('cb_or_natural', 'natural slate'),
    cb('cb_or_artificial', 'artificial slate'), cb('cb_or_fibre', 'fibre cement slates'), cb('cb_or_metal', 'metal sheeting'),
    cb('cb_or_felt', 'mineral felt'), cb('cb_or_rubber', 'rubber membrane'), cb('cb_or_single', 'single-ply membrane'),
    *other_pair('cb_or_other', 'et_or_other_text'),
] + tail)

# A2 Oil / LPG tank screen after Gas.
s = open(T.P, encoding='utf8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
lines = s.split(nl)
oil = node_lines('val_oil_lpg', 'Oil / LPG Tank', 'inside_property', 12, [
    lab('label_oil_lpg', 'Oil / LPG Tank'),
    lab('label_oil_fuel', 'Heating system served by'),
    cb('cb_ol_oil', 'Oil-fired'), cb('cb_ol_lpg', 'LPG-fired'),
    lab('label_oil_tank', 'Fuel storage tank'),
    cb('cb_ot_plastic', 'plastic'), cb('cb_ot_metal', 'metal'),
    *other_pair('cb_ot_other', 'et_ot_other_text'),
    lab('label_oil_where', 'Tank located at'),
    cb('cb_ol_front', 'front garden'), cb('cb_ol_side', 'side garden'), cb('cb_ol_rear', 'rear garden'),
    *other_pair('cb_ol_other', 'et_ol_other_text'),
])
i = next(k for k, l in enumerate(lines) if l.strip() == '"id": "val_water",')
st = i - 1
lines[st:st] = oil[:-1] + [oil[-1] + ',']
s2 = nl.join(lines)
# bump orders of the screens after Gas (water 12 -> 13, heating 13 -> 14, smoke 14 -> 15)
out = nl.join(lines)
for nid, old, new in (('val_smoke_detectors', 14, 15), ('val_hot_water_central_heating', 13, 14), ('val_water', 12, 13)):
    ls = out.split(nl)
    j = next(k for k, l in enumerate(ls) if l.strip() == '"id": "%s",' % nid)
    k = next(k for k in range(j, j + 8) if ls[k].strip() == '"order": %d,' % old)
    ls[k] = ls[k].replace('"order": %d,' % old, '"order": %d,' % new)
    out = nl.join(ls)
json.loads(out)
open(T.P, 'w', encoding='utf8', newline='').write(out)
print('tree patched')
