# -*- coding: utf-8 -*-
"""J2 (Risk to grounds): PDF wording with two option-list tokens whose values come from H2 screens.

J2 has no form of its own, so the two dropdowns that fill "small, medium or large" and "gently, moderately, steeply"
live on the H2 screens (extra fields, not printed there). Idempotent."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from slicelib import P, add_or_set, set_keys  # noqa: E402
from treeedit import edit_screen_fields, field  # noqa: E402

trees, _ = P('J2', 'Influencing trees:', 'Retaining Walls:', subs={'small, medium or large': '{J2_TREE_SIZE}'})
slope, _ = P('J2', 'Sloping Ground:', None, subs={'gently, moderately, steeply': '{J2_SLOPE}'})
set_keys([add_or_set('{RISK_TO_GROUNDS}::{GROUNDS_INFLUENCING_TREES}', trees),
          add_or_set('{RISK_TO_GROUNDS}::{GROUNDS_SLOPING_GROUND}', slope)])


def add(screen, fid, label, options):
    def fn(fields):
        if any(f['id'] == fid for f in fields):
            return fields
        return list(fields) + [field(fid, label, 'dropdown', options)]
    edit_screen_fields(screen, fn)


add('activity_other_repair_nearby_trees', 'actv_j2_tree_size', 'Tree size (J2 Risk to grounds)', ['Small', 'Medium', 'Large'])
add('activity_grounds_other_grounds', 'actv_j2_slope', 'Slope (J2 Risk to grounds)', ['Gently', 'Moderately', 'Steeply'])
print('J2 keys and fields done')
