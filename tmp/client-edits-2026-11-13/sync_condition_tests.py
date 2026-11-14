# Regenerates the valuation Condition entries in test/tool/option_rules_file_test.dart and the exemption list in
# test/features/property_inspection/option_labels_report_test.dart from the live valuation tree. Run after any condition change.
import json, re
V = json.load(open('E:/survey-scriber/assets/property_valuation/valuation_tree.json', encoding='utf8'))
ids = {}
for sec in V['sections']:
    for n in sec['nodes']:
        for f in n.get('fields', []):
            if f.get('label') == 'Condition' and f.get('type') == 'dropdown' and f.get('options') == ["Good", "Reasonable", "Fair", "Poor", "Very poor"]:
                ids[f['id']] = n['id']
base = {
    'val_sub_floor_vents': {'actv_sub_floor_vents': ['Adequate', 'Inadequate']},
    'val_gas': {'actv_gas_supply': ['Mains', 'None']},
    'val_water': {'actv_water_supply': ['Mains', 'Private']},
    'val_damp_meter': {'actv_damp_meter': ['Damp Found', 'No damp']},
    'overall_condition': {'actv_overall_condition': ['Reasonable', 'Reasonable with repair']},
}
for i, sc in ids.items(): base.setdefault(sc, {})[i] = ['Good', 'Reasonable', 'Fair', 'Very poor']
q = lambda l: '[' + ', '.join("'%s'" % x for x in l) + ']'
p = 'E:/survey-scriber/test/tool/option_rules_file_test.dart'
s = open(p, encoding='utf8', newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
i = s.index("const _valuation = <String, Map<String, List<String>>>{"); j = s.index("};", i) + 2
body = "const _valuation = <String, Map<String, List<String>>>{" + nl
for scr, fs in base.items(): body += "  '%s': {" % scr + ', '.join("'%s': %s" % (f, q(o)) for f, o in fs.items()) + "}," + nl
open(p, 'w', encoding='utf8', newline='').write(s[:i] + body + "};" + s[j:])
p = 'E:/survey-scriber/test/features/property_inspection/option_labels_report_test.dart'
s = open(p, encoding='utf8', newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
s = re.sub(r"  '[a-z_]+/actv_condition_[a-z_]+/(Good|Reasonable|Fair|Very poor)',\r?\n", '', s)
a = "  'overall_condition/actv_overall_condition/Reasonable with repair'," + nl
assert a in s
s = s.replace(a, a + ''.join("  '%s/%s/%s',%s" % (sc, i, o, nl) for i, sc in ids.items() for o in ['Good', 'Reasonable', 'Fair', 'Very poor']))
open(p, 'w', encoding='utf8', newline='').write(s)
json.dump(list(ids), open('E:/survey-scriber/tmp/client-edits-2026-11-13/condition_ids.json', 'w'))
print(len(ids), 'condition dropdowns synced')
