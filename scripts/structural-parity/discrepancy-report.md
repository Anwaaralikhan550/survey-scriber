# Structural Parity Discrepancy Report

Generated: 2026-02-14T05:07:48.244Z

## Summary

| Metric | Count |
|--------|-------|
| Matched screen pairs | 311 |
| Native-only screens (not in V2) | 88 |
| V2-only screens (not in native) | 184 |
| Total discrepancies | 1184 |
| Auto-fixable | 0 |
| Manual review needed | 1184 |

## Discrepancies by Type

| # | Check | Count | Auto-fixable |
|---|-------|-------|-------------|
| 1 | Field count mismatch | 225 | 0 |
| 2 | Field order mismatch | 0 | 0 |
| 3 | Missing section headings | 0 | 0 |
| 4 | Label text mismatch | 0 | 0 |
| 5 | Dropdown option mismatch | 0 | 0 |
| 6 | Missing/wrong conditionals | 288 | 0 |
| 7 | Missing/extra field IDs | 671 | 0 |

## By Severity

- **Errors**: 500 (must fix)
- **Warnings**: 225 (should fix)
- **Info**: 459 (review)

## By Section

| Section | Screens with issues | Total discrepancies |
|---------|-------------------|-------------------|
| A | 5 | 7 |
| D | 26 | 166 |
| E | 85 | 474 |
| F | 82 | 322 |
| G | 33 | 115 |
| H | 22 | 78 |
| I | 3 | 11 |
| J | 2 | 9 |
| R | 1 | 2 |

## Auto-Fixable Discrepancies (by screen)

## Manual Review Items

#### activity_communal_garden
- **[warning]** Field count: native=47, v2=24
- **[error]** Field 'android_material_design_spinner3' (text: "Type") exists in native but missing in V2
- **[error]** Field 'android_material_design_spinner4' (text: "Boundry Fencing") exists in native but missing in V2
- **[error]** Field 'fd_Rl2' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl3' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl4' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl6' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl7' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'll5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl9' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl10' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl11' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl12' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl13' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl14' (checkbox: "") exists in native but missing in V2
- **[info]** Field 'other' (text: "Other") exists in V2 but not in native

#### activity_construction_floor
- **[warning]** Field count: native=16, v2=9
- **[error]** Field 'll2' (dropdown: "Build Type") exists in native but missing in V2
- **[error]** Field 'fd_Rl2' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl3' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl4' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl5' (checkbox: "") exists in native but missing in V2

#### activity_construction_window
- **[warning]** Field count: native=26, v2=14
- **[info]** Field 'etGlazzedTypeOther' is hidden by default in native but has no conditional in V2
- **[info]** Field 'etWindowMatirialOther' is hidden by default in native but has no conditional in V2
- **[error]** Field 'll1' (dropdown: "Glazzed With") exists in native but missing in V2
- **[error]** Field 'fd_Rl2' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl3' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl4' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl6' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl7' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl8' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl9' (checkbox: "") exists in native but missing in V2

#### activity_energy_effiency
- **[warning]** Field count: native=4, v2=2

#### activity_energy_environment_impect
- **[warning]** Field count: native=4, v2=2

#### activity_estate_location
- **[warning]** Field count: native=14, v2=12

#### activity_extended_wall
- **[warning]** Field count: native=53, v2=30
- **[error]** Field 'fd_Rl2' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl3' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl6' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl8' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl9' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl10' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl12' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl13' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl14' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl15' (checkbox: "") exists in native but missing in V2
- **[info]** Field 'etFinishesOther' (text: "Other") exists in V2 but not in native
- **[info]** Field 'etCladdingFingerOther' (text: "Other") exists in V2 but not in native

#### activity_front_garden
- **[warning]** Field count: native=50, v2=25
- **[info]** Field 'android_material_design_spinner' is hidden by default in native but has no conditional in V2
- **[info]** Field 'android_material_design_spinner2' is hidden by default in native but has no conditional in V2
- **[error]** Field 'fd_Rl2' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl3' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl4' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl6' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl7' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'll5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl9' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl10' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl11' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl12' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl13' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl14' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'android_material_design_spinner3' (text: "Type") exists in native but missing in V2
- **[error]** Field 'android_material_design_spinner4' (text: "Boundry Fencing") exists in native but missing in V2
- **[error]** Field 'android_material_design_spinner5' (text: "Type") exists in native but missing in V2
- **[error]** Field 'android_material_design_spinner6' (text: "Boundry Fencing") exists in native but missing in V2

#### activity_garden
- **[warning]** Field count: native=12, v2=15
- **[info]** Field 'label_front_garden' (label: "Front Garden") exists in V2 but not in native
- **[info]** Field 'label_rear_garden' (label: "Rear Garden") exists in V2 but not in native
- **[info]** Field 'label_communal_garden' (label: "Communal Garden") exists in V2 but not in native

#### activity_gated_community
- **[warning]** Field count: native=14, v2=12

#### activity_grounds_garage
- **[warning]** Field count: native=30, v2=23
- **[info]** Field 'cb_other_594' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_390' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_376' is hidden by default in native but has no conditional in V2
- **[info]** Field 'actv_condition' is hidden by default in native but has no conditional in V2
- **[error]** Field 'rl_tiles' (checkbox: "") exists in native but missing in V2

#### activity_grounds_garage_garage_repair
- **[warning]** Field count: native=21, v2=17
- **[error]** Field 'llMainContainer' (dropdown: "Repair Type") exists in native but missing in V2
- **[info]** Field 'actv_repair_type' (dropdown: "Repair Type") exists in V2 but not in native

#### activity_grounds_garage_main_screen
- **[warning]** Field count: native=4, v2=2
- **[error]** Field 'rl_chimney_not_inspected' (dropdown: "Condition Rating") exists in native but missing in V2

#### activity_grounds_garage_not_inspected
- **[warning]** Field count: native=3, v2=2
- **[error]** Field 'rl_not_inspected_no_garage' (checkbox: "") exists in native but missing in V2

#### activity_grounds_garage_roof_timber_repair
- **[warning]** Field count: native=9, v2=7
- **[info]** Field 'cb_other_795' is hidden by default in native but has no conditional in V2

#### activity_grounds_other_area_emf
- **[warning]** Field count: native=7, v2=5
- **[info]** Field 'cb_other_495' is hidden by default in native but has no conditional in V2

#### activity_grounds_other_area_flooding
- **[warning]** Field count: native=8, v2=6
- **[info]** Field 'cb_other_535' is hidden by default in native but has no conditional in V2

#### activity_grounds_other_area_knotweed
- **[warning]** Field count: native=6, v2=3
- **[error]** Field 'llMainContainer' (dropdown: "Status") exists in native but missing in V2
- **[error]** Field 'et_other_732' (checkbox: "") exists in native but missing in V2
- **[info]** Field 'actv_status' (dropdown: "Status") exists in V2 but not in native

#### activity_grounds_other_area_main_screen
- **[warning]** Field count: native=3, v2=2
- **[info]** Field 'ar_etNote' is hidden by default in native but has no conditional in V2

#### activity_grounds_other_area_not_inspected
- **[warning]** Field count: native=3, v2=1
- **[error]** Field 'rl_not_inspected_no_garage' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_not_inspected_no_garage' (checkbox: "") exists in native but missing in V2

#### activity_grounds_other_area_right_of_way
- **[warning]** Field count: native=10, v2=8
- **[info]** Field 'cb_other_325' is hidden by default in native but has no conditional in V2

#### activity_grounds_other_front_garden
- **[warning]** Field count: native=37, v2=30
- **[info]** Field 'cb_other_277' is hidden by default in native but has no conditional in V2
- **[error]** Field 'll5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'll_brick_lap1' (dropdown: "Roof Type") exists in native but missing in V2
- **[error]** Field 'll_brick_lap1' (dropdown: "Roof Type") exists in native but missing in V2
- **[error]** Field 'll_timber_lap1' (dropdown: "Roof Type") exists in native but missing in V2
- **[error]** Field 'll_timber_lap1' (dropdown: "Roof Type") exists in native but missing in V2
- **[info]** Field 'actv_roof_type_brick' (dropdown: "Roof Type") exists in V2 but not in native
- **[info]** Field 'actv_roof_type_timber' (dropdown: "Roof Type") exists in V2 but not in native

#### activity_grounds_other_grounds
- **[error]** Field 'llMainContainer' (dropdown: "The property is set within") exists in native but missing in V2
- **[info]** Field 'actv_type' (dropdown: "The property is set within") exists in V2 but not in native

#### activity_grounds_other_large_outbuildings
- **[warning]** Field count: native=38, v2=27
- **[info]** Field 'cb_other_1072' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_458' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_222' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_243' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_279' is hidden by default in native but has no conditional in V2
- **[info]** Field 'actv_condition' is hidden by default in native but has no conditional in V2
- **[error]** Field 'rl_tiles' (checkbox: "") exists in native but missing in V2

#### activity_grounds_other_main_screen
- **[warning]** Field count: native=4, v2=2
- **[info]** Field 'ar_etNote' is hidden by default in native but has no conditional in V2
- **[error]** Field 'rl_chimney_not_inspected' (dropdown: "Condition Rating") exists in native but missing in V2

#### activity_grounds_other_repair_fence
- **[warning]** Field count: native=19, v2=15
- **[info]** Field 'cb_other_271' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_938' is hidden by default in native but has no conditional in V2

#### activity_grounds_other_repair_shed
- **[warning]** Field count: native=14, v2=10
- **[info]** Field 'actv_shed_type' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_998' is hidden by default in native but has no conditional in V2

#### activity_grounds_shared_access
- **[warning]** Field count: native=9, v2=7
- **[info]** Field 'cb_other_190' is hidden by default in native but has no conditional in V2
- **[error]** Field 'llMainContainer' (dropdown: "Shared Status") exists in native but missing in V2
- **[info]** Field 'actv_shared_status' (dropdown: "Shared Status") exists in V2 but not in native

#### activity_inside_property_about_roof_structure
- **[warning]** Field count: native=28, v2=21
- **[info]** Field 'actv_cause' is hidden by default in native but has no conditional in V2
- **[error]** Field 'llMainContainer' (dropdown: "Construction") exists in native but missing in V2
- **[error]** Field 'cb_underlining' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'll_lap2' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'ventilationRelatedDampVisible' (checkbox: "") exists in native but missing in V2
- **[info]** Field 'actv_construction' (dropdown: "Construction") exists in V2 but not in native

#### activity_inside_property_bathroom_fittings_main_screen
- **[warning]** Field count: native=4, v2=2

#### activity_inside_property_built_in_fittings_main_screen
- **[warning]** Field count: native=4, v2=2

#### activity_inside_property_ceilings_contains_asbestos
- **[warning]** Field count: native=9, v2=7
- **[info]** Field 'cb_other_525' is hidden by default in native but has no conditional in V2

#### activity_inside_property_ceilings_cracks
- **[warning]** Field count: native=7, v2=5
- **[info]** Field 'cb_other_467' is hidden by default in native but has no conditional in V2

#### activity_inside_property_ceilings_heavy_paper_lining
- **[warning]** Field count: native=9, v2=3
- **[info]** Field 'et_other_691' is hidden by default in native but has no conditional in V2
- **[error]** Field 'cb_back_addition' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_extension' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_bay_window' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_dormer_window' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_other_601' (checkbox: "") exists in native but missing in V2

#### activity_inside_property_ceilings_main_screen
- **[warning]** Field count: native=4, v2=2

#### activity_inside_property_ceilings_not_inspected
- **[warning]** Field count: native=9, v2=3
- **[info]** Field 'et_other_691' is hidden by default in native but has no conditional in V2
- **[error]** Field 'cb_back_addition' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_extension' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_bay_window' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_dormer_window' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_other_601' (checkbox: "") exists in native but missing in V2

#### activity_inside_property_ceilings_polystyrene
- **[warning]** Field count: native=10, v2=3
- **[info]** Field 'cb_other_601' is hidden by default in native but has no conditional in V2
- **[info]** Field 'actv_assumed_type' is hidden by default in native but has no conditional in V2
- **[error]** Field 'cb_back_addition' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_extension' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_bay_window' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'cb_dormer_window' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'et_other_691' (checkbox: "") exists in native but missing in V2

#### activity_inside_property_ceilings_repairs_ceilings
- **[warning]** Field count: native=37, v2=29
- **[error]** Field 'llMainContainer' (dropdown: "Status") exists in native but missing in V2
- **[info]** Field 'actv_status' (dropdown: "Status") exists in V2 but not in native

#### activity_inside_property_ceilings_repairs_ornamental_plaster
- **[warning]** Field count: native=8, v2=6
- **[info]** Field 'cb_other_945' is hidden by default in native but has no conditional in V2

#### activity_inside_property_fireplaces_main_screen
- **[warning]** Field count: native=4, v2=2

#### activity_inside_property_floors_main_screen
- **[warning]** Field count: native=4, v2=2
- **[info]** Field 'ar_etNote' is hidden by default in native but has no conditional in V2
- **[error]** Field 'rl_chimney_not_inspected' (dropdown: "Condition Rating") exists in native but missing in V2

#### activity_inside_property_limitation
- **[warning]** Field count: native=19, v2=7
- **[info]** Field 'etGroundTypeOther' is hidden by default in native but has no conditional in V2
- **[error]** Field 'fd_Rl2' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'llVisible' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl3' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'ch3' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl4' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'ch4' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'ch5' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'fd_Rl6' (checkbox: "") exists in native but missing in V2
- **[error]** Field 'ch6' (text: "") exists in native but missing in V2
- **[error]** Field 'ch6' (text: "") exists in native but missing in V2
- **[error]** Field 'android_material_design_spinner4' (dropdown: "") exists in native but missing in V2

#### activity_inside_property_loft_converted
- **[warning]** Field count: native=8, v2=6
- **[info]** Field 'cb_other_608' is hidden by default in native but has no conditional in V2

#### activity_inside_property_other_celler_damp
- **[warning]** Field count: native=9, v2=7
- **[info]** Field 'cb_others_389' is hidden by default in native but has no conditional in V2

#### activity_inside_property_other_celler_flooded
- **[error]** Field 'llMainContainer' (dropdown: "Possible Flooded") exists in native but missing in V2
- **[info]** Field 'actv_possible_flooded' (dropdown: "Possible flooded") exists in V2 but not in native

#### activity_inside_property_other_celler_inspected
- **[error]** Field 'llMainContainer' (dropdown: "Used As") exists in native but missing in V2
- **[info]** Field 'actv_used_as' (dropdown: "Used as") exists in V2 but not in native

#### activity_inside_property_other_celler_not_habitable
- **[warning]** Field count: native=9, v2=7
- **[info]** Field 'actv_should_not_use_because_of' is hidden by default in native but has no conditional in V2
- **[info]** Field 'cb_other_697' is hidden by default in native but has no conditional in V2

#### activity_inside_property_other_celler_no_access
- **[warning]** Field count: native=7, v2=4
- **[info]** Field 'cb_other_704' is hidden by default in native but has no conditional in V2
- **[error]** Field 'rl_no_access' (checkbox: "") exists in native but missing in V2

#### activity_inside_property_other_not_inspected
- **[warning]** Field count: native=5, v2=3
- **[info]** Field 'et_other_691' is hidden by default in native but has no conditional in V2
- **[info]** Field 'actv_assumed_type' is hidden by default in native but has no conditional in V2
- **[error]** Field 'cb_extension' (checkbox: "") exists in native but missing in V2

#### activity_inside_property_repair_insect_infestation
- **[error]** Field 'llMainContainer' (dropdown: "Insect Infestation") exists in native but missing in V2
- **[info]** Field 'actv_insect_infestation' (dropdown: "Insect infestation") exists in V2 but not in native

... and 209 more screens with manual review items