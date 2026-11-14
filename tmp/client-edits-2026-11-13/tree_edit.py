# Helpers to rewrite a valuation tree node's fields (text-level, keeps the one-field-per-line format).
import json
P = 'E:/survey-scriber/assets/property_valuation/valuation_tree.json'
def cb(i, l, cond=None): return _f(i, l, 'checkbox', cond)
def txt(i, l, cond=None): return _f(i, l, 'text', cond)
def num(i, l, cond=None): return _f(i, l, 'number', cond)
def lab(i, l, cond=None): return _f(i, l, 'label', cond)
def dd(i, l, opts, cond=None): return _f(i, l, 'dropdown', cond, opts)
def _f(i, l, t, cond=None, opts=None):
    d = {'id': i, 'label': l, 'type': t}
    if opts is not None: d['options'] = opts
    if cond:
        d['conditionalOn'] = cond
    return d
def other_pair(cbid, txtid, label='Other', textlabel='Other (describe)'):
    return [cb(cbid, label), txt(txtid, textlabel, cbid)]
def _line(d, ind):
    parts = ['"id": %s' % json.dumps(d['id']), '"label": %s' % json.dumps(d['label'], ensure_ascii=False), '"type": %s' % json.dumps(d['type'])]
    if 'options' in d: parts.append('"options": ' + json.dumps(d['options'], ensure_ascii=False))
    if 'conditionalOn' in d:
        parts.append('"conditionalOn": %s' % json.dumps(d['conditionalOn']))
        if d['type'] == 'text' and '=' not in d['conditionalOn'] and '|' not in d['conditionalOn'] and '&' not in d['conditionalOn']:
            parts += ['"conditionalValue": "true"', '"conditionalMode": "show"']
    return ind + '{ ' + ', '.join(parts) + ' }'
def set_fields(node_id, fields, title=None):
    s = open(P, encoding='utf8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    lines = s.split(nl)
    i = next(k for k, l in enumerate(lines) if l.strip() == '"id": "%s",' % node_id)
    if title:
        assert '"title"' in lines[i + 1]
        ind0 = lines[i + 1][:len(lines[i + 1]) - len(lines[i + 1].lstrip())]
        lines[i + 1] = ind0 + '"title": %s,' % json.dumps(title)
    f0 = next(k for k in range(i, len(lines)) if lines[k].strip() == '"fields": [')
    f1 = next(k for k in range(f0, len(lines)) if lines[k].strip() == ']')
    ind = lines[f0 + 1][:len(lines[f0 + 1]) - len(lines[f0 + 1].lstrip())] if f1 > f0 + 1 else ' ' * 12
    new = [_line(d, ind) + (',' if n < len(fields) - 1 else '') for n, d in enumerate(fields)]
    lines[f0 + 1:f1] = new
    s2 = nl.join(lines); json.loads(s2)
    open(P, 'w', encoding='utf8', newline='').write(s2)
def get_fields(node_id):
    V = json.load(open(P, encoding='utf8'))
    for s in V['sections']:
        for n in s['nodes']:
            if n['id'] == node_id: return n['fields']
def COND(prefix): return [dd('actv_condition_' + prefix, 'Condition', ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'])]
def notes(prefix, nid): c = 'actv_condition_' + prefix; return txt(nid, 'Notes', f'{c}=Fair|{c}=Poor|{c}=Very poor')

def node_lines(nid, title, parent, order, fields):
    pj = 'null' if parent is None else json.dumps(parent)
    out = ['        {', '          "id": %s,' % json.dumps(nid), '          "title": %s,' % json.dumps(title), '          "type": "screen",',
           '          "parentId": %s,' % pj, '          "order": %d,' % order, '          "fields": [']
    ind = ' ' * 12
    out += [_line(d, ind) + (',' if n < len(fields) - 1 else '') for n, d in enumerate(fields)]
    out += ['          ]', '        }']
    return out
def replace_node(old_id, new_nodes):
    """Replace node old_id by the given nodes (list of node_lines lists)."""
    s = open(P, encoding='utf8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    lines = s.split(nl)
    i = next(k for k, l in enumerate(lines) if l.strip() == '"id": "%s",' % old_id)
    st = i - 1
    assert lines[st].strip() == '{'
    ind = len(lines[st]) - len(lines[st].lstrip())
    en = next(k for k in range(i, len(lines)) if lines[k].strip() in ('}', '},') and len(lines[k]) - len(lines[k].lstrip()) == ind)
    tail_comma = lines[en].strip() == '},'
    block = []
    for n, nodelines in enumerate(new_nodes):
        nodelines = list(nodelines)
        if n < len(new_nodes) - 1 or tail_comma: nodelines[-1] = nodelines[-1] + ','
        block += nodelines
    lines[st:en + 1] = block
    s2 = nl.join(lines); json.loads(s2)
    open(P, 'w', encoding='utf8', newline='').write(s2)
