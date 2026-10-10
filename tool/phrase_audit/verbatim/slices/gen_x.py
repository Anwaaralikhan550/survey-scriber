# -*- coding: utf-8 -*-
"""Generate slices/x_e.json: three short bridging sentences for explicit "No / none" answers where the PDF is silent.
Client-authorised wording (listed in approved_extras.csv and CLIENT_QUERIES.md #129-#131), not PDF text."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import rule  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'x_e.json')
LISTED = 'The property is not understood to be a listed building.'
GATED = 'The property is not located within a gated development.'
NONE_J4 = 'No other risks were identified during the inspection.'

slices = [
    {'screen': 'activity_listed_building__listed_building', 'rules': [
        rule('x_listed_no', ['{D_CONSTRUCTION}'], '{X_NOT_LISTED}', LISTED, when=['android_material_design_spinner', 'No'])]},
    {'screen': 'activity_listed_building', 'rules': [
        rule('x_listed_no2', ['{D_CONSTRUCTION}'], '{X_NOT_LISTED}', LISTED, when=['android_material_design_spinner', 'No'])]},
    {'screen': 'activity_gated_community', 'rules': [
        rule('x_gated_no', ['{D_GROUND}'], '{X_NOT_GATED}', GATED, when=['android_material_design_spinner3', 'No'])]},
    {'screen': 'activity_risks_other_', 'rules': [
        rule('x_j4_none', ['{RISK_TO_OTHER}'], '{X_NO_OTHER_RISKS}', NONE_J4, when=['cb_x_j4_none', 'true'],
             extra=[field('cb_x_j4_none', 'No other risks identified', 'checkbox')])]},
]
json.dump(slices, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print('wrote', OUT)
