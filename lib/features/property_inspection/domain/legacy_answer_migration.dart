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
