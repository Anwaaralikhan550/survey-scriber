# -*- coding: utf-8 -*-
"""UI-option coverage: every dropdown option and checkbox of a screen that has verbatim rules must be used by a rule
(as a trigger value, a token option, or the field that gates a rule). Lists the options that would print nothing.

Usage: python3 tool/phrase_audit/verbatim/optioncheck.py [--show 60]
Exit code 1 when unused options exist.
"""
import argparse
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
TREE = 'assets/property_inspection/inspection_tree.json'
SPEC = 'lib/features/property_inspection/domain/inspection_verbatim_spec.dart'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--show', type=int, default=60)
    a = ap.parse_args()
    spec = open(SPEC, encoding='utf-8').read()
    chunks = re.split(r'\n  VerbatimRule\(', spec)[1:]
    used = {}   # screen -> {'vals': {(field,value)}, 'fields': {field}}
    for c in chunks:
        m = re.match(r"\s*'([^']+)',\s*'([^']+)'", c)
        if not m:
            continue
        screen = m.group(2)
        u = used.setdefault(screen, {'vals': set(), 'fields': set()})
        wf = re.search(r"whenField: '([^']+)',\s*whenValue: '([^']*)'", c)
        if wf:
            u['vals'].add((wf.group(1), wf.group(2).lower()))
            u['fields'].add(wf.group(1))
        for f, v in re.findall(r"\['([^']+)', '([^']*)'\]", c):
            u['vals'].add((f, v.lower()))
            u['fields'].add(f)
        for t in re.finditer(r"dropdown: '([^']+)',\s*dropdownOptions: \[([^\]]*)\]", c):
            u['fields'].add(t.group(1))
            for o in re.findall(r"'((?:[^'\\]|\\.)*)'", t.group(2)):
                u['vals'].add((t.group(1), o.lower()))
        for ids in re.findall(r"'([A-Za-z0-9_]+)':\s*'", c):
            u['fields'].add(ids)
        for ids in re.findall(r"otherCheckbox: '([^']+)',\s*otherText: '([^']+)'", c):
            u['fields'].update(ids)
        for ids in re.findall(r"whenField: '([^']+)'", c):
            u['fields'].add(ids)
    tree = json.load(open(TREE, encoding='utf-8'))
    unused_dd, unused_cb = [], []
    for sec in tree['sections']:
        for n in sec['nodes']:
            u = used.get(n['id'])
            if not u or n.get('type') != 'screen':
                continue
            for f in n.get('fields', []):
                if f['type'] == 'dropdown':
                    for o in f.get('options') or []:
                        if (f['id'], o.lower()) not in u['vals']:
                            unused_dd.append((n['id'], f['id'], o))
                elif f['type'] == 'checkbox' and f['id'] not in u['fields']:
                    unused_cb.append((n['id'], f['id'], f.get('label', '')))
    print(f'screens with rules: {len(used)}; dropdown options that trigger no rule: {len(unused_dd)}; '
          f'checkboxes no rule reads: {len(unused_cb)}')
    for x in unused_dd[:a.show]:
        print('  DROPDOWN', x)
    for x in unused_cb[:a.show]:
        print('  CHECKBOX', x)
    sys.exit(1 if unused_dd or unused_cb else 0)


if __name__ == '__main__':
    main()
