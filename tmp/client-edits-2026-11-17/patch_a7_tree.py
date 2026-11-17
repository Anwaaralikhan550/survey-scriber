# A7: FBS Valuation Matrix screen after Valuation (one JSON answer; the screen draws its own grid).
import sys, json
sys.path.insert(0, 'E:/survey-scriber/tmp/client-edits-2026-11-13')
from tree_edit import *
import tree_edit as T

s = open(T.P, encoding='utf8', newline='').read()
assert '"valuation_matrix"' not in s, 'already applied'
nl = '\r\n' if '\r\n' in s else '\n'
lines = s.split(nl)
node = node_lines('valuation_matrix', 'FBS Valuation Matrix', None, 2, [
    txt('et_matrix_grid', 'FBS Valuation Matrix'),
])
i = next(k for k, l in enumerate(lines) if l.strip() == '"id": "general_remarks",')
st = i - 1
assert lines[st].strip() == '{'
lines[st:st] = node[:-1] + [node[-1] + ',']
out = nl.join(lines)
for nid, old, new in (('scan_floor_plan', 3, 4), ('general_remarks', 2, 3)):
    ls = out.split(nl)
    j = next(k for k, l in enumerate(ls) if l.strip() == '"id": "%s",' % nid)
    k = next(k for k in range(j, j + 8) if ls[k].strip().startswith('"order": %d' % old))
    ls[k] = ls[k].replace('"order": %d' % old, '"order": %d' % new)
    out = nl.join(ls)
json.loads(out)
open(T.P, 'w', encoding='utf8', newline='').write(out)
print('tree patched')
