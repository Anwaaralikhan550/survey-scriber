import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/voice_text_field.dart';
import '../../domain/models/inspection_models.dart';

List<InspectionFieldDefinition> sanitizeInspectionFieldsForScreen(
  String screenId,
  List<InspectionFieldDefinition> fields,
) {
  if (screenId == 'activity_outside_property_conservatory_porch_roof') {
    return fields
        .where((field) =>
            field.id != 'actv_conservatory_porch' &&
            field.id != 'cb_floor_above')
        .toList();
  }
  if (screenId == 'activity_outside_property_conservatory_porch_roof__roof') {
    return fields
        .where((field) => field.id != 'actv_conservatory_porch')
        .toList();
  }
  if (screenId == 'activity_outside_property_conservatory_porch_doors') {
    return fields
        .where((field) => field.id != 'actv_conservatory_porch')
        .toList();
  }
  if (screenId == 'activity_outside_property_conservatory_porch_doors__doors') {
    return fields
        .where((field) => field.id != 'actv_conservatory_porch')
        .toList();
  }
  if (screenId == 'activity_outside_property_conservatory_porch_windows') {
    return fields
        .where((field) => field.id != 'actv_conservatory_porch')
        .toList();
  }
  if (screenId ==
      'activity_outside_property_conservatory_porch_windows__windows') {
    return fields
        .where((field) => field.id != 'actv_conservatory_porch')
        .toList();
  }
  if (screenId ==
          'activity_outside_property_conservatory_porch_safety_glass_rating' ||
      screenId ==
          'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating' ||
      screenId == 'activity_outside_property_porch_open_to_building' ||
      screenId ==
          'activity_outside_property_porch_open_to_building__open_to_building' ||
      screenId == 'activity_outside_property_porch_poor_condition' ||
      screenId ==
          'activity_outside_property_porch_poor_condition__poor_condition') {
    return fields.where((field) => field.id != 'actv_condition').toList();
  }
  if (screenId ==
      'activity_outside_property_conservatory_porch_not_inspected') {
    return fields
        .where((field) =>
            field.id == 'cb_main_building' || field.id == 'cb_back_addition')
        .toList();
  }
  if (screenId == 'activity_outside_property_other_not_inspected') {
    return fields.where((field) => field.id == 'cb_not_inspected').toList();
  }
  if (screenId == 'activity_inside_property_other_not_inspected') {
    // Legacy parity: only one "Not inspected" checkbox.
    return fields.where((field) => field.id == 'cb_not_inspected').toList();
  }
  if (screenId == 'activity_services_water_main_screen') {
    // Legacy parity: Water screen should include stopcock/lead controls
    // plus condition rating and note.
    final byId = <String, InspectionFieldDefinition>{
      for (final field in fields) field.id: field,
    };
    InspectionFieldDefinition? f(String id) => byId[id];

    return <InspectionFieldDefinition>[
      f('cb_stopcock_found') ??
          const InspectionFieldDefinition(
            id: 'cb_stopcock_found',
            label: 'Main water stopcock found',
            type: InspectionFieldType.checkbox,
          ),
      f('actv_stopcok_location') ??
          const InspectionFieldDefinition(
            id: 'actv_stopcok_location',
            label: 'Main water stopcock location',
            type: InspectionFieldType.dropdown,
            options: <String>[
              'Front',
              'Side',
              'Rear',
              'Other',
            ],
            conditionalOn: 'cb_stopcock_found=true',
            conditionalValue: '',
            conditionalMode: 'show',
          ),
      f('cb_lead_rising') ??
          const InspectionFieldDefinition(
            id: 'cb_lead_rising',
            label: 'Lead rising main',
            type: InspectionFieldType.checkbox,
          ),
      if (f('android_material_design_spinner4') != null)
        f('android_material_design_spinner4')!,
      if (f('ar_etNote') != null) f('ar_etNote')!,
    ];
  }
  if (screenId == 'activity_services_heating_main_screen') {
    // Legacy parity: collapsed Heating menu keeps the detailed "About Heating"
    // controls on this screen.
    final byId = <String, InspectionFieldDefinition>{
      for (final field in fields) field.id: field,
    };
    InspectionFieldDefinition? f(String id) => byId[id];

    return <InspectionFieldDefinition>[
      const InspectionFieldDefinition(
        id: 'cb_not_inspected',
        label: 'Not Inspected',
        type: InspectionFieldType.checkbox,
      ),
      const InspectionFieldDefinition(
        id: 'cb_no_heating',
        label: 'No Heating',
        type: InspectionFieldType.checkbox,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'cb_communal_heating',
        label: 'Communal Heating',
        type: InspectionFieldType.checkbox,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'label_other_heating',
        label: 'Other Heating',
        type: InspectionFieldType.label,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'cb_oil_filled',
        label: 'Oil filled',
        type: InspectionFieldType.checkbox,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'cb_electric_storage',
        label: 'Electric storage',
        type: InspectionFieldType.checkbox,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'cb_convector',
        label: 'Convector',
        type: InspectionFieldType.checkbox,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'cb_other_923',
        label: 'Other',
        type: InspectionFieldType.checkbox,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'et_other_717',
        label: 'Other',
        type: InspectionFieldType.text,
        conditionalOn: 'cb_other_923 & !cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'label_property_heated_by',
        label: 'Property heated by',
        type: InspectionFieldType.label,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'actv_boiler',
        label: 'Boiler',
        type: InspectionFieldType.dropdown,
        options: <String>[
          'Combination boiler',
          'Conventional boiler',
          'Condensing boiler',
          'Conventional boiler combined with tank',
          'Other',
        ],
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'actv_location',
        label: 'Location',
        type: InspectionFieldType.dropdown,
        options: <String>[
          'Kitchen',
          'Utility',
          'Bedroom',
          'Garage',
          'Lounge',
          'Chimney breast',
          'Other',
        ],
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'label_boiler_flue',
        label: 'Boiler Flue Connected To',
        type: InspectionFieldType.label,
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'actv_location_new',
        label: 'Location',
        type: InspectionFieldType.dropdown,
        options: <String>[
          'Sidewall',
          'Roof covering',
          'Chimney',
          'Other',
        ],
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'actv_condition',
        label: 'Condition',
        type: InspectionFieldType.dropdown,
        options: <String>[
          'Reasonable',
          'Satisfactory',
          'Unsatisfactory and Poor',
        ],
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'actv_connected_heat',
        label: 'Connected heat emitters',
        type: InspectionFieldType.dropdown,
        options: <String>[
          'Radiators',
          'Underfloor pipes',
          'Other',
        ],
        conditionalOn: '!cb_not_inspected',
      ),
      const InspectionFieldDefinition(
        id: 'cb_old_boiler',
        label: 'Old Boiler',
        type: InspectionFieldType.checkbox,
        conditionalOn: '!cb_not_inspected',
      ),
      if (f('android_material_design_spinner4') != null)
        f('android_material_design_spinner4')!,
      if (f('ar_etNote') != null) f('ar_etNote')!,
    ];
  }
  if (screenId == 'activity_inside_property_ceilings_not_inspected') {
    // Legacy parity: this screen has only one field ("Not inspected").
    return fields.where((field) => field.id == 'cb_not_inspected').toList();
  }
  if (screenId == 'activity_in_side_property_fire_places') {
    // Legacy parity: "An open fire" should not include the fire-type list.
    const blockedIds = <String>{
      'other',
      'label_fire_type',
      'cb_flues_not_inspected',
      'cb_an_open_fire',
      'cb_gas_fire',
      'cb_imitation_system',
      'cb_wood_burning_stove',
      'cb_electric_fire',
      'cb_other_316',
      'et_other_633',
    };
    return fields
        .where((field) => !blockedIds.contains(field.id))
        .map((field) => field.id == 'actv_condition'
            ? field.copyWith(label: 'Condition')
            : field)
        .toList();
  }
  if (screenId == 'activity_in_side_property_fire_places_repair_boiler_flue') {
    // Legacy parity: this dropdown label is explicit in legacy app.
    return fields
        .map((field) => field.id == 'actv_flue_discharges_through'
            ? field.copyWith(label: 'Fire discharges through')
            : field)
        .toList();
  }
  if (screenId == 'activity_in_side_property_bathroom_fittings_second') {
    // Legacy parity: the quality dropdown label should be "Condition".
    return fields
        .map((field) => field.id == 'android_material_design_spinner3'
            ? field.copyWith(label: 'Condition')
            : field)
        .toList();
  }
  if (screenId == 'activity_in_side_property_bathroom_fittings_extractor_fan') {
    // Legacy parity: show only Condition first; reveal rest by OK/Replace.
    final byId = <String, InspectionFieldDefinition>{
      for (final field in fields) field.id: field,
    };
    InspectionFieldDefinition? f(String id) => byId[id];

    final result = <InspectionFieldDefinition>[
      if (f('actv_status') != null)
        f('actv_status')!.copyWith(label: 'Condition'),
      if (f('label_fan_location_3') != null)
        f('label_fan_location_3')!.copyWith(
          conditionalOn: 'actv_status=OK | actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_bathroom_56') != null)
        f('cb_bathroom_56')!.copyWith(
          conditionalOn: 'actv_status=OK | actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_shower_room_100') != null)
        f('cb_shower_room_100')!.copyWith(
          conditionalOn: 'actv_status=OK | actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_en_suite_bathroom_101') != null)
        f('cb_en_suite_bathroom_101')!.copyWith(
          conditionalOn: 'actv_status=OK | actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_en_suite_shower_room_81') != null)
        f('cb_en_suite_shower_room_81')!.copyWith(
          conditionalOn: 'actv_status=OK | actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_separate_toilet_99') != null)
        f('cb_separate_toilet_99')!.copyWith(
          conditionalOn: 'actv_status=OK | actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_other_725') != null)
        f('cb_other_725')!.copyWith(
          conditionalOn: 'actv_status=OK | actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('et_other_631') != null)
        f('et_other_631')!.copyWith(
          conditionalOn:
              'actv_status=OK & cb_other_725 | actv_status=Replace & cb_other_725',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('label_tested') != null)
        f('label_tested')!.copyWith(
          conditionalOn: 'actv_status=OK',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_was_switched_on_and_it_was_35') != null)
        f('cb_was_switched_on_and_it_was_35')!.copyWith(
          conditionalOn: 'actv_status=OK',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_were_switched_on_and_were_64') != null)
        f('cb_were_switched_on_and_were_64')!.copyWith(
          conditionalOn: 'actv_status=OK',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_other_1068') != null)
        f('cb_other_1068')!.copyWith(
          conditionalOn: 'actv_status=OK',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('et_other_297') != null)
        f('et_other_297')!.copyWith(
          conditionalOn: 'actv_status=OK & cb_other_1068',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('label_defect_70') != null)
        f('label_defect_70')!.copyWith(
          conditionalOn: 'actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_was_not_working') != null)
        f('cb_was_not_working')!.copyWith(
          conditionalOn: 'actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_has_blocked_vent') != null)
        f('cb_has_blocked_vent')!.copyWith(
          conditionalOn: 'actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_is_too_small') != null)
        f('cb_is_too_small')!.copyWith(
          conditionalOn: 'actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_has_weak_suction') != null)
        f('cb_has_weak_suction')!.copyWith(
          conditionalOn: 'actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_other_987') != null)
        f('cb_other_987')!.copyWith(
          conditionalOn: 'actv_status=Replace',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('et_other_368') != null)
        f('et_other_368')!.copyWith(
          conditionalOn: 'actv_status=Replace & cb_other_987',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
    ];
    return result;
  }
  if (screenId == 'activity_in_side_property_bathroom_fittings_sealant') {
    // Legacy parity: keep this defect item as "Damaged" only.
    return fields
        .map((field) =>
            field.id == 'cb_damaged_partly_missing_poorly_applied_76'
                ? field.copyWith(label: 'Damaged')
                : field)
        .toList();
  }
  if (screenId == 'activity_in_side_property_other_communal_area') {
    // Legacy parity: inspected-state dropdown is "Condition".
    return fields
        .map((field) => field.id == 'actv_condition'
            ? field.copyWith(label: 'Condition')
            : field)
        .toList();
  }
  if (screenId == 'activity_in_side_property_built_in_fittings') {
    // Legacy parity: quality dropdown should be labeled Condition.
    return fields
        .map((field) => field.id == 'android_material_design_spinner3'
            ? field.copyWith(label: 'Condition')
            : field)
        .toList();
  }
  if (screenId.contains('activity_in_side_property_wood_work_second')) {
    // Legacy parity: keep only "made up of" fields and condition.
    const allowedIds = <String>{
      'label_made_up_of_2',
      'cb_doors',
      'cb_architraves',
      'cb_stairs',
      'cb_stairs_threads',
      'cb_handrails',
      'cb_balusters',
      'cb_skirting_boards',
      'cb_cladding',
      'cb_other_410',
      'et_other_800',
      'actv_condition',
    };
    return fields
        .where((field) => allowedIds.contains(field.id))
        .map((field) => field.id == 'actv_condition'
            ? field.copyWith(label: 'Condition')
            : field)
        .toList();
  }
  if (screenId == 'activity_in_side_property_wood_work' ||
      screenId.startsWith('activity_in_side_property_wood_work__')) {
    // Legacy parity: keep only native main wood-work controls.
    const allowedIds = <String>{
      'label_woodwork',
      'label_fittedbuiltin_cupboards',
      'label_damaged_lock',
      'cb_Door_sampling',
      'cb_out_of_square_doors',
      'cb_glazed_internal_doors',
      'cb_creaking_stairs',
      'cb_stairs_handrails',
      'cb_no_stairs_handrails',
      'cb_open_threads',
    };
    return fields.where((field) => allowedIds.contains(field.id)).toList();
  }
  if (screenId.startsWith('activity_inside_property_wap_not_inspected')) {
    // Legacy parity: walls & partitions not inspected has one checkbox only.
    return fields.where((field) => field.id == 'cb_not_inspected').toList();
  }
  if (screenId.startsWith('activity_inside_property_about_roof_structure')) {
    // Legacy parity: drop inactive/hidden extras from XML.
    return fields
        .where((field) =>
            field.id != 'cb_underlining' &&
            field.id != 'actv_cause' &&
            field.id != 'label_ventilation')
        .map((field) => field.id == 'actv_roof_structure_condition'
            ? field.copyWith(label: 'Roof Structure Condition')
            : field)
        .toList();
  }
  if (screenId.startsWith('activity_inside_property_water_tank')) {
    // Legacy parity: hide controls marked gone in XML.
    return fields
        .where((field) =>
            field.id != 'label_remove_defects' && field.id != 'cb_defect')
        .map((field) => field.id == 'actv_tank_condition'
            ? field.copyWith(label: 'Tank Condition')
            : field)
        .toList();
  }
  if (screenId.startsWith('activity_inside_property_wap_walls')) {
    // Legacy parity: the final dropdown is Condition, not Other.
    return fields
        .map((field) => field.id == 'actv_condition'
            ? field.copyWith(label: 'Condition')
            : field)
        .toList();
  }
  if (screenId.startsWith('activity_in_side_property_wap_dampness')) {
    // Legacy parity: keep only legacy dampness fields and visibility flow.
    final byId = <String, InspectionFieldDefinition>{
      for (final field in fields) field.id: field,
    };

    InspectionFieldDefinition? f(String id) => byId[id];

    final result = <InspectionFieldDefinition>[
      if (f('damp_status') != null) f('damp_status')!,
      if (f('et_location') != null)
        f('et_location')!.copyWith(
          conditionalOn: 'damp_status=Present',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('label_eg_lower_walls_in_the_kitchen') != null)
        f('label_eg_lower_walls_in_the_kitchen')!.copyWith(
          conditionalOn: 'damp_status=Present',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('label_cause') != null)
        f('label_cause')!.copyWith(
          conditionalOn: 'damp_status=Present',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('actv_status_91') != null)
        f('actv_status_91')!.copyWith(
          conditionalOn: 'damp_status=Present',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('label_caused_by_4') != null)
        f('label_caused_by_4')!.copyWith(
          conditionalOn: 'damp_status=Present & actv_status_91=Known',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_blocked_gullies') != null)
        f('cb_blocked_gullies')!.copyWith(
          conditionalOn: 'damp_status=Present & actv_status_91=Known',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_leaking_pipes') != null)
        f('cb_leaking_pipes')!.copyWith(
          conditionalOn: 'damp_status=Present & actv_status_91=Known',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_defective_rainwater_goods') != null)
        f('cb_defective_rainwater_goods')!.copyWith(
          conditionalOn: 'damp_status=Present & actv_status_91=Known',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_bridged_damp_proof_course') != null)
        f('cb_bridged_damp_proof_course')!.copyWith(
          conditionalOn: 'damp_status=Present & actv_status_91=Known',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_rising_damp') != null)
        f('cb_rising_damp')!.copyWith(
          conditionalOn: 'damp_status=Present & actv_status_91=Known',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_other') != null)
        f('cb_other')!.copyWith(
          conditionalOn: 'damp_status=Present & actv_status_91=Known',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('et_other_839') != null)
        f('et_other_839')!.copyWith(
          conditionalOn:
              'damp_status=Present & actv_status_91=Known & cb_other',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
    ];

    return result;
  }
  if (screenId.startsWith('activity_in_side_property_wap_removed_wall')) {
    // Product decision: non-repair Removed Wall should not have condition split.
    final byId = <String, InspectionFieldDefinition>{
      for (final field in fields) field.id: field,
    };
    InspectionFieldDefinition? f(String id) => byId[id];

    InspectionFieldDefinition alwaysVisible(String id) {
      final field = f(id);
      if (field == null) {
        return const InspectionFieldDefinition(
          id: '',
          label: '',
          type: InspectionFieldType.text,
        );
      }
      return field.copyWith(
        conditionalOn: '',
        conditionalValue: '',
        conditionalMode: 'show',
      );
    }

    final result = <InspectionFieldDefinition>[
      alwaysVisible('cb_lounge'),
      alwaysVisible('cb_bedroom'),
      alwaysVisible('cb_kitchen'),
      alwaysVisible('cb_bathroom'),
      alwaysVisible('cb_other_752'),
      if (f('et_other_666') != null)
        f('et_other_666')!.copyWith(
          conditionalOn: 'cb_other_752=true',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
    ].where((field) => field.id.isNotEmpty).toList();

    return result;
  }
  if (screenId.startsWith('activity_inside_property_floors_main_screen')) {
    // Legacy parity: no standalone "Floors" row on this header-style screen.
    final filtered = fields
        .where((field) =>
            field.id != 'label_floors' &&
            field.label.trim().toLowerCase() != 'floors')
        .toList();
    final seen = <String>{};
    var olderSeen = false;
    final deduped = <InspectionFieldDefinition>[];
    for (final field in filtered) {
      if (field.label.trim().toLowerCase() == 'timber floor older properties') {
        if (olderSeen) continue;
        olderSeen = true;
      }
      if (!seen.add(field.id)) continue;
      deduped.add(field);
    }
    return deduped;
  }
  if (screenId.startsWith('activity_in_side_property_floors_about_floor')) {
    // Legacy parity: last dropdown is "Condition", not "Other".
    return fields
        .map((field) => field.id == 'actv_condition'
            ? field.copyWith(label: 'Condition')
            : field)
        .toList();
  }
  if (screenId.contains('floors_dampness')) {
    // Legacy parity: no damp-meter fields on Floors > Dampness.
    final byId = <String, InspectionFieldDefinition>{
      for (final field in fields) field.id: field,
    };
    InspectionFieldDefinition? f(String id) => byId[id];

    final result = <InspectionFieldDefinition>[
      if (f('actv_status') != null) f('actv_status')!,
      if (f('label_location_34') != null)
        f('label_location_34')!.copyWith(
          conditionalOn: 'actv_status=known cause',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_kitchen') != null) f('cb_kitchen')!,
      if (f('cb_bathroom_s') != null) f('cb_bathroom_s')!,
      if (f('cb_toilet_s') != null) f('cb_toilet_s')!,
      if (f('cb_utility_room') != null) f('cb_utility_room')!,
      if (f('cb_other_240') != null) f('cb_other_240')!,
      if (f('et_other_392') != null) f('et_other_392')!,
      if (f('label_caused_by') != null)
        f('label_caused_by')!.copyWith(
          conditionalOn: 'actv_status=known cause',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (f('cb_faulty_plumbing') != null) f('cb_faulty_plumbing')!,
      if (f('cb_bathtub_spillage') != null) f('cb_bathtub_spillage')!,
      if (f('cb_leaking_sealants') != null) f('cb_leaking_sealants')!,
      if (f('cb_other_215') != null) f('cb_other_215')!,
      if (f('et_other_358') != null) f('et_other_358')!,
    ];

    return result;
  }
  if (screenId == 'activity_in_side_property_floors') {
    // Legacy parity: this screen should not show a standalone "Floors" field.
    final filtered = fields
        .where((field) =>
            field.id != 'label_floors' &&
            field.label.trim().toLowerCase() != 'floors')
        .toList();
    final seen = <String>{};
    var olderSeen = false;
    final deduped = <InspectionFieldDefinition>[];
    for (final field in filtered) {
      if (field.label.trim().toLowerCase() == 'timber floor older properties') {
        if (olderSeen) continue;
        olderSeen = true;
      }
      if (!seen.add(field.id)) continue;
      deduped.add(field);
    }
    return deduped;
  }
  if (screenId.startsWith('activity_inside_property_ceilings_polystyrene')) {
    // Legacy parity: only "Parts are covered with polystyrene" checkbox exists.
    return fields.where((field) => field.id == 'cb_not_inspected').toList();
  }
  if (screenId
      .startsWith('activity_inside_property_ceilings_heavy_paper_lining')) {
    // Legacy parity: only "Heavy paper lining" checkbox exists.
    return fields.where((field) => field.id == 'cb_not_inspected').toList();
  }
  if (screenId ==
          'activity_outside_property_other_joinery_finishes_not_inspected' ||
      screenId ==
          'activity_outside_property_other_joinery_finishes_not_inspected__not_inspected') {
    return fields.where((field) => field.id == 'cb_not_inspected').toList();
  }
  if (screenId == 'activity_outside_property_other_communal_area') {
    final byId = <String, InspectionFieldDefinition>{
      for (final field in fields) field.id: field,
    };

    InspectionFieldDefinition withInspectedGate(String id) {
      final field = byId[id];
      if (field == null) {
        return const InspectionFieldDefinition(
          id: '',
          label: '',
          type: InspectionFieldType.text,
        );
      }
      return field.copyWith(
        conditionalOn: 'actv_status=Inspected',
        conditionalValue: '',
        conditionalMode: 'show',
      );
    }

    InspectionFieldDefinition withNotInspectedGate(String id) {
      final field = byId[id];
      if (field == null) {
        return const InspectionFieldDefinition(
          id: '',
          label: '',
          type: InspectionFieldType.text,
        );
      }
      return field.copyWith(
        conditionalOn: 'actv_status=Not Inspected',
        conditionalValue: '',
        conditionalMode: 'show',
      );
    }

    final sanitized = <InspectionFieldDefinition>[
      if (byId['actv_status'] != null) byId['actv_status']!,
      withInspectedGate('label_external_communal_parts'),
      withInspectedGate('cb_automatic_gates'),
      withInspectedGate('cb_cctv'),
      withInspectedGate('cb_communal_door'),
      withInspectedGate('cb_entry_system'),
      withInspectedGate('cb_drive_access'),
      withInspectedGate('cb_car_park'),
      withInspectedGate('cb_walk_paths'),
      withInspectedGate('cb_gardens'),
      withInspectedGate('cb_grounds'),
      withInspectedGate('cb_play_ground'),
      withInspectedGate('cb_other_1034'),
      if (byId['et_other_747'] != null)
        byId['et_other_747']!.copyWith(
          conditionalOn: 'actv_status=Inspected&cb_other_1034=true',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      if (byId['actv_condition'] != null)
        byId['actv_condition']!.copyWith(
          label: 'Condition',
          conditionalOn: 'actv_status=Inspected',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
      withNotInspectedGate('label_because_of'),
      withNotInspectedGate('cb_the_area_is_not_accessible'),
      withNotInspectedGate('cb_of_limited_access'),
      withNotInspectedGate('cb_other_251'),
      if (byId['et_other_928'] != null)
        byId['et_other_928']!.copyWith(
          conditionalOn: 'actv_status=Not Inspected&cb_other_251=true',
          conditionalValue: '',
          conditionalMode: 'show',
        ),
    ].where((f) => f.id.isNotEmpty && f.label.isNotEmpty).toList();

    return sanitized;
  }
  if (screenId ==
          'activity_outside_property_other_joinery_and_finishes_main_screen' ||
      screenId ==
          'activity_outside_property_other_about_joinery_and_finishes' ||
      screenId ==
          'activity_outside_property_other_joinery_finishes_condition' ||
      screenId ==
          'activity_outside_property_other_about_joinery_and_finishes__other_joinery_and_finishes') {
    return fields
        .map((field) => field.id == 'actv_condition'
            ? field.copyWith(
                label: 'Condition Rating',
                options: const ['1', '2', '3'],
              )
            : field)
        .toList();
  }
  if (screenId.startsWith('activity_outside_property_other_other_external')) {
    // Legacy layout keeps the Area dropdown hidden for these screens.
    return fields.where((field) => field.id != 'actv_area').toList();
  }
  if (screenId.startsWith('activity_outside_property_other_other_wall')) {
    // Legacy layout keeps wall-location hidden for these screens.
    return fields.where((field) => field.id != 'actv_area').toList();
  }
  if (screenId.startsWith('activity_outside_property_other_floors')) {
    // Legacy layout keeps wall-location hidden for these screens.
    return fields.where((field) => field.id != 'actv_area').toList();
  }
  if (screenId.startsWith('activity_outside_property_other_drains')) {
    // Legacy layout keeps drains location and condition hidden.
    return fields
        .where((field) =>
            field.id != 'actv_drains_location' && field.id != 'actv_condition')
        .toList();
  }
  if (screenId.startsWith('activity_outside_property_other_repairs_wall')) {
    // Legacy layout keeps repair wall location hidden.
    return fields.where((field) => field.id != 'actv_location').toList();
  }
  if (screenId.startsWith('activity_outside_property_other_handrails')) {
    // Legacy layout keeps wall-location hidden.
    return fields.where((field) => field.id != 'actv_area').toList();
  }
  if (screenId
      .startsWith('activity_outside_property_other_repairs_hand_rails')) {
    // Legacy layout hides the first "Handrail defect" block completely.
    return fields
        .where((field) =>
            field.id != 'cb_not_strong_enough' &&
            field.id != 'cb_inadequately_designed' &&
            !field.id.startsWith('label_handrail_defect'))
        .toList();
  }
  if (screenId.startsWith('activity_outside_property_other_no_safety_glass')) {
    // Legacy layout keeps glazing-location hidden.
    return fields.where((field) => field.id != 'actv_condition').toList();
  }
  if (screenId.startsWith('activity_outside_property_other_other_roof')) {
    // Legacy layout keeps roof location and condition hidden.
    return fields
        .where((field) =>
            field.id != 'actv_roof_location' && field.id != 'actv_condition')
        .toList();
  }
  return fields;
}

bool shouldShowInspectionField(
  InspectionFieldDefinition field,
  Map<String, String> answers,
) {
  final controller = field.conditionalOn;
  if (controller == null || controller.isEmpty) return true;

  if (controller.contains('&') ||
      controller.contains('|') ||
      controller.contains('!')) {
    final expr = controller;
    final groups = expr
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    bool evalToken(String token) {
      var key = token.trim();
      var negate = false;
      if (key.startsWith('!')) {
        negate = true;
        key = key.substring(1).trim();
      }
      var truthy = false;
      if (key.contains('=')) {
        final parts = key.split('=');
        final fieldKey = parts.first.trim();
        final expected = parts.sublist(1).join('=').trim().toLowerCase();
        final rawValue = (answers[fieldKey] ?? '').trim().toLowerCase();
        final normalized =
            rawValue.isEmpty && expected == 'false' ? 'false' : rawValue;
        truthy = normalized == expected;
      } else {
        final rawValue = answers[key] ?? '';
        truthy =
            rawValue.trim().isNotEmpty && rawValue.toLowerCase() != 'false';
      }
      return negate ? !truthy : truthy;
    }

    bool evalGroup(String group) {
      final tokens = group
          .split('&')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (tokens.isEmpty) return true;
      for (final token in tokens) {
        if (!evalToken(token)) return false;
      }
      return true;
    }

    final matched = groups.isEmpty ? evalGroup(expr) : groups.any(evalGroup);
    final mode = (field.conditionalMode ?? 'show').toLowerCase();
    return mode == 'hide' ? !matched : matched;
  }

  if (controller.contains('=')) {
    final parts = controller.split('=');
    final fieldKey = parts.first.trim();
    final expected = parts.sublist(1).join('=').trim().toLowerCase();
    final rawValue = (answers[fieldKey] ?? '').trim().toLowerCase();
    final normalized =
        rawValue.isEmpty && expected == 'false' ? 'false' : rawValue;
    final matched = normalized == expected;
    final mode = (field.conditionalMode ?? 'show').toLowerCase();
    return mode == 'hide' ? !matched : matched;
  }

  final rawValue = answers[controller] ?? '';
  final expected = field.conditionalValue;
  final mode = (field.conditionalMode ?? 'show').toLowerCase();
  if (expected == null || expected.isEmpty) {
    final matched =
        rawValue.trim().isNotEmpty && rawValue.toLowerCase() != 'false';
    return mode == 'hide' ? !matched : matched;
  }

  final normalizedValue = rawValue.trim().toLowerCase();
  final candidates = expected
      .split(RegExp(r'[|,]'))
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();
  if (candidates.isEmpty) return true;
  final effectiveValue = normalizedValue.isEmpty && candidates.contains('false')
      ? 'false'
      : normalizedValue;
  final matched = candidates.contains(effectiveValue);
  return mode == 'hide' ? !matched : matched;
}

/// Removes label fields that have no visible interactive field after them
/// before the next label (or end of list).
///
/// Works on an already-filtered list (post-[shouldShowInspectionField]) so
/// conditional visibility is already accounted for.
List<InspectionFieldDefinition> filterLonelyLabels(
  List<InspectionFieldDefinition> visibleFields,
) {
  if (visibleFields.isEmpty) return visibleFields;

  final keep = List<bool>.filled(visibleFields.length, true);

  for (var i = 0; i < visibleFields.length; i++) {
    if (visibleFields[i].type != InspectionFieldType.label) continue;

    // Keep the label only if the next visible field is interactive (non-label).
    final next = i + 1 < visibleFields.length ? visibleFields[i + 1] : null;
    if (next == null || next.type == InspectionFieldType.label) {
      keep[i] = false;
    }
  }

  return [
    for (var i = 0; i < visibleFields.length; i++)
      if (keep[i]) visibleFields[i],
  ];
}

class InspectionFieldInput extends StatelessWidget {
  const InspectionFieldInput({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final InspectionFieldDefinition field;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
      ),
    );

    switch (field.type) {
      case InspectionFieldType.label:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.label_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  field.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      case InspectionFieldType.checkbox:
        final checked = value.toLowerCase() == 'true' || value == '1';
        return Material(
          color: checked
              ? theme.colorScheme.primaryContainer.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onChanged(checked ? 'false' : 'true'),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: checked
                      ? theme.colorScheme.primary.withOpacity(0.4)
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: checked,
                      onChanged: (next) =>
                          onChanged(next == true ? 'true' : 'false'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case InspectionFieldType.dropdown:
        final options = field.options ?? const <String>[];
        if (options.isEmpty) {
          return TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              labelText: field.label,
              prefixIcon: Icon(
                Icons.list_alt_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              border: fieldBorder,
              enabledBorder: fieldBorder,
            ),
            onChanged: onChanged,
          );
        }
        return _InspectionDropdown(
          label: field.label,
          value: value,
          options: options,
          onChanged: onChanged,
        );
      case InspectionFieldType.number:
        return TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: Icon(
              Icons.numbers_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: fieldBorder,
            enabledBorder: fieldBorder,
          ),
          onChanged: onChanged,
        );
      case InspectionFieldType.text:
        return VoiceTextFormField(
          initialValue: value,
          labelText: field.label,
          prefixIcon: Icon(
            Icons.short_text_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          fieldBorder: fieldBorder,
          onChanged: onChanged,
        );
    }
  }
}

/// A polished Material 3 dropdown that opens a bottom sheet with checkmarks,
/// subtle dividers, and smooth open/close animations.
class _InspectionDropdown extends StatefulWidget {
  const _InspectionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_InspectionDropdown> createState() => _InspectionDropdownState();
}

class _InspectionDropdownState extends State<_InspectionDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _iconController;
  late final Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue =
        widget.value.isNotEmpty && widget.options.contains(widget.value);

    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isFocused: _isOpen,
        isEmpty: !hasValue,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(
            Icons.view_list_outlined,
            size: 20,
            color: _isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          suffixIcon: RotationTransition(
            turns: _iconTurns,
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color:
                  _isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        child: hasValue
            ? Text(
                widget.value,
                style: theme.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
    );
  }

  void _openSheet(BuildContext parentContext) {
    final theme = Theme.of(parentContext);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(parentContext).size.height;
    final bottomPadding = MediaQuery.of(parentContext).viewPadding.bottom;

    setState(() => _isOpen = true);
    _iconController.forward();

    const headerHeight = 76.0;
    const itemHeight = 49.0;
    final contentHeight =
        headerHeight + (widget.options.length * itemHeight) + bottomPadding;
    final maxHeight = screenHeight * 0.7;
    final sheetHeight =
        contentHeight.clamp(headerHeight + itemHeight, maxHeight);

    showModalBottomSheet<String>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
            // Options list
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding + 4),
                itemCount: widget.options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 20,
                  color: colorScheme.outlineVariant.withOpacity(0.15),
                ),
                itemBuilder: (_, index) {
                  final option = widget.options[index];
                  final isSelected = option == widget.value;

                  return _DropdownOption(
                    label: option,
                    isSelected: isSelected,
                    onTap: () {
                      widget.onChanged(option);
                      Navigator.pop(sheetContext, option);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isOpen = false);
        _iconController.reverse();
      }
    });
  }
}

class _DropdownOption extends StatelessWidget {
  const _DropdownOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InspectionPhrasePreview extends StatefulWidget {
  const InspectionPhrasePreview({
    required this.phraseText,
    required this.isEdited,
    this.userNote = '',
    this.onPhraseTextChanged,
    this.onRegenerate,
    this.onUserNoteChanged,
    super.key,
  });

  /// The text to display — either auto-generated phrases joined by \n\n
  /// or the user's manually edited text.
  final String phraseText;

  /// Whether [phraseText] is the user's own edited version.
  final bool isEdited;

  final String userNote;
  final ValueChanged<String>? onPhraseTextChanged;
  final VoidCallback? onRegenerate;
  final ValueChanged<String>? onUserNoteChanged;

  @override
  State<InspectionPhrasePreview> createState() =>
      _InspectionPhrasePreviewState();
}

class _InspectionPhrasePreviewState extends State<InspectionPhrasePreview> {
  bool _isEditingPhrases = false;
  bool _isEditingNote = false;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.userNote);
  }

  @override
  void didUpdateWidget(InspectionPhrasePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync note controller
    if (oldWidget.userNote != widget.userNote && !_isEditingNote) {
      _noteController.text = widget.userNote;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = widget.userNote.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row with action buttons ──
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isEditingPhrases)
                // "Done" button when editing
                InkWell(
                  onTap: () => setState(() => _isEditingPhrases = false),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else ...[
                // Edit button
                InkWell(
                  onTap: () => setState(() => _isEditingPhrases = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // Regenerate button (only when user has edited)
                if (widget.isEdited) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      widget.onRegenerate?.call();
                      setState(() => _isEditingPhrases = false);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 8),

          // ── Phrase text area ──
          if (_isEditingPhrases)
            VoiceTextFormField(
              initialValue: widget.phraseText,
              maxLines: null,
              minLines: 3,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              hintText: 'Edit preview text...',
              fieldBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              onChanged: (value) => widget.onPhraseTextChanged?.call(value),
            )
          else
            // Read-only display
            Text(
              widget.phraseText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),

          // ── Divider + User note section ──
          if (widget.phraseText.isNotEmpty && (hasNote || _isEditingNote))
            Divider(
              height: 16,
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),

          if (_isEditingNote) ...[
            TextField(
              controller: _noteController,
              maxLines: 3,
              minLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              decoration: InputDecoration(
                hintText: 'Add your observation...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              onChanged: widget.onUserNoteChanged,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _isEditingNote = false),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Done'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  textStyle: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ] else if (hasNote) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note_rounded,
                    size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.userNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isEditingNote = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_rounded,
                        size: 16, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () => setState(() => _isEditingNote = true),
              icon: Icon(Icons.edit_note_rounded,
                  size: 18, color: theme.colorScheme.primary),
              label: Text(
                'Add Note',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
