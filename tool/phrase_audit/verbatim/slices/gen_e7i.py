# -*- coding: utf-8 -*-
"""Generate slices/e7i_e.json (E7 scope paragraph: "This section applies where ... this section is not applicable.")."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import para_rule  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e7i_e.json')
slices = [{'screen': 'activity_outside_property_conservatory_porch_main_screen', 'rules': [
    para_rule('E7', 'e7_scope', ['{E_CONSERVATORY_PORCHES}'], '{E7_SCOPE}', 'This section applies where', 'Conservatory:',
              when=['cb_e7_scope', 'true'], extra=[field('cb_e7_scope', 'Section scope statement', 'checkbox')])]}]
json.dump(slices, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print('wrote', OUT)
