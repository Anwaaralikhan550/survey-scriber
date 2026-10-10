# -*- coding: utf-8 -*-
"""Generate slices/e1g_e.json (E1 General notes paragraph on the chimney main screen)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import para_rule  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'e1g_e.json')
slices = [{'screen': 'activity_outside_property_chimney_main_screen', 'rules': [
    para_rule('E1', 'e1_general', ['{E_CHIMNEY}'], '{E1_GENERAL_NOTES}', 'General notes:', 'If the Property is a Flat',
              when=['cb_e1_general', 'true'], extra=[field('cb_e1_general', 'General notes', 'checkbox')])]}]
json.dump(slices, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print('wrote', OUT)
