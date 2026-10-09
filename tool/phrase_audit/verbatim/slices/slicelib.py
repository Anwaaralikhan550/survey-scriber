# -*- coding: utf-8 -*-
"""Helpers shared by the gen_*.py slice generators."""


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
