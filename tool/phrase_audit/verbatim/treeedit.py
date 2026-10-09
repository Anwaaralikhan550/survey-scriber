# -*- coding: utf-8 -*-
"""Text-level edits of one screen's `fields` array in inspection_tree.json.

The tree file has mixed hand formatting, so it is never re-serialised as a
whole: only the targeted `"fields": [ ... ]` text is replaced, keeping CRLF and
the surrounding indentation, so diffs stay minimal.

Library use:
    from treeedit import edit_screen_fields, field
    edit_screen_fields('activity_x', lambda fields: [...])

CLI check (identity transform, must print 'unchanged'):
    python tool/phrase_audit/verbatim/treeedit.py SCREEN_ID
"""
import json
import sys

TREE = 'assets/property_inspection/inspection_tree.json'


def field(fid, label, ftype, options=None, cond=None, cond_expr=None):
    f = {'id': fid, 'label': label, 'type': ftype}
    if options is not None:
        f['options'] = options
    if cond_expr:
        f['conditionalOn'], f['conditionalMode'] = cond_expr, 'show'
    elif cond:
        f['conditionalOn'], f['conditionalValue'] = cond
        f['conditionalMode'] = 'show'
    return f


def _match_close(text, open_idx):
    """Index of the bracket closing the `[` at open_idx (string-aware)."""
    depth, i, in_str = 0, open_idx, False
    while i < len(text):
        c = text[i]
        if in_str:
            if c == '\\':
                i += 1
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == '[':
                depth += 1
            elif c == ']':
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    raise ValueError('unbalanced')


def edit_screen_fields(screen_id, fn, path=TREE):
    raw = open(path, encoding='utf-8', newline='').read()
    marker = '"id": "%s"' % screen_id
    if raw.count(marker) != 1:
        raise SystemExit(f'screen id {screen_id!r} occurs {raw.count(marker)}x')
    start = raw.index(marker)
    fpos = raw.index('"fields": [', start)
    # make sure the fields array belongs to this screen (no other "id" of a
    # screen node in between)
    between = raw[start + len(marker):fpos]
    if '"type": "screen"' not in between and '"id": "' in between:
        raise SystemExit('fields array does not belong to the screen')
    open_idx = fpos + len('"fields": ')
    close_idx = _match_close(raw, open_idx)
    old_text = raw[open_idx:close_idx + 1]
    fields = json.loads(old_text)
    new_fields = fn(json.loads(old_text))
    line_start = raw.rfind('\n', 0, fpos) + 1
    indent = ' ' * (fpos - line_start)
    body = json.dumps(new_fields, indent=2, ensure_ascii=False)
    lines = body.split('\n')
    new_text = lines[0] + ''.join('\r\n' + indent + ln for ln in lines[1:])
    changed = new_text != old_text
    if changed:
        raw = raw[:open_idx] + new_text + raw[close_idx + 1:]
        json.loads(raw)
        open(path, 'w', encoding='utf-8', newline='').write(raw)
    return changed, fields, new_fields


if __name__ == '__main__':
    ch, _, _ = edit_screen_fields(sys.argv[1], lambda f: f, path=TREE + '.tmp_check') \
        if False else (None, None, None)
    raw = open(TREE, encoding='utf-8', newline='').read()
    # dry identity check without writing
    import tempfile, shutil, os
    tmp = tempfile.mktemp(suffix='.json')
    shutil.copy(TREE, tmp)
    changed, _, _ = edit_screen_fields(sys.argv[1], lambda f: f, path=tmp)
    print('changed' if changed else 'unchanged')
    os.remove(tmp)


def _match_brace(text, open_idx):
    depth, i, in_str = 0, open_idx, False
    while i < len(text):
        c = text[i]
        if in_str:
            if c == chr(92):
                i += 1
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    raise ValueError('unbalanced braces')


def add_screen(node_id, title, parent_id, order, fields, after_id, path=TREE):
    """Insert a new screen node right after node `after_id` (text-level).
    Returns False (no change) if node_id already exists."""
    raw = open(path, encoding='utf-8', newline='').read()
    if '"id": "%s"' % node_id in raw:
        return False
    marker = '"id": "%s"' % after_id
    if raw.count(marker) != 1:
        raise SystemExit(f'after id {after_id!r} occurs {raw.count(marker)}x')
    mi = raw.index(marker)
    line_start = raw.rfind('\n', 0, mi) + 1
    indent = len(raw[line_start:mi]) - 2           # object indent (id is one level in)
    obj_start = raw.rfind('{', 0, mi)
    obj_end = _match_brace(raw, obj_start)
    node = {
        'id': node_id, 'title': title, 'type': 'screen',
        'parentId': parent_id, 'order': order, 'fields': fields,
    }
    body = json.dumps(node, indent=2, ensure_ascii=False).split('\n')
    pad = ' ' * indent
    text = ',\r\n' + pad + body[0] + ''.join('\r\n' + pad + ln for ln in body[1:])
    raw = raw[:obj_end + 1] + text + raw[obj_end + 1:]
    json.loads(raw)
    open(path, 'w', encoding='utf-8', newline='').write(raw)
    return True
