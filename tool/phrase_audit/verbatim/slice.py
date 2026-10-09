# -*- coding: utf-8 -*-
"""Apply "slices": form fields / new screens + bank keys + master refs + Dart rules.

Usage:  python tool/phrase_audit/verbatim/slice.py slice.json

slice.json = one slice dict or a list of them:
{
  "screen": "activity_outside_property_stacks",
  "new_screen": {"id": ..., "title": ..., "parent": ..., "order": N, "after": "<node id>"},  # optional
  "remove_fields": ["old_id", ...],                                                     # optional
  "rules": [
    {
      "id": "e1_x",                       # unique; used in test names
      "masters": ["{E_CHIMNEY_SINGLE_STACK}", "{E_CHIMNEY_MULTI_STACK}"],   # bank masters to write
      "dart_master": "@chimney",          # master the engine reads (default masters[0])
      "sub": "{SUB}",
      "text": "bank sentence with {CS_TOKENS}",
      "pdf": "PDF sentence exactly as printed (links the ledger option-list row)",
      "after_sub": "{PREV}",              # insert bank key after masters::{PREV} (optional)
      "master_ref_after": "{CODE}",       # put {SUB} before {CODE} in each master template
      "first": false, "is_are": false,
      "when": ["actv_condition", "Repair now"],   # fire only when that dropdown has this value
      "after_field": "field_id",          # insert this rule's fields after that field (default end)
      "tokens": [                          # one or more
        {"kind": "checks", "token": "{CS_X}", "label": "Group label",
         "options": [["id", "label"], ...], "other": ["cbId", "textId"],
         "legacy": {"old_id": "old label"}, "pdf_options": [...], "cap": false, "optional": false},
        {"kind": "dropdown", "token": "{CS_Y}", "dropdown": "field_id", "field_label": "Label",
         "dropdown_options": [...], "pdf_options": [...], "lower": false},
        {"kind": "text", "token": "{CS_Z}", "dropdown": "field_id", "field_label": "Label"},
        {"kind": "constant", "token": "{RC_TYPE}", "value": "pitched"}
      ]
    }
  ]
}
Bank keys are added when missing and replaced when present. A rule without any
token fires whenever its `when` matches.
"""
import json
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))
from treeedit import add_screen, edit_screen_fields, field, remove_screen, set_title  # noqa: E402

SPEC = 'lib/features/property_inspection/domain/inspection_verbatim_spec.dart'
MARK = '  // <<verbatim-rules-end>>'


def dq(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def norm_tokens(r):
    if 'tokens' in r:
        return r['tokens']
    if 'kind' not in r:
        return []
    return [{k: v for k, v in r.items() if k in (
        'kind', 'token', 'label', 'options', 'other', 'legacy', 'pdf_options', 'cap',
        'optional', 'dropdown', 'field_label', 'dropdown_options', 'lower', 'value', 'cond')}]


def dart_token(t):
    kind = t['kind']
    out = ['      VerbatimToken(', '        ' + dq(t['token']) + ',']
    if kind == 'checks':
        out.append('        options: {')
        for i, l in t['options']:
            out.append(f'          {dq(i)}: {dq(l)},')
        out.append('        },')
        if t.get('legacy'):
            out.append('        legacy: {' + ', '.join(f'{dq(k)}: {dq(v)}' for k, v in t['legacy'].items()) + '},')
        if t.get('other'):
            out.append(f"        otherCheckbox: {dq(t['other'][0])},")
            out.append(f"        otherText: {dq(t['other'][1])},")
        if t.get('cap'):
            out.append('        cap: true,')
        out.append('        pdfOptions: [' + ', '.join(dq(x) for x in t['pdf_options']) + '],')
    elif kind == 'dropdown':
        out.append(f"        dropdown: {dq(t['dropdown'])},")
        out.append('        dropdownOptions: [' + ', '.join(dq(x) for x in t['dropdown_options']) + '],')
        if t.get('lower'):
            out.append('        lower: true,')
        if t.get('cap'):
            out.append('        cap: true,')
        out.append('        pdfOptions: [' + ', '.join(dq(x) for x in t['pdf_options']) + '],')
    elif kind == 'text':
        out.append(f"        text: {dq(t['dropdown'])},")
    elif kind == 'constant':
        out.append(f"        constant: {dq(t['value'])},")
    if t.get('optional'):
        out.append('        optional: true,')
    out.append('      ),')
    return out


def dart_rule(r, screen):
    lines = ['  VerbatimRule(', f"    {dq(r['id'])},", f'    {dq(screen)},',
             f"    {dq(r.get('dart_master') or r['masters'][0])},", f"    {dq(r['sub'])},", '    [']
    for t in norm_tokens(r):
        lines += dart_token(t)
    lines.append('    ],')
    pdfs = r.get('pdf')
    if isinstance(pdfs, str):
        pdfs = [pdfs]
    if pdfs:
        lines += ['    pdf:', f"        {dq(pdfs[0])},"]
        if len(pdfs) > 1:
            lines.append('    pdfMore: [')
            lines += [f'      {dq(p)},' for p in pdfs[1:]]
            lines.append('    ],')
    if r.get('first'):
        lines.append('    first: true,')
    if r.get('is_are'):
        lines.append('    isAre: true,')
    if r.get('when'):
        lines.append(f"    whenField: {dq(r['when'][0])},")
        lines.append(f"    whenValue: {dq(r['when'][1])},")
        if r.get('when_any'):
            lines.append('    whenAny: [' + ', '.join(
                '[' + dq(a) + ', ' + dq(b) + ']' for a, b in r['when_any']) + '],')
    lines.append('  ),')
    return '\n'.join(lines)


def token_fields(t):
    new = []
    kind = t['kind']
    ce = t.get('cond')  # conditionalOn expression, e.g. "actv_condition=Repair soon|Repair now"
    if t.get('label'):
        new.append(field('label_' + t['token'].strip('{}').lower(), t['label'], 'label', cond_expr=ce))
    if kind == 'checks':
        for i, l in t['options']:
            new.append(field(i, l, 'checkbox', cond_expr=ce))
        if t.get('other'):
            new.append(field(t['other'][0], 'Other', 'checkbox', cond_expr=ce))
            new.append(field(t['other'][1], 'Other', 'text',
                             cond_expr=(ce + '&' + t['other'][0]) if ce else None,
                             cond=None if ce else (t['other'][0], 'true')))
    elif kind == 'dropdown':
        new.append(field(t['dropdown'], t['field_label'], 'dropdown', t['dropdown_options'], cond_expr=ce))
    elif kind == 'text':
        new.append(field(t['dropdown'], t['field_label'], 'text', cond_expr=ce))
    return new


def apply_slice(sl):
    if 'remove_screens' in sl:
        for sid in sl['remove_screens']:
            if ('"id": "%s"' % sid) in open('assets/property_inspection/inspection_tree.json', encoding='utf-8').read():
                remove_screen(sid)
                print('removed screen', sid)
        return
    screen = sl['screen']
    if sl.get('set_title'):
        set_title(screen, sl['set_title'])
    ns = sl.get('new_screen')
    removes = list(sl.get('remove_fields', []))
    if ns:
        made = add_screen(ns['id'], ns['title'], ns['parent'], ns['order'],
                          [field('placeholder', 'x', 'label')], ns['after'])
        print(f"new screen {ns['id']}: {'created' if made else 'exists'}")
        if made:
            removes.append('placeholder')

    def build_fields(fields):
        if sl.get('replace_all'):
            keep = set(sl.get('keep', []))
            fields = [f for f in fields if f['id'] in keep]
        fields = [f for f in fields if f['id'] not in removes]
        for r in sl['rules']:
            for ef in r.get('extra_fields', []):
                fields = [f for f in fields if f['id'] != ef['id']] + [ef]
            for t in norm_tokens(r):
                new = token_fields(t)
                if not new:
                    continue
                existing = {f['id'] for f in fields}
                byid = {n['id']: n for n in new}
                fields = [byid.get(f['id'], f) for f in fields]
                new = [n for n in new if n['id'] not in existing]
                if new:
                    after = r.get('after_field')
                    ids = [f['id'] for f in fields]
                    if after and after in ids:
                        i = ids.index(after) + 1
                        fields = fields[:i] + new + fields[i:]
                    else:
                        fields = fields + new
        return fields

    ch, old, new = edit_screen_fields(screen, build_fields)
    print(f'form: {screen} {"changed" if ch else "unchanged"} ({len(old)} -> {len(new)} fields)')

    bank = json.load(open('assets/property_inspection/phrase_texts.json', encoding='utf-8'))
    bank_ops, master_edits, rules_dart = [], [], []
    for r in sl['rules']:
        for m in r['masters']:
            key = f"{m}::{r['sub']}"
            if key in bank:
                bank_ops.append({'op': 'set', 'key': key, 'value': r['text']})
            else:
                after = f"{m}::{r['after_sub']}" if r.get('after_sub') else None
                if not after or after not in bank:
                    same = [k for k in bank if k.startswith(m + '::')]
                    fam = [k for k in bank if k.startswith(m[:6])]
                    after = (same or fam or list(bank))[-1]
                bank_ops.append({'op': 'add', 'key': key, 'value': r['text'], 'after': after})
                bank[key] = r['text']
            if r.get('master_ref_after') and r['sub'] not in bank.get(m, ''):
                a = r['master_ref_after']
                master_edits.append({'key': m, 'old': a, 'new': r['sub'] + ' ' + a})
        rules_dart.append(dart_rule(r, screen))

    tmp = tempfile.mkdtemp()
    if bank_ops:
        bp = os.path.join(tmp, 'bank.json')
        json.dump(bank_ops, open(bp, 'w', encoding='utf-8'), ensure_ascii=False)
        subprocess.check_call([sys.executable, 'tool/phrase_audit/verbatim/bankkeys.py', bp])
    if master_edits:
        mp = os.path.join(tmp, 'master.json')
        json.dump(master_edits, open(mp, 'w', encoding='utf-8'), ensure_ascii=False)
        subprocess.check_call([sys.executable, 'tool/phrase_audit/verbatim/apply.py', mp])

    src = open(SPEC, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in src else '\n'
    if MARK not in src:
        k = src.index('];' + nl + nl + 'extension _VerbatimSpec')
        src = src[:k] + MARK + nl + src[k:]
    for code in rules_dart:
        rid = code.split("'")[1]
        if f"'{rid}'" in src:
            print(f'skip rule {rid}: already in spec')
            continue
        src = src.replace(MARK, code.replace('\n', nl) + nl + MARK)
    open(SPEC, 'w', encoding='utf-8', newline='').write(src)
    print(f'rules added: {[c.split(chr(39))[1] for c in rules_dart]}')


def main(path):
    data = json.load(open(path, encoding='utf-8'))
    for sl in (data if isinstance(data, list) else [data]):
        apply_slice(sl)


if __name__ == '__main__':
    main(sys.argv[1])
