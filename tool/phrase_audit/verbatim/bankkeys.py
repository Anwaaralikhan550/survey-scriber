# -*- coding: utf-8 -*-
"""Line-level key edits for phrase_texts.json (one key per line, CRLF).

Usage: python tool/phrase_audit/verbatim/bankkeys.py ops.json
ops.json = list of
  {"op": "set", "key": K, "value": V}                 replace K (must exist)
  {"op": "add", "key": K, "value": V, "after": K2}    insert K after K2 (K must not exist)
  {"op": "del", "key": K}                             delete K (must exist)
All operations are applied to the text; the file is only written if the result
is valid JSON and every precondition held.
"""
import json
import sys

P = 'assets/property_inspection/phrase_texts.json'


def line_span(raw, key):
    tag = '  ' + json.dumps(key, ensure_ascii=False) + ': '
    n = raw.count('\r\n' + tag)
    if n != 1:
        sys.exit(f'ABORT key {key!r} found {n}x')
    start = raw.index('\r\n' + tag) + 2
    end = raw.index('\r\n', start)
    return start, end


def main(path):
    ops = json.load(open(path, encoding='utf-8'))
    raw = open(P, encoding='utf-8', newline='').read()
    for o in ops:
        key, op = o['key'], o['op']
        if op == 'set':
            s, e = line_span(raw, key)
            tail = ',' if raw[s:e].endswith(',') else ''
            raw = raw[:s] + '  ' + json.dumps(key, ensure_ascii=False) + ': ' + \
                json.dumps(o['value'], ensure_ascii=False) + tail + raw[e:]
        elif op == 'add':
            if ('\r\n  ' + json.dumps(key, ensure_ascii=False) + ': ') in raw:
                sys.exit(f'ABORT key {key!r} already exists')
            s, e = line_span(raw, o['after'])
            line = raw[s:e]
            had_comma = line.endswith(',')
            if not had_comma:  # inserting after the last key
                raw = raw[:e] + ',' + raw[e:]
                e += 1
            new = '\r\n  ' + json.dumps(key, ensure_ascii=False) + ': ' + \
                json.dumps(o['value'], ensure_ascii=False) + (',' if had_comma else '')
            raw = raw[:e] + new + raw[e:]
        elif op == 'del':
            s, e = line_span(raw, key)
            last = not raw[s:e].endswith(',')
            raw = raw[:s - 2] + raw[e:] if not last else raw[:s - 2] + raw[e:]
            if last:  # removed the final key: drop the comma of the new last line
                raw = raw.replace(',\r\n}', '\r\n}')
        else:
            sys.exit(f'bad op {op}')
    json.loads(raw)
    open(P, 'w', encoding='utf-8', newline='').write(raw)
    print(f'applied {len(ops)} key ops OK; JSON valid')


if __name__ == '__main__':
    main(sys.argv[1])
