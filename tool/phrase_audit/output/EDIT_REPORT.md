# SurveyScriber Report-Language Edit Report

Date: 2026-07-07

Automated line-by-line audit of every report phrase the app can
produce, verified against the approved phrase database (legacy 2018
bank + HB APP Database v5). Produced by the permutation test harness
(`test/phrase_audit/phrase_permutation_audit_test.dart`), which will
re-run on every future change to keep the report language compliant.

## 1. Executive summary

| Area | Result |
|---|---|
| Inspection screens audited | 510 |
| Inspection phrases exercised | 2598 |
| Inspection phrases matching approved bank | 2272 (87%) |
| Inspection phrases NOT from approved bank | 182 across 50 screens |
| Valuation phrases NOT from approved bank | 466 of 500 (valuation engine is not bank-driven at all) |
| Screens producing no phrase at all (gaps) | 0 |
| Screens emitting broken/ungrammatical sentences | 1 inspection + 0 valuation |
| Unresolved template tokens leaking into report | 0 screens |
| Report sections rendered sentence-per-line instead of paragraphs | 29 of 33 sections |
| Sections missing a condition rating | 2 of 26 required |
| Approved phrases updated in Database v5 but absent from app | 235 |

## 2. Paragraph structure defects (client examples: Construction, Porch)

The approved database defines which sentences belong together in one
paragraph. The current report renderer only honours this for 4 areas.
The following report sections are affected and will be fixed by
driving paragraph assembly from the database structure itself:

- **D_CONSTRUCTION** — sentence groups: CONSTRUCTION_TYPE_AREA + CONSTRUCTION_ROOF_AREA + CONSTRUCTION_EXT_WALL_AREA + CONSTRUCTION_EXT_WALL_FINISHES + CONSTRUCTION_EXT_WALL_CLADDING + CONSTRUCTION_INT_WALL_AREA + CONSTRUCTION_FLOOR_AREA + CONSTRUCTION_WINDOWS_AREA
- **D_ENERGY** — sentence groups: ENERGY_EFFICIENCY_CURRENT_VALUE + ENERGY_EFFICIENCY_POTENTIAL_VALUE; ENVIRONMENT_IMPACT_CURRENT_VALUE + ENVIRONMENT_IMPACT_POTENTIAL_VALUE
- **D_FLAT_INFORMATION** — sentence groups: FLAT_INFO_PRO_ON_FLOOR + FLAT_INFO_PRO_NO_OF_STOREY + FLAT_INFO_PRO_ACCESS_VIA + FLAT_INFO_PRO_ACCESS_ELEVATION
- **D_GROUND** — sentence groups: GROUND_PROPERTY_AREA + GROUND_TOPOGRAPHY + GROUND_FRONT_GARDEN + GROUND_REAR_GARDEN + GROUND_COMMUNAL_GARDEN + D_GROUND_PARKING_AREA + GATED_COMMUNITY + GROUND_ESTATE_LOCATION
- **D_LOCATION** — sentence groups: LOCATION_AREA + LOCATION_PRIVATE_PROPERTY_AREA + D_LOCATION_NEAR_NOISY_AREA + D_LOCATION_CONVERSATION_AREA
- **D_PROPERTY_STATUS** — sentence groups: PROPERTY_STATUS_OCCUPANCY + PROPERTY_STATUS_FURNISHING + PROPERTY_STATUS_FLOOR_COVERING
- **D_PROPERTY_TYPE_FLAT** — sentence groups: FLAT_NO_OF_BEDROOMS + FLAT_TYPE + FLAT_FLOOR_LOCATION + FLAT_NO_OF_STOREY + FLAT_TOTAL_FLATS
- **D_PROPERTY_TYPE_HOUSE** — sentence groups: HOUSE_SUB_TYPE + HOUSE_TYPE + HOUSE_NO_OF_BEDROOMS
- **D_PRO_CONVERSION_STATUS_KNOWN** — sentence groups: PRO_CONVERSION_PRO_SUB_TYPE + PRO_CONVERSION_PRO_TYPE + PRO_CONVERSION_DATE
- **D_PRO_CONVERSION_STATUS_UNKNOWN** — sentence groups: PRO_CONVERSION_PRO_SUB_TYPE + PRO_CONVERSION_PRO_TYPE
- **D_PRO_EXTENDED_STATUS_KNOWN** — sentence groups: PRO_EXTENDED_LOCATION + PRO_EXTENDED_DATE
- **D_WEATHER** — sentence groups: WEATHER_NOW + WEATHER_BEFORE
- **E_CHIMNEY_REPAIR** — sentence groups: E_CHIMNEY_FLAUNCHING_REPAIR_NOW + FLAUNCHING_REPAIR_NOW_CAUSING_DUMP; E_CHIMNEY_POTS_REPAIR_NOW + CHIMNEY_POTS_REPAIR_NOW_SAFETY_HAZARD; E_CHIMNEY_REPOINTING_REPAIR_NOW + CHIMNEY_REPOINTING_REPAIR_NOW_CAUSING_DUMP
- **E_CONSERVATORY_PORCHES** — sentence groups: LOCATION_CONSTRUCTION + CP_SAFETY_GLASS_RATING; CP_ROOF + CP_DOORS + CP_WINDOWS + CP_FLOOR + CP_CONDITION + CP_DOORS_INCORPORATES_IF_DOUBLE_SELECTED; PORCH_LOCATION_CONSTRUCTION + PORCH_SAFETY_GLASS_RATING
- **E_OTHER_JOINERY_AND_FINISHES** — sentence groups: ABOUT_OTHER_JOINERY_AND_FINISHES + CONDITION
- **E_OTHER** — sentence groups: COMMUNAL_AREA + COMMUNAL_AREA_CONDITION
- **E_RAINWATER_GOODS_RWG** — sentence groups: WEATHER_CONDITION_WET + WEATHER_CONDITION_DRY + WEATHER_CONDITION_LEAKES_NOTES; RWG_ABOUT_TYPE + RWG_ABOUT_CONDITION
- **E_ROOF_COVERING** — sentence groups: E_RC_WEATHER_CONDITION + E_RC_WEATHER_CONDITION_LEAKS_NOTED; RC_ABOUT_TYPE_PITCHED + RC_ABOUT_TYPE_PITCHED_CONDITION; RC_ABOUT_TYPE_FLAT + RC_ABOUT_TYPE_FLAT_CONDITION
- **F7_DAMAGED_LOCK** — sentence groups: DOOR_LOCKED_REPAIR_LOCATION + DOOR_LOCKED_REPAIR_DEFECT
- **F7_DOOR_SAMPLING** — sentence groups: DOORSAMPLING_REPAIR_LOCATION + DOORSAMPLING_REPAIR_DEFECT
- **F_BATHROOM_FITTINGS** — sentence groups: BATHROOM_FITTINGS_REPAIR_NOW + IF_CRACKED_OR_POORLY_SECURED_IS_SELECTED
- **F_CEILINGS** — sentence groups: ABOUT_CONSTRUCTION + ABOUT_FINISHES + ABOUT_CONDITION
- **F_FIREPLACES_AND_CHIMNEYS** — sentence groups: AN_OPEN_FIRE_LOCATION + AN_OPEN_FIRE_CONDITION; GAS_FIRE_LOCATION + GAS_FIRE_CONDITION; IMITATION_SYSTEM_LOCATION + IMITATION_SYSTEM_CONDITION
- **F_FLOORS** — sentence groups: FLOOR_CONSTRUCTION + FLOOR_COVERING + FLOOR_CONDITION
- **F_ROOF_STRUCTURE** — sentence groups: WEATHER_CONDITION + LEAKES_NOTED
- **F_WALLS_AND_PARTITIONS** — sentence groups: WALL_TYPE + WALL_FINISHES + WALL_CONDITION
- **H_GARAGE** — sentence groups: ABOUT_GARAGE_TYPE + ABOUT_GARAGE_WALLS + ABOUT_GARAGE_ROOF
- **H_OTHER** — sentence groups: OTHER_GROUNDS + OTHER_FRONT_GARDEN
- **PROPERTY_ADDRESS** — sentence groups: PROPERTY_ADDRESS_COUNTRY + PROPERTY_ADDRESS_POSTCODE

## 3. Phrases not from the approved database

### 3.1 Inspection

| Screen | Section | Sample non-approved output |
|---|---|---|
| `activity_property_roof` | D | The flat and pitched roof construction over the main building is covered in concrete, clay, natural, composite… |
| `activity_property_ground_area` | D | The property is in a residential area. |
| `activity_extended_wall` | D | Externally, the main walls are fully rendered. |
| `activity_listed_building` | D | The property is not a listed building. |
| `activity_listed_building__listed_building` | D | The property is not a listed building. |
| `activity_property_location` | D | The property is in a well established residential area. |
| `activity_property_local_environment` | D | Local environmental factors were noted but no specific adverse source was identified in the inspection data. |
| `activity_property_private_road` | D | The road outside the property is not understood to be a private road. |
| `activity_property_is_noisy_area` | D | The property is in a noisy area. |
| `activity_capture_floor_site_plan_sketches` | K | Floor/site plan sketches captured during the inspection. |
| `activity_grounds_garage_main_screen` | H | Condition rating: 1. |
| `activity_grounds_other_main_screen` | H | Condition rating: 1. |
| `activity_grounds_other_area_main_screen` | H | Condition rating: 1. |
| `activity_services_main_gas` | G | There is mains gas supply connected to the property, and the meter and control valve are located under the sta… |
| `inside_property_ceilings_about_ceilings` | F | The ceilings are made up mainly of modern plasterboard, plasterboard, lath and plaster, concrete and sample de… |
| `activity_inside_property_wap_walls` | F | The internal walls and partitions of the building are of solid, stud, lath and plaster, concrete and sample de… |
| `activity_in_side_property_floors` | F | In a property of this age, some degree of infestation to concealed areas would not be entirely unexpected. Fur… |
| `activity_in_side_property_floors_about_floor` | F | The floor(s) in the property are mainly of solid construction. The floors are covered mainly with fixed and fi… |
| `activity_inside_property_about_roof_structure` | F | The roof structure is built of traditional cut timber construction. The underlining of the roof is installed w… |
| `activity_inside_property_roof_structure_main_screen` | F | Condition rating: 1. |
| `activity_inside_property_ceilings_main_screen` | F | Condition rating: 1. |
| `activity_inside_property_walls_and_partitions_main_screen` | F | Condition rating: 1. |
| `activity_inside_property_floors_main_screen` | F | Condition rating: 1. |
| `activity_no_of_rooms` | R | Lower Ground floor: 5 living rooms. |
| `activity_no_of_rooms__ground` | R | Ground floor: 5 living rooms. |
| `activity_no_of_rooms__first` | R | First floor: 5 living rooms. |
| `activity_no_of_rooms__second` | R | Second floor: 5 living rooms. |
| `activity_no_of_rooms__third` | R | Third floor: 5 living rooms. |
| `activity_no_of_rooms__other` | R | Other floor: 5 living rooms. |
| `activity_no_of_rooms__roof_space` | R | Roof Space floor: 5 living rooms. |
| `activity_issues_regulation` | I | You should ask your legal adviser to confirm whether the property has a warranty certificate, what portion of … |
| `activity_issues_other_matters` | I | Your legal adviser should be asked to verify the legal position and advice upon the implications of boundaries… |
| `activity_risks_risk_to_building_` | J | There are signs that the property appears to be affected by minor subsidence as evidenced by stepped cracking.… |
| `activity_risks_repair_or_improve` | J | As regards wants of repair, you are most strongly advised to obtain competitive quotations from reputable cont… |
| `activity_outside_property_roof_covering_main` | E | Condition Rating: 1 |
| `activity_outside_property_main_walls_about_wall` | E | The main external walls to the main building, back addition, extension and sample detail are built of sample d… |
| `activity_outside_property_out_side_doors_about_doors` | E | You should ask your legal adviser to check whether the doors have been installed by a contractor registered wi… |
| `activity_outside_property_main_walls_about_wall__cavity_brick_wall` | E | The main external walls to the main building, back addition, extension and sample detail are built of sample d… |
| `activity_outside_property_out_side_doors_about_doors__timber` | E | You should ask your legal adviser to check whether the doors have been installed by a contractor registered wi… |
| `activity_outside_property_main_walls_damp` | E | Dampness: |
| … | … | *(+10 further screens — see inspection_audit.json)* |

### 3.2 Valuation

The valuation phrase engine does not read the approved database at
all: 466 of 500 generated phrases have no
database source. Recommendation: rebuild valuation phrasing on the
same bank-driven mechanism as inspection.

## 4. Broken sentences and empty-slot defects

Sentences produced with missing values (e.g. *"it was occupied and
."*, *"There is a brick to the of the property"*, *"are pvc ."*).
These occur when a template is emitted although a dependent answer is
empty. Fix: suppress or reduce the sentence when a slot is empty.

| Screen | Section | Issues | Sample |
|---|---|---|---|
| `activity_outside_property_conservatory_porch_roof__roof` | E | covered_in_floor_above | The roof over the porch is pitched and covered in floor above, pvc double glazed sections,… |

## 5. Screens generating no phrase (gaps)


## 6. Condition rating coverage

The approved database requires an explicit condition rating in 26 sections.
- **E_MAIN_WALLS_REPAIR** — 11 matching screens, none carries a condition-rating field (MISSING)
- **E_WINDOWS_REPAIR** — 10 matching screens, none carries a condition-rating field (MISSING)

## 7. Database v5 reconciliation

235 phrases in HB APP Database v5 have no
match in the app's current bank — the approved language has been
revised since the original migration. Each needs client sign-off and
import (full list: excel_v5_diff.json / .md).

## 8. How this audit stays current

- `flutter test test/phrase_audit/phrase_permutation_audit_test.dart`
  regenerates sections 3-5 on demand (runs in ~20 s).
- `python tool/phrase_audit/paragraph_structure_audit.py`,
  `condition_rating_audit.py`, `excel_v5_diff.py` cover sections 2,
  6, 7.
- `python tool/phrase_audit/generate_edit_report.py` rebuilds this
  document.

