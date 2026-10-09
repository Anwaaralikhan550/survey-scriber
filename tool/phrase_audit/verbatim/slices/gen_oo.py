# -*- coding: utf-8 -*-
"""Generate slices/oo_e.json (A: Overall opinion verdict paragraphs; price is formatted by the engine)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import dd, para_rule  # noqa: E402
from treeedit import field  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), 'oo_e.json')
S, MW = 'Overall opinion', '{OVERALL_OPINION}'
RATINGS = ['Reasonable', 'Good', 'Fair', 'Poor']
PRICE = '£390,500.00 [Three Hundred Ninety Thousand and five hundred Pounds]'
FIELD = 'android_material_design_spinner5'
PRICE_FIELD = 'android_material_design_spinner'

slices = [{'screen': 'activity_over_all_openion', 'replace_all': True, 'keep': [], 'rules': [
    para_rule(S, 'oo_pleased', [MW], '{OO_PLEASED}', 'Reasonable:', 'In my opinion,', subs={PRICE: '{OO_PRICE}'},
              when=[FIELD, 'Reasonable'],
              tokens=[{'kind': 'text', 'token': '{OO_PRICE}', 'dropdown': PRICE_FIELD,
                       'field_label': 'Purchase price (GBP, digits)'}]),
    para_rule(S, 'oo_opinion', [MW], '{OO_OPINION}', 'In my opinion,', 'Reasonable with repair:',
              subs={'reasonable, good, fair, poor': '{OO_RATING}'}, when=[FIELD, RATINGS[0]],
              when_any=[[FIELD, r] for r in RATINGS[1:]],
              tokens=[dd('{OO_RATING}', FIELD, 'Opinion', RATINGS, lower=True)]),
    para_rule(S, 'oo_repair', [MW], '{OO_REASONABLE_WITH_REPAIR}', 'Reasonable with repair:', '(Although this appears',
              when=['cb_oo_repair', 'true'], extra=[field('cb_oo_repair', 'Reasonable with repair', 'checkbox')]),
]}]
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(slices, f, ensure_ascii=False, indent=2)
print('wrote', OUT)
