# -*- coding: utf-8 -*-
"""Apply one verbatim "slice": form fields + bank key(s) + master + Dart rule.

Usage:  python tool/phrase_audit/verbatim/slice.py slice.json

slice.json
{
  "screen": "activity_outside_property_stacks",
  "rules": [
    {
      "id": "e1_stack_construction",          # unique, used in test names
      "masters": ["{E_CHIMNEY_SINGLE_STACK}", "{E_CHIMNEY_MULTI_STACK}"],
      "dart_master": "@chimney",               # or the single master code
      "sub": "{STACK_CONSTRUCTION}",
      "text": "Description: The chimney stack(s) are constructed of {CS_X}.",
      "pdf": "Description: ... exactly as the PDF prints it ...",
      "after_sub": "{STACK}",                  # bank key to insert after (optional)
      "master_ref_after": "{STACK_LOCATION}",  # put the new sub code before this one
                                               # in each master template (optional)
      "first": false,
      "label": "Description",                  # optional label field above the options
      "after_field": "EtMultipleNumber",       # insert after this field (default: end)
      "kind": "checks" | "dropdown" | "text",
      "token": "{CS_X}",
      "options": [["st_brick", "brick"], ...],         # checks: [id, label]
      "other": ["st_other", "et_stack_other"],         # optional
      "legacy": {"ch3": "lead and mortar"},            # optional
      "dropdown": "actv_stack_appearance",             # dropdown/text: field id
      "field_label": "Appearance",                     # dropdown/text label
      "dropdown_options": ["original", "replaced"],    # form options (as stored)
      "pdf_options": ["original", "replaced"],         # as the PDF lists them
      "lower": false
    }
  ],
  "remove_fields": ["old_field_id"]                    # optional
}
Each rule's bank keys are added when missing and replaced when present.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from treeedit import add_screen, edit_screen_fields, field  # noqa: E402
import subprocess
import tempfile

SPEC = 'lib/features/property_inspection/domain/inspection_verbatim_spec.dart'
MARK = '  // <<verbatim-rules-end>>'


def dq(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def dart_rule(r):
    kind = r['kind']
    tok = ['        ' + dq(r['token']) + ',']
    if kind == 'checks':
        tok.append('        options: {')
        for i, l in r['options']:
            tok.append(f'          {dq(i)}: {dq(l)},')
        tok.append('        },')
        if r.get('legacy'):
            tok.append('        legacy: {' + ', '.join(f'{dq(k)}: {dq(v)}' for k, v in r['legacy'].items()) + '},')
        if r.get('other'):
            tok.append(f"        otherCheckbox: {dq(r['other'][0])},")
            tok.append(f"        otherText: {dq(r['other'][1])},")
        tok.append('        pdfOptions: [' + ', '.join(dq(x) for x in r['pdf_options']) + '],')
        if r.get('cap'):
            tok.append('        cap: true,')
    elif kind == 'dropdown':
        tok.append(f"        dropdown: {dq(r['dropdown'])},")
        tok.append('        dropdownOptions: [' + ', '.join(dq(x) for x in r['dropdown_options']) + '],')
        if r.get('lower'):
            tok.append('        lower: true,')
        tok.append('        pdfOptions: [' + ', '.join(dq(x) for x in r['pdf_options']) + '],')
    elif kind == 'text':
        tok.append(f"        text: {dq(r['dropdown'])},")
    lines = [
        '  VerbatimRule(',
        f"    {dq(r['id'])},",
        f"    {dq(r['_screen'])},",
        f"    {dq(r.get('dart_master') or r['masters'][0])},",
        f"    {dq(r['sub'])},",
        '    [',
        '      VerbatimToken(',
        *tok,
        '      ),',
        '    ],',
    ]
    if r.get('pdf'):
        lines += ['    pdf:', f"        {dq(r['pdf'])},"]
    if r.get('first'):
        lines.append('    first: true,')
    if r.get('is_are'):
        lines.append('    isAre: true,')
    lines.append('  ),')
    return '\n'.join(lines)


def main(path):
    data = json.load(open(path, encoding='utf-8'))
    for sl in (data if isinstance(data, list) else [data]):
        apply_slice(sl)


def apply_slice(sl):
    screen = sl['screen']
    bank_ops, master_edits, rules_dart, field_plan = [], [], [], []

    # ---- form
    def build_fields(fields):
        ids = [f['id'] for f in fields]
        for rid in sl.get('remove_fields', []):
            fields = [f for f in fields if f['id'] != rid]
        for r in sl['rules']:
            new = []
            if r.get('label'):
                new.append(field('label_' + r['id'], r['label'], 'label'))
            if r['kind'] == 'checks':
                for i, l in r['options']:
                    new.append(field(i, l, 'checkbox'))
                if r.get('other'):
                    new.append(field(r['other'][0], 'Other', 'checkbox'))
                    new.append(field(r['other'][1], 'Other', 'text', cond=(r['other'][0], 'true')))
            elif r['kind'] == 'dropdown':
                new.append(field(r['dropdown'], r['field_label'], 'dropdown', r['dropdown_options']))
            elif r['kind'] == 'text':
                new.append(field(r['dropdown'], r['field_label'], 'text'))
            # replace fields that already exist with the same id, keep position
            existing = {f['id'] for f in fields}
            if any(n['id'] in existing for n in new):
                byid = {n['id']: n for n in new}
                fields = [byid.get(f['id'], f) if f['id'] in byid else f for f in fields]
                new = [n for n in new if n['id'] not in existing]
            if new:
                after = r.get('after_field')
                if after and after in [f['id'] for f in fields]:
                    i = [f['id'] for f in fields].index(after) + 1
                    fields = fields[:i] + new + fields[i:]
                else:
                    fields = fields + new
        return fields

    ns = sl.get('new_screen')
    if ns:
        made = add_screen(ns['id'], ns['title'], ns['parent'], ns['order'],
                          [field('placeholder', 'x', 'label')], ns['after'])
        print(f"new screen {ns['id']}: {'created' if made else 'exists'}")
        if made:  # replace the placeholder content below
            sl['remove_fields'] = list(sl.get('remove_fields', [])) + ['placeholder']
    ch, old, new = edit_screen_fields(screen, build_fields)
    print(f'form: {screen} {"changed" if ch else "unchanged"} ({len(old)} -> {len(new)} fields)')

    # ---- bank + masters + rules
    bank = json.load(open('assets/property_inspection/phrase_texts.json', encoding='utf-8'))
    for r in sl['rules']:
        r['_screen'] = screen
        for m in r['masters']:
            key = f"{m}::{r['sub']}"
            if key in bank:
                bank_ops.append({'op': 'set', 'key': key, 'value': r['text']})
            else:
                after = f"{m}::{r['after_sub']}" if r.get('after_sub') else None
                if not after or after not in bank:
                    cands = [k for k in bank if k.startswith(m + '::')]
                    after = cands[-1]
                bank_ops.append({'op': 'add', 'key': key, 'value': r['text'], 'after': after})
            if r.get('master_ref_after') and r['sub'] not in bank.get(m, ''):
                a = r['master_ref_after']
                master_edits.append({'key': m, 'old': a, 'new': r['sub'] + ' ' + a})
        if not any(f"{r['id']}" in l for l in []):
            rules_dart.append(dart_rule(r))

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
            sys.exit(f'ABORT rule id {rid} already exists in {SPEC}')
        src = src.replace(MARK, code.replace('\n', nl) + nl + MARK)
    open(SPEC, 'w', encoding='utf-8', newline='').write(src)
    print(f'rules added: {[c.split(chr(39))[1] for c in rules_dart]}')


if __name__ == '__main__':
    main(sys.argv[1])
