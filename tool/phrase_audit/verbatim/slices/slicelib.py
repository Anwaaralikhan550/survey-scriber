# -*- coding: utf-8 -*-
"""Helpers shared by the gen_*.py slice generators."""
import json
import os



def checks(token, label, opts, other=None, cond=None, cap=False):
    """opts = [(id, label)] -> kind=checks token (pdf_options = labels)."""
    t = {'kind': 'checks', 'token': token, 'options': [[i, l] for i, l in opts],
         'pdf_options': [l for _, l in opts]}
    if label:
        t['label'] = label
    if other:
        t['other'] = list(other)
    if cond:
        t['cond'] = cond
    if cap:
        t['cap'] = True
    return t


def dd(token, field_id, label, opts, lower=False, cond=None):
    t = {'kind': 'dropdown', 'token': token, 'dropdown': field_id, 'field_label': label,
         'dropdown_options': opts,
         'pdf_options': [o.lower() for o in opts] if lower else opts}
    if lower:
        t['lower'] = True
    if cond:
        t['cond'] = cond
    return t


def rule(rid, masters, sub, text, pdf=None, tokens=None, when=None, when_any=None,
         extra=None, **kw):
    r = {'id': rid, 'masters': masters, 'sub': sub, 'text': text, 'tokens': tokens or []}
    if pdf:
        r['pdf'] = pdf
    if when:
        r['when'] = when
    if when_any:
        r['when_any'] = when_any
    if extra:
        r['extra_fields'] = extra
    r.update(kw)
    return r


# ───────────── PDF paragraph access (text is cut from the digitised PDF, never retyped) ─────────────
import re as _re  # noqa: E402
import sys as _sys  # noqa: E402

_sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from common import sentences as _sentences  # noqa: E402

_REF = os.path.join(os.path.dirname(__file__), '..', '..', 'reference', 'rics_l2_library_v2.json')
_BLOCKS = {}


def block(section):
    if not _BLOCKS:
        for e in json.load(open(_REF, encoding='utf-8'))['entries']:
            _BLOCKS[e['key']] = _re.sub(r'(?<=\w)- (?=[a-z])', '-', _re.sub(r'\s+', ' ', e['rawBlock']))
    return _BLOCKS[section]


def slug(label):
    return _re.sub(r'[^a-z0-9]+', '_', label.lower()).strip('_')


def opts(prefix, labels):
    """[(id, label)] with ids prefix + slug(label)."""
    return [(prefix + slug(l), l) for l in labels]


def _overlaps(r, old):
    if old in r or r in old:
        return True
    return any(r[i:i + 25] in old for i in range(0, max(1, len(r) - 24), 8))


def P(section, start, end=None, subs=None, tail=None, drop=None):
    """Paragraph of the PDF block from `start` up to (excluding) `end`.

    subs = {exact PDF substring: replacement}; every key must occur. Returns
    (template_text, pdf_rows) where pdf_rows are the PDF sentences of the
    paragraph that contain a substituted substring (the rows a rule claims).
    `tail` is appended to the text (e.g. an approved cross-reference pointer).
    """
    b = block(section)
    s = b.index(start)
    e = b.index(end, s + len(start)) if end else len(b)
    para = b[s:e].strip()
    if drop:
        assert para.startswith(drop), (start[:40], drop)
        para = para[len(drop):].strip()
    rows = []
    text = para
    for old, new in (subs or {}).items():
        assert old in para, (start[:40], old)
        text = text.replace(old, new)
        rows += [r for r in _sentences(para) if _overlaps(r, old)]
    seen = []
    for r in rows:
        if r not in seen:
            seen.append(r)
    if tail:
        text = text + tail
    return text, seen


def lst(s):
    """Option labels of a PDF list "a, b, c, other ..." (items starting with 'other' are dropped:
    the form's Other checkbox + text covers them)."""
    return [x.strip() for x in s.split(', ') if x.strip() and not x.strip().startswith('other')]


def para_rule(section, rid, masters, sub, start, end, subs=None, tokens=None, tail=None, drop=None, **kw):
    """Rule whose bank text is cut from the PDF block (see P). `subs` maps PDF substring -> token."""
    text, rows = P(section, start, end, subs, tail, drop)
    return rule(rid, masters, sub, text, pdf=rows or None, tokens=tokens or [], **kw)
