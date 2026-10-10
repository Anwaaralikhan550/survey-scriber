# -*- coding: utf-8 -*-
"""List screens (id | parent order | fields) whose id contains any of the given substrings.
   python tool/phrase_audit/verbatim/scr.py electric solar ...   [--fields]"""
import json
import sys

from common import utf8_stdout

utf8_stdout()
subs = [a for a in sys.argv[1:] if not a.startswith('--')]
full = '--fields' in sys.argv
t = json.load(open('assets/property_inspection/inspection_tree.json', encoding='utf-8'))


def walk(n):
    if isinstance(n, dict):
        if n.get('type') == 'screen' and any(s in n['id'] for s in subs):
            fs = n['fields']
            print(n['id'], '|', n.get('parentId'), n.get('order'), len(fs))
            if full:
                for f in fs:
                    o = f.get('options', '') if f['type'] == 'dropdown' else ''
                    print('     ', f['id'], f['type'], repr(f['label'])[:30], o, (f.get('conditionalOn') or '')[:24])
        for v in n.values():
            walk(v)
    elif isinstance(n, list):
        for v in n:
            walk(v)


walk(t)
