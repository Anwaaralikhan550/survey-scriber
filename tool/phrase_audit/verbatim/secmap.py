# -*- coding: utf-8 -*-
"""Print the form screens/fields under a tree group, compactly.

    python tool/phrase_audit/verbatim/secmap.py <group-title-substring> [--sec E]
"""
import json
import sys

from common import utf8_stdout

TREE = 'assets/property_inspection/inspection_tree.json'


def main():
    utf8_stdout()
    want = sys.argv[1].lower()
    t = json.load(open(TREE, encoding='utf-8'))
    byid, parent = {}, {}

    def walk(n, par=None):
        if isinstance(n, dict):
            if 'id' in n and 'type' in n:
                byid[n['id']] = n
                parent[n['id']] = n.get('parentId') or par
                par = n['id']
            for v in n.values():
                walk(v, par)
        elif isinstance(n, list):
            for v in n:
                walk(v, par)

    walk(t)
    roots = [i for i, n in byid.items() if n['type'] != 'screen' and want in (n.get('title') or '').lower()]

    def under(i, root):
        while i:
            if i == root:
                return True
            i = parent.get(i)
        return False

    for r in roots:
        print('GROUP', r, '|', byid[r].get('title'))
        for i, n in byid.items():
            if n['type'] == 'screen' and under(i, r):
                print('##', i, '|', n.get('title'), '|', n.get('parentId'), n.get('order'))
                for f in n.get('fields', []):
                    o = f.get('options', '') if f['type'] == 'dropdown' else ''
                    print('    ', f['id'], f['type'], repr(f['label'])[:30], o, (f.get('conditionalOn') or '')[:28])


main()
