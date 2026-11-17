# Tree edits for A6 (Limitations screen) and A10 (Reinstatement Value fields on the Valuation screen).
import sys, json
sys.path.insert(0, 'E:/survey-scriber/tmp/client-edits-2026-11-13')
from tree_edit import *
import tree_edit as T

# A10 Valuation screen: Reinstatement Value + Higher Reinstatement Value at the end.
fs = T.get_fields('valuation')
if not any(f['id'] == 'et_reinstatement_value' for f in fs):
  fs += [
    lab('label_reinstatement', 'Reinstatement'),
    txt('et_reinstatement_value', 'Reinstatement Value'),
    cb('cb_higher_reinstatement', 'Higher Reinstatement Value'),
  ]
  set_fields('valuation', fs)

# A6 Limitations screen first in Condition & Restrictions (before Overall Condition).
s = open(T.P, encoding='utf8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
lines = s.split(nl)
lim = node_lines('val_limitations', 'Limitations', None, 1, [
    cb('cb_lim_no_restrictions', 'No Restrictions'),
    cb('cb_lim_no_rear_access', 'No Rear Access'),
])
i = next(k for k, l in enumerate(lines) if l.strip() == '"id": "overall_condition",')
st = i - 1
assert lines[st].strip() == '{'
lines[st:st] = lim[:-1] + [lim[-1] + ',']
out = nl.join(lines)
for nid, old, new in (('val_significant', 2, 3), ('overall_condition', 1, 2)):
    ls = out.split(nl)
    j = next(k for k, l in enumerate(ls) if l.strip() == '"id": "%s",' % nid)
    k = next(k for k in range(j, j + 8) if ls[k].strip().startswith('"order": %d' % old))
    ls[k] = ls[k].replace('"order": %d' % old, '"order": %d' % new)
    out = nl.join(ls)
json.loads(out)
open(T.P, 'w', encoding='utf8', newline='').write(out)
print('tree patched')
