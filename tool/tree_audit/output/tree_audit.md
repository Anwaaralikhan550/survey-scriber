# Inspection tree audit

Nodes: 436 (341 screens). Element landings checked: 23.

| Code | Check | Findings |
|---|---|---|
| L1 | Landing does not follow the Roof Covering pattern | 0 |
| L2 | Condition rating screen not the inline header of the main group | 0 |
| L3 | Repairs / Not inspected in the wrong position | 0 |
| L4 | Duplicate Condition Rating screens in one element | 0 |
| L5 | App order (placement) differs from the "order" attribute | 6 |
| L6 | Duplicate titles on one page | 0 |
| D1 | Repair dropdown still labelled "Condition" | 0 |
| D2 | Dropdown with too few or duplicate options | 0 |
| T1 | Title style | 3 |
| F1 | Conditional field can never appear (missing controller or impossible value) | 0 |
| F2 | "Other" checkbox with no text box | 0 |
| F3 | Duplicate field id | 0 |
| E1 | Empty group or screen | 2 |

## L5: App order (placement) differs from the "order" attribute (6)

- **Outside Property > Rain Water Goods > Rainwater Goods** (`group_rainwater_goods_14`): app shows ['Weather Condition', 'About RWG', 'Insufficient slope', 'Leakage', 'Corrosion', 'Blocked RWG', 'Blocked gullies', 'Open runoffs'] but "order" says ['Weather Condition', 'About RWG', 'Blocked RWG', 'Insufficient slope', 'Leakage', 'Blocked gullies', 'Corrosion', 'Open runoffs']
- **Outside Property > Windows > Windows** (`group_windows_21`): app shows ['About windows', 'Velux window', 'Windowsills', 'Operation', 'Defective operation', 'Failed glazed units', 'Damaged glazing', 'Timber windows', 'Condensation', 'Sill Projection/Wall Sealing', 'Sill Defect'] but "order" says ['About windows', 'Velux window', 'Windowsills', 'Sill Projection/Wall Sealing', 'Operation', 'Defective operation', 'Failed glazed units', 'Damaged glazing', 'Timber windows', 'Condensation', 'Sill Defect']
- **F Inside Property > Ceilings > Ceilings** (`group_ceilings_61`): app shows ['About Ceilings', 'Cracks', 'Unevenness', 'Water staining', 'Polystyrene', 'Heavy Paper Lining'] but "order" says ['About Ceilings', 'Cracks', 'Polystyrene', 'Heavy Paper Lining', 'Unevenness', 'Water staining']
- **F Inside Property > Roof Structure > Roof Structure** (`group_roof_structure_58`): app shows ['Loft Converted', 'About Roof structure', 'Roof underlay', 'Roof ventilation', 'Roof insulation', 'Water Tank', 'Insect infestation', 'Timber rot', 'Undersize timber', 'Heavy roof', 'Roof movement', 'Structural alterations', 'Removed Chimney Breast', 'Party Wall Problem'] but "order" says ['Loft Converted', 'About Roof structure', 'Water Tank', 'Insect infestation', 'Timber rot', 'Undersize timber', 'Heavy roof', 'Removed Chimney Breast', 'Party Wall Problem', 'Roof underlay', 'Roof ventilation', 'Roof insulation', 'Roof movement', 'Structural alterations']
- **F Inside Property > Walls and Partitions > Walls and Partitions** (`group_walls_and_partitions_64`): app shows ['Walls', 'Condensation', 'Dampness', 'Movement Cracks', 'Hollow plaster', 'Removed Wall'] but "order" says ['Walls', 'Condensation', 'Dampness', 'Movement Cracks', 'Removed Wall', 'Hollow plaster']
- **Capture floor/site plan sketches > Capture floor/site plan sketches** (`activity_capture_floor_site_plan_sketches`): app shows ['Capture floor/site plan sketches', 'K1 Valuation assumptions'] but "order" says ['K1 Valuation assumptions', 'Capture floor/site plan sketches']

## T1: Title style (3)

- **Outside Property > Chimney > Not Inspected** (`activity_outside_property_chimney_not_inspected`): "Not Inspected" (spellings in use: {'Not Inspected': 3, 'Not inspected': 3})
- **Outside Property > Roof Covering > Not Inspected** (`activity_outside_property_roof_not_inspected`): "Not Inspected" (spellings in use: {'Not Inspected': 3, 'Not inspected': 3})
- **F Inside Property > Roof Structure > Not Inspected** (`activity_inside_property_roof_structure_not_inspected`): "Not Inspected" (spellings in use: {'Not Inspected': 3, 'Not inspected': 3})

## E1: Empty group or screen (2)

- **F Inside Property > OutSide_Property_Other_Joinery_And_Finishes_Main_Screen_** (`group_outside_property_other_joinery_and_finishes_main_screen_80`): empty group
- **Capture floor/site plan sketches > Capture floor/site plan sketches** (`activity_capture_floor_site_plan_sketches`): screen has no answerable field
