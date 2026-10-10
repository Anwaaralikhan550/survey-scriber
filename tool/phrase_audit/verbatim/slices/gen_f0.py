# -*- coding: utf-8 -*-
"""Generate slices/f0_e.json (F Inside the Property limitations; PDF text sits at the tail of the E9 block)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import checks, opts, para_rule  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'f0_e.json')
MW = '{F_INSIDE_THE_PROPERTY}'
LIM = ('fitted floor coverings, furniture, stored items, fixed fittings, restricted access, locked rooms, '
       'limited roof access, limited lighting, health, and safety considerations')
LIM_OPTS = ['fitted floor coverings', 'furniture', 'stored items', 'fixed fittings', 'restricted access', 'locked rooms',
            'limited roof access', 'limited lighting', 'health, and safety considerations']
RNFI = ('limited roof height; the floor was not safe to walk on, floor was boarded, excessive storage, insulation, '
        'underlining, other')
RNFI_OPTS = ['limited roof height; the floor was not safe to walk on', 'floor was boarded', 'excessive storage',
             'insulation', 'underlining']


def pr(rid, sub, start, end, label, **kw):
    t = 'cb_' + rid
    return para_rule('E9', rid, [MW], '{F0_%s}' % sub, start, end, when=[t, 'true'],
                     extra=[field(t, label, 'checkbox')], **kw)


rules = [
    pr('f0_concealed', 'CONCEALED', 'It was not practical to inspect', 'Where the roof space is inaccessible', 'Concealed or inaccessible parts'),
    pr('f0_roofspace', 'ROOF_SPACE_INACCESSIBLE', 'Where the roof space is inaccessible', 'Moisture readings', 'Roof space inaccessible'),
    pr('f0_moisture', 'MOISTURE', 'Moisture readings', 'The inspection was visual and non-invasive.', 'Moisture readings'),
    pr('f0_visual', 'VISUAL', 'The inspection was visual and non-invasive.', 'Limitations: The inspection of the internal',
       'Visual and non-invasive inspection'),
    pr('f0_limited', 'LIMITED_BY', 'Limitations: The inspection of the internal', 'Where roof space access was available',
       'Internal accommodation limited by', subs={LIM: '{F0_LIMITS}'},
       tokens=[checks('{F0_LIMITS}', 'Limited by', opts('f0l_', LIM_OPTS))]),
    pr('f0_roofavail', 'ROOF_ACCESS_AVAILABLE', 'Where roof space access was available', 'Roof Not Fully Inspected:',
       'Roof space access available'),
    pr('f0_rnfi', 'ROOF_NOT_FULLY', 'Roof Not Fully Inspected:', 'Unsafe floor:', 'Roof not fully inspected',
       subs={RNFI: '{F0_RNFI_REASONS}'},
       tokens=[checks('{F0_RNFI_REASONS}', 'Because of', opts('f0r_', RNFI_OPTS), other=('f0r_other', 'f0r_other_text'))]),
    pr('f0_unsafe', 'UNSAFE_FLOOR', 'Unsafe floor:', None, 'Unsafe floor'),
]
slices = [{'screen': 'activity_inside_property_limitation', 'replace_all': True, 'keep': [], 'rules': rules}]
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT, len(rules), 'rules')
