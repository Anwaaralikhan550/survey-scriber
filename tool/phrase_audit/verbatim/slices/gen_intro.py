# -*- coding: utf-8 -*-
"""Section intro paragraphs ("standard text" printed before the first element), emitted from the
section's main screen once a condition rating is chosen. Text is cut from the PDF block."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from slicelib import para_rule  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'intro_e.json')
RATING = ('android_material_design_spinner4', '1', [['android_material_design_spinner4', '2'],
                                                     ['android_material_design_spinner4', '3']])

# (rule id, PDF section, master, sub, start, end, main screen id)
INTROS = [
    ('e4_intro', 'E4', '{E_MAIN_WALLS}', '{STANDARD_TEXT}', 'The external walls have been inspected visually',
     'Description: The external walls of the main building', 'activity_outside_property_main_walls_main_screen'),
    ('e5_intro', 'E5', '{E_WINDOWS}', '{WINDOWS_STANDARD_TEXT}', 'Not every part of the windows was inspected',
     'Description: The windows are formed of', 'activity_outside_property_windows_main_screen'),
]
slices = []
for rid, sec, master, sub, start, end, screen in INTROS:
    r = para_rule(sec, rid, [master], sub, start, end, when=[RATING[0], RATING[1]], when_any=RATING[2], first=True)
    slices.append({'screen': screen, 'rules': [r]})
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT)
