# usage: python rm_node.py <nodeId> [<nodeId> ...]  -> removes whole node objects from valuation_tree.json (text-level, keeps formatting)
import sys, json
P = 'E:/survey-scriber/assets/property_valuation/valuation_tree.json'
s = open(P, encoding='utf8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
lines = s.split(nl)
for nid in sys.argv[1:]:
    i = next(k for k, l in enumerate(lines) if l.strip().startswith('"id": "%s"' % nid) and '"title"' not in l)
    st = i - 1
    assert lines[st].strip() == '{', lines[st]
    ind = len(lines[st]) - len(lines[st].lstrip())
    en = next(k for k in range(i, len(lines)) if lines[k].strip() in ('}', '},') and len(lines[k]) - len(lines[k].lstrip()) == ind)
    last = lines[en].strip() == '}'
    del lines[st:en + 1]
    if last:  # removed the last node: drop the comma of the previous one
        lines[st - 1] = lines[st - 1].rstrip().rstrip(',')
s2 = nl.join(lines)
json.loads(s2)
open(P, 'w', encoding='utf8', newline='').write(s2)
print('removed', sys.argv[1:])
