/// Answers saved before a single-choice dropdown became multiple selection
/// (client edit list, 2 Nov 2026). The old value becomes its tick when the answers
/// are read, so surveys already in progress keep what the surveyor chose.
library;

const _dropdownToTicks = <String, Map<String, Map<String, String>>>{
  'activity_outside_property_main_walls_movements': {
    'actv_movement_status': {
      'Minor subsidence': 'mv_minor_subsidence',
      'Significant subsidence': 'mv_significant_subsidence',
      'No structural movement': 'mv_no_structural_movement',
      'Normal defects': 'mv_normal_defects',
      'Recent defects': 'mv_recent_defects',
      'Recurring defects': 'mv_recurring_defects',
      'Differential thermal movement': 'mv_differential_thermal_movement',
      'Restraint steel rods': 'mv_restraint_steel_rods',
    },
  },
  // Movement Cracks: the three choices became separate ticks (client file 6, 13 Nov 2026).
  'activity_in_side_property_wap_movement_cracks': {
    'android_material_design_spinner3': {
      'Minor cracking': 'cb_f3_minor',
      'Significant cracking': 'cb_f3_significant',
      'Structural Movement': 'cb_f3_structural',
    },
  },
  // Other Communal Areas: the dropdown became separate ticks (client file 6, 13 Nov 2026).
  'activity_in_side_property_other_communal_area': {
    'actv_status': {
      'Not inspected': 'cb_f9_not_inspected',
      'No defects noted': 'cb_f9_no_defects',
      'Wear and tear noted': 'cb_f9_wear',
      'Poor condition': 'cb_f9_poor',
    },
  },
  'activity_services_heating_main_screen': {
    'actv_location': {
      'Kitchen': 'g4b_kitchen',
      'Utility': 'g4b_utility',
      'Bedroom': 'g4b_bedroom',
      'Garage': 'g4b_garage',
      'Lounge': 'g4b_lounge',
      'Chimney breast': 'g4b_chimney_breast',
      'Other': 'g4b_other',
    },
    'actv_connected_heat': {
      'Radiators': 'g4he_radiators',
      'Underfloor pipes': 'g4he_underfloor_pipes',
      'Other': 'g4he_other',
    },
  },
};

Map<String, String> migrateLegacyAnswers(
  String screenId,
  Map<String, String> answers,
) {
  final fields = _dropdownToTicks[screenId];
  if (fields == null) return answers;

  final out = Map<String, String>.from(answers);
  fields.forEach((dropdownId, ticks) {
    final old = out.remove(dropdownId)?.trim();
    // Once any tick is saved the surveyor has moved on from the old value.
    if (ticks.values.any(out.containsKey)) return;
    final tick = ticks[old];
    if (tick != null) out[tick] = 'true';
  });
  return out;
}

/// Fields that moved to a new screen: new screen -> old screen, field id prefix.
const movedAnswers = <String, ({String fromScreen, String fieldPrefix})>{
  'activity_outside_property_windows_sill_defect': (
    fromScreen: 'activity_outside_property_windows_sill_projection',
    fieldPrefix: 'e5sd_',
  ),
  'activity_inside_property_other_celler_walls': (
    fromScreen: 'activity_inside_property_other_celler_inspected',
    fieldPrefix: 'f9cw_',
  ),
  'activity_inside_property_other_celler_floor': (
    fromScreen: 'activity_inside_property_other_celler_inspected',
    fieldPrefix: 'f9cf_',
  ),
  'activity_inside_property_other_celler_condition': (
    fromScreen: 'activity_inside_property_other_celler_inspected',
    fieldPrefix: 'actv_condition',
  ),
};

/// Answers saved on the old screen show on the new one until it has its own.
Map<String, String> mergeMovedAnswers(
  String screenId,
  Map<String, String> answers,
  Map<String, String> oldScreenAnswers,
) {
  final moved = movedAnswers[screenId];
  if (moved == null) return answers;
  return {
    for (final entry in oldScreenAnswers.entries)
      if (entry.key.startsWith(moved.fieldPrefix)) entry.key: entry.value,
    ...answers,
  };
}
