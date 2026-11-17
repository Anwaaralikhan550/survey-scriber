import sys
sys.path.insert(0, 'E:/survey-scriber/tmp/client-edits-2026-11-13')
from add_templates import add

add([
    # A2 Oil / LPG tank (client, 17 Nov 2026)
    'The property is served by an [free text] heating system.',
    'The property is served by an [free text] heating system with [free text] fuel storage tank(s).',
    'The property is served by an [free text] heating system located at the [free text].',
    'The property is served by an [free text] heating system with [free text] fuel storage tank(s) located at the [free text].',
    # A3 Electricity Dated
    'The meter unit is dated.',
    # A4 Date of Extension inside the Extension sentence
    'The property has been extended in [number] to provide [free text] accommodation.',
    'The property has been extended in [number].',
    # A5 three roofs
    'The flat roof covering is formed in [free text].',
    'The other roof covering is formed in [free text].',
    '[free text] covering is formed in [free text].',
    # A8 Rainwater Goods
    'The rainwater goods comprise [free text], and associated fittings.',
], 'VAL_N17')
